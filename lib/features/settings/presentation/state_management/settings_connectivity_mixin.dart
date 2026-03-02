import 'package:flutter/material.dart';
import 'package:nexus/core/services/platform/backend_health_checker.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_connectivity_helper.dart';

/// Mixin providing connectivity state management for settings screen.
mixin SettingsConnectivityMixin<T extends StatefulWidget> on State<T> {
  bool driveAuthenticated = false;
  bool isGoogleSignedIn = false;
  bool isSigningIn = false;

  ConnectivityStatus? firebaseStatus;
  ConnectivityStatus? hiveStatus;
  ConnectivityStatus? googleDriveStatus;
  DateTime? lastChecked;
  bool isChecking = false;

  late SettingsConnectivityHelper connectivityHelper;

  /// Call this in initState after creating the helper.
  void initConnectivity(SettingsConnectivityHelper helper) {
    connectivityHelper = helper;
    refreshDriveStatus();
    checkAllConnectivity();
  }

  void safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void checkAllConnectivity() {
    connectivityHelper.checkAllConnectivity(
      isCurrentlyChecking: isChecking,
      onIsCheckingChanged: () => safeSetState(() => isChecking = !isChecking),
      onFirebaseStatusChanged: (s) => safeSetState(() => firebaseStatus = s),
      onHiveStatusChanged: (s) => safeSetState(() => hiveStatus = s),
      onGoogleDriveStatusChanged: (s) =>
          safeSetState(() => googleDriveStatus = s),
      onLastCheckedChanged: (t) => safeSetState(() => lastChecked = t),
    );
  }

  void refreshFirebaseStatus() {
    connectivityHelper.checkFirebaseConnectivity(
      onFirebaseStatusChanged: (s) => safeSetState(() => firebaseStatus = s),
      onLastCheckedChanged: (t) => safeSetState(() => lastChecked = t),
    );
  }

  void refreshHiveStatus() {
    connectivityHelper.checkHiveConnectivity(
      onHiveStatusChanged: (s) => safeSetState(() => hiveStatus = s),
      onLastCheckedChanged: (t) => safeSetState(() => lastChecked = t),
    );
  }

  void refreshGoogleDriveStatus() {
    connectivityHelper.checkGoogleDriveConnectivity(
      onGoogleDriveStatusChanged: (s) =>
          safeSetState(() => googleDriveStatus = s),
      onLastCheckedChanged: (t) => safeSetState(() => lastChecked = t),
    );
  }

  Future<void> handleAuthenticate() async {
    final success = await connectivityHelper.handleAuthenticate();
    if (success && mounted) {
      final authenticated = await connectivityHelper.refreshDrive();
      safeSetState(() => driveAuthenticated = authenticated);
      refreshGoogleDriveStatus();
    }
  }

  Future<void> handleRevoke() async {
    await connectivityHelper.handleRevoke(
      onRefreshDriveStatus: refreshDriveStatus,
    );
  }

  Future<void> refreshDriveStatus() async {
    final result = await connectivityHelper.refreshDriveStatus();
    safeSetState(() {
      driveAuthenticated = result.authenticated;
      isGoogleSignedIn = result.signedIn;
    });
  }

  Future<void> handleGoogleSignIn() async {
    await connectivityHelper.handleGoogleSignIn(
      onSigningInStart: () => safeSetState(() => isSigningIn = true),
      onSignInComplete: (success) => safeSetState(() {
        isGoogleSignedIn = success;
        isSigningIn = false;
      }),
      onRefreshStatus: refreshGoogleDriveStatus,
    );
  }

  Future<void> handleGoogleSignOut() async {
    await connectivityHelper.handleGoogleSignOut(
      onSignOutComplete: () => safeSetState(() => isGoogleSignedIn = false),
      onRefreshStatus: refreshGoogleDriveStatus,
    );
  }
}
