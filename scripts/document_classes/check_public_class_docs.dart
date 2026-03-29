// ignore_for_file: avoid_print

import 'dart:io';

/// One-off audit: public top-level classes without a `///` doc after imports
/// (and before the class, skipping only blank lines and `@` annotations).
void main(List<String> args) {
  final roots = args.isEmpty ? ['lib', 'test'] : args;
  final issues = <String>[];

  for (final root in roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      final bodyStart = _endOfLeadingDirectives(lines);
      for (var i = 0; i < lines.length; i++) {
        final trimmed = lines[i].trim();
        final match = RegExp(
          r'^class ([A-Za-z_][a-zA-Z0-9_]*)',
        ).firstMatch(trimmed);
        if (match == null) continue;
        final name = match.group(1)!;
        if (name.startsWith('_')) continue;

        var j = i - 1;
        while (j >= 0 && lines[j].trim().isEmpty) {
          j--;
        }
        while (j >= 0 && lines[j].trim().startsWith('@')) {
          j--;
        }
        while (j >= 0 && lines[j].trim().isEmpty) {
          j--;
        }
        final hasDoc =
            j >= bodyStart && j >= 0 && lines[j].trimLeft().startsWith('///');
        if (!hasDoc) {
          issues.add('${entity.path}:${i + 1}: class $name');
        }
      }
    }
  }

  issues.sort();
  for (final line in issues) {
    print(line);
  }
  print('Total: ${issues.length}');
}

/// First line index after leading `import` / `export` / `part` / `library` lines.
int _endOfLeadingDirectives(List<String> lines) {
  var i = 0;
  while (i < lines.length) {
    final t = lines[i].trim();
    if (t.isEmpty) {
      i++;
      continue;
    }
    if (t.startsWith('import ') ||
        t.startsWith('export ') ||
        t.startsWith('library ') ||
        t.startsWith('part of ')) {
      i++;
      continue;
    }
    if (t.startsWith('part ')) {
      i++;
      continue;
    }
    break;
  }
  return i;
}
