import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/notes/models/note.dart';
import 'package:nexus/features/notes/models/note_attachment.dart';
import 'package:nexus/features/notes/models/note_repository.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:uuid/uuid.dart';

class NoteController extends ChangeNotifier {
  NoteController({
    required NoteRepository repo,
    required SyncService syncService,
    required GoogleDriveService googleDrive,
    required String deviceId,
  }) : _repo = repo,
       _syncService = syncService,
       _googleDrive = googleDrive,
       _deviceId = deviceId,
       _listenable = repo.listenable() {
    _listenable.addListener(_onLocalChanged);
  }

  final NoteRepository _repo;
  final SyncService _syncService;
  final GoogleDriveService _googleDrive;
  final String _deviceId;
  final Listenable _listenable;

  static const _uuid = Uuid();

  String _query = '';
  String get query => _query;

  void _onLocalChanged() => notifyListeners();

  @override
  void dispose() {
    _listenable.removeListener(_onLocalChanged);
    super.dispose();
  }

  void setQuery(String v) {
    _query = v.trim();
    notifyListeners();
  }

  List<Note> get visibleNotes {
    final all = _repo.getAll().toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((n) {
      final t = (n.title ?? '').toLowerCase();
      final plain = _plainText(n).toLowerCase();
      return t.contains(q) || plain.contains(q);
    }).toList();
  }

  Note? byId(String id) => _repo.getById(id);

  Future<Note> createEmpty() async {
    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      title: null,
      // Minimal Quill Delta JSON: insert newline.
      contentDeltaJson: jsonEncode([
        {'insert': '\n'},
      ]),
      createdAt: now,
      updatedAt: now,
      lastModifiedByDevice: _deviceId,
      attachments: const [],
      isDirty: true,
      syncStatus: SyncStatus.idle.index,
    );
    await _repo.upsert(note);
    await _enqueueUpsert(note, isCreate: true);
    return note;
  }

  Future<void> saveEditor({
    required Note note,
    required quill.QuillController controller,
    String? title,
  }) async {
    final now = DateTime.now();
    note.title = (title?.trim().isEmpty ?? true) ? null : title?.trim();
    note.contentDeltaJson = jsonEncode(controller.document.toDelta().toJson());
    note.updatedAt = now;
    note.lastModifiedByDevice = _deviceId;
    note.isDirty = true;
    note.syncStatusEnum = SyncStatus.idle;
    await note.save();
    await _enqueueUpsert(note, isCreate: false);
  }

  Future<void> delete(Note note) async {
    await _repo.delete(note.id);
    final op = SyncOperation(
      id: _uuid.v4(),
      type: SyncOperationType.delete.index,
      entityType: 'note',
      entityId: note.id,
      createdAt: DateTime.now(),
    );
    await _syncService.enqueueOperation(op);
    unawaited(_syncService.syncOnce());
  }

  String _plainText(Note n) {
    try {
      final decoded = jsonDecode(n.contentDeltaJson);
      final doc = quill.Document.fromJson(
        (decoded as List).cast<Map<String, dynamic>>(),
      );
      return doc.toPlainText();
    } catch (_) {
      return '';
    }
  }

  Future<void> addVoiceAttachment(Note note, NoteAttachment attachment) async {
    note.attachments = [...note.attachments, attachment];
    note.updatedAt = DateTime.now();
    note.lastModifiedByDevice = _deviceId;
    note.isDirty = true;
    note.syncStatusEnum = SyncStatus.idle;
    await note.save();

    // Best-effort upload if authenticated and local file exists.
    if (attachment.localUri != null) {
      try {
        final file = File(attachment.localUri!);
        if (await file.exists()) {
          // This will throw DriveAuthRequiredException if not authenticated
          final driveId = await _googleDrive.uploadNoteFile(
            noteId: note.id,
            file: file,
            filename: attachment.id,
            mimeType: attachment.mimeType,
          );
          attachment.driveFileId = driveId;
          attachment.uploaded = true;
          await note.save();
        }
      } catch (e) {
        // Re-throw DriveAuthRequiredException so view can handle it
        // Other errors are silently ignored - attachment is saved locally
        rethrow;
      }
    }

    await _enqueueUpsert(note, isCreate: false);
  }

  Future<void> _enqueueUpsert(Note note, {required bool isCreate}) async {
    final op = SyncOperation(
      id: _uuid.v4(),
      type: (isCreate ? SyncOperationType.create : SyncOperationType.update)
          .index,
      entityType: 'note',
      entityId: note.id,
      createdAt: DateTime.now(),
      data: note.toFirestoreJson(),
    );
    await _syncService.enqueueOperation(op);
    unawaited(_syncService.syncOnce());
  }
}
