import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef LineWriter = void Function(String line);

const _configRelativePath = 'tool/base_cli.template.json';

Future<void> main(List<String> arguments) async {
  final code = await runBaseCli(arguments);
  if (code != 0) {
    exitCode = code;
  }
}

Future<int> runBaseCli(
  List<String> arguments, {
  LineWriter? output,
  LineWriter? errorOutput,
  String? defaultRoot,
}) async {
  final LineWriter out = output ?? (line) => stdout.writeln(line);
  final LineWriter err = errorOutput ?? (line) => stderr.writeln(line);

  try {
    final parsed = CliArguments.parse(arguments);
    if (parsed.showHelp || parsed.command == null) {
      out(_usage);
      return 0;
    }

    final root = parsed.option('root') ?? defaultRoot ?? _scriptRoot();
    switch (parsed.command) {
      case 'doctor':
        parsed.validateAllowed(options: const {'root'});
        final report = await BaseCliEngine(root).doctor();
        for (final line in report.lines) {
          out(line);
        }
        return report.hasErrors ? 2 : 0;
      case 'rename':
        parsed.validateAllowed(
          options: const {'root', 'package-name', 'bundle-id', 'display-name'},
          flags: const {'apply'},
        );
        final request = RenameRequest.fromArguments(parsed);
        final engine = BaseCliEngine(root);
        final plan = engine.planRename(request);
        _printPlan(plan, out: out, apply: parsed.flag('apply'));
        if (!parsed.flag('apply')) {
          out(
            'DRY-RUN: chưa có file nào bị thay đổi. Thêm --apply để thực thi.',
          );
          return 0;
        }
        await engine.apply(plan);
        out(
          'Đã áp dụng ${plan.edits.length} file edit và '
          '${plan.moves.length} file move.',
        );
        _printPostRenameChecklist(plan.config, out);
        return 0;
      case 'create':
        parsed.validateAllowed(
          options: const {
            'root',
            'destination',
            'package-name',
            'bundle-id',
            'display-name',
          },
          flags: const {'apply', 'skip-bootstrap'},
        );
        final request = RenameRequest.fromArguments(parsed);
        final destination = parsed.requiredOption('destination');
        return _createApplication(
          sourceRoot: root,
          destination: destination,
          request: request,
          apply: parsed.flag('apply'),
          skipBootstrap: parsed.flag('skip-bootstrap'),
          out: out,
        );
      default:
        throw BaseCliException(
          'Command không hỗ trợ: ${parsed.command}. Dùng --help để xem lệnh.',
        );
    }
  } on BaseCliException catch (error) {
    err('ERROR: ${error.message}');
    return 2;
  } on FileSystemException catch (error) {
    err('ERROR filesystem: ${error.message} (${error.path ?? 'unknown'})');
    return 3;
  }
}

Future<int> _createApplication({
  required String sourceRoot,
  required String destination,
  required RenameRequest request,
  required bool apply,
  required bool skipBootstrap,
  required LineWriter out,
}) async {
  final source = _canonicalExistingDirectory(sourceRoot);
  final target = validateCreateDestination(source, destination);
  final sourceEngine = BaseCliEngine(source);
  final doctor = await sourceEngine.doctor();
  if (doctor.hasErrors) {
    throw BaseCliException(
      'Template source chưa hợp lệ:\n${doctor.lines.join('\n')}',
    );
  }

  final dirty = await _gitStatus(source);
  out('CREATE PLAN');
  out('  source      : $source');
  out('  destination : $target');
  out('  package     : ${request.dartPackage}');
  out('  bundle id   : ${request.bundleId}');
  out('  display name: ${request.displayName}');
  out('  bootstrap   : ${skipBootstrap ? 'skip' : 'run scripts/bootstrap.sh'}');
  if (dirty.isNotEmpty) {
    out(
      '  BLOCKED     : source Git tree đang dirty; clone sẽ bỏ sót thay đổi.',
    );
  }

  if (!apply) {
    out(
      'DRY-RUN: chưa tạo thư mục. Commit source rồi thêm --apply để thực thi.',
    );
    return dirty.isEmpty ? 0 : 2;
  }
  if (dirty.isNotEmpty) {
    throw BaseCliException(
      'Source Git tree phải sạch trước create --apply:\n$dirty',
    );
  }

  final clone = await Process.run('git', [
    'clone',
    '--recurse-submodules',
    '--local',
    source,
    target,
  ]);
  if (clone.exitCode != 0) {
    throw BaseCliException('Git clone thất bại:\n${clone.stderr}');
  }

  final targetEngine = BaseCliEngine(target);
  try {
    final plan = targetEngine.planRename(request);
    await targetEngine.apply(plan);
  } on Object catch (error) {
    throw BaseCliException(
      'Clone đã tạo tại $target nhưng rename thất bại. Giữ thư mục để điều tra: '
      '$error',
    );
  }

  if (!skipBootstrap) {
    final bootstrap = await Process.run(
      './scripts/bootstrap.sh',
      const [],
      workingDirectory: target,
      runInShell: false,
    );
    if (bootstrap.exitCode != 0) {
      throw BaseCliException(
        'App đã tạo tại $target nhưng bootstrap thất bại:\n'
        '${bootstrap.stdout}\n${bootstrap.stderr}',
      );
    }
  }

  out('Đã tạo application tại $target. Git history của base được giữ nguyên.');
  _printPostRenameChecklist(targetEngine.config, out);
  return 0;
}

void _printPlan(
  MutationPlan plan, {
  required LineWriter out,
  required bool apply,
}) {
  out('${apply ? 'APPLY' : 'DRY-RUN'} RENAME PLAN');
  out('  root        : ${plan.root}');
  out('  Dart package: ${plan.config.dartPackage}');
  out('  Android ID  : ${plan.config.androidApplicationId}');
  out('  iOS ID      : ${plan.config.iosBundleId}');
  out('  Display name: ${plan.config.displayName}');
  for (final edit in plan.edits) {
    out('  EDIT ${_relative(plan.root, edit.path)}');
  }
  for (final move in plan.moves) {
    out('  MOVE ${_relative(plan.root, move.from)}');
    out('    -> ${_relative(plan.root, move.to)}');
  }
}

void _printPostRenameChecklist(BaseTemplateConfig config, LineWriter out) {
  out('Việc bắt buộc làm theo từng sản phẩm:');
  out('  1. Thay Firebase config của từng flavor; không tin credential mẫu.');
  out('  2. Cấu hình Android/iOS signing bằng secret local hoặc CI.');
  out('  3. Review icon, splash, API URL, sample feature và branding legacy.');
  if (config.legacyBrandTokens.isNotEmpty) {
    out('  4. Tìm và xử lý có chủ ý: ${config.legacyBrandTokens.join(', ')}.');
  }
  out('  5. Chạy derry gen, derry quality và native debug build.');
}

class BaseCliEngine {
  BaseCliEngine(String root)
    : root = _canonicalExistingDirectory(root),
      config = BaseTemplateConfig.read(
        File('${_canonicalExistingDirectory(root)}/$_configRelativePath'),
      );

  final String root;
  BaseTemplateConfig config;

  Future<DoctorReport> doctor() async {
    final lines = <String>[];
    var hasErrors = false;

    void check(bool condition, String success, String failure) {
      if (condition) {
        lines.add('[OK] $success');
      } else {
        hasErrors = true;
        lines.add('[ERROR] $failure');
      }
    }

    final pubspec = File('$root/pubspec.yaml');
    final androidGradle = File('$root/android/app/build.gradle');
    final iosProject = File('$root/ios/Runner.xcodeproj/project.pbxproj');
    check(pubspec.existsSync(), 'pubspec.yaml tồn tại', 'thiếu pubspec.yaml');
    check(
      File('$root/derry.yaml').existsSync(),
      'derry.yaml tồn tại',
      'thiếu derry.yaml',
    );
    check(
      File('$root/lib/modules/sli_common/pubspec.yaml').existsSync(),
      'sli_common đã được initialize',
      'sli_common chưa initialize; chạy git submodule update --init --recursive',
    );
    if (pubspec.existsSync()) {
      check(
        RegExp(
          '^name:\\s*${RegExp.escape(config.dartPackage)}\\s*\$',
          multiLine: true,
        ).hasMatch(pubspec.readAsStringSync()),
        'Dart package khớp config: ${config.dartPackage}',
        'Dart package trong pubspec không khớp $_configRelativePath',
      );
    }
    if (androidGradle.existsSync()) {
      check(
        androidGradle.readAsStringSync().contains(config.androidApplicationId),
        'Android application ID khớp config',
        'Android application ID không khớp config',
      );
    } else {
      check(false, '', 'thiếu android/app/build.gradle');
    }
    if (iosProject.existsSync()) {
      check(
        iosProject.readAsStringSync().contains(config.iosBundleId),
        'iOS bundle ID khớp config',
        'iOS bundle ID không khớp config',
      );
    } else {
      check(false, '', 'thiếu ios/Runner.xcodeproj/project.pbxproj');
    }

    final activities = _findMainActivities(root);
    check(
      activities.length == 1,
      'Tìm thấy đúng một MainActivity Kotlin',
      'Cần đúng một MainActivity Kotlin, hiện có ${activities.length}',
    );
    if (activities.length == 1) {
      final expected = _mainActivityPath(root, config.androidApplicationId);
      final actual = activities.single.path;
      check(
        activities.single.readAsStringSync().contains(
          'package ${config.androidApplicationId}',
        ),
        'Kotlin package khớp Android ID',
        'Kotlin package không khớp Android ID',
      );
      if (actual != expected) {
        lines.add(
          '[WARN] MainActivity path đang lệch package; rename --apply sẽ move: '
          '${_relative(root, actual)}',
        );
      }
    }
    return DoctorReport(lines: lines, hasErrors: hasErrors);
  }

  MutationPlan planRename(RenameRequest request) {
    request.validate();
    _validateTemplateShape();

    final nextConfig = config.copyWith(
      dartPackage: request.dartPackage,
      androidApplicationId: request.bundleId,
      iosBundleId: request.bundleId,
      displayName: request.displayName,
    );
    final drafts = <String, _EditDraft>{};

    void replaceInFile(File file, String from, String to, String reason) {
      if (from == to || !file.existsSync()) {
        return;
      }
      final current = drafts[file.path]?.updated ?? file.readAsStringSync();
      if (!current.contains(from)) {
        return;
      }
      drafts[file.path] = _EditDraft(
        original: drafts[file.path]?.original ?? file.readAsStringSync(),
        updated: current.replaceAll(from, to),
        reasons: {...?drafts[file.path]?.reasons, reason},
      );
    }

    void transformFile(
      File file,
      String reason,
      String Function(String content) transform,
    ) {
      if (!file.existsSync()) {
        return;
      }
      final current = drafts[file.path]?.updated ?? file.readAsStringSync();
      final updated = transform(current);
      if (current == updated) {
        return;
      }
      drafts[file.path] = _EditDraft(
        original: drafts[file.path]?.original ?? file.readAsStringSync(),
        updated: updated,
        reasons: {...?drafts[file.path]?.reasons, reason},
      );
    }

    if (config.dartPackage != request.dartPackage) {
      final pubspec = File('$root/pubspec.yaml');
      replaceInFile(
        pubspec,
        'name: ${config.dartPackage}',
        'name: ${request.dartPackage}',
        'Dart package name',
      );
      for (final file in _textFiles(root)) {
        replaceInFile(
          file,
          'package:${config.dartPackage}/',
          'package:${request.dartPackage}/',
          'Dart package imports',
        );
      }
    }

    if (config.androidApplicationId != request.bundleId) {
      for (final file in _nativeTextFiles('$root/android')) {
        replaceInFile(
          file,
          config.androidApplicationId,
          request.bundleId,
          'Android application ID',
        );
      }
    }
    if (config.iosBundleId != request.bundleId) {
      for (final file in _nativeTextFiles('$root/ios')) {
        replaceInFile(
          file,
          config.iosBundleId,
          request.bundleId,
          'iOS bundle ID',
        );
      }
    }

    if (config.displayName != request.displayName) {
      final oldName = RegExp.escape(config.displayName);
      final androidDisplayPattern = RegExp(
        '(resValue\\s+"string",\\s+"app_name",\\s+")'
        '$oldName((?: Dev| Staging)?)(")',
      );
      final androidGradle = File('$root/android/app/build.gradle');
      if (!androidDisplayPattern.hasMatch(androidGradle.readAsStringSync())) {
        throw BaseCliException(
          'Không tìm thấy Android display-name pattern cần đổi.',
        );
      }
      transformFile(androidGradle, 'Android display names', (content) {
        return content.replaceAllMapped(androidDisplayPattern, (match) {
          final value = _escapeGradleString(
            '${request.displayName}${match.group(2)!}',
          );
          return '${match.group(1)}$value${match.group(3)}';
        });
      });

      final iosDisplayPattern = RegExp(
        '(APP_DISPLAY_NAME\\s*=\\s*)"?'
        '$oldName((?: Dev| Staging)?)"?;',
      );
      final iosProject = File('$root/ios/Runner.xcodeproj/project.pbxproj');
      if (!iosDisplayPattern.hasMatch(iosProject.readAsStringSync())) {
        throw BaseCliException(
          'Không tìm thấy iOS display-name pattern cần đổi.',
        );
      }
      transformFile(iosProject, 'iOS display names', (content) {
        return content.replaceAllMapped(iosDisplayPattern, (match) {
          final value = _escapePbxString(
            '${request.displayName}${match.group(2)!}',
          );
          return '${match.group(1)}"$value";';
        });
      });
    }

    final configFile = File('$root/$_configRelativePath');
    final encodedConfig =
        '${const JsonEncoder.withIndent('  ').convert(nextConfig.toJson())}\n';
    final currentConfig = configFile.readAsStringSync();
    if (currentConfig != encodedConfig) {
      drafts[configFile.path] = _EditDraft(
        original: currentConfig,
        updated: encodedConfig,
        reasons: const {'Template identity config'},
      );
    }

    final activities = _findMainActivities(root);
    if (activities.length != 1) {
      throw BaseCliException(
        'Cần đúng một MainActivity Kotlin trước rename, hiện có '
        '${activities.length}.',
      );
    }
    final activity = activities.single;
    final newActivityPath = _mainActivityPath(root, request.bundleId);
    final moves = <FileMove>[];
    if (activity.path != newActivityPath) {
      if (File(newActivityPath).existsSync()) {
        throw BaseCliException(
          'MainActivity destination đã tồn tại: $newActivityPath',
        );
      }
      moves.add(FileMove(from: activity.path, to: newActivityPath));
    }

    final edits =
        drafts.entries
            .where((entry) => entry.value.original != entry.value.updated)
            .map(
              (entry) => FileEdit(
                path: entry.key,
                original: entry.value.original,
                updated: entry.value.updated,
                reasons: entry.value.reasons.toList()..sort(),
              ),
            )
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));
    if (edits.isEmpty && moves.isEmpty) {
      throw BaseCliException(
        'Identity mới giống identity hiện tại; không có gì để đổi.',
      );
    }

    return MutationPlan(
      root: root,
      config: nextConfig,
      edits: edits,
      moves: moves,
    );
  }

  Future<void> apply(MutationPlan plan) async {
    if (plan.root != root) {
      throw BaseCliException('Mutation plan không thuộc engine root hiện tại.');
    }
    for (final edit in plan.edits) {
      final file = File(edit.path);
      if (!file.existsSync() || file.readAsStringSync() != edit.original) {
        throw BaseCliException(
          'File đã đổi sau lúc lập plan, hủy apply: ${edit.path}',
        );
      }
    }
    for (final move in plan.moves) {
      if (!File(move.from).existsSync() || File(move.to).existsSync()) {
        throw BaseCliException('File move không còn hợp lệ: ${move.from}');
      }
    }

    final completedMoves = <FileMove>[];
    final completedEdits = <FileEdit>[];
    try {
      for (final edit in plan.edits) {
        _writeAtomically(edit.path, edit.updated);
        completedEdits.add(edit);
      }
      for (final move in plan.moves) {
        await Directory(File(move.to).parent.path).create(recursive: true);
        await File(move.from).rename(move.to);
        completedMoves.add(move);
      }
      config = plan.config;
    } on Object {
      for (final move in completedMoves.reversed) {
        if (File(move.to).existsSync()) {
          await Directory(File(move.from).parent.path).create(recursive: true);
          await File(move.to).rename(move.from);
        }
      }
      for (final edit in completedEdits.reversed) {
        _writeAtomically(edit.path, edit.original);
      }
      rethrow;
    }
  }

  void _validateTemplateShape() {
    final required = [
      '$root/pubspec.yaml',
      '$root/android/app/build.gradle',
      '$root/ios/Runner.xcodeproj/project.pbxproj',
      '$root/$_configRelativePath',
    ];
    final missing = required.where((path) => !File(path).existsSync()).toList();
    if (missing.isNotEmpty) {
      throw BaseCliException(
        'Template thiếu file bắt buộc:\n${missing.join('\n')}',
      );
    }
    final pubspec = File('$root/pubspec.yaml').readAsStringSync();
    if (!RegExp(
      '^name:\\s*${RegExp.escape(config.dartPackage)}\\s*\$',
      multiLine: true,
    ).hasMatch(pubspec)) {
      throw BaseCliException('Config Dart package không khớp pubspec.yaml.');
    }
  }
}

class RenameRequest {
  const RenameRequest({
    required this.dartPackage,
    required this.bundleId,
    required this.displayName,
  });

  factory RenameRequest.fromArguments(CliArguments arguments) => RenameRequest(
    dartPackage: arguments.requiredOption('package-name').trim(),
    bundleId: arguments.requiredOption('bundle-id').trim(),
    displayName: arguments.requiredOption('display-name').trim(),
  );

  final String dartPackage;
  final String bundleId;
  final String displayName;

  void validate() {
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(dartPackage)) {
      throw BaseCliException(
        'Dart package không hợp lệ: "$dartPackage". Dùng snake_case chữ thường.',
      );
    }
    if (!RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$').hasMatch(bundleId)) {
      throw BaseCliException(
        'Bundle ID không hợp lệ: "$bundleId". Dùng reverse-domain chữ thường.',
      );
    }
    final normalizedName = displayName.trim();
    if (normalizedName.isEmpty ||
        normalizedName.length > 50 ||
        normalizedName.contains(RegExp(r'[\r\n]')) ||
        normalizedName.contains(r'$')) {
      throw BaseCliException('Display name phải có 1-50 ký tự trên một dòng.');
    }
  }
}

class BaseTemplateConfig {
  const BaseTemplateConfig({
    required this.schemaVersion,
    required this.dartPackage,
    required this.androidApplicationId,
    required this.iosBundleId,
    required this.displayName,
    required this.legacyBrandTokens,
  });

  factory BaseTemplateConfig.read(File file) {
    if (!file.existsSync()) {
      throw BaseCliException('Thiếu template config: ${file.path}');
    }
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final config = BaseTemplateConfig(
        schemaVersion: json['schemaVersion'] as int,
        dartPackage: json['dartPackage'] as String,
        androidApplicationId: json['androidApplicationId'] as String,
        iosBundleId: json['iosBundleId'] as String,
        displayName: json['displayName'] as String,
        legacyBrandTokens: (json['legacyBrandTokens'] as List<dynamic>)
            .cast<String>(),
      );
      if (config.schemaVersion != 1) {
        throw BaseCliException(
          'schemaVersion không hỗ trợ: ${config.schemaVersion}',
        );
      }
      return config;
    } on BaseCliException {
      rethrow;
    } on Object catch (error) {
      throw BaseCliException('Template config không hợp lệ: $error');
    }
  }

  final int schemaVersion;
  final String dartPackage;
  final String androidApplicationId;
  final String iosBundleId;
  final String displayName;
  final List<String> legacyBrandTokens;

  BaseTemplateConfig copyWith({
    String? dartPackage,
    String? androidApplicationId,
    String? iosBundleId,
    String? displayName,
  }) => BaseTemplateConfig(
    schemaVersion: schemaVersion,
    dartPackage: dartPackage ?? this.dartPackage,
    androidApplicationId: androidApplicationId ?? this.androidApplicationId,
    iosBundleId: iosBundleId ?? this.iosBundleId,
    displayName: displayName ?? this.displayName,
    legacyBrandTokens: legacyBrandTokens,
  );

  Map<String, Object> toJson() => {
    'schemaVersion': schemaVersion,
    'dartPackage': dartPackage,
    'androidApplicationId': androidApplicationId,
    'iosBundleId': iosBundleId,
    'displayName': displayName,
    'legacyBrandTokens': legacyBrandTokens,
  };
}

class MutationPlan {
  const MutationPlan({
    required this.root,
    required this.config,
    required this.edits,
    required this.moves,
  });

  final String root;
  final BaseTemplateConfig config;
  final List<FileEdit> edits;
  final List<FileMove> moves;
}

class FileEdit {
  const FileEdit({
    required this.path,
    required this.original,
    required this.updated,
    required this.reasons,
  });

  final String path;
  final String original;
  final String updated;
  final List<String> reasons;
}

class FileMove {
  const FileMove({required this.from, required this.to});

  final String from;
  final String to;
}

class DoctorReport {
  const DoctorReport({required this.lines, required this.hasErrors});

  final List<String> lines;
  final bool hasErrors;
}

class _EditDraft {
  const _EditDraft({
    required this.original,
    required this.updated,
    required this.reasons,
  });

  final String original;
  final String updated;
  final Set<String> reasons;
}

class CliArguments {
  CliArguments._({
    required this.command,
    required this.options,
    required this.flags,
    required this.showHelp,
  });

  factory CliArguments.parse(List<String> arguments) {
    if (arguments.isEmpty) {
      return CliArguments._(
        command: null,
        options: const {},
        flags: const {},
        showHelp: true,
      );
    }
    final command = arguments.first.startsWith('-') ? null : arguments.first;
    final start = command == null ? 0 : 1;
    final options = <String, String>{};
    final flags = <String>{};
    var showHelp = false;
    const booleanFlags = {'apply', 'skip-bootstrap'};

    for (var index = start; index < arguments.length; index++) {
      final item = arguments[index];
      if (item == '--help' || item == '-h') {
        showHelp = true;
        continue;
      }
      if (!item.startsWith('--')) {
        throw BaseCliException('Argument không hợp lệ: $item');
      }
      final name = item.substring(2);
      if (booleanFlags.contains(name)) {
        flags.add(name);
        continue;
      }
      if (index + 1 >= arguments.length ||
          arguments[index + 1].startsWith('--')) {
        throw BaseCliException('Thiếu giá trị cho --$name');
      }
      final values = <String>[];
      while (index + 1 < arguments.length &&
          !arguments[index + 1].startsWith('--')) {
        values.add(arguments[++index]);
      }
      options[name] = values.join(' ');
    }
    return CliArguments._(
      command: command,
      options: options,
      flags: flags,
      showHelp: showHelp,
    );
  }

  final String? command;
  final Map<String, String> options;
  final Set<String> flags;
  final bool showHelp;

  bool flag(String name) => flags.contains(name);

  String? option(String name) => options[name];

  String requiredOption(String name) {
    final value = options[name];
    if (value == null || value.trim().isEmpty) {
      throw BaseCliException('Thiếu option bắt buộc --$name');
    }
    return value;
  }

  void validateAllowed({
    required Set<String> options,
    Set<String> flags = const {},
  }) {
    final unknownOptions = this.options.keys
        .where((name) => !options.contains(name))
        .toList();
    final unknownFlags = this.flags
        .where((name) => !flags.contains(name))
        .toList();
    if (unknownOptions.isNotEmpty || unknownFlags.isNotEmpty) {
      final unknown = [
        ...unknownOptions.map((name) => '--$name'),
        ...unknownFlags.map((name) => '--$name'),
      ];
      throw BaseCliException('Option không hỗ trợ: ${unknown.join(', ')}');
    }
  }
}

class BaseCliException implements Exception {
  const BaseCliException(this.message);

  final String message;

  @override
  String toString() => message;
}

String validateCreateDestination(String sourceRoot, String destination) {
  final target = _canonicalNewPath(destination);
  final source = _canonicalExistingDirectory(sourceRoot);
  if (target == source ||
      _isWithin(source, target) ||
      _isWithin(target, source)) {
    throw BaseCliException(
      'Destination không được trùng, nằm trong hoặc bao ngoài source repository.',
    );
  }
  if (FileSystemEntity.typeSync(target) != FileSystemEntityType.notFound) {
    throw BaseCliException('Destination đã tồn tại: $target');
  }
  final parent = Directory(target).parent;
  if (!parent.existsSync()) {
    throw BaseCliException(
      'Thư mục cha của destination không tồn tại: ${parent.path}',
    );
  }
  return target;
}

Iterable<File> _textFiles(String root) sync* {
  const extensions = {
    '.dart',
    '.md',
    '.yaml',
    '.yml',
    '.json',
    '.arb',
    '.env',
    '.xml',
    '.plist',
    '.pbxproj',
    '.gradle',
    '.kts',
    '.kt',
    '.swift',
    '.m',
    '.mm',
    '.h',
    '.rb',
    '.sh',
    '.txt',
    '.xcconfig',
  };
  const excludedSegments = {
    '.git',
    '.dart_tool',
    '.fvm',
    'build',
    'Pods',
    '.symlinks',
  };

  final pending = <Directory>[Directory(root)];
  while (pending.isNotEmpty) {
    final directory = pending.removeLast();
    for (final entity in directory.listSync(followLinks: false)) {
      if (entity is Link) {
        continue;
      }
      final relative = _relative(root, entity.path);
      final segments = relative.split(Platform.pathSeparator);
      if (entity is Directory) {
        if (segments.any(excludedSegments.contains) ||
            relative ==
                'lib${Platform.pathSeparator}modules${Platform.pathSeparator}sli_common' ||
            relative.startsWith(
              'lib${Platform.pathSeparator}modules${Platform.pathSeparator}sli_common${Platform.pathSeparator}',
            )) {
          continue;
        }
        pending.add(entity);
        continue;
      }
      if (entity is! File || entity.statSync().size > 2 * 1024 * 1024) {
        continue;
      }
      if (segments.any(excludedSegments.contains)) {
        continue;
      }
      final dot = entity.path.lastIndexOf('.');
      final extension = dot == -1 ? '' : entity.path.substring(dot);
      if (!extensions.contains(extension) &&
          !const {
            'pubspec.yaml',
            'derry.yaml',
            'Appfile',
            'Fastfile',
            'Gemfile',
          }.contains(segments.last)) {
        continue;
      }
      try {
        utf8.decode(entity.readAsBytesSync());
        yield entity;
      } on FormatException {
        continue;
      }
    }
  }
}

Iterable<File> _nativeTextFiles(String root) sync* {
  if (!Directory(root).existsSync()) {
    return;
  }
  for (final file in _textFiles(root)) {
    yield file;
  }
}

List<File> _findMainActivities(String root) =>
    Directory('$root/android/app/src')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('${Platform.pathSeparator}MainActivity.kt'),
        )
        .toList();

String _mainActivityPath(String root, String bundleId) =>
    '$root/android/app/src/main/kotlin/${bundleId.replaceAll('.', '/')}/MainActivity.kt';

String _escapeGradleString(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

String _escapePbxString(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

void _writeAtomically(String path, String content) {
  final file = File(path);
  final originalMode = file.statSync().mode & 0x1FF;
  final temporary = File(
    '$path.base_cli_tmp_${pid}_${DateTime.now().microsecondsSinceEpoch}',
  );
  temporary.writeAsStringSync(content, flush: true);
  if (!Platform.isWindows) {
    final chmod = Process.runSync('chmod', [
      originalMode.toRadixString(8).padLeft(3, '0'),
      temporary.path,
    ]);
    if (chmod.exitCode != 0) {
      temporary.deleteSync();
      throw FileSystemException(
        'Không giữ được permission của file khi atomic write',
        path,
      );
    }
  }
  temporary.renameSync(file.path);
}

Future<String> _gitStatus(String root) async {
  final result = await Process.run('git', [
    '-C',
    root,
    'status',
    '--porcelain',
    '--untracked-files=normal',
  ]);
  if (result.exitCode != 0) {
    throw BaseCliException('Không đọc được Git status: ${result.stderr}');
  }
  return (result.stdout as String).trim();
}

String _scriptRoot() {
  final script = File.fromUri(Platform.script);
  return script.parent.parent.path;
}

String _canonicalExistingDirectory(String path) {
  final directory = Directory(path);
  if (!directory.existsSync()) {
    throw BaseCliException('Directory không tồn tại: $path');
  }
  return directory.resolveSymbolicLinksSync();
}

String _canonicalNewPath(String path) {
  final absolute = Directory(path).absolute.uri.normalizePath().toFilePath();
  final parent = Directory(absolute).parent;
  if (!parent.existsSync()) {
    return absolute;
  }
  return '${parent.resolveSymbolicLinksSync()}${Platform.pathSeparator}${_basename(absolute)}';
}

bool _isWithin(String parent, String child) =>
    child.startsWith('$parent${Platform.pathSeparator}');

String _relative(String root, String path) {
  if (path == root) {
    return '.';
  }
  final prefix = '$root${Platform.pathSeparator}';
  return path.startsWith(prefix) ? path.substring(prefix.length) : path;
}

String _basename(String path) {
  final normalized = path.endsWith(Platform.pathSeparator)
      ? path.substring(0, path.length - 1)
      : path;
  return normalized.substring(
    normalized.lastIndexOf(Platform.pathSeparator) + 1,
  );
}

const _usage = '''
Dart Base CLI — source of truth cho create/rename workflow

Usage:
  dart run tool/base_cli.dart doctor [--root PATH]
  dart run tool/base_cli.dart rename \\
    --display-name "My App" --package-name my_app \\
    --bundle-id com.company.my_app [--apply] [--root PATH]
  dart run tool/base_cli.dart create \\
    --destination ../my_app --display-name "My App" \\
    --package-name my_app --bundle-id com.company.my_app \\
    [--apply] [--skip-bootstrap] [--root PATH]

Safety:
  - create và rename luôn dry-run nếu không có --apply.
  - validation hoàn tất trước mutation đầu tiên.
  - create --apply chỉ chạy khi source Git tree sạch.
  - Firebase/signing/secret không được tự động tạo hoặc tin cậy.
''';
