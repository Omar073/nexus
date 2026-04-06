import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';

/// Result of a connectivity check
enum ConnectivityStatus { connected, disconnected, unknown }

/// Service for checking connectivity status of various backend services.
///
/// Unlike [ConnectivityService] which tracks network on/off state,
/// this class performs actual health checks against specific backends
/// (Firebase, Hive, Google Drive) to verify they are reachable and functional.
class BackendHealthChecker {
  BackendHealthChecker({
    FirebaseFirestore? firestore,
    GoogleDriveService? googleDriveService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _googleDriveService = googleDriveService;

  final FirebaseFirestore _firestore;
  final GoogleDriveService? _googleDriveService;

  /// Checks Firebase/Firestore connectivity
  ///
  /// Returns [ConnectivityStatus.connected] if Firebase is reachable,
  /// [ConnectivityStatus.disconnected] if not, or [ConnectivityStatus.unknown] on error
  Future<ConnectivityStatus> checkFirebaseConnectivity() async {
    mDebugPrint('[BackendHealthChecker] Checking Firebase connectivity...');
    try {
      // Try to read a non-existent document with a timeout
      // This will fail quickly if offline, or succeed if online
      await _firestore
          .collection('_connectivity_check')
          .doc('_test')
          .get(const GetOptions(source: Source.server))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Firebase connectivity check timed out');
            },
          );

      // If we get here, Firebase is reachable
      mDebugPrint('[BackendHealthChecker] Firebase: CONNECTED');
      return ConnectivityStatus.connected;
    } on TimeoutException {
      mDebugPrint('[BackendHealthChecker] Firebase: DISCONNECTED (timeout)');
      return ConnectivityStatus.disconnected;
    } catch (e) {
      mDebugPrint('[BackendHealthChecker] Firebase check error: $e');
      // Check if it's a network error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('network') ||
          errorString.contains('unavailable') ||
          errorString.contains('failed host lookup')) {
        mDebugPrint(
          '[BackendHealthChecker] Firebase: DISCONNECTED (network error)',
        );
        return ConnectivityStatus.disconnected;
      }
      // Other errors might indicate connectivity issues
      mDebugPrint('[BackendHealthChecker] Firebase: UNKNOWN (other error)');
      return ConnectivityStatus.unknown;
    }
  }

  /// Checks Hive (local storage) connectivity/availability
  ///
  /// Returns [ConnectivityStatus.connected] if Hive boxes are accessible,
  /// [ConnectivityStatus.disconnected] if not
  Future<ConnectivityStatus> checkHiveConnectivity() async {
    mDebugPrint('[BackendHealthChecker] Checking Hive connectivity...');
    try {
      // Check if main boxes are open (already opened during app init)
      final tasksOpen = Hive.isBoxOpen(HiveBoxes.tasks);
      final notesOpen = Hive.isBoxOpen(HiveBoxes.notes);
      final syncOpsOpen = Hive.isBoxOpen(HiveBoxes.syncOps);

      mDebugPrint(
        '[BackendHealthChecker] Boxes open status: tasks=$tasksOpen, notes=$notesOpen, syncOps=$syncOpsOpen',
      );

      if (tasksOpen && notesOpen && syncOpsOpen) {
        mDebugPrint('[BackendHealthChecker] Hive: CONNECTED');
        return ConnectivityStatus.connected;
      } else {
        mDebugPrint(
          '[BackendHealthChecker] Hive: DISCONNECTED (some boxes not open)',
        );
        return ConnectivityStatus.disconnected;
      }
    } catch (e) {
      mDebugPrint('[BackendHealthChecker] Hive check error: $e');
      mDebugPrint('[BackendHealthChecker] Hive: DISCONNECTED');
      return ConnectivityStatus.disconnected;
    }
  }

  /// Checks Google Drive connectivity
  ///
  /// Returns [ConnectivityStatus.connected] if Google Drive is reachable and authenticated,
  /// [ConnectivityStatus.disconnected] if not authenticated or unreachable,
  /// or [ConnectivityStatus.unknown] on error
  Future<ConnectivityStatus> checkGoogleDriveConnectivity() async {
    mDebugPrint('[BackendHealthChecker] Checking Google Drive connectivity...');
    final googleDriveService = _googleDriveService;
    if (googleDriveService == null) {
      mDebugPrint(
        '[BackendHealthChecker] GoogleDriveService is null - UNKNOWN',
      );
      return ConnectivityStatus.unknown;
    }

    try {
      // Check if authenticated (password gate)
      mDebugPrint(
        '[BackendHealthChecker] Checking isAuthenticated (password gate)...',
      );
      final isAuthenticated = await googleDriveService.isAuthenticated();
      mDebugPrint('[BackendHealthChecker] isAuthenticated: $isAuthenticated');
      if (!isAuthenticated) {
        mDebugPrint(
          '[BackendHealthChecker] Google Drive: DISCONNECTED (not authenticated via password)',
        );
        return ConnectivityStatus.disconnected;
      }

      // Check if signed in to Google (for API access)
      mDebugPrint(
        '[BackendHealthChecker] Checking isSignedIn (Google Sign-In)...',
      );
      final isSignedIn = await googleDriveService.isSignedIn();
      mDebugPrint('[BackendHealthChecker] isSignedIn: $isSignedIn');
      if (!isSignedIn) {
        mDebugPrint(
          '[BackendHealthChecker] Google Drive: DISCONNECTED (not signed into Google)',
        );
        return ConnectivityStatus.disconnected;
      }

      // Try to verify the media folder exists (lightweight API call)
      mDebugPrint('[BackendHealthChecker] Verifying media folder...');
      final folderExists = await googleDriveService.verifyMediaFolder().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          mDebugPrint('[BackendHealthChecker] verifyMediaFolder timed out');
          return false;
        },
      );
      mDebugPrint('[BackendHealthChecker] folderExists: $folderExists');

      if (folderExists) {
        mDebugPrint('[BackendHealthChecker] Google Drive: CONNECTED');
        return ConnectivityStatus.connected;
      } else {
        mDebugPrint(
          '[BackendHealthChecker] Google Drive: DISCONNECTED (folder not found or inaccessible)',
        );
        return ConnectivityStatus.disconnected;
      }
    } on TimeoutException {
      mDebugPrint(
        '[BackendHealthChecker] Google Drive: DISCONNECTED (timeout)',
      );
      return ConnectivityStatus.disconnected;
    } catch (e) {
      mDebugPrint('[BackendHealthChecker] Google Drive check error: $e');
      // Check if it's a network error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('network') ||
          errorString.contains('unavailable') ||
          errorString.contains('failed host lookup')) {
        mDebugPrint(
          '[BackendHealthChecker] Google Drive: DISCONNECTED (network error)',
        );
        return ConnectivityStatus.disconnected;
      }
      mDebugPrint('[BackendHealthChecker] Google Drive: UNKNOWN (other error)');
      return ConnectivityStatus.unknown;
    }
  }
}
