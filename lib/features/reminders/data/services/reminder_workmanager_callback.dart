import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/services/notifications/notification_service.dart';
import 'package:nexus/core/services/notifications/reminder_notifications.dart';
import 'package:nexus/features/reminders/data/models/reminder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

/// Workmanager entry point for reminder background checks.
/// Must be top-level for isolate entry. Registered from [AppInitializer].
///
/// By design, this isolate depends on the reminders **data layer** ([Reminder] Hive model)
/// because the background entry point cannot use DI or domain use cases.
@pragma('vm:entry-point')
void reminderWorkmanagerCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      final notifications = NotificationService();
      await notifications.initialize();

      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        Hive.init(appDir.path);
      }

      if (!Hive.isAdapterRegistered(HiveTypeIds.reminder)) {
        Hive.registerAdapter(ReminderAdapter());
      }

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

/// Testable logic for checking due reminders (used by entry point and tests).
Future<bool> handleBackgroundCheck({
  required Box<Reminder> box,
  required ReminderNotifications notifications,
}) async {
  final now = DateTime.now();
  final dueReminders = box.values.where((r) {
    if (r.completedAt != null) return false;
    if (!r.time.isBefore(now)) return false;
    final diff = now.difference(r.time);
    return diff.inMinutes <= 46;
  }).toList();

  debugPrint('[Workmanager] Found ${dueReminders.length} due reminders');

  for (final reminder in dueReminders) {
    await notifications.showNow(
      id: reminder.notificationId,
      title: 'Reminder',
      body: reminder.title,
    );
  }
  return true;
}
