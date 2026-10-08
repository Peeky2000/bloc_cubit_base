/// Machine-checked conventions for this repository.
///
/// Pure Dart so the rules can be unit tested on fixtures. Each rule returns
/// human-readable violations; `test/convention/convention_test.dart` runs them
/// over `lib/` and fails `derry quality` and CI when one appears.
library;

/// One source file: repository-relative path with `/` separators, and text.
class SourceFile {
  const SourceFile(this.path, this.text);
  final String path;
  final String text;

  String get name => path.split('/').last;
  String get stem => name.endsWith('.dart')
      ? name.substring(0, name.length - '.dart'.length)
      : name;
  List<String> get segments => path.split('/');
}

class Violation {
  const Violation(this.rule, this.path, this.message);
  final String rule;
  final String path;
  final String message;

  @override
  String toString() => '[$rule] $path: $message';
}

/// Existing code that predates a rule. Entries are `rule|path`. Shrink this
/// list; never add to it to make new code pass.
typedef Baseline = Set<String>;

final _snake = RegExp(r'^[a-z][a-z0-9_]*$');

String _pascal(String snake) => snake
    .split('_')
    .where((p) => p.isNotEmpty)
    .map((p) => p[0].toUpperCase() + p.substring(1))
    .join();

bool _declares(String text, String className) =>
    RegExp('\\bclass\\s+$className\\b').hasMatch(text);

Iterable<String> _classes(String text) => RegExp(
  r'^(?:abstract\s+|abstract\s+interface\s+|sealed\s+|final\s+|base\s+|interface\s+)*class\s+(\w+)',
  multiLine: true,
).allMatches(text).map((m) => m.group(1)!);

/// Every rule, in report order.
List<Violation> checkAll(
  List<SourceFile> files, {
  Baseline baseline = const {},
}) {
  final found = <Violation>[
    for (final f in files) ...checkFile(f),
    ...checkFeatureTests(files),
  ];
  return [
    for (final v in found)
      if (!baseline.contains('${v.rule}|${v.path}')) v,
  ];
}

/// Rules that look at one file.
List<Violation> checkFile(SourceFile f) {
  final out = <Violation>[];
  void add(String rule, String message) =>
      out.add(Violation(rule, f.path, message));
  final s = f.segments;
  final text = f.text;

  if (!f.path.startsWith('lib/') || !f.name.endsWith('.dart')) return out;

  // File names are snake_case everywhere.
  if (!_snake.hasMatch(f.stem.replaceAll('.g', ''))) {
    add('file-name', 'file names must be snake_case');
  }

  // Domain repositories: lib/domain/repositories/<name>_repo.dart
  if (f.path.startsWith('lib/domain/repositories/')) {
    if (!f.stem.endsWith('_repo')) {
      add('repo-name', 'domain repository files end with _repo.dart');
    } else {
      final cls = _pascal(f.stem);
      if (!RegExp(
        'abstract\\s+(interface\\s+)?class\\s+$cls\\b',
      ).hasMatch(text)) {
        add('repo-name', 'declare abstract class $cls');
      }
    }
  }

  // Repository implementations: lib/data/repositories/<name>_repo_impl.dart
  if (f.path.startsWith('lib/data/repositories/') &&
      f.stem.endsWith('_repo_impl')) {
    final iface = _pascal(f.stem.replaceAll('_repo_impl', '_repo'));
    final cls = '${iface}Impl';
    if (!_declares(text, cls)) add('repo-impl', 'declare class $cls');
    if (!text.contains('@LazySingleton(as: $iface)')) {
      add('repo-impl', 'bind with @LazySingleton(as: $iface)');
    }
  }

  // Use cases: lib/domain/use_case/<name>_use_case.dart, no DI annotations.
  if (f.path.startsWith('lib/domain/use_case/')) {
    if (!f.stem.endsWith('_use_case')) {
      add('use-case-name', 'use case files end with _use_case.dart');
    } else if (!_declares(text, _pascal(f.stem))) {
      add('use-case-name', 'declare class ${_pascal(f.stem)}');
    }
    if (RegExp(
      r'@(injectable|lazySingleton|singleton|LazySingleton|Injectable)\b',
    ).hasMatch(text)) {
      add('use-case-di', 'register use cases in lib/di/register_module.dart');
    }
  }

  // Remote data sources: contract + Impl bound by interface.
  if (f.path.startsWith('lib/data/datasource/remote/') &&
      f.stem.endsWith('_remote_data_source')) {
    final iface = _pascal(f.stem);
    if (!RegExp(
      'abstract\\s+(interface\\s+)?class\\s+$iface\\b',
    ).hasMatch(text)) {
      add('data-source', 'declare abstract class $iface');
    }
    if (!text.contains('@LazySingleton(as: $iface)')) {
      add(
        'data-source',
        'bind the implementation with @LazySingleton(as: $iface)',
      );
    }
  }

  // Data models: json_serializable with matching part file.
  if (f.path.startsWith('lib/data/model/') && !f.name.endsWith('.g.dart')) {
    if (!text.contains('@JsonSerializable')) {
      add('model', 'annotate data models with @JsonSerializable');
    }
    if (!text.contains("part '${f.stem}.g.dart';")) {
      add('model', "add part '${f.stem}.g.dart';");
    }
  }

  // Presentation feature layout.
  if (s.length >= 4 && s[0] == 'lib' && s[1] == 'presentation') {
    final feature = s[2];
    if (!_snake.hasMatch(feature)) {
      add('feature-name', 'feature folders are snake_case');
    }
    final folder = s.length >= 5 ? s[3] : null;
    if (folder != null &&
        !{'cubit', 'bloc', 'view', 'widget'}.contains(folder)) {
      add(
        'feature-layout',
        'feature files live in cubit/, bloc/, view/ or widget/',
      );
    }
    if (folder == null) {
      add(
        'feature-layout',
        'feature files live in cubit/, bloc/, view/ or widget/',
      );
    }

    if (folder == 'cubit' || folder == 'bloc') {
      final kind = folder;
      final owner = '${feature}_$kind';
      final allowed = {
        owner,
        '${feature}_state',
        '${feature}_effect',
        if (kind == 'bloc') '${feature}_event',
      };
      if (!allowed.contains(f.stem)) {
        add(
          'state-files',
          '$kind/ holds only ${allowed.map((e) => '$e.dart').join(', ')}',
        );
      }
      if (f.stem == owner) {
        final cls = _pascal(owner);
        final state = '${_pascal(feature)}State';
        final base = kind == 'cubit' ? 'BaseCubit<$state>' : 'BaseBloc<';
        if (!_declares(text, cls)) add('state-owner', 'declare class $cls');
        if (!text.contains('extends $base')) {
          add(
            'state-owner',
            '$cls extends ${kind == 'cubit' ? base : 'BaseBloc<${_pascal(feature)}Event, $state>'}',
          );
        }
        if (!RegExp(r'@injectable\b').hasMatch(text)) {
          add('state-owner', 'annotate $cls with @injectable');
        }
        if (!text.contains("part '${feature}_state.dart';")) {
          add('state-owner', "keep state in part '${feature}_state.dart'");
        }
        if (RegExp(
          r'Injector\.getIt|GetIt\.instance|\bgetIt\b',
        ).hasMatch(text)) {
          add('state-owner', 'inject dependencies through the constructor');
        }
      }
      if (f.stem == '${feature}_state') {
        final state = '${_pascal(feature)}State';
        if (!text.startsWith("part of '$owner.dart';")) {
          add('state-shape', "start with part of '$owner.dart';");
        }
        if (!text.contains('class $state extends BaseAppState<')) {
          add('state-shape', '$state extends BaseAppState<...>');
        }
        for (final member in [
          'copyWith(',
          'factory $state.initial(',
          'get props',
        ]) {
          if (!text.contains(member)) {
            add('state-shape', '$state needs ${member.replaceAll('(', '')}');
          }
        }
      }
      if (f.stem == '${feature}_effect') {
        final effect = '${_pascal(feature)}Effect';
        if (!text.contains('sealed class $effect')) {
          add('effect-shape', 'declare sealed class $effect');
        }
        for (final cls in _classes(text)) {
          if (cls != effect && !cls.startsWith(_pascal(feature))) {
            add(
              'effect-shape',
              '$cls should be named ${_pascal(feature)}...Effect',
            );
          }
        }
      }
    }

    if (folder == 'view' && f.stem == '${feature}_screen') {
      final screen = '${_pascal(feature)}Screen';
      final builder = '${_camel(feature)}ScreenBuilder';
      if (!_declares(text, screen)) add('screen', 'declare class $screen');
      if (!RegExp('Widget\\s+$builder\\(').hasMatch(text)) {
        add('screen', 'expose Widget $builder() for the route table');
      }
    }
  }

  // No print in app code.
  for (final line in text.split('\n')) {
    final code = line.trimLeft();
    if (code.startsWith('//')) continue;
    if (RegExp(r'(?<![\w.])print\(').hasMatch(code)) {
      add('no-print', 'use log() or the redacted logger instead of print()');
      break;
    }
  }

  return out;
}

String _camel(String snake) {
  final p = _pascal(snake);
  return p.isEmpty ? p : p[0].toLowerCase() + p.substring(1);
}

/// Every Cubit/BLoC has a test at `test/presentation/<feature>_<kind>_test.dart`.
List<Violation> checkFeatureTests(List<SourceFile> files) {
  final paths = files.map((f) => f.path).toSet();
  final out = <Violation>[];
  for (final f in files) {
    final s = f.segments;
    if (s.length == 5 &&
        s[1] == 'presentation' &&
        (s[3] == 'cubit' || s[3] == 'bloc') &&
        f.stem == '${s[2]}_${s[3]}') {
      final test = 'test/presentation/${s[2]}_${s[3]}_test.dart';
      if (!paths.contains(test)) {
        out.add(Violation('state-test', f.path, 'add $test'));
      }
    }
  }
  return out;
}
