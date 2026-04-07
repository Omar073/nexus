import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Persists reminder ids when Complete runs in the notification headless isolate.
///
/// The main isolate can miss Hive updates (Hive is not isolate-safe) and
/// [markNotified] can race and overwrite [completedAt]. On resume / startup we
/// [readAndClear] and re-apply completion on the main isolate when needed.
class NotificationCompletePending {
  NotificationCompletePending._();

  static const _fileName = 'nexus_pending_complete_reminder_ids.txt';

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Emits whenever the pending file is created/modified/deleted.
  ///
  /// This is used as an event-driven signal in the main isolate to drain pending
  /// completes without polling.
  static Stream<FileSystemEvent> watch() async* {
    if (kIsWeb) return;
    final f = await _file();
    final parent = f.parent;
    if (!await parent.exists()) return;
    yield* parent.watch(events: FileSystemEvent.all).where((e) {
      // Keep this check simple and robust across platforms.
      // Watchers are noisy (create/modify/modify). Consumers must be idempotent:
      // `readAndClear()` returns [] if the file is already gone.
      return e.path.endsWith(_fileName);
    });
  }

  static Future<void> append(String reminderId) async {
    if (kIsWeb) return;
    try {
      final f = await _file();
      // Best-effort. If the main isolate drains/deletes concurrently, this may
      // fail on some filesystems. Correctness still comes from `completedAt`
      // being persisted to Hive by the background handler.
      await f.writeAsString(
        '$reminderId\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // Best-effort; completion still saved to Hive in the bg handler.
    }
  }

  /// Returns distinct ids (order preserved) and deletes the file.
  static Future<List<String>> readAndClear() async {
    if (kIsWeb) return [];
    try {
      final f = await _file();
      if (!await f.exists()) return [];
      final raw = await f.readAsString();
      await f.delete();
      if (raw.trim().isEmpty) return [];
      final seen = <String>{};
      final out = <String>[];
      for (final line in raw.split('\n')) {
        final id = line.trim();
        if (id.isEmpty || seen.contains(id)) continue;
        seen.add(id);
        out.add(id);
      }
      return out;
    } catch (_) {
      return [];
    }
  }
}
