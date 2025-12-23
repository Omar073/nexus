import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

/// NOTE: Workmanager callbacks must be top-level or static functions.
@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // Phase 2 minimal: no-op periodic job.
    // We rely primarily on the OS-held scheduled notifications.
    if (!kIsWeb && Platform.isAndroid) {
      // Placeholder for future: re-sync reminders/tasks or reschedule alarms.
    }
    return Future.value(true);
  });
}

