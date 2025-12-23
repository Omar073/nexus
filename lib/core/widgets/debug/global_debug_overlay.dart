import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexus/core/services/debug/debug_logger_service.dart';

class GlobalDebugOverlay extends StatefulWidget {
  const GlobalDebugOverlay({super.key, required this.child});
  final Widget child;

  @override
  State<GlobalDebugOverlay> createState() => _GlobalDebugOverlayState();
}

class _GlobalDebugOverlayState extends State<GlobalDebugOverlay> {
  bool _show = false;
  int _tapCount = 0;
  Timer? _tapTimer;
  Timer? _uiTimer;
  Timer? _statusTimer;
  String? _statusMessage;
  final ScrollController _scroll = ScrollController();

  bool get _supportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    unawaited(DebugLoggerService.instance.initialize());
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    _uiTimer?.cancel();
    _statusTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_supportedPlatform) return;
    if (kDebugMode) return;

    final size = MediaQuery.of(context).size;
    final p = details.globalPosition;

    // Top-right 50x50px secret region
    if (p.dx > size.width - 50 && p.dy < 50) {
      _tapCount++;
      _tapTimer?.cancel();
      _tapTimer = Timer(const Duration(milliseconds: 500), () {
        _tapCount = 0;
      });

      if (_tapCount >= 3) {
        _tapCount = 0;
        _toggle();
      }
    }
  }

  void _toggle() {
    if (!mounted) return;
    setState(() {
      _show = !_show;
    });

    _uiTimer?.cancel();
    if (_show) {
      _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _show) setState(() {});
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  void _setStatus(String message) {
    _statusTimer?.cancel();
    setState(() => _statusMessage = message);
    _statusTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _statusMessage = null);
    });
  }

  double _panelWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) {
      // Android/mobile: 85% (300..400)
      return (w * 0.85).clamp(300.0, 400.0);
    }
    // Windows/desktop: 85% (400..600)
    return (w * 0.85).clamp(400.0, 600.0);
  }

  Color _colorFor(DebugLogLevel level) {
    switch (level) {
      case DebugLogLevel.error:
        return Colors.redAccent;
      case DebugLogLevel.warning:
        return Colors.orangeAccent;
      case DebugLogLevel.info:
        return Colors.greenAccent;
    }
  }

  void _copyLast(int n) {
    final text = DebugLoggerService.instance.exportLastNLogs(n);
    Clipboard.setData(ClipboardData(text: text));
    _setStatus('Copied last $n logs');
  }

  void _copyAll() {
    final text = DebugLoggerService.instance.exportLogs();
    Clipboard.setData(ClipboardData(text: text));
    _setStatus('Copied all logs');
  }

  void _clear() {
    DebugLoggerService.instance.clearLogs();
    _setStatus('Cleared logs');
  }

  String _archiveCountdown() {
    final next = DebugLoggerService.instance.nextArchiveAt;
    if (next == null) return 'Next archive: disabled';
    final diff = next.difference(DateTime.now());
    if (diff.isNegative) return 'Next archive: soon';
    final mins = diff.inMinutes;
    final secs = diff.inSeconds % 60;
    return 'Next archive in: ${mins}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) return widget.child;
    if (!_supportedPlatform) return widget.child;

    Widget content = GestureDetector(
      onTapDown: _handleTapDown,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          widget.child,
          if (_show) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggle,
                child: Container(color: Colors.black.withValues(alpha: 0.30)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: _DebugPanel(
                width: _panelWidth(context),
                scroll: _scroll,
                statusMessage: _statusMessage,
                onClose: _toggle,
                onClear: _clear,
                onCopyLast10: () => _copyLast(10),
                onCopyLast20: () => _copyLast(20),
                onCopyLast30: () => _copyLast(30),
                onCopyAll: _copyAll,
                archiveCountdown: _archiveCountdown(),
                colorFor: _colorFor,
              ),
            ),
          ],
        ],
      ),
    );

    // Windows-only keyboard shortcut: Ctrl+Shift+D
    if (_isWindows) {
      content = CallbackShortcuts(
        bindings: {
          const SingleActivator(
            LogicalKeyboardKey.keyD,
            control: true,
            shift: true,
          ): _toggle,
        },
        child: Focus(autofocus: true, child: content),
      );
    }

    return content;
  }
}

class _DebugPanel extends StatelessWidget {
  const _DebugPanel({
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
            _Header(onClose: onClose, onClear: onClear),
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
            _Footer(
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

class _Header extends StatelessWidget {
  const _Header({required this.onClose, required this.onClear});
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

class _Footer extends StatelessWidget {
  const _Footer({
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
