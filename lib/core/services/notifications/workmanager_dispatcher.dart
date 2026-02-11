import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/services/notifications/notification_service.dart';
import 'package:nexus/features/reminders/models/reminder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

/// NOTE: Workmanager callbacks must be top-level or static functions.
@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // 1. Initialize dependencies
      WidgetsFlutterBinding.ensureInitialized();

      // 2. Initialize Notification Service
      final notifications = NotificationService();
      await notifications.initialize();

      // 3. Initialize Hive
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        Hive.init(appDir.path);
      }

      if (!Hive.isAdapterRegistered(HiveTypeIds.reminder)) {
        Hive.registerAdapter(ReminderAdapter());
      }

      // 4. Open Reminders Box
      if (!Hive.isBoxOpen(HiveBoxes.reminders)) {
        await Hive.openBox<Reminder>(HiveBoxes.reminders);
      }
      final box = Hive.box<Reminder>(HiveBoxes.reminders);

      return await handleBackgroundCheck(
        box: box,
        notifications: notifications,
      );
    } catch (e, stack) {
      debugPrint('[Workmanager] Error: $e\n$stack');
      return Future.value(false);
    }
  });
}

/// Testable logic for checking due reminders
Future<bool> handleBackgroundCheck({
  required Box<Reminder> box,
  required NotificationService notifications,
}) async {
  // 5. Check for due reminders
  final now = DateTime.now();
  final dueReminders = box.values.where((r) {
    if (r.completedAt != null) return false;
    // Check if due in the past (missed)
    if (!r.time.isBefore(now)) return false;

    // [SPAM PREVENTION]
    // Only fire if the reminder was due recently (e.g. within the last 46 minutes).
    // This prevents the Safety Net from nagging about old reminders every 15 minutes.
    // Since Workmanager runs every ~15 mins, a 46-minute window gives us ~3 chances to catch it.
    final diff = now.difference(r.time);
    return diff.inMinutes <= 46;
  }).toList();

  debugPrint('[Workmanager] Found ${dueReminders.length} due reminders');

  for (final reminder in dueReminders) {
    // Show immediate notification
    // Note: Using the same ID updates the existing notification if present
    await notifications.showNow(
      id: reminder.notificationId,
      title: 'Reminder',
      body: reminder.title,
    );
  }
  return true;
}
