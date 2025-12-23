import 'package:flutter/material.dart';
import 'package:nexus/core/extensions/l10n_x.dart';
import 'package:nexus/core/widgets/theme_toggle_button.dart';
import 'package:nexus/features/sync/views/sync_status_widget.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:nexus/features/tasks/views/widgets/task_editor_dialog.dart';
import 'package:nexus/features/tasks/views/widgets/task_list_tab.dart';
import 'package:nexus/features/tasks/views/widgets/task_search_bar.dart';

/// Main screen for displaying and managing tasks.
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.navTasks),
          actions: const [ThemeToggleButton(), SyncStatusWidget()],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.tasksActive),
              Tab(text: l10n.tasksPending),
              Tab(text: l10n.tasksCompleted),
            ],
          ),
        ),
        body: const Column(
          children: [
            TaskSearchBar(),
            Expanded(
              child: TabBarView(
                children: [
                  TaskListTab(status: TaskStatus.active),
                  TaskListTab(status: TaskStatus.pending),
                  TaskListTab(status: TaskStatus.completed),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showTaskEditorDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
