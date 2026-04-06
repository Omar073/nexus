import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:nexus/core/services/notifications/notification_action_handler.dart';
import 'package:nexus/core/services/notifications/reminder_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Schedules, shows, and cancels local reminder notifications.
class NotificationService implements ReminderNotifications {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const String channelId = 'nexus_reminders_v2';
  static const String channelName = 'Reminders';
  static const String channelDescription = 'Task reminders and daily alerts';

  Future<void> initialize() async {
    mDebugPrint('[NotificationService] Initializing...');
    const android = AndroidInitializationSettings('ic_notification');
    const initSettings = InitializationSettings(android: android);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onForegroundNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );
    mDebugPrint('[NotificationService] Plugin initialized');

    tz.initializeTimeZones();
    mDebugPrint('[NotificationService] Timezones initialized');

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        final timezone = timezoneInfo.identifier;
        mDebugPrint('[NotificationService] Local timezone: $timezone');
        tz.setLocalLocation(tz.getLocation(timezone));
        mDebugPrint('[NotificationService] Timezone set successfully');
      } catch (e) {
        mDebugPrint('[NotificationService] Error setting timezone: $e');
        tz.setLocalLocation(tz.UTC);
      }
    }
    mDebugPrint('[NotificationService] Initialization complete');
  }

  Future<bool> requestPermissionsIfNeeded() async {
    mDebugPrint('[NotificationService] Requesting permissions...');
    if (kIsWeb) {
      mDebugPrint('[NotificationService] Web platform - skipping permissions');
      return false;
    }
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final notificationGranted = await androidPlugin
          ?.requestNotificationsPermission();
      mDebugPrint(
        '[NotificationService] Notification permission granted: $notificationGranted',
      );

      final exactAlarmGranted = await androidPlugin
          ?.canScheduleExactNotifications();
      mDebugPrint(
        '[NotificationService] Exact alarm permission: $exactAlarmGranted',
      );

      if (exactAlarmGranted == false) {
        mDebugPrint(
          '[NotificationService] Requesting exact alarm permission...',
        );
        await androidPlugin?.requestExactAlarmsPermission();
      }

      return (notificationGranted ?? false) && (exactAlarmGranted ?? true);
    }
    return true;
  }

  Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canSchedule = await androidPlugin?.canScheduleExactNotifications();
    mDebugPrint(
      '[NotificationService] Can schedule exact alarms: $canSchedule',
    );
    return canSchedule ?? true;
  }

  Future<void> openExactAlarmSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;

    mDebugPrint('[NotificationService] Opening exact alarm settings...');
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  Future<bool> isBatteryOptimizationExempt() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    return (await Permission.ignoreBatteryOptimizations.status).isGranted;
  }

  Future<bool> requestBatteryOptimizationExemption() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) return true;
    final result = await Permission.ignoreBatteryOptimizations.request();
    mDebugPrint(
      '[NotificationService] Battery optimization exemption: ${result.isGranted}',
    );
    return result.isGranted;
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool silent = false,
  }) async {
    mDebugPrint('[NotificationService] Showing immediate notification:');
    mDebugPrint('  ID: $id, Title: $title, Payload: $payload, silent: $silent');

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: silent ? Importance.low : Importance.max,
        priority: silent ? Priority.low : Priority.high,
        icon: 'ic_notification',
        actions: kActionButtons,
        playSound: !silent,
        enableVibration: !silent,
      ),
    );

    try {
      await _plugin.show(id, title, body, details, payload: payload);
      mDebugPrint('[NotificationService] Immediate notification shown');
    } catch (e) {
      mDebugPrint('[NotificationService] Error showing notification: $e');
    }
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    mDebugPrint('[NotificationService] Scheduling notification:');
    mDebugPrint('  ID: $id, Title: $title, When: $when, Payload: $payload');

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_notification',
        actions: kActionButtons,
      ),
    );

    final scheduledTime = tz.TZDateTime.from(when, tz.local);

    final canUseExact = await canScheduleExactAlarms();
    final scheduleMode = canUseExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    mDebugPrint('  Schedule mode: $scheduleMode (canUseExact: $canUseExact)');

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
        payload: payload,
      );
      mDebugPrint('[NotificationService] Notification scheduled successfully');
    } catch (e) {
      mDebugPrint('[NotificationService] Error scheduling notification: $e');
    }
  }

  @override
  Future<void> cancel(int id) async {
    mDebugPrint('[NotificationService] Cancelling notification ID: $id');
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    mDebugPrint('[NotificationService] Cancelling all notifications');
    await _plugin.cancelAll();
  }
}
