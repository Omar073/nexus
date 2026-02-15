import 'package:nexus/core/services/storage/google_drive_service.dart';

/// No-op stub for [GoogleDriveService].
///
/// Returns controllable values for auth and connectivity checks.
class FakeGoogleDriveService extends GoogleDriveService {
  bool authenticated = false;
  bool signedIn = false;
  bool folderExists = true;

  @override
  Future<bool> isAuthenticated() async => authenticated;
  @override
  Future<bool> isSignedIn() async => signedIn;
  @override
  Future<bool> verifyMediaFolder() async => folderExists;
}
