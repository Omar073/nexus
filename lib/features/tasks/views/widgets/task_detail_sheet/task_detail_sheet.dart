import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexus/core/services/storage/attachment_storage_service.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/views/widgets/attachments/attachments_list.dart';
import 'package:nexus/features/tasks/views/widgets/task_detail_sheet/attachment_buttons.dart';
import 'package:nexus/features/tasks/views/widgets/task_detail_sheet/task_detail_actions.dart';
import 'package:nexus/features/tasks/views/widgets/task_detail_sheet/task_detail_header.dart';
import 'package:provider/provider.dart';

/// Shows a modal bottom sheet with task details, attachments, and actions.
Future<void> showTaskDetailSheet(BuildContext context, Task task) async {
  final controller = context.read<TaskController>();
  final storage = AttachmentStorageService();
  final picker = ImagePicker();

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task header
            TaskDetailHeader(task: task),
            const SizedBox(height: 16),

            // Attachments section
            const Text('Attachments'),
            const SizedBox(height: 8),
            AttachmentsList(task: task),
            const SizedBox(height: 8),

            // Add attachment buttons
            AttachmentButtons(
              task: task,
              controller: controller,
              storage: storage,
              picker: picker,
            ),
            const SizedBox(height: 16),

            // Action buttons
            TaskDetailActions(
              task: task,
              controller: controller,
              onClose: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      );
    },
  );
}
