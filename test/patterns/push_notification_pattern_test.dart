// Reference implementation: push notifications.
//
// Pattern: .agents/skills/flutter-patterns/references/push_notification.md
// Decision: docs/decisions/D-0007-push-notification-qua-domain-port.md
//
// `firebase_messaging` ^16.7.0 (D-0007; needs firebase_core ^4.15.0) is not in
// pubspec yet, so the SDK sits behind a domain port. The adapter below was
// analyzed against firebase_messaging 16.7.0 and flutter_local_notifications
// 19.5.0. Device registration (with revisioned writes, as TokenProvider does),
// payload parsing and tap routing through the deep link parser are compiled
// and tested here.

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

/// `permanentlyDenied`: Android 13+ will not show the dialog again; only
/// system settings can enable notifications. iOS reports this as `denied`.
enum PushPermission {
  granted,
  provisional,
  denied,
  permanentlyDenied,
  notDetermined,
}

/// How the app received a message.
sealed class PushEvent {
  const PushEvent(this.message);

  final PushMessage message;
}

/// Arrived while the app is in the foreground. The OS shows nothing (iOS
/// presentation options stay off, Android never shows FCM notifications in
/// the foreground); the app shows an in-app banner.
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
  /// The current permission, without a dialog.
  Future<PushPermission> permission();

  /// Shows the system dialog when the OS still allows it (Android 13+
  /// `POST_NOTIFICATIONS`, iOS alert/badge/sound); otherwise returns the
  /// current answer.
  Future<PushPermission> requestPermission();

  /// The opaque device address the server sends to (FCM registration token
  /// today), or null when it is not ready yet (iOS before the APNs token);
  /// it then arrives on [tokenRefreshes]. Throws [PushFailure] when the push
  /// service is unavailable (no Google Play services, no network).
  Future<String?> getToken();

  /// New tokens after rotation or first availability.
  Stream<String> get tokenRefreshes;

  /// Foreground messages and taps, in order; the tap that launched the app
  /// is emitted once per process. Never errors.
  Stream<PushEvent> get events;

  /// Deletes the device token so no push reaches a signed-out device.
  /// Throws [PushFailure].
  Future<void> deleteToken();

  /// Removes this app's notifications still shown in the tray.
  Future<void> clearDelivered();
}

/// Server side of registration: `POST /devices`, `DELETE /devices/{token}`.
abstract class PushDeviceRepo {
  Future<void> register(String token);

  Future<void> unregister(String token);
}

// Adapter: lib/data/repositories/firebase_push_repo.dart, analyzed with
// firebase_messaging 16.7.0 + firebase_core 4.15.0 + flutter_local_notifications
// 19.5.0 (`flutter analyze`: no issues). 15.x is the last line for
// firebase_core 3.x but has no UIScene support (16.1.0) and no
// `deniedPermanently` (16.7.0); see D-0007.
//
//   import 'dart:async';
//
//   import 'package:firebase_core/firebase_core.dart';
//   import 'package:firebase_messaging/firebase_messaging.dart';
//   import 'package:flutter/foundation.dart';
//   import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
//   /// Top-level so the OS can start it in a background isolate without the
//   /// app. Registered in bootstrap before runApp:
//   /// `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)`.
//   @pragma('vm:entry-point')
//   Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//     await Firebase.initializeApp();
//     // Notification messages are shown by the OS. No DI, no UI, < 30 s; only
//     // local writes for a data-only message accepted by a decision.
//   }
//
//   @LazySingleton(as: PushRepo)
//   class FirebasePushRepo implements PushRepo {
//     FirebasePushRepo(this._messaging, this._local);
//
//     /// Same id as `default_notification_channel_id` in AndroidManifest.xml.
//     static const channel = AndroidNotificationChannel(
//       'default_channel',
//       'Thông báo', // l10n: channel names are user-visible in Settings
//       importance: Importance.high, // heads-up; cannot be raised later
//     );
//
//     final FirebaseMessaging _messaging; // FirebaseMessaging.instance
//     final FlutterLocalNotificationsPlugin _local; // channel and tray only
//     bool _initialRead = false;
//
//     /// Once from bootstrap after Firebase.initializeApp(). Idempotent.
//     Future<void> createChannel() async {
//       await _local
//           .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin
//           >()
//           ?.createNotificationChannel(channel);
//     }
//
//     @override
//     Stream<PushEvent> get events {
//       final subscriptions = <StreamSubscription<RemoteMessage>>[];
//       late final StreamController<PushEvent> controller;
//
//       void add(RemoteMessage remote, PushEvent Function(PushMessage) wrap) {
//         final message = _map(remote);
//         if (message != null && !controller.isClosed) {
//           controller.add(wrap(message));
//         }
//       }
//
//       controller = StreamController<PushEvent>(
//         onListen: () async {
//           // Listen first so nothing is missed while reading the launch tap.
//           subscriptions
//             ..add(
//               FirebaseMessaging.onMessage.listen(
//                 (m) => add(m, PushReceivedInForeground.new),
//               ),
//             )
//             ..add(
//               FirebaseMessaging.onMessageOpenedApp.listen(
//                 (m) => add(m, PushOpened.new),
//               ),
//             );
//           if (_initialRead) return;
//           _initialRead = true; // read the launching tap once per process
//           final initial = await _messaging.getInitialMessage();
//           if (initial != null) add(initial, PushOpened.new);
//         },
//         onCancel: () => Future.wait(subscriptions.map((s) => s.cancel())),
//       );
//       return controller.stream;
//     }
//
//     static PushMessage? _map(RemoteMessage m) => PushMessage.fromData(
//       m.data,
//       title: m.notification?.title,
//       body: m.notification?.body,
//     );
//
//     @override
//     Future<PushPermission> permission() async => _permission(
//       (await _messaging.getNotificationSettings()).authorizationStatus,
//     );
//
//     @override
//     Future<PushPermission> requestPermission() async =>
//         _permission((await _messaging.requestPermission()).authorizationStatus);
//
//     static PushPermission _permission(AuthorizationStatus status) =>
//         switch (status) {
//           AuthorizationStatus.authorized => PushPermission.granted,
//           AuthorizationStatus.provisional => PushPermission.provisional,
//           AuthorizationStatus.denied => PushPermission.denied,
//           AuthorizationStatus.deniedPermanently =>
//             PushPermission.permanentlyDenied,
//           AuthorizationStatus.notDetermined => PushPermission.notDetermined,
//         };
//
//     @override
//     Future<String?> getToken() => _guard(() async {
//       // iOS: no FCM token before the APNs token; onTokenRefresh delivers it.
//       if (defaultTargetPlatform == TargetPlatform.iOS &&
//           await _messaging.getAPNSToken() == null) {
//         return null;
//       }
//       return _messaging.getToken();
//     });
//
//     @override
//     Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;
//
//     @override
//     Future<void> deleteToken() => _guard(_messaging.deleteToken);
//
//     /// Removes this app's delivered notifications, FCM ones included.
//     @override
//     Future<void> clearDelivered() => _local.cancelAll();
//
//     static Future<T> _guard<T>(Future<T> Function() call) async {
//       try {
//         return await call();
//       } on FirebaseException {
//         throw const PushFailure(PushFailureCode.unavailable);
//       }
//     }
//   }
//
// Never call `FlutterLocalNotificationsPlugin.initialize` or set the iOS
// `UNUserNotificationCenter` delegate for it: firebase_messaging owns the
// delegate and every tap goes through `onMessageOpenedApp`.

// ---------------------------------------------------------------------------
// lib/domain/use_case/push_use_case.dart
// ---------------------------------------------------------------------------

/// Owns device registration for the signed-in session, so no user's pushes
/// reach the next user of the device. Neither call ever throws: push must not
/// break sign-in or sign-out.
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

  Future<PushPermission> permission() => _push.permission();

  Future<PushPermission> requestPermission() => _push.requestPermission();

  /// After `SessionRepo.start` and at every app start with a restored
  /// session. Registering on every start keeps the server's timestamp fresh
  /// (FCM token guidance); a failure is retried at the next start or rotation.
  Future<void> onSignedIn() async {
    final revision = ++_revision;
    await _refreshes?.cancel();
    _refreshes = _push.tokenRefreshes.listen(
      (token) => _tryRegister(token, revision),
    );
    try {
      final token = await _push.getToken();
      if (token != null) await _tryRegister(token, revision);
    } on PushFailure {
      // No push service on this device: the app works without push.
    }
  }

  /// Before `SessionRepo.end()` clears the credentials, because
  /// `DELETE /devices/{token}` needs them. On forced expiry that call fails;
  /// the token is still deleted, and FCM then answers UNREGISTERED to the
  /// server, which drops it.
  Future<void> onSignedOut() async {
    ++_revision;
    await _refreshes?.cancel();
    _refreshes = null;
    final token = _registeredToken;
    _registeredToken = null;
    try {
      if (token != null) await _devices.unregister(token);
    } on Object {
      // Never block sign-out; the token is deleted below.
    }
    try {
      await _push.deleteToken();
    } on PushFailure {
      // The server moves a re-registered token to its new owner.
    }
    await _push.clearDelivered();
  }

  Future<void> _tryRegister(String token, int revision) async {
    try {
      await _register(token, revision);
    } on Object {
      // Retried at the next app start or token rotation.
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
  String? _lastOpenedId;

  /// Called once from MainApp.initState. Reads the permission without asking.
  void start() {
    _events ??= _useCase.events.listen(_onEvent);
    unawaited(checkPermission());
  }

  /// Also from `AppLifecycleListener(onResume: ...)`: the user may have
  /// changed it in system settings.
  Future<void> checkPermission() async {
    final permission = await _useCase.permission();
    if (isClosed) return;
    emit(state.copyWith(permission: permission));
  }

  /// After an in-app explanation the user accepted (soft prompt), at a moment
  /// that needs push ("notify me when it ships"), never at launch.
  Future<void> requestPermission() async {
    final permission = await _useCase.requestPermission();
    if (isClosed) return;
    emit(state.copyWith(permission: permission));
  }

  void _onEvent(PushEvent event) {
    if (isClosed) return;
    // The same tap can arrive twice (launch message and opened-app stream).
    if (event is PushOpened) {
      if (event.message.id == _lastOpenedId) return;
      _lastOpenedId = event.message.id;
    }
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

    test('sign-in completes when the push service is unavailable', () async {
      push.tokenError = const PushFailure(PushFailureCode.unavailable);

      await useCase.onSignedIn();

      expect(devices.registered, isEmpty);
    });

    test(
      'a token that is not ready yet is registered when it arrives',
      () async {
        push.token = null; // iOS before the APNs token
        await useCase.onSignedIn();

        push.refreshes.add('token-apns');
        await pumpEventQueue();

        expect(devices.registered, {'token-apns'});
      },
    );

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
      expect(push.cleared, 1);
    });

    test('sign-out deletes the device token even if the API fails', () async {
      await useCase.onSignedIn();
      devices.failUnregister = true;

      await useCase.onSignedOut();

      expect(push.deleted, 1);
      expect(push.cleared, 1);
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

    test('the same tap delivered twice opens once', () async {
      final tap = PushOpened(
        PushMessage(
          id: 'n-2',
          type: PushType.orderStatus,
          link: Uri.parse('https://app.example.com/orders/o-1'),
        ),
      );
      push.incoming
        ..add(tap)
        ..add(tap);
      await pumpEventQueue();

      expect(cubit.state.effect!.revision, 1);
    });

    test('a tap without a link only opens the app', () async {
      push.incoming.add(const PushOpened(message));
      await pumpEventQueue();

      expect(cubit.state.effect, isNull);
    });

    test('start reads the permission without asking', () async {
      await pumpEventQueue();

      expect(cubit.state.permission, PushPermission.granted);
      expect(push.requests, 0);
    });

    test('permission result is kept in state', () async {
      push.answer = PushPermission.permanentlyDenied;

      await cubit.requestPermission();

      expect(cubit.state.permission, PushPermission.permanentlyDenied);
      expect(push.requests, 1);
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
  PushPermission answer = PushPermission.granted;
  String? token = 'token-1';
  PushFailure? tokenError;
  int requests = 0;
  int deleted = 0;
  int cleared = 0;

  @override
  Future<PushPermission> permission() async => answer;

  @override
  Future<PushPermission> requestPermission() async {
    requests++;
    return answer;
  }

  @override
  Future<String?> getToken() async {
    final error = tokenError;
    if (error != null) throw error;
    return token;
  }

  @override
  Stream<String> get tokenRefreshes => refreshes.stream;

  @override
  Stream<PushEvent> get events => incoming.stream;

  @override
  Future<void> deleteToken() async => deleted++;

  @override
  Future<void> clearDelivered() async => cleared++;
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
