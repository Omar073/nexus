import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/features/tasks/data/models/task.dart';

class TaskConflictSnapshotCard extends StatelessWidget {
  const TaskConflictSnapshotCard({
    super.key,
    required this.title,
    required this.task,
    required this.other,
  });

  final String title;
  final Task task;
  final Task other;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget row(String label, String value, {required bool diff}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label, style: theme.textTheme.bodySmall),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: diff
                    ? theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      )
                    : theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    String fmtDate(DateTime? d) =>
        d == null ? '—' : DateFormat.yMMMd().add_Hm().format(d);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            row('Title', task.title, diff: task.title != other.title),
            row(
              'Description',
              task.description ?? '—',
              diff: (task.description ?? '') != (other.description ?? ''),
            ),
            row(
              'Due',
              fmtDate(task.dueDate),
              diff:
                  (task.dueDate?.millisecondsSinceEpoch ?? 0) !=
                  (other.dueDate?.millisecondsSinceEpoch ?? 0),
            ),
            row(
              'Status',
              task.statusEnum.name,
              diff: task.status != other.status,
            ),
            row(
              'Priority',
              task.priorityEnum?.name ?? '—',
              diff: (task.priority ?? -1) != (other.priority ?? -1),
            ),
            row(
              'Updated',
              fmtDate(task.updatedAt),
              diff: task.updatedAt != other.updatedAt,
            ),
          ],
        ),
      ),
    );
  }
}
