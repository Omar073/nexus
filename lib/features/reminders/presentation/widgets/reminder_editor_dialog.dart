import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/bottom_sheet/nexus_bottom_sheet.dart';
import 'package:nexus/core/widgets/common_snackbar.dart';
import 'package:nexus/features/reminders/domain/entities/reminder_entity.dart';
import 'package:nexus/features/reminders/presentation/state_management/reminder_controller.dart';
import 'package:nexus/features/reminders/presentation/utils/reminder_time_utils.dart';
import 'package:nexus/features/reminders/presentation/widgets/reminder_editor_result.dart';
import 'package:nexus/features/reminders/presentation/widgets/reminder_editor_sheet.dart';
import 'package:provider/provider.dart';

/// Shows a dialog for creating or editing a reminder.
Future<void> showReminderEditorDialog(
  BuildContext context, {
  ReminderEntity? reminder,
}) async {
  final controller = context.read<ReminderController>();

  final result = await showNexusBottomSheet<ReminderEditorResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (dialogContext) => ReminderEditorSheet(reminder: reminder),
  );

  if (result == null) return;
  if (result.title.trim().isEmpty) return;

  if (reminder == null) {
    await controller.create(title: result.title, time: result.time);
  } else {
    await controller.update(reminder, title: result.title, time: result.time);
  }

  final duration = result.time.difference(DateTime.now());
  if (!context.mounted) return;
  CommonSnackbar.show(
    context,
    'Reminder set for ${formatReminderOffsetLabel(duration)}',
    Theme.of(context).colorScheme.primary,
    duration: const Duration(seconds: 2),
  );
}
