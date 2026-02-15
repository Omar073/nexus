import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexus/features/tasks/controllers/attachment_helper.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/views/utils/attachment_picker_utils.dart';

/// Buttons for adding image and voice attachments.
class AttachmentButtons extends StatelessWidget {
  const AttachmentButtons({
    super.key,
    required this.task,
    required this.controller,
    required this.attachmentHelper,
    required this.picker,
  });

  final Task task;
  final TaskController controller;
  final AttachmentHelper attachmentHelper;
  final ImagePicker picker;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => pickAndAddImage(
            context: context,
            task: task,
            controller: controller,
            attachmentHelper: attachmentHelper,
            picker: picker,
          ),
          icon: const Icon(Icons.image_outlined),
          label: const Text('Add image'),
        ),
        OutlinedButton.icon(
          onPressed: () => recordAndAddVoice(
            context: context,
            task: task,
            controller: controller,
            attachmentHelper: attachmentHelper,
          ),
          icon: const Icon(Icons.mic_none),
          label: const Text('Add voice'),
        ),
      ],
    );
  }
}
