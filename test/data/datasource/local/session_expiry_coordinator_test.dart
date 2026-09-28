import 'package:bloc_cubit_base/core/session/session_event.dart';
import 'package:bloc_cubit_base/data/datasource/local/session_expiry_coordinator.dart';
import 'package:bloc_cubit_base/data/datasource/local/token_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late _MockTokenProvider tokenProvider;
  late SessionEventController sessionEvents;
  late SessionExpiryCoordinator coordinator;

  setUp(() {
    tokenProvider = _MockTokenProvider();
    sessionEvents = SessionEventController();
    coordinator = SessionExpiryCoordinator(tokenProvider, sessionEvents);
  });

  tearDown(() => sessionEvents.dispose());

  test('clears credentials before publishing a typed expiry event', () async {
    var credentialsCleared = false;
    when(() => tokenProvider.clearToken()).thenAnswer((_) async {
      credentialsCleared = true;
    });
    final event = sessionEvents.events.first;

    await coordinator.expire();

    expect(await event, isA<SessionExpiredEvent>());
    expect(credentialsCleared, isTrue);
    verify(() => tokenProvider.clearToken()).called(1);
  });

  test('publishes expiry even when secure cleanup reports an error', () async {
    when(
      () => tokenProvider.clearToken(),
    ).thenThrow(StateError('secure storage unavailable'));
    final event = sessionEvents.events.first;

    await expectLater(coordinator.expire(), throwsStateError);

    expect(await event, isA<SessionExpiredEvent>());
    verify(() => tokenProvider.clearToken()).called(1);
  });
}

class _MockTokenProvider extends Mock implements TokenProvider {}
