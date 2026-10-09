# Realtime updates: stream, WebSocket or polling

Decision: [D-0005](../../../../docs/decisions/D-0005-cap-nhat-realtime-qua-stream.md)
(proposed). Reference code: `test/patterns/realtime_pattern_test.dart`.

## When to use

A screen shows server state that changes while it is open: order tracking,
delivery status, a live counter, a job's progress. Chat with history and
typing indicators follows the same port shape but deserves its own decision.
Changes while the app is in the background go through push
([push_notification.md](push_notification.md)); Android Doze suspends network
access and Google recommends FCM over a persistent connection.

## Decision

The domain port is one `Stream<FeatureRealtimeEvent>` that connects on
listen, disconnects on cancel, emits the current snapshot after every
(re)connect and reconnects with capped exponential backoff and full jitter.
A WebSocket adapter (`web_socket_channel` ^3.0.3) backs it when the backend has
a socket, a polling adapter otherwise; the Cubit is the same for both.

## Package

| Package | Constraint | Why |
|---|---|---|
| `web_socket_channel` | `^3.0.3` (tools.dart.dev, latest, already transitive at 3.0.1) | Dart team package used by the Flutter cookbook; `IOWebSocketChannel.connect` takes `headers`, `pingInterval`, `connectTimeout`; `ready` throws `WebSocketChannelException` whose `inner` carries the handshake HTTP status |

No native setup: `INTERNET` is already in `AndroidManifest.xml`, and `wss://`
needs no ATS exception. Not chosen: `web_socket_client` (0.2.1, built-in
reconnect but fixed headers, so a refreshed credential is not used).

## Files to create (feature `order_tracking`)

| Layer | Path | Content |
|---|---|---|
| Entity | `lib/domain/entities/order/order_status.dart` | `enum OrderStatus` |
| Port | `lib/domain/repositories/order_realtime_repo.dart` | `Stream<OrderRealtimeEvent> watchOrder(String orderId)`; `OrderStatusChanged{orderId, status, updatedAt}`, `RealtimeConnectionChanged(connecting/live/reconnecting)`, `RealtimeFailure{code}` |
| UseCase | `lib/domain/use_case/order_tracking_use_case.dart` | passes through |
| Backoff (shared) | `lib/data/datasource/remote/realtime_backoff.dart` | full jitter: random in [0, min(30 s, 1 s·2ⁿ)] |
| Socket seam (shared) | `lib/data/datasource/remote/realtime_socket.dart` | `RealtimeSocket`, `RealtimeSocketFactory` |
| Ticket source (shared) | `lib/data/datasource/remote/realtime_ticket_remote_data_source.dart` | `POST /realtime/tickets` via `ApiClient` |
| Socket adapter | `lib/data/datasource/remote/web_socket_factory.dart` | verified code in the test file |
| WS repo | `lib/data/repositories/web_socket_order_realtime_repo.dart` | subscribe, parse, reconnect, close codes |
| Polling repo | `lib/data/repositories/polling_order_realtime_repo.dart` | `GET` every 15 s, emit on change only |
| Cubit | `lib/presentation/order_tracking/cubit/order_tracking_cubit.dart` | `start(orderId)`, `pause()`, `resume()`, `reconnect()` |
| State/effect | `.../cubit/order_tracking_state.dart`, `order_tracking_effect.dart` | see below |

Bind exactly one adapter with `@LazySingleton(as: OrderRealtimeRepo)`.

## Port contract

- Network drops are not errors: `RealtimeConnectionChanged(reconnecting)`,
  then a retry after `RealtimeBackoff.delay(attempt)`.
- After every (re)connect the server sends a snapshot first, so a change
  missed while offline or paused is not lost. No replay log on the client.
- Every connect asks the factory for a fresh credential. Close 4401 on a
  socket that was live means the session expired on the server: reconnect.
- The stream errors with `RealtimeFailure` and ends only when retrying
  cannot help: the ticket request is rejected (401/403 after the
  `SessionInterceptor` refresh), 4401 right after a fresh credential, 4404 /
  HTTP 404 (resource not visible).
- Unknown, malformed or other-resource messages are ignored, not errors.
- Backoff resets when the snapshot arrives (the server accepted us).

## Socket adapter rules

- `wss://` only, URL from `AppConfig`. Credential: a short-lived single-use
  ticket from an authenticated `POST`, sent as the handshake `Authorization`
  header. Never the access token in the URL query (it lands in proxy logs).
- `pingInterval: 20 s`: dart:io pings and closes with 1001 when no pong
  arrives within the interval, so a half-open socket is detected.
- `connectTimeout: 10 s`; the default waits forever.
- Close with `status.normalClosure` (1000) and do not await it. Clients may
  only send 1000 or 3000–4999; `goingAway` (1001) throws `ArgumentError`.

## State and effects

```dart
final String? orderId;
final OrderStatus? status;
final DateTime? updatedAt;
final RealtimeConnection connection;   // badge "reconnecting", data stays
final UiEffect<OrderTrackingEffect>? effect;
```

`loading` is `loading` until the first status, then `complete`; `error` only
for a `RealtimeFailure`, which also emits
`OrderTrackingShowErrorEffect{error, retryAction: reconnect}`.

## Cubit rules

- One subscription. `start` cancels the previous one.
- Order and de-duplication: ignore an `OrderStatusChanged` older than the
  `updatedAt` on screen; an equal one is idempotent (same state).
- The Screen wires `AppLifecycleListener(onHide: cubit.pause, onShow:
  cubit.resume)` and disposes it. `pause` closes the socket or timer;
  `resume` restarts only what `pause` stopped, never a stream that ended in
  failure (that waits for the user's `reconnect`).
- `close()` cancels the subscription, which closes the socket or stops the
  timer.

## Implementation trap

Build the adapter stream with a `StreamController` (or stream operators), not
`async*` around an endless source: cancelling an `async*` stream waits until
its next `yield`, so `close()` hangs while the source is quiet. The deep link
reference hit this and was fixed the same way.

## Error, empty, offline

Offline → `reconnecting` badge, last status kept. Terminal failure → error
view or snackbar with reconnect. An order that does not exist yet is
`notFound`.

## Security and performance

- The server authorizes every subscribe for this user and closes with 4401
  when the session expires or is revoked; the client-side `orderId` filter is
  not a security control. Validate every message before use.
- Full jitter spreads reconnects after a server restart. Polling interval
  15 s by default, never below 5 s without a decision.
- Nothing runs in the background, so no battery cost and no Doze surprises.

## Test checklist

- [ ] Backoff: full jitter under a ceiling that doubles and caps at 30 s.
- [ ] WS: subscribe message, snapshot → live, changes in order.
- [ ] WS: malformed/unknown/other-order messages ignored.
- [ ] WS: drop → reconnecting with growing delays → resubscribe → live.
- [ ] WS: backoff resets after live.
- [ ] WS: 4401 before live → typed failure, no reconnect; 4401 while live →
      reconnect with a new credential; credential refused → typed failure.
- [ ] WS: cancel closes the socket and stops reconnecting.
- [ ] Polling: emits on change only; failure → reconnecting → live; 404 →
      `notFound` and done; cancel stops the timer.
- [ ] Cubit: loading → first status; reconnecting keeps data; older event
      ignored; terminal failure → error effect, reconnect relistens; pause and
      resume; resume after a failure does nothing; close cancels.

## Nguồn

- https://pub.dev/packages/web_socket_channel (3.0.3, tools.dart.dev)
- https://docs.flutter.dev/cookbook/networking/web-sockets
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://github.com/grpc/grpc/blob/master/doc/connection-backoff.md
- https://cheatsheetseries.owasp.org/cheatsheets/WebSocket_Security_Cheat_Sheet.html
- https://devcenter.heroku.com/articles/websocket-security (ticket auth)
- https://developer.android.com/training/monitoring-device-state/doze-standby
- https://api.flutter.dev/flutter/widgets/AppLifecycleListener-class.html
- https://pub.dev/packages/web_socket_client (alternative)
