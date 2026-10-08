import 'package:bloc_cubit_base/core/session/session_event.dart';
import 'package:bloc_cubit_base/data/datasource/local/session_expiry_coordinator.dart';
import 'package:bloc_cubit_base/domain/repositories/session_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late _MockSessionRepo session;
  late SessionEventController sessionEvents;
  late SessionExpiryCoordinator coordinator;

  setUp(() {
    session = _MockSessionRepo();
    sessionEvents = SessionEventController();
    coordinator = SessionExpiryCoordinator(session, sessionEvents);
  });

  tearDown(() => sessionEvents.dispose());

  test('clears credentials before publishing a typed expiry event', () async {
    var credentialsCleared = false;
    when(() => session.end()).thenAnswer((_) async {
      credentialsCleared = true;
    });
    final event = sessionEvents.events.first;

    await coordinator.expire();

    expect(await event, isA<SessionExpiredEvent>());
    expect(credentialsCleared, isTrue);
    verify(() => session.end()).called(1);
  });

  test('publishes expiry even when secure cleanup reports an error', () async {
    when(
      () => session.end(),
    ).thenThrow(StateError('secure storage unavailable'));
    final event = sessionEvents.events.first;

    await expectLater(coordinator.expire(), throwsStateError);

    expect(await event, isA<SessionExpiredEvent>());
    verify(() => session.end()).called(1);
  });
}

class _MockSessionRepo extends Mock implements SessionRepo {}
