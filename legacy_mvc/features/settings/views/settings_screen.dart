import 'package:flutter/material.dart';
import 'package:nexus/core/services/platform/backend_health_checker.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/features/settings/controllers/settings_connectivity_mixin.dart';
import 'package:nexus/features/settings/controllers/settings_connectivity_helper.dart';
import 'package:nexus/features/settings/controllers/settings_controller.dart';
import 'package:nexus/features/settings/views/sections/theme_section.dart';
import 'package:nexus/features/settings/views/sections/task_management_section.dart';
import 'package:nexus/features/settings/views/sections/sync_section.dart';
import 'package:nexus/features/settings/views/sections/connectivity_status_section.dart';
import 'package:nexus/features/settings/views/sections/drive_access_section.dart';
import 'package:nexus/features/settings/views/sections/permissions_section.dart';
import 'package:nexus/features/settings/views/widgets/settings_header.dart';
import 'package:nexus/features/settings/views/widgets/settings_section.dart';
import 'package:nexus/core/widgets/app_drawer_button.dart';

import 'package:provider/provider.dart';

/// Settings screen following Nexus design system.
/// Features large header, profile section, grouped settings.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SettingsConnectivityMixin {
  BackendHealthChecker get connectivityService =>
      context.read<BackendHealthChecker>();

  GoogleDriveService get driveService => context.read<GoogleDriveService>();

  @override
  void initState() {
    super.initState();
    initConnectivity(
      SettingsConnectivityHelper(
        context: context,
        connectivityStatusService: connectivityService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navBarStyle = context.watch<SettingsController>().navBarStyle;

    return Scaffold(
      appBar: AppBar(leading: const AppDrawerButton()),
      body: ListView(
        padding: EdgeInsets.only(bottom: navBarStyle.contentPadding),
        children: [
          const SettingsHeader(),
          const SizedBox(height: 24),

          const SettingsSection(title: 'Appearance', child: ThemeSection()),
          const SizedBox(height: 24),

          const SettingsSection(
            title: 'Task Management',
            child: TaskManagementSection(),
          ),
          const SizedBox(height: 24),

          const SettingsSection(title: 'Sync & Backup', child: SyncSection()),
          const SizedBox(height: 24),

          SettingsSection(
            title: 'Connectivity',
            child: ConnectivityStatusSection(
              firebaseStatus: firebaseStatus,
              hiveStatus: hiveStatus,
              googleDriveStatus: googleDriveStatus,
              lastChecked: lastChecked,
              isChecking: isChecking,
              onRefreshFirebase: refreshFirebaseStatus,
              onRefreshHive: refreshHiveStatus,
              onRefreshGoogleDrive: refreshGoogleDriveStatus,
            ),
          ),
          const SizedBox(height: 24),

          SettingsSection(
            title: 'Cloud Storage',
            child: DriveAccessSection(
              isAuthenticated: driveAuthenticated,
              isGoogleSignedIn: isGoogleSignedIn,
              isSigningIn: isSigningIn,
              onAuthenticate: handleAuthenticate,
              onRevoke: handleRevoke,
              onGoogleSignIn: handleGoogleSignIn,
              onGoogleSignOut: handleGoogleSignOut,
            ),
          ),
          const SizedBox(height: 24),

          const SettingsSection(
            title: 'Permissions',
            child: PermissionsSection(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
