import 'dart:io';
import 'dart:async';

import 'package:nexus/core/services/storage/google_drive_service.dart';

/// Best-effort cleanup for attachments.
///
/// This is intentionally tolerant: failures should not break UX flows like
/// deleting an attachment from a note.
class AttachmentCleanupService {
  const AttachmentCleanupService({required GoogleDriveService drive})
    : _drive = drive;

  final GoogleDriveService _drive;

  Future<void> deleteLocalIfPresent(String? localUri) async {
    if (localUri == null || localUri.isEmpty) return;
    try {
      await File(localUri).delete();
    } catch (_) {}
  }

  Future<void> deleteDriveIfPresent(String? driveFileId) async {
    if (driveFileId == null || driveFileId.isEmpty) return;
    try {
      await _drive.deleteFile(driveFileId);
    } catch (_) {}
  }

  void deleteLocalInBackground(String? localUri) {
    unawaited(deleteLocalIfPresent(localUri));
  }
}
