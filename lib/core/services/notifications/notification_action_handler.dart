import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:nexus/core/services/notifications/notification_service.dart';
import 'package:nexus/features/reminders/data/models/reminder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final _timeFmt = DateFormat('h:mm a');

const kCompleteActionId = 'complete_reminder';
const kSnoozeActionId = 'snooze_reminder';

const kActionButtons = <AndroidNotificationAction>[
  AndroidNotificationAction(
    kSnoozeActionId,
    'Snooze 5 min',
    showsUserInterface: false,
  ),
  AndroidNotificationAction(
    kCompleteActionId,
    'Complete',
    showsUserInterface: false,
  ),
];

/// Background isolate entry point for notification actions (app terminated).
/// Must be top-level for `flutter_local_notifications`.
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

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
    final reminder = box.values.where((r) => r.id == payload).firstOrNull;
    if (reminder == null) return;

    final notifications = NotificationService();
    await notifications.initialize();

    switch (response.actionId) {
      case kCompleteActionId:
        reminder.completedAt = DateTime.now();
        reminder.updatedAt = DateTime.now();
        reminder.isDirty = true;
        await reminder.save();
        await notifications.cancel(reminder.notificationId);
        mDebugPrint('[BgAction] Completed reminder: ${reminder.title}');
      case kSnoozeActionId:
        final originalTime = reminder.time;
        final newTime = DateTime.now().add(const Duration(minutes: 5));
        reminder.time = newTime;
        reminder.notifiedAt = null;
        reminder.updatedAt = DateTime.now();
        reminder.isDirty = true;
        await reminder.save();

        final snoozedBody =
            '${reminder.title}\n'
            'Was ${_timeFmt.format(originalTime)} · '
            'Snoozed until ${_timeFmt.format(newTime)}';

        await notifications.showNow(
          id: reminder.notificationId,
          title: 'Snoozed',
          body: snoozedBody,
          payload: reminder.id,
          silent: true,
        );

        await notifications.schedule(
          id: reminder.notificationId,
          title: 'Reminder',
          body: reminder.title,
          when: newTime,
          payload: reminder.id,
        );
        mDebugPrint(
          '[BgAction] Snoozed reminder: ${reminder.title} → $newTime',
        );
    }
  } catch (e) {
    mDebugPrint('[BgAction] Error handling notification action: $e');
  }
}

/// Foreground callback -- runs on the main isolate.
/// Also handles cold-start launches (app terminated → user tapped action →
/// Android launches the app with showsUserInterface: true).
void onForegroundNotificationResponse(NotificationResponse response) async {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;

  try {
    // Cold-start: Hive may not be open yet. Initialize like the bg handler.
    if (!Hive.isBoxOpen(HiveBoxes.reminders)) {
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        Hive.init(appDir.path);
      }
      if (!Hive.isAdapterRegistered(HiveTypeIds.reminder)) {
        Hive.registerAdapter(ReminderAdapter());
      }
      await Hive.openBox<Reminder>(HiveBoxes.reminders);
    }
    final box = Hive.box<Reminder>(HiveBoxes.reminders);
    final reminder = box.values.where((r) => r.id == payload).firstOrNull;
    if (reminder == null) return;

    final plugin = FlutterLocalNotificationsPlugin();

    switch (response.actionId) {
      case kCompleteActionId:
        reminder.completedAt = DateTime.now();
        reminder.updatedAt = DateTime.now();
        reminder.isDirty = true;
        await reminder.save();
        await plugin.cancel(reminder.notificationId);
        mDebugPrint('[FgAction] Completed reminder: ${reminder.title}');
      case kSnoozeActionId:
        final originalTime = reminder.time;
        final newTime = DateTime.now().add(const Duration(minutes: 5));
        reminder.time = newTime;
        reminder.notifiedAt = null;
        reminder.updatedAt = DateTime.now();
        reminder.isDirty = true;
        await reminder.save();

        final snoozedBody =
            '${reminder.title}\n'
            'Was ${_timeFmt.format(originalTime)} · '
            'Snoozed until ${_timeFmt.format(newTime)}';

        // Replace the current notification with a silent "snoozed" state
        await plugin.show(
          reminder.notificationId,
          'Snoozed',
          snoozedBody,
          NotificationDetails(
            android: AndroidNotificationDetails(
              NotificationService.channelId,
              NotificationService.channelName,
              channelDescription: NotificationService.channelDescription,
              importance: Importance.low,
              priority: Priority.low,
              icon: 'ic_notification',
              playSound: false,
              enableVibration: false,
              actions: kActionButtons,
            ),
          ),
          payload: reminder.id,
        );

        // Schedule the re-trigger with full sound/vibration
        tz.initializeTimeZones();
        final scheduledTime = tz.TZDateTime.from(newTime, tz.local);
        await plugin.zonedSchedule(
          reminder.notificationId,
          'Reminder',
          reminder.title,
          scheduledTime,
          NotificationDetails(
            android: AndroidNotificationDetails(
              NotificationService.channelId,
              NotificationService.channelName,
              channelDescription: NotificationService.channelDescription,
              importance: Importance.max,
              priority: Priority.high,
              icon: 'ic_notification',
              actions: kActionButtons,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: reminder.id,
        );
        mDebugPrint(
          '[FgAction] Snoozed reminder: ${reminder.title} → $newTime',
        );
    }
  } catch (e) {
    mDebugPrint('[FgAction] Error: $e');
  }
}
