import 'debug_log_archiver.dart';

class _StubDebugLogArchiver implements DebugLogArchiver {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> append(String text) async {}
}

DebugLogArchiver createArchiver() => _StubDebugLogArchiver();


