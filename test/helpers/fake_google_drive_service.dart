/// No-op stub for [GoogleDriveService].
///
/// Returns controllable values for auth and connectivity checks.
class FakeGoogleDriveService {
  bool authenticated = false;
  bool signedIn = false;
  bool folderExists = true;

  Future<bool> isAuthenticated() async => authenticated;
  Future<bool> isSignedIn() async => signedIn;
  Future<bool> verifyMediaFolder() async => folderExists;
}
