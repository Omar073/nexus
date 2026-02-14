import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/core/services/platform/backend_health_checker.dart';

void main() {
  group('BackendHealthChecker', () {
    test('checkFirebaseConnectivity returns connected on success', () async {
      final firestore = FakeFirebaseFirestore();
      final checker = BackendHealthChecker(firestore: firestore);

      final result = await checker.checkFirebaseConnectivity();

      // FakeFirebaseFirestore always succeeds
      expect(result, ConnectivityStatus.connected);
    });

    test('checkGoogleDriveConnectivity returns unknown when null', () async {
      final firestore = FakeFirebaseFirestore();
      final checker = BackendHealthChecker(
        firestore: firestore,
        // googleDriveService is null
      );

      final result = await checker.checkGoogleDriveConnectivity();

      expect(result, ConnectivityStatus.unknown);
    });
  });
}
