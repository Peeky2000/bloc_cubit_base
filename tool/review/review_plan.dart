/// Deterministic file selection and rule matching for code review.
///
/// Pure Dart so it can be unit tested without git.
library;

class FileChange {
  const FileChange(this.path, this.status);
  final String path;

  /// One of added, modified, deleted, renamed, untracked.
  final String status;
}

class ExcludeRule {
  const ExcludeRule(this.glob, this.reason);
  final String glob;
  final String reason;
}

class ReviewRule {
  const ReviewRule(this.id, this.glob, this.skills, this.checks);
  final String id;
  final String glob;
  final List<String> skills;
  final List<String> checks;
}

class ReviewConfig {
  const ReviewConfig(this.exclude, this.rules);

  factory ReviewConfig.fromJson(Map<String, dynamic> json) => ReviewConfig(
    [
      for (final e in json['exclude'] as List)
        ExcludeRule((e as Map)['glob'] as String, e['reason'] as String),
    ],
    [
      for (final r in json['rules'] as List)
        ReviewRule(
          (r as Map)['id'] as String,
          r['glob'] as String,
          (r['skills'] as List).cast<String>(),
          (r['checks'] as List).cast<String>(),
        ),
    ],
  );

  final List<ExcludeRule> exclude;

  /// Ordered from most to least specific; the first match wins.
  final List<ReviewRule> rules;
}

class ReviewPlan {
  const ReviewPlan(this.files, this.excluded, this.groups);

  /// Files to review with the rule id applied to each.
  final List<Map<String, String>> files;
  final List<Map<String, String>> excluded;

  /// Rule id -> rule and its files, so shared rules are read once.
  final Map<String, Map<String, Object>> groups;

  Map<String, Object> toJson() => {
    'total_files': files.length + excluded.length,
    'reviewable_count': files.length,
    'reviewable_files': files,
    'excluded_files': excluded,
    'rule_groups': groups,
    'instructions':
        'Review every reviewable file with its rule group. Mark each file '
        'reviewed or skipped with a reason. Report coverage as reviewed / '
        'reviewable. Deleted files are reviewed for dangling references.',
  };
}

ReviewPlan buildPlan(List<FileChange> changes, ReviewConfig config) {
  final files = <Map<String, String>>[];
  final excluded = <Map<String, String>>[];
  final groups = <String, Map<String, Object>>{};
  final seen = <String>{};
  for (final change in changes) {
    if (!seen.add('${change.path}|${change.status}')) continue;
    final skip = config.exclude
        .where((e) => matchesGlob(e.glob, change.path))
        .firstOrNull;
    if (skip != null) {
      excluded.add({'path': change.path, 'reason': skip.reason});
      continue;
    }
    final rule = config.rules
        .where((r) => matchesGlob(r.glob, change.path))
        .firstOrNull;
    final id = rule?.id ?? 'default';
    files.add({'path': change.path, 'status': change.status, 'rule': id});
    final group = groups[id] ??= {
      'skills': rule?.skills ?? const ['flutter-code-review'],
      'checks':
          rule?.checks ??
          const [
            'Correctness, security, performance, maintainability and tests.',
          ],
      'files': <String>[],
    };
    (group['files']! as List<String>).add(change.path);
  }
  return ReviewPlan(files, excluded, groups);
}

/// Parses `git diff --name-status` output.
List<FileChange> parseNameStatus(String output) => [
  for (final line in output.split('\n'))
    if (line.trim().isNotEmpty) _fromNameStatus(line),
];

FileChange _fromNameStatus(String line) {
  final parts = line.split('\t');
  final code = parts.first;
  final path = parts.last;
  return FileChange(path, switch (code[0]) {
    'A' => 'added',
    'D' => 'deleted',
    'R' => 'renamed',
    _ => 'modified',
  });
}

/// Parses `git status --porcelain=v1` output, including untracked files.
List<FileChange> parsePorcelain(String output) => [
  for (final line in output.split('\n'))
    if (line.length > 3) _fromPorcelain(line),
];

FileChange _fromPorcelain(String line) {
  final code = line.substring(0, 2);
  var path = line.substring(3);
  if (path.contains(' -> ')) path = path.split(' -> ').last;
  if (path.startsWith('"') && path.endsWith('"')) {
    path = path.substring(1, path.length - 1);
  }
  final status = code == '??'
      ? 'untracked'
      : code.contains('D')
      ? 'deleted'
      : code.contains('R')
      ? 'renamed'
      : code.contains('A')
      ? 'added'
      : 'modified';
  return FileChange(path, status);
}

/// Glob matching with `**` (any depth), `*` (one segment), `?` and `{a,b}`.
bool matchesGlob(String glob, String path) =>
    _globToRegExp(glob).hasMatch(path);

final _cache = <String, RegExp>{};

RegExp _globToRegExp(String glob) => _cache[glob] ??= () {
  final out = StringBuffer('^');
  var i = 0;
  var braces = 0;
  while (i < glob.length) {
    final c = glob[i];
    if (c == '*') {
      final doubleStar = i + 1 < glob.length && glob[i + 1] == '*';
      if (doubleStar) {
        final slashAfter = i + 2 < glob.length && glob[i + 2] == '/';
        out.write(slashAfter ? '(?:.*/)?' : '.*');
        i += slashAfter ? 3 : 2;
        continue;
      }
      out.write('[^/]*');
    } else if (c == '?') {
      out.write('[^/]');
    } else if (c == '{') {
      braces++;
      out.write('(?:');
    } else if (c == '}' && braces > 0) {
      braces--;
      out.write(')');
    } else if (c == ',' && braces > 0) {
      out.write('|');
    } else {
      out.write(RegExp.escape(c));
    }
    i++;
  }
  out.write(r'$');
  return RegExp(out.toString());
}();
