// Reference implementation: offline cache with stale-while-revalidate.
//
// Pattern: .agents/skills/flutter-patterns/references/offline_cache.md
// Decision: docs/decisions/D-0003-cache-offline-theo-stale-while-revalidate.md
//
// The repository owns cache + network and exposes one Stream of snapshots:
// the saved value first (when there is one), then the fresh value. The Cubit
// only renders snapshots; it never decides between cache and network, and it
// revalidates by itself when the network comes back.

import 'dart:async';
import 'dart:convert';

import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/core/error/exception.dart';
import 'package:bloc_cubit_base/core/helper/network/network_checker.dart';
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

  /// When this device received the value from the server (device clock).
  /// The Screen shows it as "updated at" whenever saved data is on screen
  /// without a fresh copy.
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
  /// Emits the saved summary first when one exists for the signed-in account
  /// and is not expired, then the network summary unless the saved one is
  /// still fresh and [forceRefresh] is false. Ends after the last snapshot. A
  /// network failure is a stream error after the saved snapshot.
  Stream<CachedSnapshot<DashboardSummary>> watchSummary({
    bool forceRefresh = false,
  });

  /// Removes the saved summary, for example after an edit that makes it
  /// wrong. Sign-out clears every cache through `UserCacheCleaner`.
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
// lib/data/datasource/local/user_cache_cleaner.dart  (shared; add once)
// ---------------------------------------------------------------------------

/// Every cache entry that belongs to a user is stored under [prefix]. The
/// session end path (`SessionRepoImpl.end()`, shared by sign-out and expiry)
/// calls [clearAll] once, so no feature cache can be forgotten (storage rules
/// 1, 4 and 5). Device settings use other keys and stay.
// @lazySingleton
class UserCacheCleaner {
  UserCacheCleaner(this._preferences);

  static const String prefix = 'cache.';

  final SharedPreferences _preferences;

  Future<void> clearAll() async {
    final keys = _preferences.getKeys().where((key) => key.startsWith(prefix));
    await Future.wait([
      for (final key in keys.toList()) _preferences.remove(key),
    ]);
  }
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

  /// One key per feature; the owner is inside the entry, so the device never
  /// holds two accounts' data. Bump the suffix when the stored shape changes:
  /// the old key becomes a miss and is removed at the next sign-out.
  static const String key = '${UserCacheCleaner.prefix}dashboard_summary.v1';

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

  /// A saved value older than this is never shown, not even offline: it is
  /// removed and read as a miss. The product sets it per feature.
  static const Duration maxStale = Duration(days: 7);

  final DashboardRemoteDataSource _remote;
  final DashboardLocalDataSource _local;
  final SessionRepo _session;
  final DateTime Function() _now;

  /// Bumped by every network read. Only the newest read may write the cache,
  /// so a slow older response cannot overwrite a newer one (storage rule 6).
  int _revision = 0;

  /// Null when nobody is signed in: nothing is read or saved then.
  String? get _ownerId {
    final id = _session.account.id;
    return id == null ? null : '$id';
  }

  @override
  Stream<CachedSnapshot<DashboardSummary>> watchSummary({
    bool forceRefresh = false,
  }) async* {
    final owner = _ownerId;
    final saved = owner == null ? null : await _readUsable(owner);
    if (saved != null) {
      final age = _now().difference(saved.fetchedAt);
      // A fetch time in the future means the clock moved: never fresh.
      final fresh = !age.isNegative && age < freshFor;
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
    if (owner != null && revision == _revision && _ownerId == owner) {
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

  /// The saved entry of [owner], or null. An entry past [maxStale] is
  /// removed: very old data is worse than an honest error.
  Future<CacheEntry<DashboardSummaryResponseModel>?> _readUsable(
    String owner,
  ) async {
    final saved = _local.read();
    if (saved == null || saved.ownerId != owner) return null;
    if (_now().difference(saved.fetchedAt) > maxStale) {
      await _local.clear();
      return null;
    }
    return saved;
  }
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
  DashboardCubit(this._useCase, NetworkChecker network)
    : super(DashboardState.initial()) {
    _connection = network.connectionChanges.listen(_onConnectionChanged);
  }

  final DashboardUseCase _useCase;
  late final StreamSubscription<bool> _connection;
  int _generation = 0;

  @override
  Future<void> load() => _watch(forceRefresh: false);

  /// Pull-to-refresh and the banner's retry button.
  Future<void> refresh() => _watch(forceRefresh: true);

  /// Revalidates when the network comes back while an error or the offline
  /// banner is shown. Connectivity is only this hint; it never blocks a
  /// request, because a connection does not prove the server is reachable.
  void _onConnectionChanged(bool connected) {
    if (connected && state.error != null) unawaited(refresh());
  }

  @override
  Future<void> close() async {
    await _connection.cancel();
    return super.close();
  }

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
            // Saved data stays marked as saved until a fresh copy arrives,
            // so a retry offline does not flash the banner away.
            error: snapshot.revalidating ? state.error : null,
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

    test('an entry past maxStale is never shown and is removed', () async {
      await repo.watchSummary().drain<void>();
      now = now.add(DashboardRepoImpl.maxStale + const Duration(minutes: 1));
      remote.failNext = NetworkIssueException();
      final received = <Object>[];

      await repo.watchSummary().handleError(received.add).forEach(received.add);

      expect(received.single, isA<NetworkIssueException>());
      expect(preferences.getString(DashboardLocalDataSourceImpl.key), isNull);
    });

    test('a fetch time in the future is not trusted as fresh', () async {
      await repo.watchSummary().drain<void>();
      now = now.subtract(const Duration(hours: 1));

      final snapshots = await repo.watchSummary().toList();

      expect(snapshots.map((s) => s.source), [
        SnapshotSource.cache,
        SnapshotSource.network,
      ]);
    });

    test('nothing is read or saved without a signed-in account', () async {
      await repo.watchSummary().drain<void>();
      session.accountId = null;

      final snapshots = await repo.watchSummary().toList();

      expect(snapshots.single.source, SnapshotSource.network);
      final stored = preferences.getString(DashboardLocalDataSourceImpl.key)!;
      expect(jsonDecode(stored)['ownerId'], '7');
    });

    test('a response that lands after sign-out is not saved', () async {
      remote.hold = true;
      final reading = repo.watchSummary().toList();
      await pumpEventQueue();
      session.accountId = null;
      await UserCacheCleaner(preferences).clearAll();

      remote.release();
      await reading;

      expect(preferences.getString(DashboardLocalDataSourceImpl.key), isNull);
    });

    test('sign-out clears every user cache and keeps settings', () async {
      await repo.watchSummary().drain<void>();
      await preferences.setString('${UserCacheCleaner.prefix}other.v1', '{}');
      await preferences.setString('language', 'vi');

      await UserCacheCleaner(preferences).clearAll();

      expect(
        preferences.getKeys().where(
          (key) => key.startsWith(UserCacheCleaner.prefix),
        ),
        isEmpty,
      );
      expect(preferences.getString('language'), 'vi');
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
    late _FakeNetwork network;
    late DashboardCubit cubit;

    setUp(() {
      network = _FakeNetwork();
      cubit = DashboardCubit(DashboardUseCase(repo), network);
    });
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

    test('a retry that fails again keeps the banner the whole time', () async {
      await repo.watchSummary().drain<void>();
      remote.failNext = NetworkIssueException();
      await cubit.refresh();
      remote.failNext = NetworkIssueException();

      final states = await _record(cubit, cubit.refresh);

      expect(states, isNotEmpty);
      expect(states.every((s) => s.showsSavedData), isTrue);
    });

    test('reconnecting revalidates while the banner is shown', () async {
      await repo.watchSummary().drain<void>();
      remote.failNext = NetworkIssueException();
      await cubit.refresh();
      expect(cubit.state.showsSavedData, isTrue);

      network.changes.add(true);
      await pumpEventQueue();

      expect(cubit.state.showsSavedData, isFalse);
      expect(cubit.state.summary!.orderCount, 3);
    });

    test('reconnecting without an error sends nothing', () async {
      await cubit.load();

      network.changes.add(true);
      await pumpEventQueue();

      expect(remote.calls, 1);
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

/// Only the connection stream is used by the Cubit.
class _FakeNetwork extends Fake implements NetworkChecker {
  final StreamController<bool> changes = StreamController<bool>.broadcast();

  @override
  Stream<bool> get connectionChanges => changes.stream;
}

class _FakeSession extends Fake implements SessionRepo {
  _FakeSession({required this.accountId});

  int? accountId;

  @override
  Account get account => _FakeAccount(accountId);
}

class _FakeAccount extends Fake implements Account {
  _FakeAccount(this.id);

  @override
  final int? id;
}
