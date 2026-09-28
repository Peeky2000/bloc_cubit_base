import 'dart:async';

import 'package:injectable/injectable.dart';

sealed class SessionEvent {
  const SessionEvent();
}

final class SessionExpiredEvent extends SessionEvent {
  const SessionExpiredEvent();
}

@singleton
class SessionEventController {
  final StreamController<SessionEvent> _controller =
      StreamController<SessionEvent>.broadcast(sync: true);

  Stream<SessionEvent> get events => _controller.stream;

  void publish(SessionEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  @disposeMethod
  Future<void> dispose() => _controller.close();
}
