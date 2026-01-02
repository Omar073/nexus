import 'package:flutter/material.dart';
import 'package:nexus/core/services/platform/connectivity_status_service.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/widgets/nexus_card.dart';
import 'package:nexus/features/settings/controllers/settings_connectivity_mixin.dart';
import 'package:nexus/features/settings/controllers/settings_connectivity_helper.dart';
import 'package:nexus/features/settings/views/sections/theme_section.dart';
import 'package:nexus/features/settings/views/sections/task_management_section.dart';
import 'package:nexus/features/settings/views/sections/sync_section.dart';
import 'package:nexus/features/settings/views/sections/connectivity_status_section.dart';
import 'package:nexus/features/settings/views/sections/drive_access_section.dart';
import 'package:nexus/features/settings/views/sections/permissions_section.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(leading: const AppDrawerButton()),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customize your experience',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Profile Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NexusCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 16,
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'O',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Omar',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your account',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section Title - Appearance
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'APPEARANCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NexusCard(
              padding: EdgeInsets.zero,
              borderRadius: 16,
              child: const ThemeSection(),
            ),
          ),
          const SizedBox(height: 24),

          // Section Title - Tasks
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'TASK MANAGEMENT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NexusCard(
              padding: EdgeInsets.zero,
              borderRadius: 16,
              child: const TaskManagementSection(),
            ),
          ),
          const SizedBox(height: 24),

          // Section Title - Sync
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'SYNC & BACKUP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NexusCard(
              padding: EdgeInsets.zero,
              borderRadius: 16,
              child: const SyncSection(),
            ),
          ),
          const SizedBox(height: 24),

          // Section Title - Connectivity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'CONNECTIVITY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NexusCard(
              padding: EdgeInsets.zero,
              borderRadius: 16,
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
          ),
          const SizedBox(height: 24),

          // Section Title - Google Drive
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'CLOUD STORAGE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NexusCard(
              padding: EdgeInsets.zero,
              borderRadius: 16,
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
          ),
          const SizedBox(height: 24),

          // Section Title - Permissions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'PERMISSIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NexusCard(
              padding: EdgeInsets.zero,
              borderRadius: 16,
              child: const PermissionsSection(),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
