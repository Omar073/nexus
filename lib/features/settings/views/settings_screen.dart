import 'package:flutter/material.dart';
import 'package:nexus/core/extensions/l10n_x.dart';
import 'package:nexus/core/services/platform/connectivity_status_service.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/features/settings/controllers/settings_connectivity_utils.dart';
import 'package:nexus/features/settings/views/theme_section.dart';
import 'package:nexus/features/settings/views/task_management_section.dart';
import 'package:nexus/features/settings/views/sync_section.dart';
import 'package:nexus/features/settings/views/connectivity_status_section.dart';
import 'package:nexus/features/settings/views/drive_access_section.dart';
import 'package:nexus/features/settings/views/permissions_section.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _driveAuthenticated = false;
  bool _isGoogleSignedIn = false;
  bool _isSigningIn = false;

  // Connectivity status
  ConnectivityStatus? _firebaseStatus;
  ConnectivityStatus? _hiveStatus;
  ConnectivityStatus? _googleDriveStatus;
  DateTime? _lastChecked;
  bool _isChecking = false;

  late SettingsConnectivityHelper _connectivityHelper;

  @override
  void initState() {
    super.initState();
    final connectivityStatusService = ConnectivityStatusService(
      googleDriveService: context.read<GoogleDriveService>(),
    );
    _connectivityHelper = SettingsConnectivityHelper(
      context: context,
      connectivityStatusService: connectivityStatusService,
    );
    // Refresh Drive authentication and Google Sign-In status
    _refreshDriveStatus();
    // Check all connectivity statuses
    _connectivityHelper.checkAllConnectivity(
      isCurrentlyChecking: _isChecking,
      onIsCheckingChanged: () {
        if (mounted) {
          setState(() {
            _isChecking = !_isChecking;
          });
        }
      },
      onFirebaseStatusChanged: (status) {
        if (mounted) {
          setState(() {
            _firebaseStatus = status;
          });
        }
      },
      onHiveStatusChanged: (status) {
        if (mounted) {
          setState(() {
            _hiveStatus = status;
          });
        }
      },
      onGoogleDriveStatusChanged: (status) {
        if (mounted) {
          setState(() {
            _googleDriveStatus = status;
          });
        }
      },
      onLastCheckedChanged: (lastChecked) {
        if (mounted) {
          setState(() {
            _lastChecked = lastChecked;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
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
            firebaseStatus: _firebaseStatus,
            hiveStatus: _hiveStatus,
            googleDriveStatus: _googleDriveStatus,
            lastChecked: _lastChecked,
            isChecking: _isChecking,
            onRefreshFirebase: _refreshFirebaseStatus,
            onRefreshHive: _refreshHiveStatus,
            onRefreshGoogleDrive: _refreshGoogleDriveStatus,
          ),
          const SizedBox(height: 24),
          DriveAccessSection(
            isAuthenticated: _driveAuthenticated,
            isGoogleSignedIn: _isGoogleSignedIn,
            isSigningIn: _isSigningIn,
            onAuthenticate: _handleAuthenticate,
            onRevoke: _handleRevoke,
            onGoogleSignIn: _handleGoogleSignIn,
            onGoogleSignOut: _handleGoogleSignOut,
          ),
          const SizedBox(height: 24),
          const PermissionsSection(),
        ],
      ),
    );
  }

  void _refreshFirebaseStatus() {
    _connectivityHelper.checkFirebaseConnectivity(
      onFirebaseStatusChanged: (status) {
        if (mounted) {
          setState(() {
            _firebaseStatus = status;
          });
        }
      },
      onLastCheckedChanged: (lastChecked) {
        if (mounted) {
          setState(() {
            _lastChecked = lastChecked;
          });
        }
      },
    );
  }

  void _refreshHiveStatus() {
    _connectivityHelper.checkHiveConnectivity(
      onHiveStatusChanged: (status) {
        if (mounted) {
          setState(() {
            _hiveStatus = status;
          });
        }
      },
      onLastCheckedChanged: (lastChecked) {
        if (mounted) {
          setState(() {
            _lastChecked = lastChecked;
          });
        }
      },
    );
  }

  void _refreshGoogleDriveStatus() {
    _connectivityHelper.checkGoogleDriveConnectivity(
      onGoogleDriveStatusChanged: (status) {
        if (mounted) {
          setState(() {
            _googleDriveStatus = status;
          });
        }
      },
      onLastCheckedChanged: (lastChecked) {
        if (mounted) {
          setState(() {
            _lastChecked = lastChecked;
          });
        }
      },
    );
  }

  Future<void> _handleAuthenticate() async {
    final success = await _connectivityHelper.handleAuthenticate();
    if (success && mounted) {
      final authenticated = await _connectivityHelper.refreshDrive();
      if (mounted) {
        setState(() {
          _driveAuthenticated = authenticated;
        });
      }
      _connectivityHelper.checkGoogleDriveConnectivity(
        onGoogleDriveStatusChanged: (status) {
          if (mounted) {
            setState(() {
              _googleDriveStatus = status;
              _lastChecked = DateTime.now();
            });
          }
        },
        onLastCheckedChanged: (lastChecked) {
          if (mounted) {
            setState(() {
              _lastChecked = lastChecked;
            });
          }
        },
      );
    }
  }

  Future<void> _handleRevoke() async {
    final drive = context.read<GoogleDriveService>();
    await drive.revokeAuthentication();
    await _refreshDriveStatus();
  }

  Future<void> _refreshDriveStatus() async {
    final drive = context.read<GoogleDriveService>();

    // Check password authentication
    final authenticated = await _connectivityHelper.refreshDrive();
    // Check Google Sign-In status
    final signedIn = await drive.isSignedIn();

    if (mounted) {
      setState(() {
        _driveAuthenticated = authenticated;
        _isGoogleSignedIn = signedIn;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final drive = context.read<GoogleDriveService>();

    setState(() => _isSigningIn = true);

    try {
      final success = await drive.signIn();
      if (mounted) {
        setState(() {
          _isGoogleSignedIn = success;
          _isSigningIn = false;
        });

        if (success) {
          // Refresh connectivity status to show connected
          _refreshGoogleDriveStatus();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connected to Google Drive'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to connect to Google Drive'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningIn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignOut() async {
    final drive = context.read<GoogleDriveService>();
    await drive.signOut();

    if (mounted) {
      setState(() => _isGoogleSignedIn = false);
      // Refresh connectivity status to show disconnected
      _refreshGoogleDriveStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disconnected from Google Drive'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
