import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:nexus/core/widgets/debug/debug_panel.dart';

/// A debug overlay that can be triggered by triple-tapping the top-right corner.
///
/// Only works in profile/release mode (not debug mode) on Android and Windows.
/// On Windows, can also be triggered with Ctrl+Shift+D.
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
              child: DebugPanel(
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
