import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexus/core/services/platform/permission_service.dart';
import 'package:nexus/features/tasks/controllers/attachment_helper.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/views/utils/attachment_auth_helper.dart';
import 'package:nexus/features/tasks/views/widgets/task_detail_sheet/voice_recording_dialog.dart';
import 'package:provider/provider.dart';

/// UI helper to pick an image and add it as a task attachment.
/// Handles permissions and UI flow, delegates core logic to AttachmentHelper.
Future<void> pickAndAddImage({
  required BuildContext context,
  required Task task,
  required TaskController controller,
  required AttachmentHelper attachmentHelper,
  required ImagePicker picker,
}) async {
  final ok = await context.read<PermissionService>().ensureGalleryRead();
  if (!ok) return;
  if (!context.mounted) return;

  final xfile = await picker.pickImage(source: ImageSource.gallery);
  if (xfile == null) return;

  final result = await attachmentHelper.createImageAttachment(
    taskId: task.id,
    imageFile: File(xfile.path),
  );

  if (!result.success) return;
  if (!context.mounted) return;

  await addAttachmentWithAuth(context, controller, task, result.attachment!);
}

/// UI helper to record a voice note and add it as a task attachment.
/// Handles permissions and UI flow, delegates core logic to AttachmentHelper.
Future<void> recordAndAddVoice({
  required BuildContext context,
  required Task task,
  required TaskController controller,
  required AttachmentHelper attachmentHelper,
}) async {
  final ok = await context.read<PermissionService>().ensureMicrophone();
  if (!ok) return;
  if (!context.mounted) return;

  final path = await attachmentHelper.getNewAudioPath(taskId: task.id);
  if (!context.mounted) return;

  final savedPath = await showVoiceRecordingDialog(context, path);

  if (savedPath != null && context.mounted) {
    final attachment = attachmentHelper.createVoiceAttachment(
      recordingPath: savedPath,
    );
    await addAttachmentWithAuth(context, controller, task, attachment);
  }
}
