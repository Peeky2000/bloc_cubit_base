// Reference implementation: offline cache with stale-while-revalidate.
//
// Pattern: .agents/skills/flutter-patterns/references/offline_cache.md
// Decision: docs/decisions/D-0003-cache-offline-theo-stale-while-revalidate.md
//
// The repository owns cache + network and exposes one Stream of snapshots:
// the saved value first (when there is one), then the fresh value. The Cubit
// only renders snapshots; it never decides between cache and network.

import 'dart:async';
import 'dart:convert';

import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/core/error/exception.dart';
import 'package:bloc_cubit_base/domain/entities/profile/account.dart';
import 'package:bloc_cubit_base/domain/repositories/session_repo.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// lib/domain/entities/common/cached_snapshot.dart  (shared; add once)
// ---------------------------------------------------------------------------

enum SnapshotSource { cache, network }

/// One value from a stale-while-revalidate read.
final class CachedSnapshot<T> extends Equatable {
  const CachedSnapshot({
    required this.value,
    required this.source,
    required this.fetchedAt,
    required this.revalidating,
  });

  final T value;
  final SnapshotSource source;

  /// When the server produced this value. The Screen shows "updated at".
  final DateTime fetchedAt;

  /// True when a network snapshot will follow this one.
  final bool revalidating;

  @override
  List<Object?> get props => [value, source, fetchedAt, revalidating];
}

// ---------------------------------------------------------------------------
// lib/domain/entities/dashboard/dashboard_summary.dart
// ---------------------------------------------------------------------------

abstract class DashboardSummary {
  int get orderCount;

  int get revenue;
}

// ---------------------------------------------------------------------------
// lib/domain/repositories/dashboard_repo.dart
// ---------------------------------------------------------------------------

abstract class DashboardRepo {
  /// Emits the saved summary first when one exists for the signed-in
  /// account, then the network summary unless the saved one is younger than
  /// the freshness window and [forceRefresh] is false. Ends after the last
  /// snapshot. A network failure is a stream error after the saved snapshot.
  Stream<CachedSnapshot<DashboardSummary>> watchSummary({
    bool forceRefresh = false,
  });

  /// Removes the saved summary. Called from the session end path.
  Future<void> clearCache();
}

// ---------------------------------------------------------------------------
// lib/domain/use_case/dashboard_use_case.dart
// ---------------------------------------------------------------------------

class DashboardUseCase {
  DashboardUseCase(this._repo);

  final DashboardRepo _repo;

  Stream<CachedSnapshot<DashboardSummary>> watchSummary({
    bool forceRefresh = false,
  }) => _repo.watchSummary(forceRefresh: forceRefresh);
}

// ---------------------------------------------------------------------------
// lib/data/model/response/dashboard/dashboard_summary_response_model.dart
// In the app this is @JsonSerializable.
// ---------------------------------------------------------------------------

class DashboardSummaryResponseModel implements DashboardSummary {
  DashboardSummaryResponseModel({
    required this.orderCount,
    required this.revenue,
  });

  factory DashboardSummaryResponseModel.fromJson(Map<String, dynamic> json) =>
      DashboardSummaryResponseModel(
        orderCount: json['orderCount'] as int,
        revenue: json['revenue'] as int,
      );

  @override
  final int orderCount;

  @override
  final int revenue;

  Map<String, dynamic> toJson() => {
    'orderCount': orderCount,
    'revenue': revenue,
  };
}

// ---------------------------------------------------------------------------
// lib/data/datasource/remote/dashboard_remote_data_source.dart
// ---------------------------------------------------------------------------

abstract class DashboardRemoteDataSource {
  /// `ApiHandler.get` in the app; throws NetworkIssueException offline.
  Future<DashboardSummaryResponseModel> getSummary();
}

// ---------------------------------------------------------------------------
// lib/data/datasource/local/dashboard_local_data_source.dart
// ---------------------------------------------------------------------------

/// What is stored: the value plus who owns it and when it was fetched.
final class CacheEntry<T> {
  const CacheEntry({
    required this.ownerId,
    required this.fetchedAt,
    required this.value,
  });

  final String ownerId;
  final DateTime fetchedAt;
  final T value;
}

abstract class DashboardLocalDataSource {
  CacheEntry<DashboardSummaryResponseModel>? read();

  Future<void> write(CacheEntry<DashboardSummaryResponseModel> entry);

  Future<void> clear();
}

// @LazySingleton(as: DashboardLocalDataSource)
class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  DashboardLocalDataSourceImpl(this._preferences);

  /// Bump the suffix when the stored shape changes; old keys become misses.
  static const String key = 'cache.dashboard_summary.v1';

  final SharedPreferences _preferences;

  @override
  CacheEntry<DashboardSummaryResponseModel>? read() {
    final raw = _preferences.getString(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CacheEntry(
        ownerId: json['ownerId'] as String,
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
        value: DashboardSummaryResponseModel.fromJson(
          json['value'] as Map<String, dynamic>,
        ),
      );
    } on Object {
      // A corrupt or outdated entry is a miss, never a crash.
      unawaited(_preferences.remove(key));
      return null;
    }
  }

  @override
  Future<void> write(CacheEntry<DashboardSummaryResponseModel> entry) =>
      _preferences.setString(
        key,
        jsonEncode({
          'ownerId': entry.ownerId,
          'fetchedAt': entry.fetchedAt.toUtc().toIso8601String(),
          'value': entry.value.toJson(),
        }),
      );

  @override
  Future<void> clear() => _preferences.remove(key);
}

// ---------------------------------------------------------------------------
// lib/data/repositories/dashboard_repo_impl.dart
// ---------------------------------------------------------------------------

// @LazySingleton(as: DashboardRepo)
class DashboardRepoImpl implements DashboardRepo {
  DashboardRepoImpl(
    this._remote,
    this._local,
    this._session, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// A saved value younger than this is shown without a network call.
  static const Duration freshFor = Duration(minutes: 5);

  final DashboardRemoteDataSource _remote;
  final DashboardLocalDataSource _local;
  final SessionRepo _session;
  final DateTime Function() _now;

  /// Bumped by every network read. Only the newest read may write the cache,
  /// so a slow older response cannot overwrite a newer one (storage rule 6).
  int _revision = 0;

  String get _ownerId => '${_session.account.id ?? ''}';

  @override
  Stream<CachedSnapshot<DashboardSummary>> watchSummary({
    bool forceRefresh = false,
  }) async* {
    final owner = _ownerId;
    final saved = _local.read();
    if (saved != null && saved.ownerId == owner) {
      final fresh = _now().difference(saved.fetchedAt) < freshFor;
      final revalidate = forceRefresh || !fresh;
      yield CachedSnapshot(
        value: saved.value,
        source: SnapshotSource.cache,
        fetchedAt: saved.fetchedAt,
        revalidating: revalidate,
      );
      if (!revalidate) return;
    }

    final revision = ++_revision;
    final remote = await _remote.getSummary();
    final fetchedAt = _now();
    // Skip the write when a newer read started or the account changed.
    if (revision == _revision && _ownerId == owner) {
      await _local.write(
        CacheEntry(ownerId: owner, fetchedAt: fetchedAt, value: remote),
      );
    }
    yield CachedSnapshot(
      value: remote,
      source: SnapshotSource.network,
      fetchedAt: fetchedAt,
      revalidating: false,
    );
  }

  @override
  Future<void> clearCache() => _local.clear();
}

// ---------------------------------------------------------------------------
// lib/presentation/dashboard/cubit/dashboard_state.dart  (part file)
// ---------------------------------------------------------------------------

class DashboardState extends BaseAppState<Object> {
  const DashboardState({
    required super.loading,
    super.error,
    this.summary,
    this.updatedAt,
  });

  factory DashboardState.initial() =>
      const DashboardState(loading: LoadingStatus.initial);

  final DashboardSummary? summary;

  /// `fetchedAt` of the summary on screen.
  final DateTime? updatedAt;

  /// Saved data is on screen but the latest refresh failed: the Screen shows
  /// an "offline, last updated at ..." banner with a retry button. This is
  /// lasting state, not a one-shot effect.
  bool get showsSavedData => summary != null && error != null;

  DashboardState copyWith({
    LoadingStatus? loading,
    Object? error,
    DashboardSummary? summary,
    DateTime? updatedAt,
  }) {
    return DashboardState(
      loading: loading ?? this.loading,
      error: error,
      summary: summary ?? this.summary,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [loading, error, summary, updatedAt];
}

// ---------------------------------------------------------------------------
// lib/presentation/dashboard/cubit/dashboard_cubit.dart
// ---------------------------------------------------------------------------

// @injectable
class DashboardCubit extends BaseCubit<DashboardState> {
  DashboardCubit(this._useCase) : super(DashboardState.initial());

  final DashboardUseCase _useCase;
  int _generation = 0;

  @override
  Future<void> load() => _watch(forceRefresh: false);

  /// Pull-to-refresh and the banner's retry button.
  Future<void> refresh() => _watch(forceRefresh: true);

  Future<void> _watch({required bool forceRefresh}) async {
    final generation = ++_generation;
    final hasData = state.summary != null;
    emit(
      state.copyWith(
        loading: hasData ? LoadingStatus.refresh : LoadingStatus.loading,
        error: state.error,
      ),
    );
    try {
      await for (final snapshot in _useCase.watchSummary(
        forceRefresh: forceRefresh,
      )) {
        // Leaving the loop cancels the stream of a superseded request.
        if (isClosed || generation != _generation) return;
        emit(
          state.copyWith(
            loading: snapshot.revalidating
                ? LoadingStatus.refresh
                : LoadingStatus.complete,
            summary: snapshot.value,
            updatedAt: snapshot.fetchedAt,
          ),
        );
      }
    } catch (error) {
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          loading: state.summary == null
              ? LoadingStatus.error
              : LoadingStatus.complete,
          error: error,
        ),
      );
    }
  }
}

// ===========================================================================
// Tests
// ===========================================================================

void main() {
  late SharedPreferences preferences;
  late _FakeRemote remote;
  late _FakeSession session;
  late DateTime now;
  late DashboardRepoImpl repo;

  DashboardRepoImpl boot() => DashboardRepoImpl(
    remote,
    DashboardLocalDataSourceImpl(preferences),
    session,
    now: () => now,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    remote = _FakeRemote();
    session = _FakeSession(accountId: 7);
    now = DateTime.utc(2026, 10, 8, 9);
    repo = boot();
  });

  group('DashboardRepoImpl', () {
    test('first read has no cache: network only, then saved', () async {
      final snapshots = await repo.watchSummary().toList();

      expect(snapshots.map((s) => s.source), [SnapshotSource.network]);
      expect(snapshots.single.value.orderCount, 1);
      expect(
        preferences.getString(DashboardLocalDataSourceImpl.key),
        isNotNull,
      );
    });

    test('saved value survives a restart and is shown first', () async {
      await repo.watchSummary().drain<void>();
      now = now.add(const Duration(hours: 1));
      repo = boot();

      final snapshots = await repo.watchSummary().toList();

      expect(snapshots.map((s) => s.source), [
        SnapshotSource.cache,
        SnapshotSource.network,
      ]);
      expect(snapshots.first.revalidating, isTrue);
      expect(snapshots.first.value.orderCount, 1);
      expect(snapshots.last.value.orderCount, 2);
      expect(snapshots.last.fetchedAt, now);
    });

    test('a fresh saved value skips the network', () async {
      await repo.watchSummary().drain<void>();
      now = now.add(const Duration(minutes: 1));

      final snapshots = await repo.watchSummary().toList();

      expect(snapshots.single.source, SnapshotSource.cache);
      expect(snapshots.single.revalidating, isFalse);
      expect(remote.calls, 1);
    });

    test('forceRefresh revalidates even a fresh value', () async {
      await repo.watchSummary().drain<void>();

      final snapshots = await repo.watchSummary(forceRefresh: true).toList();

      expect(snapshots.map((s) => s.source), [
        SnapshotSource.cache,
        SnapshotSource.network,
      ]);
    });

    test('offline: the saved value, then the network error', () async {
      await repo.watchSummary().drain<void>();
      remote.failNext = NetworkIssueException();
      final received = <Object>[];

      await repo
          .watchSummary(forceRefresh: true)
          .handleError(received.add)
          .forEach(received.add);

      expect(received.first, isA<CachedSnapshot<DashboardSummary>>());
      expect(received.last, isA<NetworkIssueException>());
    });

    test('another account never sees the saved value', () async {
      await repo.watchSummary().drain<void>();
      session.accountId = 8;

      final snapshots = await repo.watchSummary().toList();

      expect(snapshots.single.source, SnapshotSource.network);
    });

    test('clearCache removes the saved value', () async {
      await repo.watchSummary().drain<void>();
      await repo.clearCache();
      repo = boot();

      final snapshots = await repo.watchSummary().toList();

      expect(snapshots.single.source, SnapshotSource.network);
    });

    test('a corrupt entry is a miss and is removed', () async {
      await preferences.setString(DashboardLocalDataSourceImpl.key, '{oops');

      final snapshots = await repo.watchSummary().toList();

      expect(snapshots.single.source, SnapshotSource.network);
      final stored = preferences.getString(DashboardLocalDataSourceImpl.key)!;
      expect(jsonDecode(stored), isA<Map<String, dynamic>>());
    });
  });

  group('DashboardCubit', () {
    late DashboardCubit cubit;

    setUp(() => cubit = DashboardCubit(DashboardUseCase(repo)));
    tearDown(() => cubit.close());

    test('no cache: loading, then the network value', () async {
      final states = await _record(cubit, cubit.load);

      expect(states.map((s) => s.loading), [
        LoadingStatus.loading,
        LoadingStatus.complete,
      ]);
      expect(cubit.state.summary!.orderCount, 1);
      expect(cubit.state.updatedAt, now);
    });

    test('with cache: saved value at once, then the fresh one', () async {
      await repo.watchSummary().drain<void>();
      now = now.add(const Duration(hours: 1));

      final states = await _record(cubit, cubit.load);

      expect(states.map((s) => s.loading), [
        LoadingStatus.loading,
        LoadingStatus.refresh,
        LoadingStatus.complete,
      ]);
      expect(states[1].summary!.orderCount, 1);
      expect(states[2].summary!.orderCount, 2);
    });

    test('offline with cache keeps the data and shows the banner', () async {
      await repo.watchSummary().drain<void>();
      remote.failNext = NetworkIssueException();

      await cubit.refresh();

      expect(cubit.state.loading, LoadingStatus.complete);
      expect(cubit.state.summary!.orderCount, 1);
      expect(cubit.state.showsSavedData, isTrue);
      expect(cubit.state.error, isA<NetworkIssueException>());
    });

    test('a successful retry clears the banner', () async {
      await repo.watchSummary().drain<void>();
      remote.failNext = NetworkIssueException();
      await cubit.refresh();

      await cubit.refresh();

      expect(cubit.state.showsSavedData, isFalse);
      expect(cubit.state.summary!.orderCount, 3);
    });

    test('offline without cache is a full-screen error', () async {
      remote.failNext = NetworkIssueException();

      await cubit.load();

      expect(cubit.state.loading, LoadingStatus.error);
      expect(cubit.state.summary, isNull);
      expect(cubit.state.showsSavedData, isFalse);
    });

    test('a newer request wins on screen and in the cache', () async {
      remote.hold = true;
      final first = cubit.load();
      await pumpEventQueue();
      remote.hold = false;

      await cubit.refresh();
      remote.release();
      await first;

      expect(cubit.state.loading, LoadingStatus.complete);
      expect(cubit.state.summary!.orderCount, 2);
      final saved = await repo.watchSummary().first;
      expect(saved.source, SnapshotSource.cache);
      expect(saved.value.orderCount, 2);
    });

    test('a snapshot that arrives after close is ignored', () async {
      remote.hold = true;
      final loading = cubit.load();
      await pumpEventQueue();
      await cubit.close();
      remote.release();

      await expectLater(loading, completes);
    });
  });
}

Future<List<DashboardState>> _record(
  DashboardCubit cubit,
  Future<void> Function() action,
) async {
  final states = <DashboardState>[];
  final sub = cubit.stream.listen(states.add);
  await action();
  await Future<void>.delayed(Duration.zero);
  await sub.cancel();
  return states;
}

class _FakeRemote implements DashboardRemoteDataSource {
  int calls = 0;
  Object? failNext;
  bool hold = false;
  final List<Completer<void>> _gates = [];

  void release() {
    for (final gate in _gates) {
      gate.complete();
    }
    _gates.clear();
  }

  @override
  Future<DashboardSummaryResponseModel> getSummary() async {
    final call = ++calls;
    if (hold) {
      final gate = Completer<void>();
      _gates.add(gate);
      await gate.future;
    }
    final failure = failNext;
    if (failure != null) {
      failNext = null;
      throw failure;
    }
    return DashboardSummaryResponseModel(orderCount: call, revenue: call * 100);
  }
}

class _FakeSession extends Fake implements SessionRepo {
  _FakeSession({required this.accountId});

  int accountId;

  @override
  Account get account => _FakeAccount(accountId);
}

class _FakeAccount extends Fake implements Account {
  _FakeAccount(this.id);

  @override
  final int id;
}
