import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:nexus/core/services/notifications/reminder_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService implements ReminderNotifications {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const String channelId = 'nexus_reminders';
  static const String channelName = 'Reminders';
  static const String channelDescription = 'Task reminders and daily alerts';

  Future<void> initialize() async {
    debugPrint('[NotificationService] Initializing...');
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _plugin.initialize(initSettings);
    debugPrint('[NotificationService] Plugin initialized');

    tz.initializeTimeZones();
    debugPrint('[NotificationService] Timezones initialized');

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        final timezone = timezoneInfo.identifier;
        debugPrint('[NotificationService] Local timezone: $timezone');
        tz.setLocalLocation(tz.getLocation(timezone));
        debugPrint('[NotificationService] Timezone set successfully');
      } catch (e) {
        debugPrint('[NotificationService] Error setting timezone: $e');
        // Fallback to UTC if timezone fails
        tz.setLocalLocation(tz.UTC);
      }
    }
    debugPrint('[NotificationService] Initialization complete');
  }

  Future<bool> requestPermissionsIfNeeded() async {
    debugPrint('[NotificationService] Requesting permissions...');
    if (kIsWeb) {
      debugPrint('[NotificationService] Web platform - skipping permissions');
      return false;
    }
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // Request notification permission
      final notificationGranted = await androidPlugin
          ?.requestNotificationsPermission();
      debugPrint(
        '[NotificationService] Notification permission granted: $notificationGranted',
      );

      // Check exact alarm permission (Android 12+)
      final exactAlarmGranted = await androidPlugin
          ?.canScheduleExactNotifications();
      debugPrint(
        '[NotificationService] Exact alarm permission: $exactAlarmGranted',
      );

      if (exactAlarmGranted == false) {
        debugPrint(
          '[NotificationService] Requesting exact alarm permission...',
        );
        await androidPlugin?.requestExactAlarmsPermission();
      }

      return (notificationGranted ?? false) && (exactAlarmGranted ?? true);
    }
    return true;
  }

  /// Check if exact alarms can be scheduled (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canSchedule = await androidPlugin?.canScheduleExactNotifications();
    debugPrint('[NotificationService] Can schedule exact alarms: $canSchedule');
    return canSchedule ?? true;
  }

  /// Open exact alarm settings for the user to grant permission
  Future<void> openExactAlarmSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;

    debugPrint('[NotificationService] Opening exact alarm settings...');
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  /// Show an immediate notification (for testing)
  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    debugPrint('[NotificationService] Showing immediate notification:');
    debugPrint('  ID: $id');
    debugPrint('  Title: $title');
    debugPrint('  Body: $body');

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    try {
      await _plugin.show(id, title, body, details);
      debugPrint(
        '[NotificationService] Immediate notification shown successfully',
      );
    } catch (e) {
      debugPrint('[NotificationService] Error showing notification: $e');
    }
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    debugPrint('[NotificationService] Scheduling notification:');
    debugPrint('  ID: $id');
    debugPrint('  Title: $title');
    debugPrint('  Body: $body');
    debugPrint('  When: $when');
    debugPrint('  Now: ${DateTime.now()}');

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    final scheduledTime = tz.TZDateTime.from(when, tz.local);
    debugPrint('  Scheduled TZ time: $scheduledTime');

    // Check if we can use exact alarms, otherwise use inexact
    final canUseExact = await canScheduleExactAlarms();
    final scheduleMode = canUseExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    debugPrint('  Schedule mode: $scheduleMode (canUseExact: $canUseExact)');

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
      debugPrint('[NotificationService] Notification scheduled successfully');
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling notification: $e');
    }
  }

  @override
  Future<void> cancel(int id) async {
    debugPrint('[NotificationService] Cancelling notification ID: $id');
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    debugPrint('[NotificationService] Cancelling all notifications');
    await _plugin.cancelAll();
  }
}
