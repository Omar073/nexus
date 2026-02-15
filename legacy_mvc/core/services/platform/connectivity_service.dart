import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps `connectivity_plus` to provide simplified connectivity APIs.
///
/// ## Why the optional constructor parameter?
/// The [connectivity] parameter enables **dependency injection** for testing.
class ConnectivityService {
  /// Optional [connectivity] for dependency injection (testing).
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Stream of connectivity changes from the OS.
  /// The stream emits events whenever the OS detects WiFi/cellular changes.
  /// We don't "call" this — we **subscribe** to it, and the OS pushes events.
  Stream<List<ConnectivityResult>> get onChanged =>
      _connectivity.onConnectivityChanged;

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  /// `async*` returns a Stream, `yield` emits values without ending.
  Stream<bool> onlineStream() async* {
    yield await isOnline;

    await for (final result in onChanged) {
      yield !result.contains(ConnectivityResult.none) && result.isNotEmpty;
    }
  }
}
