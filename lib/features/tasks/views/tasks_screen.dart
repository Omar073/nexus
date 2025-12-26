import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:nexus/features/tasks/views/widgets/daily_focus_card.dart';
import 'package:nexus/features/tasks/views/widgets/daily_task_item.dart';
import 'package:nexus/features/tasks/views/widgets/date_strip.dart';
import 'package:nexus/features/tasks/views/widgets/task_editor_dialog.dart';
import 'package:provider/provider.dart';

/// Main tasks screen following new Nexus design.
/// Features Today header, date strip, daily focus, and grouped task sections.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _showCompleted = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final taskController = context.watch<TaskController>();
    final now = DateTime.now();

    // Filter tasks for selected date
    final allTasks = [
      ...taskController.tasksForStatus(TaskStatus.active),
      ...taskController.tasksForStatus(TaskStatus.pending),
    ];

    final completedTasks = taskController.tasksForStatus(TaskStatus.completed);

    // Separate overdue and upcoming
    final overdueTasks = <Task>[];
    final upcomingTasks = <Task>[];

    for (final task in allTasks) {
      if (task.dueDate != null && task.dueDate!.isBefore(now)) {
        overdueTasks.add(task);
      } else {
        upcomingTasks.add(task);
      }
    }

    // Sort by due date
    overdueTasks.sort((a, b) => (a.dueDate ?? now).compareTo(b.dueDate ?? now));
    upcomingTasks.sort(
      (a, b) => (a.dueDate ?? now).compareTo(b.dueDate ?? now),
    );

    final tasksRemaining = overdueTasks.length + upcomingTasks.length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'MMMM d',
                        ).format(_selectedDate).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  // Profile button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Date Strip
            DateStrip(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
              },
            ),
            const SizedBox(height: 20),
            // Daily Focus Card
            DailyFocusCard(tasksRemaining: tasksRemaining),
            const SizedBox(height: 24),
            // Overdue Section
            if (overdueTasks.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                title: 'Overdue',
                color: Colors.red,
                count: overdueTasks.length,
              ),
              const SizedBox(height: 12),
              ...overdueTasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: DailyTaskItem(
                    task: task,
                    isOverdue: true,
                    onToggle: (value) {
                      taskController.toggleCompleted(task, value);
                    },
                    onSnooze: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Snooze coming soon')),
                      );
                    },
                    onTap: () => showTaskEditorDialog(context, task: task),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Upcoming Section
            _buildSectionHeader(
              context,
              title: 'Upcoming',
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            if (upcomingTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 32,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No upcoming tasks',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...upcomingTasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: DailyTaskItem(
                    task: task,
                    onToggle: (value) {
                      taskController.toggleCompleted(task, value);
                    },
                    onSnooze: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Snooze coming soon')),
                      );
                    },
                    onTap: () => showTaskEditorDialog(context, task: task),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            // Completed Section
            if (completedTasks.isNotEmpty) ...[
              GestureDetector(
                onTap: () => setState(() => _showCompleted = !_showCompleted),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Completed (${completedTasks.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _showCompleted ? Icons.expand_less : Icons.expand_more,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_showCompleted)
                Opacity(
                  opacity: 0.7,
                  child: Column(
                    children: completedTasks
                        .take(5)
                        .map(
                          (task) => Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: DailyTaskItem(
                              task: task,
                              isCompleted: true,
                              onToggle: (value) {
                                // Toggle back to active
                                taskController.toggleCompleted(task, !value);
                              },
                              onTap: () =>
                                  showTaskEditorDialog(context, task: task),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'tasks_fab',
        onPressed: () => showTaskEditorDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required Color color,
    int? count,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 1, color: color.withValues(alpha: 0.2)),
          ),
        ],
      ),
    );
  }
}
