import 'package:flutter/material.dart';
import 'package:nexus/core/services/platform/connectivity_status_service.dart';
import 'package:nexus/features/settings/controllers/settings_connectivity_utils.dart';

class ConnectivityStatusTile extends StatelessWidget {
  final ConnectivityStatus? status;
  final String title;
  final bool isChecking;
  final VoidCallback onRefresh;
  final String tooltip;

  const ConnectivityStatusTile({
    super.key,
    required this.status,
    required this.title,
    required this.isChecking,
    required this.onRefresh,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        ConnectivityStatusUtils.getStatusIcon(status),
        color: ConnectivityStatusUtils.getStatusColor(status, context),
      ),
      title: Text(title),
      subtitle: Text(ConnectivityStatusUtils.getStatusText(status)),
      trailing: isChecking && status == null
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRefresh,
              tooltip: tooltip,
            ),
    );
  }
}
