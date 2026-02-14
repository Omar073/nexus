import 'package:flutter/material.dart';

/// Stub for [SettingsController] used in controller tests.
///
/// Exposes only the fields that other controllers read.
class FakeSettingsController extends ChangeNotifier {
  bool autoDeleteCompletedTasks;
  int completedRetentionDays;

  FakeSettingsController({
    this.autoDeleteCompletedTasks = false,
    this.completedRetentionDays = 30,
  });
}
