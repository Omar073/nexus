import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/tasks/domain/task_sort_option.dart';

import 'fake_settings_repository.dart';

/// Stub for [SettingsController] used in controller tests.
/// Exposes only the fields that other controllers read.
class FakeSettingsController extends SettingsController {
  FakeSettingsController({
    this.autoDeleteCompletedTasks = false,
    this.completedRetentionDays = 30,
    this.taskSortOption = TaskSortOption.recentlyModified,
  }) : super(FakeSettingsRepository());

  @override
  bool autoDeleteCompletedTasks;

  @override
  int completedRetentionDays;

  @override
  TaskSortOption taskSortOption;
}
