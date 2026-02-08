import 'package:flutter/material.dart';
import 'package:nexus/core/services/debug/debug_logger_service.dart';

/// Header component for the debug panel.
///
/// Displays the panel title, log count, and action buttons (clear, close).
class DebugPanelHeader extends StatelessWidget {
  const DebugPanelHeader({
    super.key,
    required this.onClose,
    required this.onClear,
  });

  final VoidCallback onClose;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final logsCount = DebugLoggerService.instance.logs.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.grey[850],
      child: Row(
        children: [
          const Icon(Icons.bug_report, color: Colors.greenAccent, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Debug Logs',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            '$logsCount entries',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.white70,
              size: 18,
            ),
            tooltip: 'Clear',
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}
