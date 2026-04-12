import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:nexus/core/services/notifications/notification_complete_pending.dart';
import 'package:nexus/core/services/notifications/notification_service.dart';
import 'package:nexus/features/reminders/data/models/reminder.dart';
import 'package:path_provider/path_provider.dart';

final _timeFmt = DateFormat('h:mm a');

const kCompleteActionId = 'complete_reminder';
const kSnoozeActionId = 'snooze_reminder';

const kActionButtons = <AndroidNotificationAction>[
  AndroidNotificationAction(
    kSnoozeActionId,
    'Snooze 5 min',
    // `false` = broadcast receiver + headless Dart isolate → action runs without
    // launching the app UI. (`true` would open the app to deliver actionId.)
    showsUserInterface: false,
  ),
  AndroidNotificationAction(
    kCompleteActionId,
    'Complete',
    showsUserInterface: false,
  ),
];

/// Background isolate entry point for notification actions.
///
/// When `showsUserInterface: false`, Android delivers action taps through a
/// broadcast receiver. The plugin can execute this callback on a **headless**
/// Flutter engine (separate Dart isolate) without opening the app UI.
/// Must be top-level for `flutter_local_notifications`.
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    final payload = response.payload;
    final notificationId = response.id;
    if ((payload == null || payload.isEmpty) && notificationId == null) {
      return;
    }

    // Headless isolate: we can't assume Hive was initialized/opened.
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
    // Prefer payload (reminder UUID). Some devices/OEM builds can deliver action
    // intents without payload; in that case fall back to matching by
    // notification id.
    final reminder = (payload == null || payload.isEmpty)
        ? box.values
              .where((r) => r.notificationId == notificationId)
              .firstOrNull
        : box.values.where((r) => r.id == payload).firstOrNull;
    if (reminder == null) {
      return;
    }
    final effectiveNotificationId = notificationId ?? reminder.notificationId;

    final notifications = NotificationService();
    await notifications.initialize();

    switch (response.actionId) {
      case kCompleteActionId:
        // Persist completion immediately for correctness even if the main UI
        // isolate is not alive.
        reminder.completedAt = DateTime.now();
        reminder.updatedAt = DateTime.now();
        reminder.isDirty = true;
        await reminder.save();
        // Side-channel to help the main isolate reconcile UI/sync quickly when
        // the app is running (see `NotificationCompletePending.watch()` +
        // `drainPendingReminderCompletesFromNotification`). Best-effort: if the
        // write fails we still have `completedAt` persisted in Hive.
        await NotificationCompletePending.append(reminder.id);
        await notifications.cancel(effectiveNotificationId);
        return;
      case kSnoozeActionId:
        // Snooze updates the reminder time and clears `notifiedAt` so delivery
        // can fire again at the new time.
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
          id: effectiveNotificationId,
          title: 'Snoozed',
          body: snoozedBody,
          payload: reminder.id,
          silent: true,
        );

        await notifications.schedule(
          id: effectiveNotificationId,
          title: 'Reminder',
          body: reminder.title,
          when: newTime,
          payload: reminder.id,
        );
        return;
      default:
        return;
    }
  } catch (e, st) {
    mDebugPrint('[NotificationAction] Background handler error: $e');
    mDebugPrint('$st');
  }
}

/// Foreground callback -- runs on the main isolate.
///
/// Used for **notification body** taps and any intent that routes through the
/// Activity (`SELECT_NOTIFICATION` / `SELECT_FOREGROUND_NOTIFICATION_ACTION`).
/// Action buttons use [showsUserInterface: false] and are handled by
/// [onBackgroundNotificationResponse] on a headless isolate instead.
void onForegroundNotificationResponse(NotificationResponse response) async {
  final payload = response.payload;
  final notificationId = response.id;
  if ((payload == null || payload.isEmpty) && notificationId == null) {
    return;
  }

  // Body tap opens the app; do not treat as an action button.
  // (Some OEMs may misroute action taps as body taps; that arrives here with
  // `selectedNotification` and often a null/empty `actionId`.)
  if (response.notificationResponseType ==
      NotificationResponseType.selectedNotification) {
    return;
  }

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
    // Foreground path should normally have payload, but keep the same
    // payload/id fallback logic for consistency.
    final reminder = (payload == null || payload.isEmpty)
        ? box.values
              .where((r) => r.notificationId == notificationId)
              .firstOrNull
        : box.values.where((r) => r.id == payload).firstOrNull;
    if (reminder == null) {
      return;
    }
    final effectiveNotificationId = notificationId ?? reminder.notificationId;

    final notifications = NotificationService();
    await notifications.initialize();

    switch (response.actionId) {
      case kCompleteActionId:
        reminder.completedAt = DateTime.now();
        reminder.updatedAt = DateTime.now();
        reminder.isDirty = true;
        await reminder.save();
        await notifications.cancel(effectiveNotificationId);
        return;
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
          id: effectiveNotificationId,
          title: 'Snoozed',
          body: snoozedBody,
          payload: reminder.id,
          silent: true,
        );

        await notifications.schedule(
          id: effectiveNotificationId,
          title: 'Reminder',
          body: reminder.title,
          when: newTime,
          payload: reminder.id,
        );
        return;
      default:
        return;
    }
  } catch (e, st) {
    mDebugPrint('[NotificationAction] Foreground handler error: $e');
    mDebugPrint('$st');
  }
}
