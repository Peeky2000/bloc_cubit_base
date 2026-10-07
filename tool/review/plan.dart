import 'dart:convert';
import 'dart:io';

import 'review_plan.dart';

/// Prints which changed files must be reviewed and which rules apply to each,
/// so a review agent cannot skip files or apply the wrong checklist.
///
/// Usage:
///   dart run tool/review/plan.dart                 # workspace changes
///   dart run tool/review/plan.dart --from main     # main...HEAD
///   dart run tool/review/plan.dart --from a --to b
Future<void> main(List<String> args) async {
  String? from;
  var to = 'HEAD';
  for (final arg in args) {
    if (arg.startsWith('--from=')) {
      from = arg.substring(7);
    } else if (arg.startsWith('--to=')) {
      to = arg.substring(5);
    } else {
      stderr.writeln(
        'Usage: dart run tool/review/plan.dart [--from=<ref>] [--to=<ref>]',
      );
      exitCode = 2;
      return;
    }
  }
  final config = ReviewConfig.fromJson(
    jsonDecode(File('tool/review/rules.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final changes = from == null ? await _workspace() : await _range(from, to);
  final plan = buildPlan(changes, config);
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'mode': from == null ? 'workspace' : 'range',
      'from': ?from,
      if (from != null) 'to': to,
      ...plan.toJson(),
    }),
  );
}

Future<List<FileChange>> _range(String from, String to) async {
  final result = await Process.run('git', [
    'diff',
    '--name-status',
    '--find-renames',
    '$from...$to',
  ]);
  if (result.exitCode != 0) {
    throw StateError('git diff failed: ${result.stderr}');
  }
  return parseNameStatus(result.stdout as String);
}

Future<List<FileChange>> _workspace() async {
  final result = await Process.run('git', [
    'status',
    '--porcelain=v1',
    '--untracked-files=all',
  ]);
  if (result.exitCode != 0) {
    throw StateError('git status failed: ${result.stderr}');
  }
  return parsePorcelain(result.stdout as String);
}
