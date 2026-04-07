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

/// Loud console lines for notification tap debugging (works from headless isolate).
void _notifDiag(String isolate, String message) {
  debugPrint('[NexusNotif.$isolate] $message');
}

void _logResponse(String isolate, NotificationResponse r) {
  _notifDiag(
    isolate,
    'response id=${r.id} actionId=${r.actionId} '
    'type=${r.notificationResponseType} payload=${r.payload} input=${r.input}',
  );
}

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

/// Background isolate entry point for notification actions (app terminated).
/// Must be top-level for `flutter_local_notifications`.
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) async {
  _logResponse('Bg.enter', response);
  try {
    WidgetsFlutterBinding.ensureInitialized();

    final payload = response.payload;
    final notificationId = response.id;
    if ((payload == null || payload.isEmpty) && notificationId == null) {
      _notifDiag('Bg', 'exit: no payload and no notification id');
      return;
    }

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
    final reminder =
        (payload == null || payload.isEmpty)
            ? box.values.where((r) => r.notificationId == notificationId).firstOrNull
            : box.values.where((r) => r.id == payload).firstOrNull;
    if (reminder == null) {
      _notifDiag(
        'Bg',
        'exit: no reminder for payload=$payload notifId=$notificationId '
        '(box length=${box.length})',
      );
      return;
    }
    final effectiveNotificationId = notificationId ?? reminder.notificationId;
    _notifDiag(
      'Bg',
      'matched reminder id=${reminder.id} effectiveNotifId=$effectiveNotificationId',
    );

    final notifications = NotificationService();
    await notifications.initialize();

    switch (response.actionId) {
      case kCompleteActionId:
        reminder.completedAt = DateTime.now();
        reminder.updatedAt = DateTime.now();
        reminder.isDirty = true;
        await reminder.save();
        await NotificationCompletePending.append(reminder.id);
        await notifications.cancel(effectiveNotificationId);
        mDebugPrint('[BgAction] Completed reminder: ${reminder.title}');
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
        mDebugPrint(
          '[BgAction] Snoozed reminder: ${reminder.title} → $newTime',
        );
        return;
      default:
        _notifDiag(
          'Bg',
          'exit: unknown actionId=${response.actionId} '
          '(expected $kCompleteActionId | $kSnoozeActionId)',
        );
        mDebugPrint(
          '[BgAction] Unknown actionId: ${response.actionId} (payload: $payload, notifId: $notificationId)',
        );
        return;
    }
  } catch (e, st) {
    _notifDiag('Bg', 'ERROR: $e');
    mDebugPrint('[BgAction] Error handling notification action: $e');
    mDebugPrint('[BgAction] $st');
  }
}

/// Foreground callback -- runs on the main isolate.
///
/// Used for **notification body** taps and any intent that routes through the
/// Activity (`SELECT_NOTIFICATION` / `SELECT_FOREGROUND_NOTIFICATION_ACTION`).
/// Action buttons use [showsUserInterface: false] and are handled by
/// [onBackgroundNotificationResponse] on a headless isolate instead.
void onForegroundNotificationResponse(NotificationResponse response) async {
  _logResponse('Fg.enter', response);
  final payload = response.payload;
  final notificationId = response.id;
  if ((payload == null || payload.isEmpty) && notificationId == null) {
    _notifDiag('Fg', 'exit: no payload and no notification id');
    return;
  }

  // Body tap opens the app; do not treat as an action button.
  if (response.notificationResponseType ==
      NotificationResponseType.selectedNotification) {
    _notifDiag(
      'Fg',
      'exit: selectedNotification (body tap or OEM misrouted action — '
      'actionId is ${response.actionId}, no Complete/Snooze here)',
    );
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
    final reminder =
        (payload == null || payload.isEmpty)
            ? box.values.where((r) => r.notificationId == notificationId).firstOrNull
            : box.values.where((r) => r.id == payload).firstOrNull;
    if (reminder == null) {
      _notifDiag(
        'Fg',
        'exit: no reminder for payload=$payload notifId=$notificationId '
        '(box length=${box.length})',
      );
      return;
    }
    final effectiveNotificationId = notificationId ?? reminder.notificationId;
    _notifDiag(
      'Fg',
      'matched reminder id=${reminder.id} effectiveNotifId=$effectiveNotificationId',
    );

    final notifications = NotificationService();
    await notifications.initialize();

    switch (response.actionId) {
      case kCompleteActionId:
        reminder.completedAt = DateTime.now();
        reminder.updatedAt = DateTime.now();
        reminder.isDirty = true;
        await reminder.save();
        await notifications.cancel(effectiveNotificationId);
        mDebugPrint('[FgAction] Completed reminder: ${reminder.title}');
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
        mDebugPrint(
          '[FgAction] Snoozed reminder: ${reminder.title} → $newTime',
        );
        return;
      default:
        _notifDiag(
          'Fg',
          'exit: unknown actionId=${response.actionId} '
          'type=${response.notificationResponseType}',
        );
        mDebugPrint(
          '[FgAction] Unknown actionId: ${response.actionId} (payload: $payload, notifId: $notificationId)',
        );
        return;
    }
  } catch (e, st) {
    _notifDiag('Fg', 'ERROR: $e');
    mDebugPrint('[FgAction] Error: $e');
    mDebugPrint('[FgAction] $st');
  }
}
