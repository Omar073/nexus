import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:nexus/core/services/storage/drive_auth_store.dart';
import 'package:nexus/core/services/storage/google_drive_api_client.dart';
import 'package:nexus/core/services/storage/google_drive_auth.dart';
import 'package:nexus/core/services/storage/google_drive_files.dart';
import 'package:nexus/core/services/storage/google_drive_folders.dart';

/// Main service for Google Drive operations
///
/// This is a facade that delegates to specialized modules:
/// - [GoogleDriveAuth]: Authentication (password gate + Google Sign-In)
/// - [GoogleDriveApiClient]: API client creation
/// - [GoogleDriveFolders]: Folder management
/// - [GoogleDriveFiles]: File operations (upload, download, list, delete)
class GoogleDriveService {
  final GoogleDriveAuth _auth;
  final GoogleDriveFolders _folders;
  final GoogleDriveFiles _files;

  GoogleDriveService({DriveAuthStore? authStore, GoogleSignIn? googleSignIn})
    : _auth = GoogleDriveAuth(authStore: authStore, googleSignIn: googleSignIn),
      _folders = GoogleDriveFolders(
        GoogleDriveApiClient(
          GoogleDriveAuth(authStore: authStore, googleSignIn: googleSignIn),
        ),
      ),
      _files = GoogleDriveFiles(
        GoogleDriveApiClient(
          GoogleDriveAuth(authStore: authStore, googleSignIn: googleSignIn),
        ),
        GoogleDriveFolders(
          GoogleDriveApiClient(
            GoogleDriveAuth(authStore: authStore, googleSignIn: googleSignIn),
          ),
        ),
      );

  // ============================================================================
  // Authentication Methods (delegated to GoogleDriveAuth)
  // ============================================================================

  /// Checks if the device is authenticated (password gate)
  Future<bool> isAuthenticated() => _auth.isAuthenticated();

  /// Authenticates with password
  Future<bool> authenticate(String password) => _auth.authenticate(password);

  /// Revokes authentication
  Future<void> revokeAuthentication() => _auth.revokeAuthentication();

  /// Checks if user is signed in to Google
  Future<bool> isSignedIn() => _auth.isSignedIn();

  /// Signs in to Google account for Drive API access
  Future<bool> signIn() => _auth.signIn();

  /// Signs out from Google account
  Future<void> signOut() => _auth.signOut();

  /// Gets the current signed-in user's email
  Future<String?> getSignedInEmail() => _auth.getSignedInEmail();

  // ============================================================================
  // Folder Methods (delegated to GoogleDriveFolders)
  // ============================================================================

  /// Gets the root media folder ID (the configured Google Drive folder)
  String getMediaFolderId() => _folders.getMediaFolderId();

  /// Verifies that the media folder exists and is accessible
  Future<bool> verifyMediaFolder() => _folders.verifyMediaFolder();

  /// Ensures a subfolder exists within the media folder
  Future<String> ensureSubFolder(String folderPath) =>
      _folders.ensureSubFolder(folderPath);

  /// Ensures a task-specific folder exists within the media folder
  Future<String> ensureTaskFolder(String taskId) =>
      _folders.ensureTaskFolder(taskId);

  /// Ensures a note-specific folder exists within the media folder
  Future<String> ensureNoteFolder(String noteId) =>
      _folders.ensureNoteFolder(noteId);

  // ============================================================================
  // File Methods (delegated to GoogleDriveFiles)
  // ============================================================================

  /// Uploads a file to the media folder (optionally in a subfolder)
  Future<String> uploadFile({
    required File file,
    required String filename,
    required String mimeType,
    String? parentFolderId,
  }) => _files.uploadFile(
    file: file,
    filename: filename,
    mimeType: mimeType,
    parentFolderId: parentFolderId,
  );

  /// Uploads a file for a specific task
  Future<String> uploadTaskFile({
    required String taskId,
    required File file,
    required String filename,
    required String mimeType,
  }) => _files.uploadTaskFile(
    taskId: taskId,
    file: file,
    filename: filename,
    mimeType: mimeType,
  );

  /// Uploads a file for a specific note
  Future<String> uploadNoteFile({
    required String noteId,
    required File file,
    required String filename,
    required String mimeType,
  }) => _files.uploadNoteFile(
    noteId: noteId,
    file: file,
    filename: filename,
    mimeType: mimeType,
  );

  /// Uploads a media file directly to the root media folder
  Future<String> uploadMediaFile({
    required File file,
    required String filename,
    required String mimeType,
  }) => _files.uploadMediaFile(
    file: file,
    filename: filename,
    mimeType: mimeType,
  );

  /// Lists all files in the media folder (optionally filtered by subfolder)
  Future<List<drive.File>> listFiles({String? subfolder}) =>
      _files.listFiles(subfolder: subfolder);

  /// Lists all files for a specific task
  Future<List<drive.File>> listTaskFiles(String taskId) =>
      _files.listTaskFiles(taskId);

  /// Lists all files for a specific note
  Future<List<drive.File>> listNoteFiles(String noteId) =>
      _files.listNoteFiles(noteId);

  /// Gets file metadata by ID
  Future<drive.File> getFile(String driveFileId) => _files.getFile(driveFileId);

  /// Gets a download URL for a file using public Google Drive URL
  String getDownloadUrl(String driveFileId) =>
      _files.getDownloadUrl(driveFileId);

  /// Gets a view URL for a file
  Future<String?> getViewUrl(String driveFileId) =>
      _files.getViewUrl(driveFileId);

  /// Downloads a file from Google Drive using public URL
  Future<void> downloadFile({
    required String driveFileId,
    required File destination,
  }) => _files.downloadFile(driveFileId: driveFileId, destination: destination);

  /// Deletes a file from Google Drive (requires authentication)
  Future<void> deleteFile(String driveFileId) => _files.deleteFile(driveFileId);
}
