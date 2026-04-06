import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nexus/core/services/notifications/battery_optimization_dialog.dart';
import 'package:nexus/core/services/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time battery optimization explanation + OS prompt after full app init.
///
/// Preference flag and platform checks live here so splash UI only schedules *when*
/// to run (post-frame + [mounted]), not the business rules.
class BatteryOptimizationFirstLaunchPrompt {
  BatteryOptimizationFirstLaunchPrompt._();

  static const _prefsKey = 'hasRequestedBatteryOptimization';

  /// Shows the explanation dialog once per install (unless already exempt).
  /// Call from a post-frame callback; pass [isMounted] to bail out after awaits.
  static Future<void> runIfNeeded({
    required NotificationService notificationService,
    required bool Function() isMounted,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    if (!isMounted()) return;

    final alreadyAsked = prefs.getBool(_prefsKey) ?? false;
    if (alreadyAsked) return;

    final alreadyExempt = await notificationService
        .isBatteryOptimizationExempt();
    if (!isMounted()) return;
    if (alreadyExempt) return;

    await showBatteryOptimizationExplanation(notificationService);
    if (!isMounted()) return;

    await prefs.setBool(_prefsKey, true);
  }
}
