import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:nexus/core/services/storage/google_drive_api_client.dart';
import 'package:nexus/core/services/storage/google_drive_folders.dart';

/// Upload, download, and delete file operations on Drive.
class GoogleDriveFiles {
  final GoogleDriveApiClient _apiClient;
  final GoogleDriveFolders _folders;

  GoogleDriveFiles(this._apiClient, this._folders);

  /// Uploads a file to the media folder (optionally in a subfolder)
  Future<String> uploadFile({
    required File file,
    required String filename,
    required String mimeType,
    String?
    parentFolderId, // Direct folder ID, or null to use root media folder
  }) async {
    final api = await _apiClient.createApi();
    final parentId = parentFolderId ?? GoogleDriveFolders.mediaFolderId;

    final length = await file.length();
    final media = drive.Media(file.openRead(), length, contentType: mimeType);

    final created = await api.files.create(
      drive.File()
        ..name = filename
        ..parents = [parentId],
      uploadMedia: media,
      $fields: 'id,name,webViewLink,webContentLink',
    );
    if (created.id == null) throw StateError('Upload failed (no file id).');
    return created.id!;
  }

  /// Uploads a file for a specific task
  Future<String> uploadTaskFile({
    required String taskId,
    required File file,
    required String filename,
    required String mimeType,
  }) async {
    final parentId = await _folders.ensureTaskFolder(taskId);
    return uploadFile(
      file: file,
      filename: filename,
      mimeType: mimeType,
      parentFolderId: parentId,
    );
  }

  /// Uploads a file for a specific note
  Future<String> uploadNoteFile({
    required String noteId,
    required File file,
    required String filename,
    required String mimeType,
  }) async {
    final parentId = await _folders.ensureNoteFolder(noteId);
    return uploadFile(
      file: file,
      filename: filename,
      mimeType: mimeType,
      parentFolderId: parentId,
    );
  }

  /// Uploads a media file directly to the root media folder
  Future<String> uploadMediaFile({
    required File file,
    required String filename,
    required String mimeType,
  }) async {
    return uploadFile(
      file: file,
      filename: filename,
      mimeType: mimeType,
      parentFolderId: null, // Uses root media folder
    );
  }

  /// Lists all files in the media folder (optionally filtered by subfolder)
  Future<List<drive.File>> listFiles({String? subfolder}) async {
    final api = await _apiClient.createApi();
    final parentId = subfolder != null
        ? await _folders.ensureSubFolder(subfolder)
        : GoogleDriveFolders.mediaFolderId;

    final query = "'$parentId' in parents and trashed = false";
    final response = await api.files.list(
      q: query,
      $fields:
          'files(id,name,mimeType,size,createdTime,modifiedTime,webViewLink,webContentLink)',
    );

    return response.files ?? [];
  }

  /// Lists all files for a specific task
  Future<List<drive.File>> listTaskFiles(String taskId) async {
    final api = await _apiClient.createApi();
    final taskFolderId = await _folders.ensureTaskFolder(taskId);
    final query = "'$taskFolderId' in parents and trashed = false";
    final response = await api.files.list(
      q: query,
      $fields:
          'files(id,name,mimeType,size,createdTime,modifiedTime,webViewLink,webContentLink)',
    );
    return response.files ?? [];
  }

  /// Lists all files for a specific note
  Future<List<drive.File>> listNoteFiles(String noteId) async {
    final api = await _apiClient.createApi();
    final noteFolderId = await _folders.ensureNoteFolder(noteId);
    final query = "'$noteFolderId' in parents and trashed = false";
    final response = await api.files.list(
      q: query,
      $fields:
          'files(id,name,mimeType,size,createdTime,modifiedTime,webViewLink,webContentLink)',
    );
    return response.files ?? [];
  }

  /// Gets file metadata by ID
  Future<drive.File> getFile(String driveFileId) async {
    final api = await _apiClient.createApi();
    return await api.files.get(
          driveFileId,
          $fields:
              'id,name,mimeType,size,createdTime,modifiedTime,webViewLink,webContentLink',
        )
        as drive.File;
  }

  /// Gets a download URL for a file using public Google Drive URL
  /// Works for publicly shared files without authentication
  String getDownloadUrl(String driveFileId) {
    return 'https://drive.google.com/uc?export=download&id=$driveFileId';
  }

  /// Gets a view URL for a file
  Future<String?> getViewUrl(String driveFileId) async {
    try {
      final file = await getFile(driveFileId);
      return file.webViewLink;
    } catch (e) {
      mDebugPrint('Error getting view URL: $e');
      return null;
    }
  }

  /// Downloads a file from Google Drive using public URL (no authentication required)
  /// This works for publicly shared files in the Drive folder
  Future<void> downloadFile({
    required String driveFileId,
    required File destination,
  }) async {
    final downloadUrl = getDownloadUrl(driveFileId);
    final httpClient = HttpClient();

    try {
      mDebugPrint('Downloading file from Drive: $downloadUrl');
      final request = await httpClient.getUrl(Uri.parse(downloadUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw HttpException(
          'Failed to download file from Drive: HTTP ${response.statusCode}',
          uri: Uri.parse(downloadUrl),
        );
      }

      // Read response bytes and write to file
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }

      mDebugPrint(
        'Downloaded ${bytes.length} bytes, writing to ${destination.path}',
      );

      // Ensure destination directory exists
      await destination.parent.create(recursive: true);

      // Write bytes to file
      await destination.writeAsBytes(bytes, flush: true);
      mDebugPrint('File successfully downloaded to ${destination.path}');
    } on HttpException catch (e) {
      mDebugPrint('HTTP error downloading file: $e');
      rethrow;
    } on SocketException catch (e) {
      mDebugPrint('Network error downloading file: $e');
      rethrow;
    } catch (e) {
      mDebugPrint('Error downloading file: $e');
      rethrow;
    } finally {
      httpClient.close();
    }
  }

  /// Deletes a file from Google Drive (requires authentication)
  Future<void> deleteFile(String driveFileId) async {
    final api = await _apiClient.createApi();
    await api.files.delete(driveFileId);
  }
}
