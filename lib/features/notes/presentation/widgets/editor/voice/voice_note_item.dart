import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:nexus/features/notes/domain/entities/note_attachment_entity.dart';

/// Play/pause, duration, and delete for one voice attachment.
class VoiceNoteItem extends StatefulWidget {
  const VoiceNoteItem({
    super.key,
    required this.attachment,
    required this.resolveLocalPath,
    required this.onDelete,
  });

  final NoteAttachmentEntity attachment;
  final Future<String?> Function() resolveLocalPath;
  final VoidCallback onDelete;

  @override
  State<VoiceNoteItem> createState() => _VoiceNoteItemState();
}

class _VoiceNoteItemState extends State<VoiceNoteItem> {
  late final AudioPlayer _player;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  String? _sourcePath;
  bool _loading = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _posSub = _player.onPositionChanged.listen((d) {
      if (!mounted) return;
      setState(() => _position = d);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _playing = s == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: _playing ? 'Pause' : 'Play',
                onPressed: _loading ? null : _togglePlayPause,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_playing ? Icons.pause : Icons.play_arrow),
              ),
              IconButton(
                tooltip: 'Back 10s',
                onPressed: (_duration == Duration.zero || _loading)
                    ? null
                    : _skipBack,
                icon: const Icon(Icons.replay_10),
              ),
              IconButton(
                tooltip: 'Forward 10s',
                onPressed: (_duration == Duration.zero || _loading)
                    ? null
                    : _skipForward,
                icon: const Icon(Icons.forward_10),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice note',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.attachment.uploaded ? 'Synced' : 'Local only',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.attachment.uploaded
                            ? Colors.green
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.attachment.uploaded)
                const Icon(Icons.cloud_done, size: 16, color: Colors.green),
              IconButton(
                tooltip: 'Delete voice note',
                onPressed: widget.onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          _buildSeekBar(theme),
        ],
      ),
    );
  }

  Widget _buildSeekBar(ThemeData theme) {
    final maxMs = _duration.inMilliseconds;
    final posMs = _position.inMilliseconds.clamp(0, maxMs);
    final canSeek = maxMs > 0 && !_loading;

    return Row(
      children: [
        Text(_fmt(_position), style: theme.textTheme.labelSmall),
        Expanded(
          child: Slider(
            value: maxMs == 0 ? 0 : posMs.toDouble(),
            min: 0,
            max: maxMs == 0 ? 1 : maxMs.toDouble(),
            onChanged: canSeek
                ? (v) {
                    final d = Duration(milliseconds: v.round());
                    setState(() => _position = d);
                  }
                : null,
            onChangeEnd: canSeek
                ? (v) => _player.seek(Duration(milliseconds: v.round()))
                : null,
          ),
        ),
        Text(_fmt(_duration), style: theme.textTheme.labelSmall),
      ],
    );
  }

  Future<void> _togglePlayPause() async {
    if (_playing) {
      await _player.pause();
      return;
    }

    setState(() => _loading = true);
    try {
      _sourcePath ??= await widget.resolveLocalPath();
      final path = _sourcePath;
      if (path == null || path.isEmpty) return;

      await _player.play(DeviceFileSource(path));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _skipBack() async {
    final next = _position - const Duration(seconds: 10);
    await _player.seek(next < Duration.zero ? Duration.zero : next);
  }

  Future<void> _skipForward() async {
    final next = _position + const Duration(seconds: 10);
    final end = _duration;
    await _player.seek(end == Duration.zero || next < end ? next : end);
  }

  static String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${two(m)}:${two(s)}';
  }
}
