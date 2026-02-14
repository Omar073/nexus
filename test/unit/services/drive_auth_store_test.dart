import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus/core/services/storage/drive_auth_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DriveAuthStore', () {
    test('isAuthenticated returns false initially', () async {
      final store = DriveAuthStore();
      expect(await store.isAuthenticated(), isFalse);
    });

    test('authenticate with correct password returns true', () async {
      final store = DriveAuthStore();
      final password = store.getDefaultPassword();

      final result = await store.authenticate(password);

      expect(result, isTrue);
      expect(await store.isAuthenticated(), isTrue);
    });

    test('authenticate with wrong password returns false', () async {
      final store = DriveAuthStore();

      final result = await store.authenticate('wrong-password');

      expect(result, isFalse);
      expect(await store.isAuthenticated(), isFalse);
    });

    test('revokeAuthentication clears flag', () async {
      final store = DriveAuthStore();
      final password = store.getDefaultPassword();
      await store.authenticate(password);
      expect(await store.isAuthenticated(), isTrue);

      await store.revokeAuthentication();

      expect(await store.isAuthenticated(), isFalse);
    });
  });
}
