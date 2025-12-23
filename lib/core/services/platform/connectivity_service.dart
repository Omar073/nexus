import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<List<ConnectivityResult>> get onChanged =>
      _connectivity.onConnectivityChanged;

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  Stream<bool> onlineStream() async* {
    yield await isOnline;
    await for (final result in onChanged) {
      yield !result.contains(ConnectivityResult.none) && result.isNotEmpty;
    }
  }
}

