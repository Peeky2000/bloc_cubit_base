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
        '${fixture.path}/ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync(),
      contains('APP_DISPLAY_NAME = "Example App";'),
      reason: 'PBX values containing spaces must always stay quoted.',
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
      expect(
        File('${sandbox.path}/outside/outside.dart').readAsStringSync(),
        contains('package:old_app/'),
        reason: 'Scanner must never follow a symlink outside the repository.',
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

  group('create --fresh-history', () {
    const remoteUrl = 'https://example.invalid/sli_common.git';
    late Map<String, String> environment;
    late String pinned;
    late String destination;

    List<String> createArguments({bool apply = false}) => [
      'create',
      '--root',
      fixture.path,
      '--destination',
      destination,
      '--display-name',
      'Example App',
      '--package-name',
      'example_app',
      '--bundle-id',
      'com.example.app',
      '--fresh-history',
      if (apply) '--apply',
    ];

    setUp(() {
      environment = _isolatedGitEnvironment(sandbox.path, identity: true);
      pinned = _initGitFixture(sandbox.path, fixture.path, environment);
      destination = '${sandbox.path}/new_app';
    });

    test('parses --fresh-history as a flag accepted only by create', () async {
      final parsed = CliArguments.parse([
        'create',
        '--fresh-history',
        '--destination',
        '../my_app',
      ]);
      expect(parsed.flag('fresh-history'), isTrue);
      expect(parsed.option('destination'), '../my_app');

      final output = <String>[];
      final code = await runBaseCli(
        [
          'rename',
          '--root',
          fixture.path,
          '--display-name',
          'Example',
          '--package-name',
          'example_app',
          '--bundle-id',
          'com.example.app',
          '--fresh-history',
        ],
        output: output.add,
        errorOutput: output.add,
      );
      expect(code, 2);
      expect(
        output.join('\n'),
        contains('Option không hỗ trợ: --fresh-history'),
      );

      final usage = <String>[];
      await runBaseCli(['--help'], output: usage.add);
      expect(usage.join('\n'), contains('[--fresh-history]'));
    });

    test('dry-run prints the history step without creating anything', () async {
      final output = <String>[];
      final code = await runBaseCli(
        createArguments(),
        output: output.add,
        errorOutput: output.add,
        environment: environment,
      );
      final shortHead = _runGit(
        ['rev-parse', '--short', 'HEAD'],
        fixture.path,
        environment,
      );

      expect(code, 0, reason: output.join('\n'));
      final text = output.join('\n');
      expect(
        text,
        contains(
          'history     : thay bằng 1 commit '
          '"chore: initial commit from old_app $shortHead"',
        ),
      );
      expect(
        text,
        contains(
          'submodule   : lib/modules/sli_common @ '
          '${pinned.substring(0, 12)} ($remoteUrl)',
        ),
      );
      expect(text, contains('git identity: Base Tester <tester@example.com>'));
      expect(text, contains('DRY-RUN: chưa tạo thư mục.'));
      expect(Directory(destination).existsSync(), isFalse);
    });

    test('dry-run without the flag keeps the base history', () async {
      final output = <String>[];
      final arguments = createArguments()..remove('--fresh-history');
      final code = await runBaseCli(
        arguments,
        output: output.add,
        errorOutput: output.add,
        environment: environment,
      );

      expect(code, 0, reason: output.join('\n'));
      expect(output.join('\n'), contains('giữ nguyên Git history của base'));
      expect(output.join('\n'), isNot(contains('initial commit from')));
    });

    test('missing git identity blocks before the first mutation', () async {
      final anonymous = _isolatedGitEnvironment(sandbox.path, identity: false);
      final dryRun = <String>[];
      final dryRunCode = await runBaseCli(
        createArguments(),
        output: dryRun.add,
        errorOutput: dryRun.add,
        environment: anonymous,
      );
      expect(dryRunCode, 2);
      expect(dryRun.join('\n'), contains('BLOCKED     : --fresh-history cần'));

      final apply = <String>[];
      final applyCode = await runBaseCli(
        createArguments(apply: true),
        output: apply.add,
        errorOutput: apply.add,
        environment: anonymous,
      );
      expect(applyCode, 2);
      expect(
        apply.join('\n'),
        contains('ERROR: --fresh-history cần git config user.name'),
      );
      expect(Directory(destination).existsSync(), isFalse);
    });

    test(
      'apply leaves one commit, the pinned submodule and the source intact',
      () async {
        final sourceState = _repositorySnapshot(fixture.path, environment);
        final shortHead = _runGit(
          ['rev-parse', '--short', 'HEAD'],
          fixture.path,
          environment,
        );
        final output = <String>[];

        final code = await runBaseCli(
          [...createArguments(apply: true), '--skip-bootstrap'],
          output: output.add,
          errorOutput: output.add,
          environment: environment,
        );

        expect(code, 0, reason: output.join('\n'));
        String git(List<String> arguments) =>
            _runGit(arguments, destination, environment);
        expect(
          git(['log', '--format=%s']),
          'chore: initial commit from old_app $shortHead',
        );
        expect(git(['rev-list', '--count', '--all']), '1');
        expect(git(['branch', '--show-current']), 'main');
        expect(git(['remote']), isEmpty);
        expect(git(['status', '--porcelain']), isEmpty);
        expect(
          git(['log', '--format=%an <%ae>']),
          'Base Tester <tester@example.com>',
        );
        expect(
          git(['submodule', 'status']),
          startsWith('$pinned lib/modules/sli_common'),
        );
        expect(
          git([
            'config',
            '--file',
            '.gitmodules',
            'submodule.lib/modules/sli_common.url',
          ]),
          remoteUrl,
        );
        expect(
          git(['config', 'submodule.lib/modules/sli_common.url']),
          remoteUrl,
        );
        expect(
          _runGit(
            ['config', '--get', 'remote.origin.url'],
            '$destination/lib/modules/sli_common',
            environment,
          ),
          remoteUrl,
        );
        expect(
          git(['show', 'HEAD:pubspec.yaml']),
          contains('name: example_app'),
          reason: 'The initial commit must contain the renamed identity.',
        );
        expect(_repositorySnapshot(fixture.path, environment), sourceState);
        expect(output.join('\n'), contains('Git history mới: 1 commit'));
      },
    );

    test('apply commits bootstrap output after rename', () async {
      final bootstrap = File('${fixture.path}/scripts/bootstrap.sh')
        ..writeAsStringSync(
          '#!/bin/sh\nset -e\n'
          'grep "name: example_app" pubspec.yaml > lib/bootstrap_marker.txt\n',
        );
      if (!Platform.isWindows) {
        Process.runSync('chmod', ['755', bootstrap.path]);
      }
      _runGit(['add', '--all'], fixture.path, environment);
      _runGit(['commit', '-qm', 'add bootstrap'], fixture.path, environment);
      final output = <String>[];

      final code = await runBaseCli(
        createArguments(apply: true),
        output: output.add,
        errorOutput: output.add,
        environment: environment,
      );

      expect(code, 0, reason: output.join('\n'));
      expect(
        _runGit(
          ['show', 'HEAD:lib/bootstrap_marker.txt'],
          destination,
          environment,
        ),
        'name: example_app',
      );
      expect(
        _runGit(['rev-list', '--count', 'HEAD'], destination, environment),
        '1',
      );
    });

    test('replaceGitHistory restores a drifted submodule to its pin', () async {
      final clone = '${sandbox.path}/clone';
      _runGit(
        ['clone', '--quiet', '--recurse-submodules', fixture.path, clone],
        sandbox.path,
        environment,
      );
      final submodule = '$clone/lib/modules/sli_common';
      _runGit(['checkout', '--quiet', 'origin/HEAD'], submodule, environment);
      expect(
        _runGit(['rev-parse', 'HEAD'], submodule, environment),
        isNot(pinned),
      );

      final commit = await replaceGitHistory(
        clone,
        commitMessage: 'chore: initial commit from test',
        environment: environment,
      );

      expect(_runGit(['rev-parse', 'HEAD'], clone, environment), commit);
      expect(_runGit(['rev-parse', 'HEAD'], submodule, environment), pinned);
      expect(
        _runGit(['submodule', 'status'], clone, environment),
        startsWith('$pinned lib/modules/sli_common'),
      );
      expect(_runGit(['status', '--porcelain'], clone, environment), isEmpty);
    });
  });
}

/// Git environment that ignores the developer's own config. The submodule
/// remote URL is rewritten to a local repository so no network is needed.
Map<String, String> _isolatedGitEnvironment(
  String sandbox, {
  required bool identity,
}) {
  final config = File(
    '$sandbox/gitconfig_${identity ? 'with' : 'without'}_identity',
  );
  config.writeAsStringSync(
    '[init]\n'
    '  defaultBranch = main\n'
    '[protocol "file"]\n'
    '  allow = always\n'
    '[url "$sandbox/sli_common_origin"]\n'
    '  insteadOf = https://example.invalid/sli_common.git\n'
    '[advice]\n'
    '  detachedHead = false\n'
    '${identity ? '[user]\n  name = Base Tester\n  email = tester@example.com\n' : ''}',
  );
  return {
    for (final entry in Platform.environment.entries)
      if (!entry.key.startsWith('GIT_')) entry.key: entry.value,
    'GIT_CONFIG_GLOBAL': config.path,
    'GIT_CONFIG_NOSYSTEM': '1',
  };
}

/// Turns the fixture into a Git repository with several commits and a real
/// `lib/modules/sli_common` submodule pinned behind its branch tip. Returns
/// the pinned submodule commit.
String _initGitFixture(
  String sandbox,
  String root,
  Map<String, String> environment,
) {
  final origin = Directory('$sandbox/sli_common_origin')..createSync();
  _runGit(['init', '--quiet'], origin.path, environment);
  File('${origin.path}/pubspec.yaml').writeAsStringSync(
    'name: sli_common\ndescription: package:old_app/ must stay untouched\n',
  );
  _runGit(['add', '--all'], origin.path, environment);
  _runGit(['commit', '-qm', 'sli_common v1'], origin.path, environment);
  final pinned = _runGit(['rev-parse', 'HEAD'], origin.path, environment);
  File('${origin.path}/CHANGELOG.md').writeAsStringSync('v2\n');
  _runGit(['add', '--all'], origin.path, environment);
  _runGit(['commit', '-qm', 'sli_common v2'], origin.path, environment);

  Directory('$root/lib/modules/sli_common').deleteSync(recursive: true);
  _runGit(['init', '--quiet'], root, environment);
  _runGit(['add', '--all'], root, environment);
  _runGit(['commit', '-qm', 'base: first'], root, environment);
  _runGit(
    [
      'submodule',
      'add',
      '--quiet',
      'https://example.invalid/sli_common.git',
      'lib/modules/sli_common',
    ],
    root,
    environment,
  );
  _runGit(
    ['checkout', '--quiet', pinned],
    '$root/lib/modules/sli_common',
    environment,
  );
  _runGit(['add', '--all'], root, environment);
  _runGit(['commit', '-qm', 'base: add sli_common'], root, environment);
  File('$root/README.md').writeAsStringSync('# old_app\n');
  _runGit(['add', '--all'], root, environment);
  _runGit(['commit', '-qm', 'base: readme'], root, environment);
  return pinned;
}

String _runGit(
  List<String> arguments,
  String workingDirectory,
  Map<String, String> environment,
) {
  final result = Process.runSync(
    'git',
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: false,
  );
  if (result.exitCode != 0) {
    fail(
      'git ${arguments.join(' ')} failed in $workingDirectory:\n'
      '${result.stderr}',
    );
  }
  return (result.stdout as String).trim();
}

/// Observable state of a repository, used to prove `create` never writes to
/// the source.
Map<String, String> _repositorySnapshot(
  String root,
  Map<String, String> environment,
) => {
  'head': _runGit(['rev-parse', 'HEAD'], root, environment),
  'refs': _runGit(['for-each-ref'], root, environment),
  'status': _runGit(['status', '--porcelain'], root, environment),
  'config': File('$root/.git/config').readAsStringSync(),
  'submodule': _runGit(['submodule', 'status'], root, environment),
  'submoduleConfig': File(
    '$root/.git/modules/lib/modules/sli_common/config',
  ).readAsStringSync(),
};

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
    final outside = File('${Directory(root).parent.path}/outside/outside.dart');
    outside.parent.createSync(recursive: true);
    outside.writeAsStringSync('// package:old_app/outside.dart\n');
    Link('$root/lib/external_link').createSync(outside.parent.path);
  }
  write('ios/Runner.xcodeproj/project.pbxproj', '''
APP_DISPLAY_NAME = "Old App Dev";
APP_DISPLAY_NAME = Old App;
PRODUCT_BUNDLE_IDENTIFIER = com.old.app;
''');
  write(
    'ios/config/dev/GoogleService-Info.plist',
    '<string>com.old.app</string>\n',
  );
}
