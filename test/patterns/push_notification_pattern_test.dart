// Reference implementation: push notifications.
//
// Pattern: .agents/skills/flutter-patterns/references/push_notification.md
// Decision: docs/decisions/D-0007-push-notification-qua-domain-port.md
//
// `firebase_messaging` (proposed in D-0007) is not in pubspec, so the SDK is
// behind a domain port with a documented adapter sketch. Device registration
// (with revisioned writes, as TokenProvider does), payload parsing, and tap
// routing through the deep link parser are compiled and tested here.

import 'dart:async';

import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// lib/domain/entities/push/push_message.dart
// ---------------------------------------------------------------------------

/// A notification the app received. Only the fields the app acts on; the
/// raw SDK payload never leaves the adapter.
final class PushMessage extends Equatable {
  const PushMessage({
    required this.id,
    required this.type,
    this.title,
    this.body,
    this.link,
  });

  /// Parses the data payload. The server contract is:
  /// `{"id": "...", "type": "order_status", "link": "https://app.example.com/orders/o-1"}`.
  /// Unknown types are kept as [PushType.unknown] and never routed.
  static PushMessage? fromData(
    Map<String, Object?> data, {
    String? title,
    String? body,
  }) {
    final id = data['id'];
    if (id is! String || id.isEmpty) return null;
    final rawLink = data['link'];
    return PushMessage(
      id: id,
      type: PushType.values.asNameMap()[data['type']] ?? PushType.unknown,
      title: title,
      body: body,
      link: rawLink is String ? Uri.tryParse(rawLink) : null,
    );
  }

  final String id;
  final PushType type;
  final String? title;
  final String? body;

  /// Where a tap leads. Routed only through `AppLinkParser`.
  final Uri? link;

  @override
  List<Object?> get props => [id, type, title, body, link];
}

/// Server types the app knows. Add a value per new notification type.
enum PushType { orderStatus, promotion, unknown }

enum PushPermission { granted, provisional, denied, notDetermined }

/// How the app received a message.
sealed class PushEvent {
  const PushEvent(this.message);

  final PushMessage message;
}

/// Arrived while the app is in the foreground. The OS shows nothing; the
/// app shows an in-app banner.
final class PushReceivedInForeground extends PushEvent {
  const PushReceivedInForeground(super.message);
}

/// The user tapped a notification: from background, or the one that
/// launched the app from terminated (emitted once, first).
final class PushOpened extends PushEvent {
  const PushOpened(super.message);
}

// ---------------------------------------------------------------------------
// lib/domain/repositories/push_repo.dart
// ---------------------------------------------------------------------------

enum PushFailureCode { unavailable, unknown }

final class PushFailure implements Exception {
  const PushFailure(this.code);

  final PushFailureCode code;

  @override
  String toString() => 'PushFailure($code)';
}

abstract class PushRepo {
  /// Asks the OS once; later calls return the stored answer.
  Future<PushPermission> requestPermission();

  /// The current device token, or null when the platform has none.
  /// Throws [PushFailure] when the push service is unavailable.
  Future<String?> getToken();

  /// New tokens after rotation.
  Stream<String> get tokenRefreshes;

  /// Foreground messages and taps, in order. Never errors.
  Stream<PushEvent> get events;

  /// Deletes the device token so no push reaches a signed-out device.
  Future<void> deleteToken();
}

/// Server side of registration: `POST /devices`, `DELETE /devices/{token}`.
abstract class PushDeviceRepo {
  Future<void> register(String token);

  Future<void> unregister(String token);
}

// Adapter sketch: lib/data/repositories/firebase_push_repo.dart
// Needs `firebase_messaging` 15.x, the line that matches firebase_core 3.x.
//
//   @LazySingleton(as: PushRepo)
//   class FirebasePushRepo implements PushRepo {
//     FirebasePushRepo(this._messaging);       // FirebaseMessaging.instance
//     final FirebaseMessaging _messaging;
//
//     @override
//     Stream<PushEvent> get events async* {
//       final initial = await _messaging.getInitialMessage();
//       final first = initial == null ? null : _map(initial);
//       if (first != null) yield PushOpened(first);
//       yield* StreamGroup.merge([
//         FirebaseMessaging.onMessage.map(_map).whereType<PushMessage>()
//             .map(PushReceivedInForeground.new),
//         FirebaseMessaging.onMessageOpenedApp.map(_map)
//             .whereType<PushMessage>().map(PushOpened.new),
//       ]);
//     }
//
//     PushMessage? _map(RemoteMessage m) => PushMessage.fromData(
//       m.data, title: m.notification?.title, body: m.notification?.body);
//
//     @override
//     Future<PushPermission> requestPermission() async {
//       final s = await _messaging.requestPermission();
//       return switch (s.authorizationStatus) {
//         AuthorizationStatus.authorized => PushPermission.granted,
//         AuthorizationStatus.provisional => PushPermission.provisional,
//         AuthorizationStatus.denied => PushPermission.denied,
//         AuthorizationStatus.notDetermined => PushPermission.notDetermined,
//       };
//     }
//     // getToken, onTokenRefresh, deleteToken map one to one;
//     // FirebaseException -> PushFailure.
//   }
//
// Background isolate: FirebaseMessaging.onBackgroundMessage(handler) in
// bootstrap with a top-level @pragma('vm:entry-point') handler. It has no
// DI graph and no UI; it may only write to local storage.

// ---------------------------------------------------------------------------
// lib/domain/use_case/push_use_case.dart
// ---------------------------------------------------------------------------

/// Owns device registration for the signed-in session. Called by the auth
/// flow: [onSignedIn] after `SessionRepo.start`, [onSignedOut] from the
/// session end path, so no user's pushes reach the next user of the device.
class PushUseCase {
  PushUseCase(this._push, this._devices);

  final PushRepo _push;
  final PushDeviceRepo _devices;

  StreamSubscription<String>? _refreshes;
  String? _registeredToken;

  /// Bumped by every sign-in and sign-out. A slow registration from an older
  /// session must not register a token after sign-out (storage rule 6).
  int _revision = 0;

  Stream<PushEvent> get events => _push.events;

  Future<PushPermission> requestPermission() => _push.requestPermission();

  Future<void> onSignedIn() async {
    final revision = ++_revision;
    await _refreshes?.cancel();
    _refreshes = _push.tokenRefreshes.listen(
      (token) => _register(token, revision),
    );
    final token = await _push.getToken();
    if (token != null) await _register(token, revision);
  }

  Future<void> onSignedOut() async {
    ++_revision;
    await _refreshes?.cancel();
    _refreshes = null;
    final token = _registeredToken;
    _registeredToken = null;
    try {
      if (token != null) await _devices.unregister(token);
    } finally {
      // Even when the server call fails, the device stops receiving pushes.
      await _push.deleteToken();
    }
  }

  Future<void> _register(String token, int revision) async {
    if (revision != _revision || token == _registeredToken) return;
    await _devices.register(token);
    if (revision != _revision) {
      // Signed out while the request was in flight: undo it.
      await _devices.unregister(token);
      return;
    }
    _registeredToken = token;
  }
}

// ---------------------------------------------------------------------------
// lib/presentation/push/cubit/push_effect.dart  (part)
// App-scope Cubit, resolved once in buildMainApp().
// ---------------------------------------------------------------------------

sealed class PushEffect {
  const PushEffect();
}

/// Foreground message: the Screen shows an in-app banner (Flushbar).
final class PushShowBannerEffect extends PushEffect {
  const PushShowBannerEffect(this.message);

  final PushMessage message;
}

/// A tap: the app listener passes the link to `DeepLinkCubit.openUri`, which
/// applies the allowlist, the ready gate and the session gate.
final class PushOpenLinkEffect extends PushEffect {
  const PushOpenLinkEffect(this.link);

  final Uri link;
}

// ---------------------------------------------------------------------------
// lib/presentation/push/cubit/push_state.dart  (part)
// ---------------------------------------------------------------------------

class PushState extends BaseAppState<Object> {
  const PushState({
    required super.loading,
    super.error,
    this.permission = PushPermission.notDetermined,
    this.effect,
  });

  factory PushState.initial() =>
      const PushState(loading: LoadingStatus.initial);

  final PushPermission permission;
  final UiEffect<PushEffect>? effect;

  PushState copyWith({
    LoadingStatus? loading,
    Object? error,
    PushPermission? permission,
    UiEffect<PushEffect>? effect,
  }) {
    return PushState(
      loading: loading ?? this.loading,
      error: error,
      permission: permission ?? this.permission,
      effect: effect ?? this.effect,
    );
  }

  @override
  List<Object?> get props => [loading, error, permission, effect];
}

// ---------------------------------------------------------------------------
// lib/presentation/push/cubit/push_cubit.dart
// ---------------------------------------------------------------------------

// @injectable
class PushCubit extends BaseCubit<PushState> {
  PushCubit(this._useCase) : super(PushState.initial());

  final PushUseCase _useCase;
  StreamSubscription<PushEvent>? _events;

  /// Called once from MainApp.initState.
  void start() {
    _events ??= _useCase.events.listen(_onEvent);
  }

  /// Called from a screen that explains why (soft prompt), never at launch.
  Future<void> requestPermission() async {
    final permission = await _useCase.requestPermission();
    if (isClosed) return;
    emit(state.copyWith(permission: permission));
  }

  void _onEvent(PushEvent event) {
    if (isClosed) return;
    final effect = switch (event) {
      PushReceivedInForeground(:final message) => PushShowBannerEffect(message),
      PushOpened(:final message) when message.link != null =>
        PushOpenLinkEffect(message.link!),
      PushOpened() => null,
    };
    if (effect != null) {
      emit(state.copyWith(effect: createEffect<PushEffect>(effect)));
    }
  }

  @override
  Future<void> close() async {
    await _events?.cancel();
    return super.close();
  }
}

// ===========================================================================
// Tests
// ===========================================================================

void main() {
  group('PushMessage.fromData', () {
    test('parses the data contract', () {
      final message = PushMessage.fromData({
        'id': 'n-1',
        'type': 'orderStatus',
        'link': 'https://app.example.com/orders/o-1',
      }, title: 'Order shipped');

      expect(message!.type, PushType.orderStatus);
      expect(message.link, Uri.parse('https://app.example.com/orders/o-1'));
      expect(message.title, 'Order shipped');
    });

    test('unknown type is kept; missing id is dropped', () {
      expect(
        PushMessage.fromData({'id': 'n-1', 'type': 'survey'})!.type,
        PushType.unknown,
      );
      expect(PushMessage.fromData({'type': 'orderStatus'}), isNull);
      expect(PushMessage.fromData({'id': 42}), isNull);
    });
  });

  group('PushUseCase', () {
    late _FakePushRepo push;
    late _FakeDeviceRepo devices;
    late PushUseCase useCase;

    setUp(() {
      push = _FakePushRepo();
      devices = _FakeDeviceRepo();
      useCase = PushUseCase(push, devices);
    });

    test('sign-in registers the current token', () async {
      await useCase.onSignedIn();

      expect(devices.registered, {'token-1'});
    });

    test('a rotated token is registered while signed in', () async {
      await useCase.onSignedIn();

      push.refreshes.add('token-2');
      await pumpEventQueue();

      expect(devices.registered, {'token-1', 'token-2'});
    });

    test('sign-out unregisters and deletes the token', () async {
      await useCase.onSignedIn();

      await useCase.onSignedOut();
      push.refreshes.add('token-3');
      await pumpEventQueue();

      expect(devices.registered, isEmpty);
      expect(push.deleted, 1);
    });

    test('sign-out deletes the device token even if the API fails', () async {
      await useCase.onSignedIn();
      devices.failUnregister = true;

      await expectLater(useCase.onSignedOut(), throwsStateError);

      expect(push.deleted, 1);
    });

    test('a registration that finishes after sign-out is undone', () async {
      devices.hold = Completer<void>();
      final signingIn = useCase.onSignedIn();
      await pumpEventQueue();

      final signingOut = useCase.onSignedOut();
      devices.hold!.complete();
      await Future.wait([signingIn, signingOut]);

      expect(devices.registered, isEmpty);
    });
  });

  group('PushCubit', () {
    late _FakePushRepo push;
    late PushCubit cubit;

    setUp(() {
      push = _FakePushRepo();
      cubit = PushCubit(PushUseCase(push, _FakeDeviceRepo()))..start();
    });

    tearDown(() => cubit.close());

    const message = PushMessage(
      id: 'n-1',
      type: PushType.orderStatus,
      title: 'Order shipped',
    );

    test('a foreground message becomes a banner effect', () async {
      push.incoming.add(const PushReceivedInForeground(message));
      await pumpEventQueue();

      final effect = cubit.state.effect!.value as PushShowBannerEffect;
      expect(effect.message, message);
    });

    test('a tap with a link becomes an open-link effect', () async {
      final link = Uri.parse('https://app.example.com/orders/o-1');
      push.incoming.add(
        PushOpened(
          PushMessage(id: 'n-2', type: PushType.orderStatus, link: link),
        ),
      );
      await pumpEventQueue();

      final effect = cubit.state.effect!.value as PushOpenLinkEffect;
      expect(effect.link, link);
    });

    test('a tap without a link only opens the app', () async {
      push.incoming.add(const PushOpened(message));
      await pumpEventQueue();

      expect(cubit.state.effect, isNull);
    });

    test('permission result is kept in state', () async {
      push.permission = PushPermission.denied;

      await cubit.requestPermission();

      expect(cubit.state.permission, PushPermission.denied);
    });

    test('close stops listening', () async {
      await cubit.close();

      expect(push.incoming.hasListener, isFalse);
    });
  });
}

class _FakePushRepo implements PushRepo {
  final StreamController<String> refreshes = StreamController.broadcast();
  final StreamController<PushEvent> incoming = StreamController.broadcast();
  PushPermission permission = PushPermission.granted;
  String? token = 'token-1';
  int deleted = 0;

  @override
  Future<PushPermission> requestPermission() async => permission;

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get tokenRefreshes => refreshes.stream;

  @override
  Stream<PushEvent> get events => incoming.stream;

  @override
  Future<void> deleteToken() async => deleted++;
}

class _FakeDeviceRepo implements PushDeviceRepo {
  final Set<String> registered = {};
  Completer<void>? hold;
  bool failUnregister = false;

  @override
  Future<void> register(String token) async {
    await hold?.future;
    registered.add(token);
  }

  @override
  Future<void> unregister(String token) async {
    if (failUnregister) throw StateError('server down');
    registered.remove(token);
  }
}
