import 'package:bloc_cubit_base/core/app/app.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/core/common/route.dart';
import 'package:bloc_cubit_base/core/routing/routing.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:bloc_cubit_base/l10n/arb/app_localizations.dart';
import 'package:bloc_cubit_base/presentation/account/cubit/account_cubit.dart';
import 'package:bloc_cubit_base/presentation/account/view/account_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sli_common/l10n/arb/app_localizations.dart' as sli_l10n;

/// Spec: docs/specs/001-account/tech.md, section 15 (widget level).
void main() {
  late _MockAuthUseCase authUseCase;
  late AccountCubit cubit;

  setUp(() {
    authUseCase = _MockAuthUseCase();
    cubit = AccountCubit(authUseCase);
  });

  tearDown(() => cubit.close());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        // App.init reads ScreenUtil sizes, so it runs inside the builder,
        // as MainApp does.
        builder: (_, _) {
          App.init();
          return MaterialApp(
            locale: const Locale('vi'),
            navigatorKey: SLIRouting.key,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              sli_l10n.AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            routes: {
              AppPage.signIn: (_) => const Scaffold(body: Text('sign-in')),
            },
            home: BlocProvider.value(
              value: cubit,
              child: const AccountScreen(),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('AC2: empty fields show "Chưa có"', (tester) async {
    cubit.emit(
      AccountState.initial().copyWith(
        loading: LoadingStatus.complete,
        email: 'an@example.com',
      ),
    );

    await pumpScreen(tester);

    expect(find.text('Tài khoản'), findsOneWidget);
    expect(find.text('an@example.com'), findsOneWidget);
    expect(find.text('Chưa có'), findsNWidgets(2));
  });

  testWidgets('AC3: confirming the dialog signs out and opens sign-in', (
    tester,
  ) async {
    when(() => authUseCase.logout()).thenAnswer((_) async {});
    cubit.emit(
      AccountState.initial().copyWith(loading: LoadingStatus.complete),
    );
    await pumpScreen(tester);

    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn có chắc muốn đăng xuất?'), findsOneWidget);
    verifyNever(() => authUseCase.logout());

    await tester.tap(find.text('Đăng xuất').last);
    await tester.pumpAndSettle();

    verify(() => authUseCase.logout()).called(1);
    expect(find.text('sign-in'), findsOneWidget);
  });
}

class _MockAuthUseCase extends Mock implements AuthUseCase {}
