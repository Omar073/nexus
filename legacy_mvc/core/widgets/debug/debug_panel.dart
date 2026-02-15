import 'package:flutter/material.dart';
import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:nexus/core/widgets/debug/debug_panel_footer.dart';
import 'package:nexus/core/widgets/debug/debug_panel_header.dart';

/// Slide-in panel that displays debug logs.
///
/// Shows a list of logs with header (title, actions) and footer (copy buttons).
/// Animates in from the right side of the screen.
class DebugPanel extends StatelessWidget {
  const DebugPanel({
    super.key,
    required this.width,
    required this.scroll,
    required this.statusMessage,
    required this.onClose,
    required this.onClear,
    required this.onCopyLast10,
    required this.onCopyLast20,
    required this.onCopyLast30,
    required this.onCopyAll,
    required this.archiveCountdown,
    required this.colorFor,
  });

  final double width;
  final ScrollController scroll;
  final String? statusMessage;
  final VoidCallback onClose;
  final VoidCallback onClear;
  final VoidCallback onCopyLast10;
  final VoidCallback onCopyLast20;
  final VoidCallback onCopyLast30;
  final VoidCallback onCopyAll;
  final String archiveCountdown;
  final Color Function(DebugLogLevel) colorFor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 250),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(width * (1 - value), 0),
          child: child,
        );
      },
      child: Container(
        width: width,
        color: Colors.grey[900],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DebugPanelHeader(onClose: onClose, onClear: onClear),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: DebugLoggerService.instance.changes,
                builder: (context, tick, child) {
                  final logs = DebugLoggerService.instance.logs;
                  if (logs.isEmpty) {
                    return Center(
                      child: Text(
                        'No logs yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.all(8),
                    itemCount: logs.length,
                    itemBuilder: (context, i) {
                      final log = logs[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SelectableText(
                          log.toString(),
                          style: TextStyle(
                            color: colorFor(log.level),
                            fontSize: 11,
                            fontFamily: 'monospace',
                            decoration: TextDecoration.none,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            DebugPanelFooter(
              statusMessage: statusMessage,
              onCopyLast10: onCopyLast10,
              onCopyLast20: onCopyLast20,
              onCopyLast30: onCopyLast30,
              onCopyAll: onCopyAll,
              archiveCountdown: archiveCountdown,
            ),
          ],
        ),
      ),
    );
  }
}
