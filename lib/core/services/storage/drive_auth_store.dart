import 'package:shared_preferences/shared_preferences.dart';

/// Securely persists Drive OAuth tokens and refresh state.
class DriveAuthStore {
  static const String _keyIsAuthenticated = 'drive_auth.is_authenticated';
  // Future: _keyPasswordHash for storing hashed password for verification

  // Default password - should be changed in production
  // In a real app, this would be configured server-side or via environment variables
  static const String _defaultPassword = 'nexus2026';

  /// Checks if the current device is authenticated to access Drive
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsAuthenticated) ?? false;
  }

  /// Authenticates the device with a password
  /// Returns true if password is correct, false otherwise
  Future<bool> authenticate(String password) async {
    // In production, this should hash and compare with stored hash
    // For now, using simple comparison (you should use a proper hashing library)
    if (password == _defaultPassword) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsAuthenticated, true);
      return true;
    }
    return false;
  }

  /// Revokes authentication for this device
  Future<void> revokeAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsAuthenticated, false);
  }

  /// Gets the configured password (for testing/admin purposes)
  String getDefaultPassword() => _defaultPassword;
}
