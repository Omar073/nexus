import 'dart:io';

import 'package:mime/mime.dart';
import 'package:nexus/core/services/storage/attachment_storage_service.dart';
import 'package:nexus/features/tasks/models/task_attachment.dart';
import 'package:uuid/uuid.dart';

/// Result of creating an attachment from a file.
class AttachmentResult {
  AttachmentResult({required this.attachment, this.error});

  final TaskAttachment? attachment;
  final Object? error;

  bool get success => attachment != null && error == null;
}

/// Helper for creating attachments without UI dependencies.
/// This handles the core logic of copying files and creating attachment objects.
class AttachmentHelper {
  AttachmentHelper({required this.storage});

  final AttachmentStorageService storage;
  static const _uuid = Uuid();

  /// Creates an attachment from an image file.
  Future<AttachmentResult> createImageAttachment({
    required String taskId,
    required File imageFile,
  }) async {
    try {
      final copied = await storage.copyIntoTaskDir(
        taskId: taskId,
        source: imageFile,
      );
      final mime = lookupMimeType(copied.path) ?? 'image/*';
      final attachment = TaskAttachment(
        id: _uuid.v4(),
        mimeType: mime,
        createdAt: DateTime.now(),
        localUri: copied.path,
        uploaded: false,
      );
      return AttachmentResult(attachment: attachment);
    } catch (e) {
      return AttachmentResult(attachment: null, error: e);
    }
  }

  /// Creates an attachment from a voice recording path.
  TaskAttachment createVoiceAttachment({required String recordingPath}) {
    return TaskAttachment(
      id: _uuid.v4(),
      mimeType: 'audio/mp4',
      createdAt: DateTime.now(),
      localUri: recordingPath,
      uploaded: false,
    );
  }

  /// Gets a new audio path for recording.
  Future<String> getNewAudioPath({required String taskId}) {
    return storage.newAudioPath(taskId: taskId);
  }
}
