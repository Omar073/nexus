import 'package:flutter/material.dart';
import 'package:nexus/core/services/platform/connectivity_status_service.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/widgets/common_snackbar.dart';
import 'package:nexus/core/widgets/drive_password_dialog.dart';
import 'package:provider/provider.dart';

/// Helper class for managing connectivity and Drive operations in settings screen.
class SettingsConnectivityHelper {
  final BuildContext context;
  final ConnectivityStatusService connectivityStatusService;

  SettingsConnectivityHelper({
    required this.context,
    required this.connectivityStatusService,
  });

  /// Refreshes the Drive authentication status
  Future<bool> refreshDrive() async {
    final drive = context.read<GoogleDriveService>();
    try {
      final authenticated = await drive.isAuthenticated();
      return authenticated;
    } catch (_) {
      return false;
    }
  }

  /// Handles Drive authentication via password dialog
  Future<bool> handleAuthenticate() async {
    final drive = context.read<GoogleDriveService>();
    final success = await showDrivePasswordDialog(
      context,
      (password) => drive.authenticate(password),
    );
    return success;
  }

  /// Checks all connectivity statuses (Firebase, Hive, Google Drive)
  Future<void> checkAllConnectivity({
    required bool isCurrentlyChecking,
    required VoidCallback onIsCheckingChanged,
    required ValueChanged<ConnectivityStatus?> onFirebaseStatusChanged,
    required ValueChanged<ConnectivityStatus?> onHiveStatusChanged,
    required ValueChanged<ConnectivityStatus?> onGoogleDriveStatusChanged,
    required ValueChanged<DateTime?> onLastCheckedChanged,
  }) async {
    if (isCurrentlyChecking || !context.mounted) return;

    onIsCheckingChanged();

    try {
      final results = await Future.wait([
        connectivityStatusService.checkFirebaseConnectivity(),
        connectivityStatusService.checkHiveConnectivity(),
        connectivityStatusService.checkGoogleDriveConnectivity(),
      ]);

      if (!context.mounted) return;

      onFirebaseStatusChanged(results[0]);
      onHiveStatusChanged(results[1]);
      onGoogleDriveStatusChanged(results[2]);
      onLastCheckedChanged(DateTime.now());
      onIsCheckingChanged();
    } catch (e) {
      if (context.mounted) {
        context.showSnackbar('Failed to check connectivity: $e', Colors.red);
      }
      onIsCheckingChanged();
    }
  }

  /// Checks Firebase connectivity status
  Future<void> checkFirebaseConnectivity({
    required ValueChanged<ConnectivityStatus?> onFirebaseStatusChanged,
    required ValueChanged<DateTime?> onLastCheckedChanged,
  }) async {
    if (!context.mounted) return;

    onFirebaseStatusChanged(null);

    try {
      final status = await connectivityStatusService
          .checkFirebaseConnectivity();
      if (!context.mounted) return;

      onFirebaseStatusChanged(status);
      onLastCheckedChanged(DateTime.now());

      final message = status == ConnectivityStatus.connected
          ? 'Firebase: Connected'
          : status == ConnectivityStatus.disconnected
          ? 'Firebase: Disconnected'
          : 'Firebase: Unknown status';
      final color = status == ConnectivityStatus.connected
          ? Colors.green
          : status == ConnectivityStatus.disconnected
          ? Colors.red
          : Colors.orange;

      context.showSnackbar(message, color);
    } catch (e) {
      if (!context.mounted) return;
      context.showSnackbar('Failed to check Firebase: $e', Colors.red);
    }
  }

  /// Checks Hive connectivity status
  Future<void> checkHiveConnectivity({
    required ValueChanged<ConnectivityStatus?> onHiveStatusChanged,
    required ValueChanged<DateTime?> onLastCheckedChanged,
  }) async {
    if (!context.mounted) return;

    onHiveStatusChanged(null);

    try {
      final status = await connectivityStatusService.checkHiveConnectivity();
      if (!context.mounted) return;

      onHiveStatusChanged(status);
      onLastCheckedChanged(DateTime.now());

      final message = status == ConnectivityStatus.connected
          ? 'Hive: Available'
          : 'Hive: Unavailable';
      final color = status == ConnectivityStatus.connected
          ? Colors.green
          : Colors.red;

      context.showSnackbar(message, color);
    } catch (e) {
      if (!context.mounted) return;
      context.showSnackbar('Failed to check Hive: $e', Colors.red);
    }
  }

  /// Checks Google Drive connectivity status
  Future<void> checkGoogleDriveConnectivity({
    required ValueChanged<ConnectivityStatus?> onGoogleDriveStatusChanged,
    required ValueChanged<DateTime?> onLastCheckedChanged,
  }) async {
    if (!context.mounted) return;

    onGoogleDriveStatusChanged(null);

    try {
      final status = await connectivityStatusService
          .checkGoogleDriveConnectivity();
      if (!context.mounted) return;

      onGoogleDriveStatusChanged(status);
      onLastCheckedChanged(DateTime.now());

      final message = status == ConnectivityStatus.connected
          ? 'Google Drive: Connected'
          : status == ConnectivityStatus.disconnected
          ? 'Google Drive: Disconnected'
          : 'Google Drive: Unknown status';
      final color = status == ConnectivityStatus.connected
          ? Colors.green
          : status == ConnectivityStatus.disconnected
          ? Colors.red
          : Colors.orange;

      context.showSnackbar(message, color);
    } catch (e) {
      if (!context.mounted) return;
      context.showSnackbar('Failed to check Google Drive: $e', Colors.red);
    }
  }

  /// Handles Google Sign-In flow with callbacks for state updates.
  Future<void> handleGoogleSignIn({
    required VoidCallback onSigningInStart,
    required ValueChanged<bool> onSignInComplete,
    required VoidCallback onRefreshStatus,
  }) async {
    final drive = context.read<GoogleDriveService>();

    onSigningInStart();

    try {
      final success = await drive.signIn();
      if (!context.mounted) return;

      onSignInComplete(success);

      if (success) {
        onRefreshStatus();
        context.showSnackbar('Connected to Google Drive', Colors.green);
      } else {
        context.showSnackbar('Failed to connect to Google Drive', Colors.red);
      }
    } catch (e) {
      if (!context.mounted) return;
      onSignInComplete(false);
      context.showSnackbar('Error connecting: $e', Colors.red);
    }
  }

  /// Handles Google Sign-Out flow with callbacks for state updates.
  Future<void> handleGoogleSignOut({
    required VoidCallback onSignOutComplete,
    required VoidCallback onRefreshStatus,
  }) async {
    final drive = context.read<GoogleDriveService>();
    await drive.signOut();

    if (!context.mounted) return;

    onSignOutComplete();
    onRefreshStatus();
    context.showSnackbar('Disconnected from Google Drive', Colors.orange);
  }

  /// Handles revoking Drive authentication.
  Future<void> handleRevoke({
    required Future<void> Function() onRefreshDriveStatus,
  }) async {
    final drive = context.read<GoogleDriveService>();
    await drive.revokeAuthentication();
    await onRefreshDriveStatus();
  }

  /// Refreshes Drive status including password auth and Google Sign-In.
  Future<({bool authenticated, bool signedIn})> refreshDriveStatus() async {
    final drive = context.read<GoogleDriveService>();
    final authenticated = await refreshDrive();
    final signedIn = await drive.isSignedIn();
    return (authenticated: authenticated, signedIn: signedIn);
  }
}
