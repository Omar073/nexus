import 'package:flutter/material.dart';
import 'package:nexus/core/services/platform/connectivity_status_service.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/features/settings/controllers/settings_connectivity_mixin.dart';
import 'package:nexus/features/settings/controllers/settings_connectivity_helper.dart';
import 'package:nexus/features/settings/views/sections/theme_section.dart';
import 'package:nexus/features/settings/views/sections/task_management_section.dart';
import 'package:nexus/features/settings/views/sections/sync_section.dart';
import 'package:nexus/features/settings/views/sections/connectivity_status_section.dart';
import 'package:nexus/features/settings/views/sections/drive_access_section.dart';
import 'package:nexus/features/settings/views/sections/permissions_section.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SettingsConnectivityMixin {
  @override
  void initState() {
    super.initState();
    final connectivityStatusService = ConnectivityStatusService(
      googleDriveService: context.read<GoogleDriveService>(),
    );
    initConnectivity(
      SettingsConnectivityHelper(
        context: context,
        connectivityStatusService: connectivityStatusService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ThemeSection(),
          const SizedBox(height: 24),
          const TaskManagementSection(),
          const SizedBox(height: 24),
          const SyncSection(),
          const SizedBox(height: 24),
          ConnectivityStatusSection(
            firebaseStatus: firebaseStatus,
            hiveStatus: hiveStatus,
            googleDriveStatus: googleDriveStatus,
            lastChecked: lastChecked,
            isChecking: isChecking,
            onRefreshFirebase: refreshFirebaseStatus,
            onRefreshHive: refreshHiveStatus,
            onRefreshGoogleDrive: refreshGoogleDriveStatus,
          ),
          const SizedBox(height: 24),
          DriveAccessSection(
            isAuthenticated: driveAuthenticated,
            isGoogleSignedIn: isGoogleSignedIn,
            isSigningIn: isSigningIn,
            onAuthenticate: handleAuthenticate,
            onRevoke: handleRevoke,
            onGoogleSignIn: handleGoogleSignIn,
            onGoogleSignOut: handleGoogleSignOut,
          ),
          const SizedBox(height: 24),
          const PermissionsSection(),
        ],
      ),
    );
  }
}
