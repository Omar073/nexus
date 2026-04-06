import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexus/app/app_globals.dart';
import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:nexus/core/services/platform/connectivity_service.dart';

/// Service that monitors network connectivity and shows snackbar notifications
/// when connection is lost or regained
///
/// This is a singleton service that runs independently of the widget tree.
/// It uses the global ScaffoldMessenger key to show snackbars from anywhere.
class ConnectivityMonitorService {
  factory ConnectivityMonitorService() => _instance;
  static final ConnectivityMonitorService _instance =
      ConnectivityMonitorService._internal();
  // named constructor that returns the singleton instance
  ConnectivityMonitorService._internal();

  StreamSubscription<bool>? _subscription;
  bool? _previousState;
  bool _isInitialized = false;

  void startMonitoring(ConnectivityService connectivityService) {
    _subscription?.cancel();
    _isInitialized = false;
    _previousState = null;

    _subscription = connectivityService.onlineStream().listen(
      (isOnline) {
        // Skip the first value (initial state) to avoid showing snackbar on app start
        if (!_isInitialized) {
          _isInitialized = true;
          _previousState = isOnline;
          return;
        }

        if (_previousState != null && _previousState != isOnline) {
          _showConnectivitySnackbar(isOnline);
        }

        _previousState = isOnline;
      },
      onError: (error) {
        mDebugPrint('Connectivity monitor error: $error');
      },
    );
  }

  void _showConnectivitySnackbar(bool isOnline) {
    final messenger = appMessengerKey.currentState;
    if (messenger == null) return;

    final message = isOnline
        ? 'Network connection restored'
        : 'Network connection lost';

    final color = isOnline ? Colors.green : Colors.red;

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
    _previousState = null;
  }
}
