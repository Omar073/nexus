import 'package:googleapis/drive/v3.dart' as drive;
import 'package:nexus/app_secrets/app_secrets.dart';
import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:nexus/core/services/storage/google_drive_api_client.dart';

/// Manages Google Drive folder operations
class GoogleDriveFolders {
  // Google Drive folder ID for media storage (loaded from app_secrets.dart)
  static const String mediaFolderId = googleDriveMediaFolderId;

  final GoogleDriveApiClient _apiClient;

  GoogleDriveFolders(this._apiClient);

  /// Gets the root media folder ID (the configured Google Drive folder)
  String getMediaFolderId() => mediaFolderId;

  /// Verifies that the media folder exists and is accessible
  Future<bool> verifyMediaFolder() async {
    try {
      final api = await _apiClient.createApi();
      final folder =
          await api.files.get(mediaFolderId, $fields: 'id,name,mimeType')
              as drive.File;
      return folder.mimeType == 'application/vnd.google-apps.folder';
    } catch (e) {
      mPrint('Error verifying media folder: $e');
      return false;
    }
  }

  /// Ensures a folder exists, creating it if necessary
  Future<String> ensureFolder({
    required String name,
    required String parent,
  }) async {
    final api = await _apiClient.createApi();

    final q =
        "mimeType = 'application/vnd.google-apps.folder' and trashed = false and name = '$name' and '$parent' in parents";
    final found = await api.files.list(
      q: q,
      spaces: 'drive',
      $fields: 'files(id,name)',
    );
    final file = found.files?.isNotEmpty == true ? found.files!.first : null;
    if (file?.id != null) return file!.id!;

    final created = await api.files.create(
      drive.File()
        ..name = name
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = [parent],
      $fields: 'id',
    );
    if (created.id == null) throw StateError('Failed to create folder: $name');
    return created.id!;
  }

  /// Ensures a subfolder exists within the media folder
  /// Handles nested paths like 'tasks/taskId' by creating parent folders first
  Future<String> ensureSubFolder(String folderPath) async {
    final segments = folderPath.split('/');
    String currentParent = mediaFolderId;

    for (final segment in segments) {
      if (segment.isEmpty) continue;
      currentParent = await ensureFolder(name: segment, parent: currentParent);
    }

    return currentParent;
  }

  /// Ensures a task-specific folder exists within the media folder
  Future<String> ensureTaskFolder(String taskId) async {
    // First ensure 'tasks' folder exists
    final tasksFolderId = await ensureFolder(
      name: 'tasks',
      parent: mediaFolderId,
    );
    // Then ensure task-specific folder
    return ensureFolder(name: taskId, parent: tasksFolderId);
  }

  /// Ensures a note-specific folder exists within the media folder
  Future<String> ensureNoteFolder(String noteId) async {
    // First ensure 'notes' folder exists
    final notesFolderId = await ensureFolder(
      name: 'notes',
      parent: mediaFolderId,
    );
    // Then ensure note-specific folder
    return ensureFolder(name: noteId, parent: notesFolderId);
  }
}
