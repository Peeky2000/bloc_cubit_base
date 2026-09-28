import 'package:bloc_cubit_base/core/session/session_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('publishes typed session events and closes cleanly', () async {
    final controller = SessionEventController();
    final events = <SessionEvent>[];
    final subscription = controller.events.listen(events.add);

    controller.publish(const SessionExpiredEvent());

    expect(events, [isA<SessionExpiredEvent>()]);
    await subscription.cancel();
    await controller.dispose();
    controller.publish(const SessionExpiredEvent());
    expect(events, hasLength(1));
  });
}
