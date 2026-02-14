import 'dart:async';

import 'package:flutter/foundation.dart';

import 'debug_log_archiver.dart';

enum DebugLogLevel { info, warning, error }

class DebugLogEntry {
  DebugLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    required this.source,
  });

  final DateTime timestamp;
  final DebugLogLevel level;
  final String message;
  final String source;

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  String toString() =>
      '[$formattedTime] [$source] ${level.name.toUpperCase()} $message';
}

/// Production-only debug logger with a hidden UI overlay.
///
/// - In debug mode: prints to console (like `debugPrint`)
/// - In release/profile: stores up to 500 entries in memory (Android + Windows)
///   and auto-archives to a file every 30 minutes.
class DebugLoggerService {
  static final DebugLoggerService instance = DebugLoggerService._internal();
  DebugLoggerService._internal();

  static const int _maxLogs = 500;
  static const Duration _archiveInterval = Duration(minutes: 30);

  final List<DebugLogEntry> _logs = <DebugLogEntry>[];
  final ValueNotifier<int> _changeTick = ValueNotifier<int>(0);

  Timer? _archiveTimer;
  DebugLogArchiver? _archiver;
  bool _initialized = false;
  DateTime? _nextArchiveAt;

  /// Rebuild signal for UIs that want to observe log changes.
  ValueListenable<int> get changes => _changeTick;

  /// Current logs (immutable copy).
  List<DebugLogEntry> get logs => List.unmodifiable(_logs);

  /// Next archive time, if archiving is enabled.
  DateTime? get nextArchiveAt => _nextArchiveAt;

  bool get _supportedPlatform {
    if (kIsWeb) return false;
    // Android + Windows only.
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kDebugMode) return;
    if (!_supportedPlatform) return;

    try {
      _archiver = createDebugLogArchiver();
      await _archiver!.initialize();
      _nextArchiveAt = DateTime.now().add(_archiveInterval);

      _archiveTimer?.cancel();
      _archiveTimer = Timer.periodic(_archiveInterval, (_) {
        unawaited(_archiveLogs());
      });
    } catch (_) {
      // swallow
    }
  }

  void info(String message) => _log(message, DebugLogLevel.info);
  void warning(String message) => _log(message, DebugLogLevel.warning);
  void error(String message) => _log(message, DebugLogLevel.error);

  /// Main debug method to replace `debugPrint`.
  void mPrint(String message) => info(message);

  void _log(String message, DebugLogLevel level) {
    if (kDebugMode) {
      debugPrint('[${level.name.toUpperCase()}] $message');
      return;
    }
    if (!_supportedPlatform) return;

    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      source: _extractSourceInfo(),
    );

    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
    _changeTick.value++;
  }

  String exportLogs() => _logs.map((e) => e.toString()).join('\n');

  String exportLastNLogs(int n) {
    if (_logs.isEmpty) return '';
    final count = n > _logs.length ? _logs.length : n;
    final start = _logs.length - count;
    return _logs.sublist(start).map((e) => e.toString()).join('\n');
  }

  void clearLogs() {
    _logs.clear();
    _changeTick.value++;
  }

  Future<void> _archiveLogs() async {
    final archiver = _archiver;
    if (archiver == null) return;
    if (_logs.isEmpty) {
      _nextArchiveAt = DateTime.now().add(_archiveInterval);
      _changeTick.value++;
      return;
    }

    try {
      final ts = DateTime.now();
      final header = '\n=== Archive Session: ${ts.toIso8601String()} ===\n';
      final body = exportLogs();
      await archiver.append('$header$body\n');
      _logs.clear();
      _nextArchiveAt = DateTime.now().add(_archiveInterval);
      _changeTick.value++;
    } catch (_) {
      // swallow
    }
  }

  void dispose() {
    _archiveTimer?.cancel();
  }

  /// Extract source file + method + line number from StackTrace.
  /// Best-effort (may return 'Unknown' in release).
  String _extractSourceInfo() {
    try {
      final lines = StackTrace.current.toString().split('\n');
      // Skip a couple frames (this method + _log + info/warn/error).
      for (var i = 2; i < lines.length && i < 8; i++) {
        final line = lines[i].trim();
        if (!line.contains('.dart')) continue;

        // Common formats include:
        // #2   MyClass.myMethod (package:app/file.dart:12:34)
        // or ... file.dart:12:34
        final fileMatch = RegExp(
          r'([A-Za-z0-9_]+\.dart):(\d+)',
        ).firstMatch(line);
        if (fileMatch == null) continue;
        final fileName = fileMatch.group(1) ?? '';
        final lineNumber = fileMatch.group(2) ?? '';

        final methodMatch = RegExp(
          r'#\d+\s+([A-Za-z0-9_.$<>]+)\s+\(',
        ).firstMatch(line);
        final methodName = methodMatch?.group(1)?.split('.').last ?? '';

        if (methodName.isNotEmpty) {
          return '$fileName.$methodName:$lineNumber';
        }
        return '$fileName:$lineNumber';
      }
    } catch (_) {
      // ignore
    }
    return 'Unknown';
  }
}

/// Global shorthand function for easier logging.
void mPrint(String message) => DebugLoggerService.instance.mPrint(message);
