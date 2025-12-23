import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:nexus/core/services/storage/attachment_storage_service.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

/// Manages inline voice notes for Notes (record + playback).
class NoteEmbedService {
  NoteEmbedService({
    AttachmentStorageService? storage,
    AudioPlayer? player,
  })  : _storage = storage ?? AttachmentStorageService(),
        _player = player ?? AudioPlayer();

  final AttachmentStorageService _storage;
  final AudioPlayer _player;
  final _recorder = AudioRecorder();

  static const _uuid = Uuid();

  Future<Map<String, dynamic>> recordVoiceNote({required String noteId}) async {
    final path = await _storage.newAudioPath(taskId: 'notes_$noteId', ext: '.m4a');
    final ok = await _recorder.hasPermission();
    if (!ok) {
      throw StateError('Microphone permission not granted.');
    }
    await _recorder.start(const RecordConfig(), path: path);
    // Caller decides when to stop; but Phase 3 UI uses dialog start/stop.
    return {
      'id': _uuid.v4(),
      'localUri': path,
      'mimeType': 'audio/mp4',
    };
  }

  Future<String?> stopRecording() => _recorder.stop();

  Future<void> playLocal(String localPath) async {
    final f = File(localPath);
    if (!await f.exists()) throw StateError('File not found: $localPath');
    await _player.play(DeviceFileSource(localPath));
  }

  Future<void> stopPlayback() => _player.stop();
}


