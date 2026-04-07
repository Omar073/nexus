import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nexus/core/services/connectivity_monitor_service.dart';
import 'package:nexus/core/services/notifications/notification_complete_pending.dart';
import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:nexus/core/widgets/debug/global_debug_overlay.dart';
import 'package:nexus/features/reminders/domain/repositories/reminder_repository_interface.dart';
import 'package:nexus/features/reminders/presentation/state_management/reminder_controller.dart';
import 'package:provider/provider.dart';

StreamSubscription<FileSystemEvent>? _pendingCompleteWatchSub;

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
    // File-drain fallback for any completes that happened while no UI isolate
    // was running (terminated/background).
    unawaited(drainPendingReminderCompletesFromNotification(context));

    _pendingCompleteWatchSub ??= NotificationCompletePending.watch().listen((_) {
      // Event-driven (no polling): when the headless isolate appends an id,
      // a filesystem event triggers an immediate drain.
      unawaited(drainPendingReminderCompletesFromNotification(context));
    });
  } catch (e) {
    mDebugPrint('Error initializing background services: $e');
  }
}

/// Re-applies Complete on the main isolate when the headless handler wrote
/// [NotificationCompletePending] (heals Hive races with [markNotified]).
Future<void> drainPendingReminderCompletesFromNotification(
  BuildContext context,
) async {
  if (!context.mounted) return;
  // Idempotency guard: even if the watcher emits multiple events, or if the
  // same id appears twice, we only apply completion when the current entity
  // is still incomplete.
  late final ReminderRepositoryInterface repo;
  late final ReminderController controller;
  try {
    repo = context.read<ReminderRepositoryInterface>();
    controller = context.read<ReminderController>();
  } catch (_) {
    return;
  }
  final ids = await NotificationCompletePending.readAndClear();
  for (final id in ids) {
    if (!context.mounted) return;
    final entity = repo.getById(id);
    if (entity != null && entity.completedAt == null) {
      await controller.complete(entity);
    }
  }
}

void disposeBackgroundServices() {
  try {
    ConnectivityMonitorService().dispose();
    _pendingCompleteWatchSub?.cancel();
    _pendingCompleteWatchSub = null;
    // Add dispose for future services here
  } catch (e) {
    mDebugPrint('Error disposing background services: $e');
  }
}
