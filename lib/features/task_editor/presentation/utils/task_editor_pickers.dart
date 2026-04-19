import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/bottom_sheet/nexus_bottom_sheet.dart';
import 'package:nexus/core/widgets/time_picker/nexus_time_picker.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';

Future<DateTime?> pickTaskDate(
  BuildContext context, {
  required DateTime initialDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime.now().subtract(const Duration(days: 365)),
    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
  );
}

Future<TimeOfDay?> pickTaskDueTime(
  BuildContext context, {
  required TimeOfDay initialTime,
}) {
  return showNexusTimePicker(
    context,
    initialTime: initialTime,
    title: 'Select due time',
  );
}

Future<TaskRecurrenceRule?> pickTaskRecurrence(BuildContext context) {
  return showNexusBottomSheet<TaskRecurrenceRule>(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: const Text('No repeat'),
          leading: const Icon(Icons.close),
          onTap: () => Navigator.pop(context, TaskRecurrenceRule.none),
        ),
        ListTile(
          title: const Text('Daily'),
          leading: const Icon(Icons.repeat),
          onTap: () => Navigator.pop(context, TaskRecurrenceRule.daily),
        ),
        ListTile(
          title: const Text('Weekly'),
          leading: const Icon(Icons.repeat),
          onTap: () => Navigator.pop(context, TaskRecurrenceRule.weekly),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}
