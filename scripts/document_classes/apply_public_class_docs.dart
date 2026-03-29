// ignore_for_file: avoid_print

import 'dart:io';

import 'curated_public_class_docs.dart';
import 'curated_public_class_docs_supplement.dart';

final Map<String, String> _allCuratedDocs = {
  ...kCuratedPublicClassDocs,
  ...kCuratedPublicClassDocsSupplement,
};

/// Inserts or refreshes `///` lines using merged curated maps in this folder.
///
/// Curated values may use newlines for 2–3 line summaries; each non-empty line
/// becomes one `///` line in source.
///
/// Usage:
/// - `dart run scripts/apply_public_class_docs.dart` — insert only when no doc (needs map entry).
/// - `dart run scripts/apply_public_class_docs.dart --sync` — replace attached doc blocks from the map.
///   Skips when the map has a single line but the file already has a multi-line block (hand-written).
/// - `dart run scripts/apply_public_class_docs.dart --verify` — list public classes missing from curated maps; exit 1 if any.
void main(List<String> args) {
  final verify = args.contains('--verify');
  final sync = args.contains('--sync');
  final roots = args.where((a) => !a.startsWith('-')).toList();
  final scanRoots = roots.isEmpty ? ['lib', 'test'] : roots;

  if (verify) {
    _verifyMapCoversPublicClasses(scanRoots);
    return;
  }

  var changed = 0;
  for (final root in scanRoots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (path.contains('/.')) continue;

      final lines = entity.readAsLinesSync();
      final insertsAt = <int, List<String>>{};
      final rangeOps = <_RangeDocOp>[];

      for (var i = 0; i < lines.length; i++) {
        final trimmed = lines[i].trim();
        final match = RegExp(
          r'^class ([A-Za-z_][a-zA-Z0-9_]*)',
        ).firstMatch(trimmed);
        if (match == null) continue;
        final name = match.group(1)!;
        if (name.startsWith('_')) continue;

        final text = _allCuratedDocs[name];
        if (text == null) {
          if (!sync) {
            final insertAt = _findInsertIndex(lines, i);
            if (insertAt >= 0) {
              stderr.writeln(
                'No curated doc for public class $name ($path) — add to curated_public_class_docs*.dart',
              );
            }
          }
          continue;
        }

        final newDocLines = _docLinesFromCurated(text);
        if (newDocLines.isEmpty) continue;

        final docRange = _attachedDocBlockRange(lines, i);
        if (docRange == null) {
          final insertAt = _findInsertIndex(lines, i);
          if (insertAt < 0) continue;
          insertsAt[insertAt] = newDocLines;
          continue;
        }

        if (!sync) continue;

        final (:start, :end) = docRange;
        final existing = lines.sublist(start, end + 1);
        if (_docLinesEqual(existing, newDocLines)) continue;

        // Do not replace a multi-line file doc with a single-line map entry.
        if (newDocLines.length == 1 && start < end) continue;

        rangeOps.add(_RangeDocOp(start, end, newDocLines));
      }

      var out = List<String>.from(lines);
      var fileChanged = false;

      rangeOps.sort((a, b) => b.start.compareTo(a.start));
      for (final op in rangeOps) {
        final existing = out.sublist(op.start, op.end + 1);
        if (_docLinesEqual(existing, op.lines)) continue;
        out.removeRange(op.start, op.end + 1);
        out.insertAll(op.start, op.lines);
        fileChanged = true;
      }

      final insKeys = insertsAt.keys.toList()..sort((a, b) => b.compareTo(a));
      for (final at in insKeys) {
        out.insertAll(at, insertsAt[at]!);
        fileChanged = true;
      }

      if (fileChanged) {
        final text = out.join('\n');
        entity.writeAsStringSync(text.endsWith('\n') ? text : '$text\n');
        changed++;
        print('Updated $path');
      }
    }
  }
  if (sync || changed > 0) {
    print('Files modified: $changed');
  }
}

class _RangeDocOp {
  _RangeDocOp(this.start, this.end, this.lines);
  final int start;
  final int end;
  final List<String> lines;
}

void _verifyMapCoversPublicClasses(List<String> roots) {
  final seen = <String>{};
  final missing = <String>[];

  for (final root in roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final trimmed = lines[i].trim();
        final match = RegExp(
          r'^class ([A-Za-z_][a-zA-Z0-9_]*)',
        ).firstMatch(trimmed);
        if (match == null) continue;
        final name = match.group(1)!;
        if (name.startsWith('_')) continue;
        if (!seen.add(name)) continue;
        if (!_allCuratedDocs.containsKey(name)) {
          missing.add('$path: $name');
        }
      }
    }
  }

  missing.sort();
  for (final m in missing) {
    print('Missing map entry: $m');
  }
  if (missing.isNotEmpty) {
    print('Total missing: ${missing.length}');
    exitCode = 1;
  } else {
    print('All public classes are listed in curated_public_class_docs*.dart');
  }
}

/// Turns curated text (optional newlines) into `///` lines.
List<String> _docLinesFromCurated(String text) {
  return text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .map((l) => '/// $l')
      .toList();
}

({int start, int end})? _attachedDocBlockRange(
  List<String> lines,
  int classLineIndex,
) {
  final bottom = _attachedDocBottomLine(lines, classLineIndex);
  if (bottom == null) return null;
  var start = bottom;
  while (start > 0 && lines[start - 1].trimLeft().startsWith('///')) {
    start--;
  }
  return (start: start, end: bottom);
}

bool _docLinesEqual(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].trim() != b[i].trim()) return false;
  }
  return true;
}

int? _attachedDocBottomLine(List<String> lines, int classLineIndex) {
  var j = classLineIndex - 1;
  while (j >= 0 && lines[j].trim().isEmpty) {
    j--;
  }
  while (j >= 0 && lines[j].trim().startsWith('@')) {
    j--;
  }
  while (j >= 0 && lines[j].trim().isEmpty) {
    j--;
  }
  if (j < 0) return null;
  if (!lines[j].trimLeft().startsWith('///')) return null;
  return j;
}

int _findInsertIndex(List<String> lines, int classLineIndex) {
  var start = classLineIndex;
  while (start > 0 && lines[start - 1].trim().isEmpty) {
    start--;
  }
  while (start > 0 && lines[start - 1].trim().startsWith('@')) {
    start--;
  }
  while (start > 0 && lines[start - 1].trim().isEmpty) {
    start--;
  }
  if (start > 0 && lines[start - 1].trimLeft().startsWith('///')) {
    return -1;
  }
  return start;
}
