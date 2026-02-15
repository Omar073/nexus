import 'package:nexus/features/settings/controllers/settings_controller.dart';
import 'package:nexus/features/tasks/models/task_sort_option.dart';

/// Stub for [SettingsController] used in controller tests.
///
/// Exposes only the fields that other controllers read.
class FakeSettingsController extends SettingsController {
  FakeSettingsController({
    this.autoDeleteCompletedTasks = false,
    this.completedRetentionDays = 30,
    this.taskSortOption = TaskSortOption.newestFirst,
  });

  @override
  bool autoDeleteCompletedTasks;

  @override
  int completedRetentionDays;

  @override
  TaskSortOption taskSortOption;
}
