import 'dart:io';

import 'scaffold.dart';

const _usage = '''
Usage: dart run tool/scaffold/feature.dart <feature> [options]

Creates a feature that follows the repository conventions.

  <feature>          snake_case name, such as order_list
  --bloc             use BLoC instead of the default Cubit
  --data[=<domain>]  also create entity, model, remote data source,
                     repository and use case (domain defaults to feature)
  --apply            write files; without it, only print the plan
  --help             show this message
''';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('--help')) {
    stdout.write(_usage);
    return;
  }
  String? feature;
  var bloc = false;
  var data = false;
  String? domain;
  var apply = false;
  for (final arg in args) {
    if (arg == '--bloc') {
      bloc = true;
    } else if (arg == '--apply') {
      apply = true;
    } else if (arg == '--data') {
      data = true;
    } else if (arg.startsWith('--data=')) {
      data = true;
      domain = arg.substring('--data='.length);
    } else if (!arg.startsWith('-') && feature == null) {
      feature = arg;
    } else {
      stderr.write(_usage);
      exitCode = 2;
      return;
    }
  }
  try {
    final options = ScaffoldOptions(
      feature: feature!,
      stateOwner: bloc ? 'bloc' : 'cubit',
      withData: data,
      domain: domain,
    );
    final files = scaffoldFeature(options);
    final existing = files.keys.where((p) => File(p).existsSync()).toList();
    if (existing.isNotEmpty) {
      stderr.writeln('Refusing to overwrite:\n  ${existing.join('\n  ')}');
      exitCode = 2;
      return;
    }
    stdout.writeln(apply ? 'Creating:' : 'Plan (add --apply to write):');
    for (final path in files.keys) {
      stdout.writeln('  $path');
      if (apply) {
        File(path)
          ..parent.createSync(recursive: true)
          ..writeAsStringSync(files[path]!);
      }
    }
    stdout.writeln('\nNext steps:');
    for (final step in nextSteps(options)) {
      stdout.writeln('  - $step');
    }
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 2;
  }
}
