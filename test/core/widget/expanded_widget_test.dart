// ignore_for_file: deprecated_member_use_from_same_package

import 'package:bloc_cubit_base/core/widget/expanded_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sli_common/sli_common.dart' as sli;

void main() {
  testWidgets('legacy app API delegates its behavior to sli_common', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExpandedWidget(
            expand: true,
            axis: Axis.horizontal,
            duration: Duration(milliseconds: 100),
            child: SizedBox(width: 120, height: 40),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final shared = tester.widget<sli.ExpandedWidget>(
      find.byType(sli.ExpandedWidget),
    );
    expect(shared.expand, isTrue);
    expect(shared.axis, Axis.horizontal);
    expect(shared.duration, const Duration(milliseconds: 100));
    expect(
      tester.widget<SizeTransition>(find.byType(SizeTransition)).alignment,
      Alignment.centerRight,
    );
    expect(tester.getSize(find.byType(ExpandedWidget)).width, 120);
  });
}
