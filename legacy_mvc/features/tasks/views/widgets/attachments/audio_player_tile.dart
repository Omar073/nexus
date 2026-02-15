import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// A tile widget for playing audio files.
class AudioPlayerTile extends StatefulWidget {
  const AudioPlayerTile({super.key, required this.path});

  final String path;

  @override
  State<AudioPlayerTile> createState() => _AudioPlayerTileState();
}

class _AudioPlayerTileState extends State<AudioPlayerTile> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
      return;
    }
    await _player.play(DeviceFileSource(widget.path));
    setState(() => _playing = true);
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
        onPressed: _toggle,
      ),
      title: Text(File(widget.path).uri.pathSegments.last),
      subtitle: const Text('Voice note'),
    );
  }
}
