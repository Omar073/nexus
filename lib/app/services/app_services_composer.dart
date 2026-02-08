import 'package:flutter/material.dart';
import 'package:nexus/core/services/connectivity_monitor_service.dart';
import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/widgets/debug/global_debug_overlay.dart';
import 'package:provider/provider.dart';

/// Composes all widget wrappers that need to wrap the app
///
/// This function handles the sequential wrapping of widgets.
/// Add new wrappers here as needed.
Widget wrapWithOverlays(BuildContext context, Widget child) {
  // Wrap sequentially: innermost first
  child = GlobalDebugOverlay(child: child);
  // For future wrappers: child = NewWrapper(child: child);
  return child;
}

/// Initializes all background services that run independently of the widget tree
void initializeBackgroundServices(BuildContext context) {
  try {
    final connectivityService = context.read<ConnectivityService>();
    ConnectivityMonitorService().startMonitoring(connectivityService);
    // Add init for future services here
  } catch (e) {
    debugPrint('Error initializing background services: $e');
  }
}

void disposeBackgroundServices() {
  try {
    ConnectivityMonitorService().dispose();
    // Add dispose for future services here
  } catch (e) {
    debugPrint('Error disposing background services: $e');
  }
}
