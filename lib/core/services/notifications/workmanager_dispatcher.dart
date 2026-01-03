import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/services/notifications/notification_service.dart';
import 'package:nexus/features/reminders/models/reminder.dart'; // Ensure this exports the Adapter too or import it
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
    // We add a small buffer (e.g. 1 sec) to ensure we catch "just due" items
    return r.time.isBefore(now.add(const Duration(seconds: 1)));
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
