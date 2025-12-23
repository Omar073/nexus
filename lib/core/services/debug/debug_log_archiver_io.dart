import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'debug_log_archiver.dart';

class _IoDebugLogArchiver implements DebugLogArchiver {
  File? _file;

  @override
  Future<void> initialize() async {
    try {
      if (kIsWeb) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}debug_logs_archive.txt');
      if (await file.exists()) {
        await file.delete();
      }
      final header = '=== Debug Logs Archive ===\n'
          'App Start: ${DateTime.now().toIso8601String()}\n'
          '${'-' * 50}\n\n';
      await file.writeAsString(header, flush: true);
      _file = file;
    } catch (_) {
      // Intentionally swallow: logging must never crash the app.
    }
  }

  @override
  Future<void> append(String text) async {
    final file = _file;
    if (file == null) return;
    try {
      await file.writeAsString(text, mode: FileMode.append, flush: true);
    } catch (_) {
      // swallow
    }
  }
}

DebugLogArchiver createArchiver() => _IoDebugLogArchiver();


