import 'package:flutter/material.dart';
import 'package:nexus/core/services/platform/backend_health_checker.dart';

/// Utility functions for connectivity status UI display.
class ConnectivityStatusUtils {
  /// Returns the text representation of a connectivity status
  static String getStatusText(ConnectivityStatus? status) {
    if (status == null) return 'Checking...';
    switch (status) {
      case ConnectivityStatus.connected:
        return 'Connected';
      case ConnectivityStatus.disconnected:
        return 'Disconnected';
      case ConnectivityStatus.unknown:
        return 'Unknown';
    }
  }

  /// Returns the icon for a connectivity status
  static IconData getStatusIcon(ConnectivityStatus? status) {
    if (status == null) return Icons.hourglass_empty;
    switch (status) {
      case ConnectivityStatus.connected:
        return Icons.check_circle;
      case ConnectivityStatus.disconnected:
        return Icons.error;
      case ConnectivityStatus.unknown:
        return Icons.help_outline;
    }
  }

  /// Returns the color for a connectivity status
  static Color? getStatusColor(
    ConnectivityStatus? status,
    BuildContext context,
  ) {
    if (status == null) return null;
    switch (status) {
      case ConnectivityStatus.connected:
        return Colors.green;
      case ConnectivityStatus.disconnected:
        return Theme.of(context).colorScheme.error;
      case ConnectivityStatus.unknown:
        return Colors.orange;
    }
  }
}
