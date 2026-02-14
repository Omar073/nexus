import 'debug_log_archiver_stub.dart'
    if (dart.library.io) 'debug_log_archiver_io.dart';

/// Minimal abstraction around writing debug logs to disk.
///
/// Implemented via conditional import so web builds won't pull in `dart:io`.
abstract class DebugLogArchiver {
  /// Creates/clears the archive file and writes an initial header.
  Future<void> initialize();

  /// Appends [text] to the archive file.
  Future<void> append(String text);
}

/// Factory for the best archiver implementation on the current platform.
DebugLogArchiver createDebugLogArchiver() => createArchiver();
