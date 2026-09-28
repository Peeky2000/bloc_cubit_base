import 'package:bloc_cubit_base/core/session/session_event.dart';
import 'package:bloc_cubit_base/data/datasource/local/token_provider.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SessionExpiryCoordinator {
  SessionExpiryCoordinator(this._tokenProvider, this._sessionEvents);

  final TokenProvider _tokenProvider;
  final SessionEventController _sessionEvents;

  Future<void> expire() async {
    try {
      await _tokenProvider.clearToken();
    } finally {
      _sessionEvents.publish(const SessionExpiredEvent());
    }
  }
}
