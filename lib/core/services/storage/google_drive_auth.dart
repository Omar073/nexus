import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:nexus/core/services/storage/drive_auth_exception.dart';
import 'package:nexus/core/services/storage/drive_auth_store.dart';

/// Handles authentication for Google Drive access
///
/// Manages two layers of authentication:
/// 1. Password gate (device-level authentication)
/// 2. Google Sign-In (user-level authentication for API access)
class GoogleDriveAuth {
  // Required scopes for Google Drive API
  // Using driveScope to access existing folders (driveFileScope only allows access to files created by the app)
  static const List<String> _driveScopes = [drive.DriveApi.driveScope];

  final DriveAuthStore _authStore;
  final GoogleSignIn _googleSignIn;

  GoogleDriveAuth({DriveAuthStore? authStore, GoogleSignIn? googleSignIn})
    : _authStore = authStore ?? DriveAuthStore(),
      _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            scopes: _driveScopes,
            // Web Client ID from google-services.json (client_type: 3)
            serverClientId:
                '994254093528-nlecdt98kcoj6tevbnofjee9jhr6nk8u.apps.googleusercontent.com',
          );

  /// Checks if the device is authenticated (password gate)
  Future<bool> isAuthenticated() => _authStore.isAuthenticated();

  /// Authenticates with password
  Future<bool> authenticate(String password) =>
      _authStore.authenticate(password);

  /// Revokes authentication
  Future<void> revokeAuthentication() => _authStore.revokeAuthentication();

  /// Checks if user is signed in to Google
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Signs in to Google account for Drive API access
  /// Returns true if sign-in was successful
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account != null;
    } catch (e) {
      mPrint('Google Sign-In error: $e');
      return false;
    }
  }

  /// Signs out from Google account and revokes access
  /// Uses disconnect() to fully revoke token (forces new permission prompt on next sign-in)
  Future<void> signOut() async {
    try {
      // Try disconnect first to fully revoke token
      await _googleSignIn.disconnect();
    } catch (e) {
      // Fall back to signOut if disconnect fails
      mPrint('Disconnect failed, falling back to signOut: $e');
      await _googleSignIn.signOut();
    }
  }

  /// Gets the current signed-in user's email
  Future<String?> getSignedInEmail() async {
    final account = await _googleSignIn.signInSilently();
    return account?.email;
  }

  /// Ensures device is authenticated before proceeding
  /// Throws DriveAuthRequiredException if not authenticated
  Future<void> ensureAuthenticated() async {
    if (!await isAuthenticated()) {
      throw const DriveAuthRequiredException(
        'Device not authenticated. Please enter password to access Drive.',
      );
    }
  }

  /// Gets the authenticated Google Sign-In account
  /// Throws DriveAuthRequiredException if not signed in
  Future<GoogleSignInAccount> getAuthenticatedAccount() async {
    await ensureAuthenticated();

    final account = await _googleSignIn.signInSilently();

    if (account == null) {
      throw const DriveAuthRequiredException(
        'Please sign in to your Google account to upload files to Drive.',
      );
    }

    return account;
  }

  /// Gets authentication headers for API requests
  /// Throws DriveAuthRequiredException if not authenticated
  Future<Map<String, String>> getAuthHeaders() async {
    final account = await getAuthenticatedAccount();
    return await account.authHeaders;
  }
}
