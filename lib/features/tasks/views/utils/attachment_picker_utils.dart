import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:nexus/core/services/platform/permission_service.dart';
import 'package:nexus/core/services/storage/attachment_storage_service.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_attachment.dart';
import 'package:nexus/features/tasks/views/utils/attachment_auth_helper.dart';
import 'package:nexus/features/tasks/views/widgets/task_detail_sheet/voice_recording_dialog.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

/// Picks an image from gallery and adds it as a task attachment.
Future<void> pickAndAddImage({
  required BuildContext context,
  required Task task,
  required TaskController controller,
  required AttachmentStorageService storage,
  required ImagePicker picker,
}) async {
  final ok = await context.read<PermissionService>().ensureGalleryRead();
  if (!ok) return;
  if (!context.mounted) return;

  final xfile = await picker.pickImage(source: ImageSource.gallery);
  if (xfile == null) return;

  final copied = await storage.copyIntoTaskDir(
    taskId: task.id,
    source: File(xfile.path),
  );
  final mime = lookupMimeType(copied.path) ?? 'image/*';
  final attachment = TaskAttachment(
    id: const Uuid().v4(),
    mimeType: mime,
    createdAt: DateTime.now(),
    localUri: copied.path,
    uploaded: false,
  );

  if (context.mounted) {
    await addAttachmentWithAuth(context, controller, task, attachment);
  }
}

/// Records a voice note and adds it as a task attachment.
Future<void> recordAndAddVoice({
  required BuildContext context,
  required Task task,
  required TaskController controller,
  required AttachmentStorageService storage,
}) async {
  final ok = await context.read<PermissionService>().ensureMicrophone();
  if (!ok) return;
  if (!context.mounted) return;

  final path = await storage.newAudioPath(taskId: task.id);
  if (!context.mounted) return;

  final savedPath = await showVoiceRecordingDialog(context, path);

  if (savedPath != null && context.mounted) {
    final attachment = TaskAttachment(
      id: const Uuid().v4(),
      mimeType: 'audio/mp4',
      createdAt: DateTime.now(),
      localUri: savedPath,
      uploaded: false,
    );
    await addAttachmentWithAuth(context, controller, task, attachment);
  }
}
