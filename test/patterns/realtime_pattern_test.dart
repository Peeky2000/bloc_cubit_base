// Reference implementation: realtime updates through one Stream port.
//
// Pattern: .agents/skills/flutter-patterns/references/realtime.md
// Decision: docs/decisions/D-0005-cap-nhat-realtime-qua-stream.md
//
// The domain port is `Stream<OrderRealtimeEvent>`. Two adapters implement it:
// WebSocket (when the backend has a socket) and polling (when it does not).
// The Cubit is the same for both. The WebSocket transport needs
// `web_socket_channel` as a direct dependency (D-0005), so the transport sits
// behind `RealtimeSocketFactory`; reconnect, resubscribe and parsing are
// compiled and tested here with a fake socket.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/core/error/exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// lib/domain/entities/order/order_status.dart
// ---------------------------------------------------------------------------

enum OrderStatus { pending, confirmed, shipping, delivered, cancelled }

// ---------------------------------------------------------------------------
// lib/domain/repositories/order_realtime_repo.dart
// ---------------------------------------------------------------------------

enum RealtimeConnection { connecting, live, reconnecting }

sealed class OrderRealtimeEvent {
  const OrderRealtimeEvent();
}

final class OrderStatusChanged extends OrderRealtimeEvent {
  const OrderStatusChanged({
    required this.orderId,
    required this.status,
    required this.updatedAt,
  });

  final String orderId;
  final OrderStatus status;
  final DateTime updatedAt;
}

final class RealtimeConnectionChanged extends OrderRealtimeEvent {
  const RealtimeConnectionChanged(this.connection);

  final RealtimeConnection connection;
}

enum RealtimeFailureCode { unauthorized, notFound }

/// Only for failures that retrying cannot fix. Network drops are not errors;
/// they are `RealtimeConnectionChanged(reconnecting)`.
final class RealtimeFailure implements Exception {
  const RealtimeFailure(this.code);

  final RealtimeFailureCode code;

  @override
  String toString() => 'RealtimeFailure($code)';
}

abstract class OrderRealtimeRepo {
  /// Listening connects; cancelling disconnects. After every (re)connect the
  /// current status is emitted first, so nothing missed while offline is
  /// lost. Drops reconnect with capped exponential backoff. The stream errors
  /// with [RealtimeFailure] and ends only when retrying cannot help.
  Stream<OrderRealtimeEvent> watchOrder(String orderId);
}

// ---------------------------------------------------------------------------
// lib/domain/use_case/order_tracking_use_case.dart
// ---------------------------------------------------------------------------

class OrderTrackingUseCase {
  OrderTrackingUseCase(this._repo);

  final OrderRealtimeRepo _repo;

  Stream<OrderRealtimeEvent> watchOrder(String orderId) =>
      _repo.watchOrder(orderId);
}

// ---------------------------------------------------------------------------
// lib/data/datasource/remote/realtime_backoff.dart  (shared)
// ---------------------------------------------------------------------------

/// 1 s, 2 s, 4 s ... capped at 30 s, plus up to 20 % jitter so clients do not
/// reconnect in lockstep after a server restart.
final class RealtimeBackoff {
  RealtimeBackoff({
    this.initial = const Duration(seconds: 1),
    this.max = const Duration(seconds: 30),
    Random? random,
  }) : _random = random ?? Random();

  final Duration initial;
  final Duration max;
  final Random _random;

  Duration delay(int attempt) {
    final base = initial * pow(2, min(attempt, 16)).toInt();
    final capped = base > max ? max : base;
    return capped * (1 + 0.2 * _random.nextDouble());
  }
}

Future<void> _sleep(Duration duration) => Future<void>.delayed(duration);

// ---------------------------------------------------------------------------
// lib/data/datasource/remote/realtime_socket.dart
// ---------------------------------------------------------------------------

/// One open socket. [messages] is done when the socket closes.
abstract class RealtimeSocket {
  Stream<String> get messages;

  /// Close code after [messages] is done; null when the network dropped.
  int? get closeCode;

  void send(String message);

  Future<void> close();
}

abstract class RealtimeSocketFactory {
  /// Opens and authenticates a socket; throws when it cannot.
  Future<RealtimeSocket> connect(Uri uri);
}

// Adapter sketch for lib/data/datasource/remote/web_socket_factory.dart.
// Needs `web_socket_channel` as a direct dependency (D-0005).
//
//   @LazySingleton(as: RealtimeSocketFactory)
//   class WebSocketChannelFactory implements RealtimeSocketFactory {
//     WebSocketChannelFactory(this._tokens);
//     final TokenProvider _tokens;
//
//     @override
//     Future<RealtimeSocket> connect(Uri uri) async {
//       final channel = IOWebSocketChannel.connect(
//         uri,                                   // wss:// only
//         headers: {'Authorization': 'Bearer ${_tokens.token.accessToken}'},
//         pingInterval: const Duration(seconds: 20),
//       );
//       await channel.ready;                     // throws when it cannot open
//       return _ChannelSocket(channel);          // maps stream/closeCode/sink
//     }
//   }

// ---------------------------------------------------------------------------
// lib/data/repositories/web_socket_order_realtime_repo.dart
// ---------------------------------------------------------------------------

/// Server protocol:
/// client → `{"type":"subscribe","topic":"order","orderId":"o-1"}`
/// server → `{"type":"order.snapshot",...}` once, then `{"type":"order.status",
/// "orderId":"o-1","status":"shipping","updatedAt":"2026-10-08T09:00:00Z"}`.
/// Close code 4401 = token rejected, 4404 = order not visible to this user.
// @LazySingleton(as: OrderRealtimeRepo)
class WebSocketOrderRealtimeRepo implements OrderRealtimeRepo {
  WebSocketOrderRealtimeRepo(
    this._sockets, {
    required Uri endpoint,
    RealtimeBackoff? backoff,
    Future<void> Function(Duration) wait = _sleep,
  }) : _endpoint = endpoint,
       _backoff = backoff ?? RealtimeBackoff(),
       _wait = wait;

  static const int unauthorizedCloseCode = 4401;
  static const int notFoundCloseCode = 4404;

  final RealtimeSocketFactory _sockets;
  final Uri _endpoint;
  final RealtimeBackoff _backoff;
  final Future<void> Function(Duration) _wait;

  @override
  Stream<OrderRealtimeEvent> watchOrder(String orderId) {
    var cancelled = false;
    RealtimeSocket? socket;
    late final StreamController<OrderRealtimeEvent> controller;

    Future<void> run() async {
      var attempt = 0;
      while (!cancelled) {
        controller.add(
          RealtimeConnectionChanged(
            attempt == 0
                ? RealtimeConnection.connecting
                : RealtimeConnection.reconnecting,
          ),
        );
        try {
          final open = socket = await _sockets.connect(_endpoint);
          if (cancelled) {
            await open.close();
            break;
          }
          open.send(
            jsonEncode({
              'type': 'subscribe',
              'topic': 'order',
              'orderId': orderId,
            }),
          );
          await for (final raw in open.messages) {
            final event = _parse(raw, orderId);
            if (event == null || cancelled) continue;
            if (event.$1) {
              attempt = 0;
              controller.add(
                const RealtimeConnectionChanged(RealtimeConnection.live),
              );
            }
            controller.add(event.$2);
          }
          final failure = switch (open.closeCode) {
            unauthorizedCloseCode => RealtimeFailureCode.unauthorized,
            notFoundCloseCode => RealtimeFailureCode.notFound,
            _ => null,
          };
          if (failure != null && !cancelled) {
            controller.addError(RealtimeFailure(failure));
            break;
          }
        } catch (_) {
          // Could not connect: retry below.
        }
        if (cancelled) break;
        await _wait(_backoff.delay(attempt));
        attempt++;
      }
      await controller.close();
    }

    controller = StreamController<OrderRealtimeEvent>(
      onListen: run,
      onCancel: () {
        cancelled = true;
        return socket?.close();
      },
    );
    return controller.stream;
  }

  /// Returns (isSnapshot, event) or null for anything unknown or malformed,
  /// which is ignored rather than ending the stream.
  static (bool, OrderStatusChanged)? _parse(String raw, String orderId) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final type = json['type'];
      if (type != 'order.snapshot' && type != 'order.status') return null;
      if (json['orderId'] != orderId) return null;
      final status = OrderStatus.values.byName(json['status'] as String);
      final updatedAt = DateTime.parse(json['updatedAt'] as String);
      return (
        type == 'order.snapshot',
        OrderStatusChanged(
          orderId: orderId,
          status: status,
          updatedAt: updatedAt,
        ),
      );
    } on Object {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// lib/data/datasource/remote/order_remote_data_source.dart  (polling input)
// ---------------------------------------------------------------------------

final class OrderStatusResponseModel {
  const OrderStatusResponseModel({
    required this.status,
    required this.updatedAt,
  });

  final OrderStatus status;
  final DateTime updatedAt;
}

abstract class OrderStatusRemoteDataSource {
  /// `ApiHandler.get('/orders/$orderId/status')` in the app.
  Future<OrderStatusResponseModel> getOrderStatus(String orderId);
}

// ---------------------------------------------------------------------------
// lib/data/repositories/polling_order_realtime_repo.dart
// ---------------------------------------------------------------------------

/// Same port over plain REST. Emits only when the status changes.
// @LazySingleton(as: OrderRealtimeRepo)   // bind one adapter, not both
class PollingOrderRealtimeRepo implements OrderRealtimeRepo {
  PollingOrderRealtimeRepo(
    this._remote, {
    this.interval = const Duration(seconds: 15),
    RealtimeBackoff? backoff,
  }) : _backoff = backoff ?? RealtimeBackoff();

  final OrderStatusRemoteDataSource _remote;
  final Duration interval;
  final RealtimeBackoff _backoff;

  @override
  Stream<OrderRealtimeEvent> watchOrder(String orderId) {
    var active = true;
    Timer? timer;
    DateTime? lastUpdatedAt;
    var failures = 0;
    var live = false;
    late final StreamController<OrderRealtimeEvent> controller;

    Future<void> poll() async {
      if (!active) return;
      Duration next;
      try {
        final snapshot = await _remote.getOrderStatus(orderId);
        if (!active) return;
        failures = 0;
        if (!live) {
          live = true;
          controller.add(
            const RealtimeConnectionChanged(RealtimeConnection.live),
          );
        }
        if (snapshot.updatedAt != lastUpdatedAt) {
          lastUpdatedAt = snapshot.updatedAt;
          controller.add(
            OrderStatusChanged(
              orderId: orderId,
              status: snapshot.status,
              updatedAt: snapshot.updatedAt,
            ),
          );
        }
        next = interval;
      } catch (error) {
        if (!active) return;
        final terminal = switch (_statusCode(error)) {
          401 || 403 => RealtimeFailureCode.unauthorized,
          404 => RealtimeFailureCode.notFound,
          _ => null,
        };
        if (terminal != null) {
          active = false;
          controller.addError(RealtimeFailure(terminal));
          await controller.close();
          return;
        }
        if (live) {
          live = false;
          controller.add(
            const RealtimeConnectionChanged(RealtimeConnection.reconnecting),
          );
        }
        next = _backoff.delay(failures++);
      }
      if (active) timer = Timer(next, poll);
    }

    controller = StreamController<OrderRealtimeEvent>(
      onListen: () {
        controller.add(
          const RealtimeConnectionChanged(RealtimeConnection.connecting),
        );
        poll();
      },
      onCancel: () {
        active = false;
        timer?.cancel();
      },
    );
    return controller.stream;
  }

  static int? _statusCode(Object error) {
    if (error is ServerException && error.error is DioException) {
      return (error.error as DioException).response?.statusCode;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// lib/presentation/order_tracking/cubit/order_tracking_effect.dart  (part)
// ---------------------------------------------------------------------------

enum OrderTrackingRetryAction { reconnect }

sealed class OrderTrackingEffect {
  const OrderTrackingEffect();
}

final class OrderTrackingShowErrorEffect extends OrderTrackingEffect {
  const OrderTrackingShowErrorEffect({
    required this.error,
    required this.retryAction,
  });

  final Object error;
  final OrderTrackingRetryAction retryAction;
}

// ---------------------------------------------------------------------------
// lib/presentation/order_tracking/cubit/order_tracking_state.dart  (part)
// ---------------------------------------------------------------------------

class OrderTrackingState extends BaseAppState<Object> {
  const OrderTrackingState({
    required super.loading,
    super.error,
    this.orderId,
    this.status,
    this.updatedAt,
    this.connection = RealtimeConnection.connecting,
    this.effect,
  });

  factory OrderTrackingState.initial() =>
      const OrderTrackingState(loading: LoadingStatus.initial);

  final String? orderId;
  final OrderStatus? status;
  final DateTime? updatedAt;

  /// The Screen shows a small "reconnecting" badge; data stays visible.
  final RealtimeConnection connection;

  final UiEffect<OrderTrackingEffect>? effect;

  OrderTrackingState copyWith({
    LoadingStatus? loading,
    Object? error,
    String? orderId,
    OrderStatus? status,
    DateTime? updatedAt,
    RealtimeConnection? connection,
    UiEffect<OrderTrackingEffect>? effect,
  }) {
    return OrderTrackingState(
      loading: loading ?? this.loading,
      error: error,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      connection: connection ?? this.connection,
      effect: effect ?? this.effect,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    error,
    orderId,
    status,
    updatedAt,
    connection,
    effect,
  ];
}

// ---------------------------------------------------------------------------
// lib/presentation/order_tracking/cubit/order_tracking_cubit.dart
// ---------------------------------------------------------------------------

// @injectable
class OrderTrackingCubit extends BaseCubit<OrderTrackingState> {
  OrderTrackingCubit(this._useCase) : super(OrderTrackingState.initial());

  final OrderTrackingUseCase _useCase;
  StreamSubscription<OrderRealtimeEvent>? _subscription;

  /// Called from the screen builder with the route argument.
  void start(String orderId) {
    unawaited(_subscription?.cancel());
    emit(
      state.copyWith(
        orderId: orderId,
        loading: state.status == null
            ? LoadingStatus.loading
            : LoadingStatus.refresh,
        connection: RealtimeConnection.connecting,
      ),
    );
    _subscription = _useCase
        .watchOrder(orderId)
        .listen(_onEvent, onError: _onError, cancelOnError: true);
  }

  /// Screen: `AppLifecycleListener(onHide: cubit.pause, onShow: cubit.resume)`
  /// so no socket or timer runs in the background.
  Future<void> pause() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void resume() {
    final orderId = state.orderId;
    if (orderId != null && _subscription == null) start(orderId);
  }

  /// Retry action of the error effect.
  void reconnect() {
    final orderId = state.orderId;
    if (orderId != null) start(orderId);
  }

  void _onEvent(OrderRealtimeEvent event) {
    if (isClosed) return;
    switch (event) {
      case RealtimeConnectionChanged(:final connection):
        emit(state.copyWith(connection: connection, error: state.error));
      case OrderStatusChanged(:final status, :final updatedAt):
        // Ignore an event older than what is on screen (reordered delivery).
        final current = state.updatedAt;
        if (current != null && updatedAt.isBefore(current)) return;
        emit(
          state.copyWith(
            loading: LoadingStatus.complete,
            status: status,
            updatedAt: updatedAt,
          ),
        );
    }
  }

  void _onError(Object error) {
    if (isClosed) return;
    _subscription = null;
    emit(state.copyWith(loading: LoadingStatus.error, error: error));
    emit(
      state.copyWith(
        error: error,
        effect: createEffect<OrderTrackingEffect>(
          OrderTrackingShowErrorEffect(
            error: error,
            retryAction: OrderTrackingRetryAction.reconnect,
          ),
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

// ===========================================================================
// Tests
// ===========================================================================

void main() {
  final endpoint = Uri.parse('wss://realtime.test/ws');
  final t0 = DateTime.utc(2026, 10, 8, 9);

  String status(String type, OrderStatus status, DateTime at) => jsonEncode({
    'type': type,
    'orderId': 'o-1',
    'status': status.name,
    'updatedAt': at.toIso8601String(),
  });

  group('RealtimeBackoff', () {
    test('doubles, caps at max and adds at most 20 % jitter', () {
      final backoff = RealtimeBackoff(random: Random(1));

      final delays = [for (var i = 0; i < 8; i++) backoff.delay(i)];

      expect(delays[0].inMilliseconds, inInclusiveRange(1000, 1200));
      expect(delays[1].inMilliseconds, inInclusiveRange(2000, 2400));
      expect(delays[7].inMilliseconds, inInclusiveRange(30000, 36000));
    });
  });

  group('WebSocketOrderRealtimeRepo', () {
    late _FakeSocketFactory sockets;
    late List<Duration> waits;
    late WebSocketOrderRealtimeRepo repo;

    setUp(() {
      sockets = _FakeSocketFactory();
      waits = [];
      repo = WebSocketOrderRealtimeRepo(
        sockets,
        endpoint: endpoint,
        backoff: RealtimeBackoff(random: Random(1)),
        wait: (d) async => waits.add(d),
      );
    });

    test(
      'subscribes, goes live on the snapshot, then streams changes',
      () async {
        final events = <OrderRealtimeEvent>[];
        final sub = repo.watchOrder('o-1').listen(events.add);
        await pumpEventQueue();

        final socket = sockets.opened.single;
        expect(jsonDecode(socket.sent.single), {
          'type': 'subscribe',
          'topic': 'order',
          'orderId': 'o-1',
        });
        socket.receive(status('order.snapshot', OrderStatus.confirmed, t0));
        socket.receive(
          status(
            'order.status',
            OrderStatus.shipping,
            t0.add(const Duration(minutes: 1)),
          ),
        );
        await pumpEventQueue();
        await sub.cancel();

        expect(events.map(_describe), [
          'connecting',
          'live',
          'confirmed',
          'shipping',
        ]);
        expect(socket.closed, isTrue);
      },
    );

    test('ignores malformed, unknown and other-order messages', () async {
      final events = <OrderRealtimeEvent>[];
      final sub = repo.watchOrder('o-1').listen(events.add);
      await pumpEventQueue();
      final socket = sockets.opened.single;

      socket
        ..receive('not json')
        ..receive(jsonEncode({'type': 'chat.message'}))
        ..receive(
          jsonEncode({
            'type': 'order.status',
            'orderId': 'o-2',
            'status': 'delivered',
            'updatedAt': t0.toIso8601String(),
          }),
        )
        ..receive(
          jsonEncode({
            'type': 'order.status',
            'orderId': 'o-1',
            'status': 'teleported',
            'updatedAt': t0.toIso8601String(),
          }),
        );
      await pumpEventQueue();
      await sub.cancel();

      expect(events.map(_describe), ['connecting']);
    });

    test('a drop reconnects with backoff and resubscribes', () async {
      final events = <OrderRealtimeEvent>[];
      final sub = repo.watchOrder('o-1').listen(events.add);
      await pumpEventQueue();
      sockets.opened.single.receive(
        status('order.snapshot', OrderStatus.confirmed, t0),
      );
      await pumpEventQueue();

      sockets.failNextConnects = 2;
      await sockets.opened.single.drop();
      await pumpEventQueue();
      final second = sockets.opened.last;
      second.receive(
        status(
          'order.snapshot',
          OrderStatus.shipping,
          t0.add(const Duration(minutes: 5)),
        ),
      );
      await pumpEventQueue();
      await sub.cancel();

      expect(sockets.opened, hasLength(2));
      expect(second.sent.single, contains('subscribe'));
      expect(waits, hasLength(3));
      expect(waits[1], greaterThan(waits[0]));
      expect(events.map(_describe), [
        'connecting',
        'live',
        'confirmed',
        'reconnecting',
        'reconnecting',
        'reconnecting',
        'live',
        'shipping',
      ]);
    });

    test('backoff resets after the connection is live again', () async {
      final sub = repo.watchOrder('o-1').listen((_) {});
      await pumpEventQueue();
      for (var i = 0; i < 3; i++) {
        sockets.opened.last.receive(
          status('order.snapshot', OrderStatus.confirmed, t0),
        );
        await pumpEventQueue();
        await sockets.opened.last.drop();
        await pumpEventQueue();
      }
      await sub.cancel();

      expect(
        waits.map((d) => d.inMilliseconds),
        everyElement(inInclusiveRange(1000, 1200)),
      );
    });

    test('a rejected token ends the stream with a typed failure', () async {
      final errors = <Object>[];
      final done = Completer<void>();
      repo
          .watchOrder('o-1')
          .listen((_) {}, onError: errors.add, onDone: done.complete);
      await pumpEventQueue();

      await sockets.opened.single.drop(
        closeCode: WebSocketOrderRealtimeRepo.unauthorizedCloseCode,
      );
      await done.future;

      expect(errors.single, isA<RealtimeFailure>());
      expect(
        (errors.single as RealtimeFailure).code,
        RealtimeFailureCode.unauthorized,
      );
      expect(sockets.opened, hasLength(1));
    });

    test('cancelling closes the socket and stops reconnecting', () async {
      final sub = repo.watchOrder('o-1').listen((_) {});
      await pumpEventQueue();

      await sub.cancel();
      await pumpEventQueue();

      expect(sockets.opened.single.closed, isTrue);
      expect(sockets.opened, hasLength(1));
      expect(waits, isEmpty);
    });
  });

  group('PollingOrderRealtimeRepo', () {
    late _FakeStatusRemote remote;
    late PollingOrderRealtimeRepo repo;

    setUp(() {
      remote = _FakeStatusRemote();
      repo = PollingOrderRealtimeRepo(
        remote,
        interval: Duration.zero,
        backoff: RealtimeBackoff(initial: Duration.zero, max: Duration.zero),
      );
    });

    test('emits only when the status changes', () async {
      remote.responses = [
        OrderStatusResponseModel(status: OrderStatus.confirmed, updatedAt: t0),
        OrderStatusResponseModel(status: OrderStatus.confirmed, updatedAt: t0),
        OrderStatusResponseModel(
          status: OrderStatus.shipping,
          updatedAt: t0.add(const Duration(minutes: 1)),
        ),
      ];
      final events = <OrderRealtimeEvent>[];
      final sub = repo.watchOrder('o-1').listen(events.add);
      await pumpEventQueue();
      await sub.cancel();

      expect(events.map(_describe), [
        'connecting',
        'live',
        'confirmed',
        'shipping',
      ]);
      expect(remote.calls, greaterThan(3));
    });

    test('a failed poll reports reconnecting and keeps polling', () async {
      remote
        ..responses = [
          OrderStatusResponseModel(
            status: OrderStatus.confirmed,
            updatedAt: t0,
          ),
        ]
        ..failAt = {2: NetworkIssueException()};
      final events = <OrderRealtimeEvent>[];
      final sub = repo.watchOrder('o-1').listen(events.add);
      await pumpEventQueue();
      await sub.cancel();

      expect(events.map(_describe).take(5), [
        'connecting',
        'live',
        'confirmed',
        'reconnecting',
        'live',
      ]);
    });

    test('HTTP 404 ends the stream with notFound', () async {
      remote.failAt = {
        1: ServerException(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              requestOptions: RequestOptions(),
              statusCode: 404,
            ),
          ),
        ),
      };

      await expectLater(
        repo.watchOrder('o-1'),
        emitsInOrder([
          isA<RealtimeConnectionChanged>(),
          emitsError(
            isA<RealtimeFailure>().having(
              (f) => f.code,
              'code',
              RealtimeFailureCode.notFound,
            ),
          ),
          emitsDone,
        ]),
      );
    });

    test('cancelling stops the timer', () async {
      final sub = repo.watchOrder('o-1').listen((_) {});
      await pumpEventQueue();
      await sub.cancel();
      final calls = remote.calls;

      await pumpEventQueue();

      expect(remote.calls, calls);
    });
  });

  group('OrderTrackingCubit', () {
    late _ControlledRealtimeRepo repo;
    late OrderTrackingCubit cubit;

    setUp(() {
      repo = _ControlledRealtimeRepo();
      cubit = OrderTrackingCubit(OrderTrackingUseCase(repo));
    });

    tearDown(() => cubit.close());

    test('loading until the first status, then live updates', () async {
      cubit.start('o-1');
      expect(cubit.state.loading, LoadingStatus.loading);

      repo
        ..add(const RealtimeConnectionChanged(RealtimeConnection.live))
        ..add(
          OrderStatusChanged(
            orderId: 'o-1',
            status: OrderStatus.confirmed,
            updatedAt: t0,
          ),
        );
      await pumpEventQueue();

      expect(cubit.state.loading, LoadingStatus.complete);
      expect(cubit.state.status, OrderStatus.confirmed);
      expect(cubit.state.connection, RealtimeConnection.live);
    });

    test('reconnecting keeps the last status on screen', () async {
      cubit.start('o-1');
      repo.add(
        OrderStatusChanged(
          orderId: 'o-1',
          status: OrderStatus.confirmed,
          updatedAt: t0,
        ),
      );
      repo.add(
        const RealtimeConnectionChanged(RealtimeConnection.reconnecting),
      );
      await pumpEventQueue();

      expect(cubit.state.status, OrderStatus.confirmed);
      expect(cubit.state.connection, RealtimeConnection.reconnecting);
    });

    test('an older event does not overwrite a newer status', () async {
      cubit.start('o-1');
      repo
        ..add(
          OrderStatusChanged(
            orderId: 'o-1',
            status: OrderStatus.shipping,
            updatedAt: t0.add(const Duration(minutes: 2)),
          ),
        )
        ..add(
          OrderStatusChanged(
            orderId: 'o-1',
            status: OrderStatus.confirmed,
            updatedAt: t0,
          ),
        );
      await pumpEventQueue();

      expect(cubit.state.status, OrderStatus.shipping);
    });

    test('a terminal failure shows an error with reconnect', () async {
      cubit.start('o-1');
      repo.fail(const RealtimeFailure(RealtimeFailureCode.unauthorized));
      await pumpEventQueue();

      expect(cubit.state.loading, LoadingStatus.error);
      final effect = cubit.state.effect!.value as OrderTrackingShowErrorEffect;
      expect(effect.retryAction, OrderTrackingRetryAction.reconnect);

      cubit.reconnect();
      expect(repo.listens, 2);
    });

    test('pause cancels the stream and resume restarts it', () async {
      cubit.start('o-1');
      await cubit.pause();
      expect(repo.cancels, 1);

      cubit.resume();
      expect(repo.listens, 2);
      cubit.resume();
      expect(repo.listens, 2);
    });

    test('close cancels the stream', () async {
      cubit.start('o-1');

      await cubit.close();

      expect(repo.cancels, 1);
    });
  });
}

String _describe(OrderRealtimeEvent event) => switch (event) {
  RealtimeConnectionChanged(:final connection) => connection.name,
  OrderStatusChanged(:final status) => status.name,
};

class _FakeSocket implements RealtimeSocket {
  final StreamController<String> _incoming = StreamController<String>();
  final List<String> sent = [];
  bool closed = false;

  @override
  int? closeCode;

  @override
  Stream<String> get messages => _incoming.stream;

  void receive(String message) => _incoming.add(message);

  Future<void> drop({int? closeCode}) {
    this.closeCode = closeCode;
    return _incoming.close();
  }

  @override
  void send(String message) => sent.add(message);

  @override
  Future<void> close() async {
    closed = true;
    if (!_incoming.isClosed) await _incoming.close();
  }
}

class _FakeSocketFactory implements RealtimeSocketFactory {
  final List<_FakeSocket> opened = [];
  int failNextConnects = 0;

  @override
  Future<RealtimeSocket> connect(Uri uri) async {
    if (failNextConnects > 0) {
      failNextConnects--;
      throw NetworkIssueException();
    }
    final socket = _FakeSocket();
    opened.add(socket);
    return socket;
  }
}

class _FakeStatusRemote implements OrderStatusRemoteDataSource {
  List<OrderStatusResponseModel> responses = [];
  Map<int, Object> failAt = {};
  int calls = 0;

  @override
  Future<OrderStatusResponseModel> getOrderStatus(String orderId) async {
    final call = ++calls;
    final failure = failAt[call];
    if (failure != null) throw failure;
    final index = min(call - 1, responses.length - 1);
    return index < 0
        ? OrderStatusResponseModel(
            status: OrderStatus.pending,
            updatedAt: DateTime.utc(2026),
          )
        : responses[index];
  }
}

/// A repo whose stream the test drives by hand.
class _ControlledRealtimeRepo implements OrderRealtimeRepo {
  StreamController<OrderRealtimeEvent>? _controller;
  int listens = 0;
  int cancels = 0;

  void add(OrderRealtimeEvent event) => _controller!.add(event);

  void fail(Object error) => _controller!.addError(error);

  @override
  Stream<OrderRealtimeEvent> watchOrder(String orderId) {
    final controller = _controller = StreamController<OrderRealtimeEvent>(
      onListen: () => listens++,
      onCancel: () => cancels++,
    );
    return controller.stream;
  }
}
