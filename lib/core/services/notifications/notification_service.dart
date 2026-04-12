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
    const android = AndroidInitializationSettings('ic_notification');
    const initSettings = InitializationSettings(android: android);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onForegroundNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );

    tz.initializeTimeZones();

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        final timezone = timezoneInfo.identifier;
        tz.setLocalLocation(tz.getLocation(timezone));
      } catch (e) {
        mDebugPrint('[NotificationService] Error setting timezone: $e');
        tz.setLocalLocation(tz.UTC);
      }
    }
  }

  Future<bool> requestPermissionsIfNeeded() async {
    if (kIsWeb) {
      return false;
    }
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final notificationGranted = await androidPlugin
          ?.requestNotificationsPermission();

      final exactAlarmGranted = await androidPlugin
          ?.canScheduleExactNotifications();

      if (exactAlarmGranted == false) {
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
    return canSchedule ?? true;
  }

  Future<void> openExactAlarmSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;

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
    } catch (e) {
      mDebugPrint('[NotificationService] Error scheduling notification: $e');
    }
  }

  @override
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
