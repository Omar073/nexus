import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:nexus/core/services/storage/google_drive_auth.dart';

/// Creates and manages authenticated Google Drive API clients
class GoogleDriveApiClient {
  final GoogleDriveAuth _auth;

  GoogleDriveApiClient(this._auth);

  /// Creates an authenticated HTTP client for Google Drive API
  /// 
  /// IMPORTANT: Even though the Drive folder is set to "anyone with link can edit",
  /// the Google Drive API still requires authentication for ALL API calls, including uploads.
  /// Folder permissions (public/private) only affect web UI access, not API access.
  /// 
  /// NOTE: This is only needed for WRITE operations (upload, delete, create folders).
  /// READ operations (download) use public URLs and don't require authentication.
  /// 
  /// Throws DriveAuthRequiredException if user is not authenticated.
  Future<http.Client> createAuthenticatedClient() async {
    final authHeaders = await _auth.getAuthHeaders();
    return _AuthenticatedHttpClient(http.Client(), authHeaders);
  }

  /// Creates Drive API instance with authentication
  Future<drive.DriveApi> createApi() async {
    final client = await createAuthenticatedClient();
    return drive.DriveApi(client);
  }
}

/// HTTP client wrapper that adds Google authentication headers to requests
class _AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _authHeaders;

  _AuthenticatedHttpClient(this._inner, this._authHeaders);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Add auth headers to the request
    _authHeaders.forEach((key, value) {
      request.headers[key] = value;
    });
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}

