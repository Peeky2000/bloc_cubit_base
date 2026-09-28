import 'package:bloc_cubit_base/core/app/app_cubit/app_cubit.dart';
import 'package:bloc_cubit_base/core/session/session_event.dart';
import 'package:bloc_cubit_base/domain/use_case/app_use_case.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late _MockAppUseCase appUseCase;
  late SessionEventController sessionEvents;

  setUp(() {
    appUseCase = _MockAppUseCase();
    sessionEvents = SessionEventController();
  });

  tearDown(() => sessionEvents.dispose());

  blocTest<AppCubit, AppState>(
    'maps every typed session expiry to a new app-state revision',
    build: () => AppCubit(appUseCase, sessionEvents),
    act: (_) {
      sessionEvents
        ..publish(const SessionExpiredEvent())
        ..publish(const SessionExpiredEvent());
    },
    expect: () => [
      const AppState(sessionExpiryRevision: 1),
      const AppState(sessionExpiryRevision: 2),
    ],
  );

  test('stops listening after the app cubit is closed', () async {
    final cubit = AppCubit(appUseCase, sessionEvents);
    await cubit.close();

    sessionEvents.publish(const SessionExpiredEvent());

    expect(cubit.state.sessionExpiryRevision, 0);
  });
}

class _MockAppUseCase extends Mock implements AppUseCase {}
