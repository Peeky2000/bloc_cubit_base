import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:bloc_cubit_base/presentation/splash/cubit/splash_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// load() waits on a real Future.delayed, so these tests use testWidgets for
// its fake clock: tester.pump advances time without waiting for it.
const _splashDelay = Duration(milliseconds: 1400);

void main() {
  late _MockAuthUseCase authUseCase;
  late SplashCubit cubit;

  setUp(() {
    authUseCase = _MockAuthUseCase();
    cubit = SplashCubit(authUseCase);
  });

  tearDown(() async {
    if (!cubit.isClosed) {
      await cubit.close();
    }
  });

  testWidgets('waits for the splash delay, then sends a signed-out user to '
      'sign in', (tester) async {
    when(() => authUseCase.isAppLogin()).thenReturn(false);

    final loading = cubit.load();
    await tester.pump(_splashDelay - const Duration(milliseconds: 1));
    expect(cubit.state.effect, isNull);

    await tester.pump(const Duration(milliseconds: 1));
    await loading;

    expect(cubit.state.isLogin, isFalse);
    expect(cubit.state.effect?.value, isA<SplashNavigateSignInEffect>());
  });

  testWidgets('sends a signed-in user home', (tester) async {
    when(() => authUseCase.isAppLogin()).thenReturn(true);

    final loading = cubit.load();
    await tester.pump(_splashDelay);
    await loading;

    expect(cubit.state.isLogin, isTrue);
    expect(cubit.state.effect?.value, isA<SplashNavigateHomeEffect>());
  });

  testWidgets('closing during the delay publishes nothing', (tester) async {
    when(() => authUseCase.isAppLogin()).thenReturn(true);

    final loading = cubit.load();
    await cubit.close();
    await tester.pump(_splashDelay);
    await loading;

    expect(cubit.state, SplashState.initial());
  });
}

class _MockAuthUseCase extends Mock implements AuthUseCase {}
