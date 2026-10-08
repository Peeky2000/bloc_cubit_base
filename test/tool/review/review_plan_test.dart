import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/review/review_plan.dart';

void main() {
  final config = ReviewConfig.fromJson(
    jsonDecode(File('tool/review/rules.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  String? ruleOf(String path) {
    final plan = buildPlan([FileChange(path, 'modified')], config);
    return plan.files.isEmpty ? null : plan.files.single['rule'];
  }

  test('maps each layer to its own rule, most specific first', () {
    expect(ruleOf('lib/domain/use_case/auth_use_case.dart'), 'domain');
    expect(ruleOf('lib/data/repositories/auth_repo_impl.dart'), 'data');
    expect(
      ruleOf('lib/presentation/sign_in/cubit/sign_in_cubit.dart'),
      'state',
    );
    expect(
      ruleOf('lib/presentation/sign_in/view/sign_in_screen.dart'),
      'screen',
    );
    expect(ruleOf('lib/di/register_module.dart'), 'di');
    expect(ruleOf('lib/l10n/arb/app_vi.arb'), 'arb');
    expect(ruleOf('test/di/injection_test.dart'), 'test');
    expect(ruleOf('integration_test/performance/app_start_test.dart'), 'test');
    expect(ruleOf('android/app/build.gradle'), 'native');
    expect(ruleOf('pubspec.yaml'), 'build');
    expect(ruleOf('docs/guides/measure-performance.md'), 'docs');
    expect(ruleOf('Makefile'), 'default');
  });

  test('excludes generated files and lockfiles with a reason', () {
    final plan = buildPlan(const [
      FileChange('lib/di/injection.config.dart', 'modified'),
      FileChange('lib/data/model/login_model.g.dart', 'modified'),
      FileChange('pubspec.lock', 'modified'),
      FileChange('lib/modules/sli_common/lib/a.dart', 'modified'),
      FileChange('lib/domain/entities/order.dart', 'added'),
    ], config);
    expect(plan.files.map((f) => f['path']), [
      'lib/domain/entities/order.dart',
    ]);
    expect(plan.excluded, hasLength(4));
    expect(plan.excluded.first['reason'], contains('generated'));
  });

  test('groups files that share a rule and keeps every file', () {
    final plan = buildPlan(const [
      FileChange('lib/domain/a.dart', 'modified'),
      FileChange('lib/domain/b.dart', 'added'),
      FileChange('lib/domain/a.dart', 'modified'),
    ], config);
    expect(plan.files, hasLength(2));
    expect(plan.groups['domain']!['files'], [
      'lib/domain/a.dart',
      'lib/domain/b.dart',
    ]);
    expect(plan.toJson()['reviewable_count'], 2);
  });

  test('parses git status and git diff output', () {
    final porcelain = parsePorcelain(
      ' M lib/a.dart\n?? docs/new.md\nR  old.dart -> lib/new.dart\n D x.dart\n',
    );
    expect(porcelain.map((c) => '${c.status}:${c.path}'), [
      'modified:lib/a.dart',
      'untracked:docs/new.md',
      'renamed:lib/new.dart',
      'deleted:x.dart',
    ]);
    final diff = parseNameStatus('A\tlib/a.dart\nR100\told.dart\tnew.dart\n');
    expect(diff.map((c) => '${c.status}:${c.path}'), [
      'added:lib/a.dart',
      'renamed:new.dart',
    ]);
  });

  test('glob supports globstar, braces and single segments', () {
    expect(matchesGlob('lib/**.dart', 'lib/a/b/c.dart'), isTrue);
    expect(matchesGlob('**/*.g.dart', 'lib/x/y.g.dart'), isTrue);
    expect(matchesGlob('**/*.g.dart', 'y.g.dart'), isTrue);
    expect(matchesGlob('{android,ios}/**', 'ios/Runner/Info.plist'), isTrue);
    expect(matchesGlob('*.md', 'docs/a.md'), isFalse);
  });
}
