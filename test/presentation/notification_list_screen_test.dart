import 'package:bloc_cubit_base/core/app/app.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/domain/entities/app_notification/app_notification.dart';
import 'package:bloc_cubit_base/domain/entities/common/page_result.dart';
import 'package:bloc_cubit_base/domain/use_case/app_notification_use_case.dart';
import 'package:bloc_cubit_base/l10n/arb/app_localizations.dart';
import 'package:bloc_cubit_base/presentation/notification_list/cubit/notification_list_cubit.dart';
import 'package:bloc_cubit_base/presentation/notification_list/view/notification_list_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sli_common/l10n/arb/app_localizations.dart' as sli_l10n;

/// Spec: docs/specs/002-notifications/tech.md, section 15 (widget level).
void main() {
  late _MockUseCase useCase;
  late NotificationListCubit cubit;

  setUp(() {
    useCase = _MockUseCase();
    cubit = NotificationListCubit(useCase);
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
            localizationsDelegates: const [
              AppLocalizations.delegate,
              sli_l10n.AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: BlocProvider.value(
              value: cubit,
              child: const NotificationListScreen(),
            ),
          );
        },
      ),
    );
  }

  testWidgets('AC2: rows show title, body and an unread dot', (tester) async {
    when(
      () => useCase.getNotifications(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer(
      (_) async => PageResult<AppNotification>(
        items: [
          _Notification('a', isRead: false),
          _Notification('b', isRead: true),
        ],
        page: 1,
        hasMore: false,
      ),
    );

    await pumpScreen(tester);
    await cubit.load();
    await tester.pumpAndSettle();

    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('Tiêu đề a'), findsOneWidget);
    expect(find.text('Nội dung b'), findsOneWidget);
    expect(find.bySemanticsLabel('Chưa đọc'), findsOneWidget);
    expect(find.text('Đã hết'), findsOneWidget);
  });

  testWidgets('AC4: an empty list says "Chưa có thông báo"', (tester) async {
    when(
      () => useCase.getNotifications(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer(
      (_) async =>
          const PageResult<AppNotification>(items: [], page: 1, hasMore: false),
    );

    await pumpScreen(tester);
    await cubit.load();
    await tester.pumpAndSettle();

    expect(find.text('Chưa có thông báo'), findsOneWidget);
  });

  testWidgets('AC5: a failed first load offers Thử lại, which reloads', (
    tester,
  ) async {
    var calls = 0;
    when(
      () => useCase.getNotifications(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) throw StateError('offline');
      return PageResult<AppNotification>(
        items: [_Notification('a', isRead: true)],
        page: 1,
        hasMore: false,
      );
    });

    await pumpScreen(tester);
    await cubit.load();
    await tester.pumpAndSettle();
    expect(cubit.state.loading, LoadingStatus.error);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('Tiêu đề a'), findsOneWidget);
  });
}

class _Notification implements AppNotification {
  _Notification(this.id, {required this.isRead});

  @override
  final String id;

  @override
  final bool isRead;

  @override
  String get title => 'Tiêu đề $id';

  @override
  String get body => 'Nội dung $id';

  @override
  DateTime? get createdAt => DateTime(2026, 11, 26, 9, 15);
}

class _MockUseCase extends Mock implements AppNotificationUseCase {}
