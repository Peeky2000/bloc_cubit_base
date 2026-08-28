import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/base_cli.dart';

void main() {
  late Directory sandbox;
  late Directory fixture;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('base_cli_test_');
    fixture = Directory('${sandbox.path}/template')..createSync();
    _writeFixture(fixture.path);
  });

  tearDown(() {
    if (sandbox.existsSync()) {
      sandbox.deleteSync(recursive: true);
    }
  });

  test('doctor validates deterministic template identity', () async {
    final report = await BaseCliEngine(fixture.path).doctor();

    expect(report.hasErrors, isFalse);
    expect(report.lines, contains(contains('Dart package khớp config')));
    expect(report.lines, contains(contains('MainActivity path đang lệch')));
  });

  test(
    'rename command is dry-run by default and does not mutate files',
    () async {
      final pubspec = File('${fixture.path}/pubspec.yaml');
      final before = pubspec.readAsStringSync();
      final output = <String>[];

      final code = await runBaseCli(
        [
          'rename',
          '--root',
          fixture.path,
          '--display-name',
          'Example',
          'App',
          '--package-name',
          'example_app',
          '--bundle-id',
          'com.example.app',
        ],
        output: output.add,
        errorOutput: output.add,
      );

      expect(code, 0);
      expect(output.join('\n'), contains('DRY-RUN: chưa có file nào'));
      expect(pubspec.readAsStringSync(), before);
      expect(
        File(
          '${fixture.path}/android/app/src/main/kotlin/com/old/app/MainActivity.kt',
        ).existsSync(),
        isFalse,
      );
    },
  );

  test('apply updates Dart/native identity and moves MainActivity', () async {
    final engine = BaseCliEngine(fixture.path);
    final plan = engine.planRename(
      const RenameRequest(
        dartPackage: 'example_app',
        bundleId: 'com.example.app',
        displayName: 'Example App',
      ),
    );

    expect(plan.edits, isNotEmpty);
    expect(plan.moves, hasLength(1));
    await engine.apply(plan);

    expect(
      File('${fixture.path}/pubspec.yaml').readAsStringSync(),
      contains('name: example_app'),
    );
    expect(
      File('${fixture.path}/lib/example.dart').readAsStringSync(),
      contains('package:example_app/example.dart'),
    );
    final movedActivity = File(
      '${fixture.path}/android/app/src/main/kotlin/com/example/app/MainActivity.kt',
    );
    expect(movedActivity.existsSync(), isTrue);
    expect(
      movedActivity.readAsStringSync(),
      contains('package com.example.app'),
    );
    expect(
      File(
        '${fixture.path}/ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync(),
      allOf(contains('com.example.app'), contains('Example App Dev')),
    );
    expect(
      File(
        '${fixture.path}/lib/modules/sli_common/pubspec.yaml',
      ).readAsStringSync(),
      contains('package:old_app/'),
      reason: 'Git submodule content must never be rewritten by the app CLI.',
    );
    expect(engine.config.dartPackage, 'example_app');
    expect(
      File('${fixture.path}/android/fastlane/Appfile').readAsStringSync(),
      contains('com.example.app'),
    );
    if (!Platform.isWindows) {
      expect(
        File('${fixture.path}/scripts/executable.sh').statSync().mode & 0x49,
        isNot(0),
        reason: 'Atomic replacement must preserve executable permission bits.',
      );
    }
  });

  test('invalid identity fails before any mutation', () {
    final pubspec = File('${fixture.path}/pubspec.yaml');
    final before = pubspec.readAsStringSync();
    final engine = BaseCliEngine(fixture.path);

    expect(
      () => engine.planRename(
        const RenameRequest(
          dartPackage: 'Invalid-Name',
          bundleId: 'not-a-bundle',
          displayName: 'Example',
        ),
      ),
      throwsA(isA<BaseCliException>()),
    );
    expect(pubspec.readAsStringSync(), before);
  });

  test('apply rejects stale plan before changing another file', () async {
    final engine = BaseCliEngine(fixture.path);
    final plan = engine.planRename(
      const RenameRequest(
        dartPackage: 'example_app',
        bundleId: 'com.example.app',
        displayName: 'Example App',
      ),
    );
    final first = File(plan.edits.first.path);
    first.writeAsStringSync('${first.readAsStringSync()}\nexternal change\n');
    final untouched = File('${fixture.path}/pubspec.yaml').readAsStringSync();

    await expectLater(engine.apply(plan), throwsA(isA<BaseCliException>()));
    expect(File('${fixture.path}/pubspec.yaml').readAsStringSync(), untouched);
  });

  test('destination validation rejects source descendants and collisions', () {
    expect(
      () => validateCreateDestination(
        fixture.path,
        '${fixture.path}/generated_app',
      ),
      throwsA(isA<BaseCliException>()),
    );
    final existing = Directory('${sandbox.path}/existing')..createSync();
    expect(
      () => validateCreateDestination(fixture.path, existing.path),
      throwsA(isA<BaseCliException>()),
    );
  });

  test('unsupported option is rejected instead of silently ignored', () async {
    final output = <String>[];
    final code = await runBaseCli(
      ['doctor', '--root', fixture.path, '--typo', 'value'],
      output: output.add,
      errorOutput: output.add,
    );

    expect(code, 2);
    expect(output.join('\n'), contains('Option không hỗ trợ: --typo'));
  });
}

void _writeFixture(String root) {
  void write(String relativePath, String content) {
    final file = File('$root/$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  write('pubspec.yaml', 'name: old_app\n');
  write('derry.yaml', 'doctor:\n  echo: doctor\n');
  write(
    'tool/base_cli.template.json',
    '${const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'dartPackage': 'old_app',
      'androidApplicationId': 'com.old.app',
      'iosBundleId': 'com.old.app',
      'displayName': 'Old App',
      'legacyBrandTokens': ['Old Product'],
    })}\n',
  );
  write('lib/example.dart', "import 'package:old_app/example.dart';\n");
  write(
    'lib/modules/sli_common/pubspec.yaml',
    'name: sli_common\ndescription: package:old_app/ must stay untouched\n',
  );
  write('android/app/build.gradle', '''
android {
  productFlavors {
    dev { resValue "string", "app_name", "Old App Dev" }
    prod { resValue "string", "app_name", "Old App" }
  }
  defaultConfig { applicationId "com.old.app" }
}
''');
  write(
    'android/app/src/main/AndroidManifest.xml',
    '<manifest package="com.old.app" />\n',
  );
  write(
    'android/app/src/main/kotlin/com/legacy/path/MainActivity.kt',
    'package com.old.app\n\nclass MainActivity\n',
  );
  write('android/fastlane/Appfile', 'package_name("com.old.app")\n');
  write('scripts/executable.sh', '#!/bin/sh\n# package:old_app/example.dart\n');
  if (!Platform.isWindows) {
    Process.runSync('chmod', ['755', '$root/scripts/executable.sh']);
  }
  write('ios/Runner.xcodeproj/project.pbxproj', '''
APP_DISPLAY_NAME = "Old App Dev";
PRODUCT_BUNDLE_IDENTIFIER = com.old.app;
''');
  write(
    'ios/config/dev/GoogleService-Info.plist',
    '<string>com.old.app</string>\n',
  );
}
