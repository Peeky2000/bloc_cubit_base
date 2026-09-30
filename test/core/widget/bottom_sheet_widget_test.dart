// ignore_for_file: deprecated_member_use_from_same_package

import 'package:bloc_cubit_base/core/widget/bottom_sheet_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sli_common/sli_common.dart' as sli;

void main() {
  testWidgets('legacy adapter delegates to the stable sli_common frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: BottomSheetWidget(
          title: 'Bộ lọc',
          height: 320,
          child: const Text('Nội dung'),
        ),
      ),
    );

    final frame = tester.widget<sli.SliBottomSheetFrame>(
      find.byType(sli.SliBottomSheetFrame),
    );
    expect(frame.title, 'Bộ lọc');
    expect(frame.showCloseButton, isFalse);
    expect(frame.showDivider, isFalse);
    expect(frame.safeAreaBottom, isFalse);
    expect(frame.height, isNull);
    expect(frame.maxHeight, 320);
    expect(find.text('Nội dung'), findsOneWidget);
  });

  testWidgets('legacy fixed-height contract remains available', (tester) async {
    await tester.pumpWidget(
      const _TestApp(
        child: BottomSheetWidget(
          isIntrinsicHeight: false,
          height: 280,
          child: Text('Cố định'),
        ),
      ),
    );

    expect(tester.getSize(find.byType(sli.SliBottomSheetFrame)).height, 280);
    expect(tester.takeException(), isNull);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, _) => MaterialApp(
      theme: sli.SliTheme.light(),
      home: Scaffold(body: child),
    ),
  );
}
