import 'package:flutter/material.dart';

/// Footer component for the debug panel.
///
/// Displays copy buttons (Last 10/20/30, Copy All), status messages,
/// and the archive countdown timer.
class DebugPanelFooter extends StatelessWidget {
  const DebugPanelFooter({
    super.key,
    required this.statusMessage,
    required this.onCopyLast10,
    required this.onCopyLast20,
    required this.onCopyLast30,
    required this.onCopyAll,
    required this.archiveCountdown,
  });

  final String? statusMessage;
  final VoidCallback onCopyLast10;
  final VoidCallback onCopyLast20;
  final VoidCallback onCopyLast30;
  final VoidCallback onCopyAll;
  final String archiveCountdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[850],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (statusMessage != null) ...[
            Text(
              statusMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallButton(label: 'Last 10', onPressed: onCopyLast10),
              _SmallButton(label: 'Last 20', onPressed: onCopyLast20),
              _SmallButton(label: 'Last 30', onPressed: onCopyLast30),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onCopyAll,
            icon: const Icon(Icons.content_copy, size: 16),
            label: const Text('Copy all logs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            archiveCountdown,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Small button used in the footer for quick copy actions.
class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 85,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          textStyle: const TextStyle(fontSize: 11),
        ),
        child: Text(label),
      ),
    );
  }
}
