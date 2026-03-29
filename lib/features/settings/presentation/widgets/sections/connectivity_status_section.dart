import 'package:flutter/material.dart';
import 'package:nexus/core/services/platform/backend_health_checker.dart';
import 'package:nexus/features/settings/presentation/widgets/sections/connectivity_status_tile.dart';

/// Settings block for network status.
class ConnectivityStatusSection extends StatelessWidget {
  final ConnectivityStatus? firebaseStatus;
  final ConnectivityStatus? hiveStatus;
  final ConnectivityStatus? googleDriveStatus;
  final DateTime? lastChecked;
  final bool isChecking;
  final VoidCallback onRefreshFirebase;
  final VoidCallback onRefreshHive;
  final VoidCallback onRefreshGoogleDrive;

  const ConnectivityStatusSection({
    super.key,
    required this.firebaseStatus,
    required this.hiveStatus,
    required this.googleDriveStatus,
    required this.lastChecked,
    required this.isChecking,
    required this.onRefreshFirebase,
    required this.onRefreshHive,
    required this.onRefreshGoogleDrive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connectivity Status',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ConnectivityStatusTile(
          status: firebaseStatus,
          title: 'Firebase',
          isChecking: isChecking,
          onRefresh: onRefreshFirebase,
          tooltip: 'Refresh Firebase status',
        ),
        ConnectivityStatusTile(
          status: hiveStatus,
          title: 'Hive',
          isChecking: isChecking,
          onRefresh: onRefreshHive,
          tooltip: 'Refresh Hive status',
        ),
        ConnectivityStatusTile(
          status: googleDriveStatus,
          title: 'Google Drive',
          isChecking: isChecking,
          onRefresh: onRefreshGoogleDrive,
          tooltip: 'Refresh Google Drive status',
        ),
        if (lastChecked != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              'Last checked: ${_formatTime(lastChecked!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
