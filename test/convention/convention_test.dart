import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/convention/rules.dart';

/// Fails `derry quality` and CI when code under lib/ breaks a machine-checked
/// convention. Rules live in tool/convention/rules.dart; the baseline below
/// lists legacy code that predates a rule and may only shrink.
void main() {
  test('lib/ follows the machine-checked conventions', () {
    final files = <SourceFile>[
      for (final root in ['lib', 'test/presentation'])
        for (final entity in Directory(root).listSync(recursive: true))
          if (entity is File &&
              entity.path.endsWith('.dart') &&
              !entity.path.contains('lib/modules/') &&
              !entity.path.contains('lib/generated/') &&
              !entity.path.endsWith('.g.dart') &&
              !entity.path.endsWith('injection.config.dart'))
            SourceFile(
              entity.path.replaceAll('\\', '/'),
              entity.readAsStringSync(),
            ),
    ];
    final baseline = File('tool/convention/baseline.txt')
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .toSet();
    final violations = checkAll(files, baseline: baseline);
    expect(
      violations.map((v) => v.toString()).toList(),
      isEmpty,
      reason:
          'Fix the code, or read docs/guides/ai-toolbox.md. Never add new code '
          'to tool/convention/baseline.txt.',
    );
  });
}
