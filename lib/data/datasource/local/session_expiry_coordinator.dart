import 'package:bloc_cubit_base/core/session/session_event.dart';
import 'package:bloc_cubit_base/domain/repositories/session_repo.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SessionExpiryCoordinator {
  SessionExpiryCoordinator(this._session, this._sessionEvents);

  final SessionRepo _session;
  final SessionEventController _sessionEvents;

  /// Ends the session the same way sign-out does, then announces it.
  Future<void> expire() async {
    try {
      await _session.end();
    } finally {
      _sessionEvents.publish(const SessionExpiredEvent());
    }
  }
}
