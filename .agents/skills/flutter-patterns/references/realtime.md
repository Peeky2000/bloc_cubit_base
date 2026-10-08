# Realtime updates: stream, WebSocket or polling

Decision: [D-0005](../../../../docs/decisions/D-0005-cap-nhat-realtime-qua-stream.md)
(proposed). Reference code: `test/patterns/realtime_pattern_test.dart`.

## When to use

A screen shows server state that changes while it is open: order tracking,
delivery status, a live counter, a job's progress. Chat with history and
typing indicators follows the same port shape but deserves its own decision.

## Decision

The domain port is one `Stream<FeatureRealtimeEvent>` that connects on
listen, disconnects on cancel, emits the current snapshot after every
(re)connect and reconnects with capped exponential backoff; it is backed by a
WebSocket adapter when the backend has one (`web_socket_channel`, proposed)
and by a polling adapter otherwise, with the same Cubit for both.

## Files to create (feature `order_tracking`)

| Layer | Path | Content |
|---|---|---|
| Entity | `lib/domain/entities/order/order_status.dart` | `enum OrderStatus` |
| Port | `lib/domain/repositories/order_realtime_repo.dart` | `Stream<OrderRealtimeEvent> watchOrder(String orderId)`; `OrderStatusChanged{orderId, status, updatedAt}`, `RealtimeConnectionChanged(connecting/live/reconnecting)`, `RealtimeFailure{code}` |
| UseCase | `lib/domain/use_case/order_tracking_use_case.dart` | passes through |
| Backoff (shared) | `lib/data/datasource/remote/realtime_backoff.dart` | 1 s doubling to 30 s, 20 % jitter |
| Socket seam (shared) | `lib/data/datasource/remote/realtime_socket.dart` | `RealtimeSocket`, `RealtimeSocketFactory` |
| Socket adapter | `lib/data/datasource/remote/web_socket_factory.dart` | sketch in the test file (`IOWebSocketChannel`, `wss://`, bearer header, ping 20 s) |
| WS repo | `lib/data/repositories/web_socket_order_realtime_repo.dart` | subscribe message, parse, reconnect, close codes |
| Polling repo | `lib/data/repositories/polling_order_realtime_repo.dart` | `GET` every 15 s, emit on change only |
| Cubit | `lib/presentation/order_tracking/cubit/order_tracking_cubit.dart` | `start(orderId)`, `pause()`, `resume()`, `reconnect()` |
| State/effect | `.../cubit/order_tracking_state.dart`, `order_tracking_effect.dart` | see below |

Bind exactly one adapter with `@LazySingleton(as: OrderRealtimeRepo)`.

## Port contract

- Network drops are not errors. They are
  `RealtimeConnectionChanged(reconnecting)` and the adapter retries.
- After every (re)connect the server sends a snapshot first, so a change
  missed while offline is not lost.
- The stream errors with `RealtimeFailure` and ends only when retrying
  cannot help: token rejected (close code 4401 / HTTP 401, 403), resource not
  visible (4404 / 404).
- Unknown, malformed or other-resource messages are ignored, not errors.
- Backoff resets after the connection is live again.

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
- Ignore an `OrderStatusChanged` older than `updatedAt` on screen (events can
  arrive out of order around a reconnect).
- The Screen wires `AppLifecycleListener(onHide: cubit.pause, onShow:
  cubit.resume)` so nothing runs in the background. Push notifications cover
  background changes ([push_notification.md](push_notification.md)).
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

- `wss://` only; authenticate in the handshake header, never in the URL query
  (it lands in proxy logs). Reconnect reads the current token, so a refreshed
  token is used.
- Subscribe only to resources the server authorizes for this user; the
  client-side `orderId` filter is not a security control.
- Jittered backoff avoids a thundering herd after a server restart. Polling
  interval 15 s by default, never below 5 s without a decision.

## Test checklist

- [ ] Backoff doubles, caps and jitters within 20 %.
- [ ] WS: subscribe message, snapshot → live, changes in order.
- [ ] WS: malformed/unknown/other-order messages ignored.
- [ ] WS: drop → reconnecting with growing delays → resubscribe → live.
- [ ] WS: backoff resets after live.
- [ ] WS: close code 4401 → typed failure, no reconnect.
- [ ] WS: cancel closes the socket and stops reconnecting.
- [ ] Polling: emits on change only; failure → reconnecting → live; 404 →
      `notFound` and done; cancel stops the timer.
- [ ] Cubit: loading → first status; reconnecting keeps data; older event
      ignored; terminal failure → error effect, reconnect relistens; pause and
      resume; close cancels.

Reference code: `test/patterns/realtime_pattern_test.dart`
