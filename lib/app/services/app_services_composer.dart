import 'package:flutter/material.dart';
import 'package:nexus/core/services/connectivity_monitor_service.dart';
import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/widgets/debug/global_debug_overlay.dart';
import 'package:provider/provider.dart';

/// Composes all widget wrappers that need to wrap the app
///
/// This function handles the sequential wrapping of widgets.
/// Add new wrappers here as needed.
Widget wrapWithAppServices(BuildContext context, Widget child) {
  // Wrap sequentially: innermost first
  child = GlobalDebugOverlay(child: child);
  // For future wrappers: child = NewWrapper(child: child);
  return child;
}

/// Initializes all background services that run independently of the widget tree
///
/// These services monitor state, handle events, and can show UI updates
/// (like snackbars) using the global ScaffoldMessenger key.
///
/// Add initialization for new background services here.
void initializeBackgroundServices(BuildContext context) {
  try {
    final connectivityService = context.read<ConnectivityService>();
    ConnectivityMonitorService().startMonitoring(connectivityService);
    // Add init for future services here
  } catch (e) {
    // Log error but don't crash the app
    debugPrint('Error initializing background services: $e');
  }
}

/// Disposes all background services
///
/// Called when the app is shutting down to clean up resources.
/// Add disposal for new background services here.
void disposeBackgroundServices() {
  try {
    ConnectivityMonitorService().dispose();
    // Add dispose for future services here
  } catch (e) {
    // Log error but don't crash during disposal
    debugPrint('Error disposing background services: $e');
  }
}
