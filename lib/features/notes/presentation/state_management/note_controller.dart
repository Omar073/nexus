import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nexus/core/services/storage/attachment_cleanup_service.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/notes/domain/entities/note_attachment_entity.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/domain/repositories/note_repository_interface.dart';
import 'package:nexus/features/notes/domain/use_cases/add_note_attachment_use_case.dart';
import 'package:nexus/features/notes/domain/use_cases/create_empty_note_use_case.dart';
import 'package:nexus/features/notes/domain/use_cases/delete_note_use_case.dart';
import 'package:nexus/features/notes/domain/use_cases/save_note_use_case.dart';
import 'package:nexus/features/notes/domain/use_cases/update_note_category_use_case.dart';

/// Notes feature facade: list, selection, search, and editor wiring.
/// Owns attachment add/remove, category changes, and coordinates [SaveNoteUseCase].
/// Listeners include [NotesListScreen], [NoteEditorView], and tiles.

class NoteController extends ChangeNotifier {
  NoteController({
    required NoteRepositoryInterface repo,
    required SyncService syncService,
    required GoogleDriveService googleDrive,
    required String deviceId,
  }) : _repo = repo,
       _syncService = syncService,
       _googleDrive = googleDrive,
       _deviceId = deviceId,
       _createEmpty = CreateEmptyNoteUseCase(
         repo,
         syncService,
         deviceId: deviceId,
       ),
       _save = SaveNoteUseCase(repo, syncService, deviceId: deviceId),
       _updateCategory = UpdateNoteCategoryUseCase(
         repo,
         syncService,
         deviceId: deviceId,
       ),
       _delete = DeleteNoteUseCase(repo, syncService),
       _addAttachment = AddNoteAttachmentUseCase(
         repo,
         syncService,
         googleDrive,
         deviceId: deviceId,
       ) {
    _subscription = repo.changes.listen((_) => notifyListeners());
  }

  final NoteRepositoryInterface _repo;
  final SyncService _syncService;
  final GoogleDriveService _googleDrive;
  final String _deviceId;
  late final AttachmentCleanupService _attachmentCleanup =
      AttachmentCleanupService(drive: _googleDrive);
  final CreateEmptyNoteUseCase _createEmpty;
  final SaveNoteUseCase _save;
  final UpdateNoteCategoryUseCase _updateCategory;
  final DeleteNoteUseCase _delete;
  final AddNoteAttachmentUseCase _addAttachment;
  StreamSubscription<void>? _subscription;

  String _query = '';
  String get query => _query;

  String? _categoryIdFilter;
  String? get categoryIdFilter => _categoryIdFilter;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void setQuery(String v) {
    _query = v.trim();
    notifyListeners();
  }

  void setCategoryFilter(String? id) {
    _categoryIdFilter = id;
    notifyListeners();
  }

  List<NoteEntity> get visibleNotes {
    final all = _repo.getAll().toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all.where((n) {
      if (_categoryIdFilter != null && n.categoryId != _categoryIdFilter) {
        return false;
      }
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final t = (n.title ?? '').toLowerCase();
      final plain = _plainText(n).toLowerCase();
      return t.contains(q) || plain.contains(q);
    }).toList();
  }

  NoteEntity? byId(String id) => _repo.getById(id);

  Future<void> updateCategory(NoteEntity note, String? categoryId) =>
      _updateCategory.call(note, categoryId);

  Future<NoteEntity> createEmpty({String? categoryId}) =>
      _createEmpty.call(categoryId: categoryId ?? _categoryIdFilter);

  Future<void> saveEditor({
    required String noteId,
    String? title,
    required String contentDeltaJson,
    bool isMarkdown = false,
    bool enqueueSync = true,
  }) => _save.call(
    noteId: noteId,
    title: title,
    contentDeltaJson: contentDeltaJson,
    isMarkdown: isMarkdown,
    enqueueSync: enqueueSync,
  );

  Future<void> delete(NoteEntity note) => _delete.call(note);

  /// Restore a previously deleted note (e.g. for undo).
  Future<void> restoreNote(NoteEntity note) async {
    await _repo.upsert(note);
    final payload = _repo.getSyncPayload(note.id);
    if (payload != null) {
      final op = SyncOperation(
        id: const Uuid().v4(),
        type: SyncOperationType.create.index,
        entityType: 'note',
        entityId: note.id,
        createdAt: DateTime.now(),
        data: payload,
      );
      await _syncService.enqueueOperation(op);
      unawaited(_syncService.syncOnce());
    }
  }

  Future<void> addVoiceAttachment(
    NoteEntity note,
    NoteAttachmentEntity attachment,
  ) => addAttachment(note, attachment);

  Future<void> addAttachment(
    NoteEntity note,
    NoteAttachmentEntity attachment,
  ) => _addAttachment.call(note, attachment);

  /// Removes any attachment (voice, image, etc.) by id and performs best-effort
  /// cleanup for local + Drive files.
  Future<void> removeAttachment({
    required String noteId,
    required String attachmentId,
  }) async {
    final existing = _repo.getById(noteId);
    if (existing == null) return;

    NoteAttachmentEntity? target;
    for (final attachment in existing.attachments) {
      if (attachment.id == attachmentId) {
        target = attachment;
        break;
      }
    }
    if (target == null) return;

    final updated = NoteEntity(
      id: existing.id,
      title: existing.title,
      contentDeltaJson: existing.contentDeltaJson,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      lastModifiedByDevice: _deviceId,
      attachments: existing.attachments
          .where((a) => a.id != attachmentId)
          .toList(),
      isDirty: true,
      lastSyncedAt: existing.lastSyncedAt,
      syncStatus: 0,
      categoryId: existing.categoryId,
      isMarkdown: existing.isMarkdown,
    );

    await _repo.upsert(updated);
    await _enqueueUpsert(updated.id);

    _attachmentCleanup.deleteLocalInBackground(target.localUri);
    await _attachmentCleanup.deleteDriveIfPresent(target.driveFileId);
  }

  /// Backwards-compatible name (voice notes UI used this previously).
  Future<void> removeVoiceAttachment({
    required String noteId,
    required String attachmentId,
  }) => removeAttachment(noteId: noteId, attachmentId: attachmentId);

  Future<void> cacheAttachmentLocalUri({
    required String noteId,
    required String attachmentId,
    required String localUri,
  }) async {
    final existing = _repo.getById(noteId);
    if (existing == null) return;

    final updatedAttachments = existing.attachments.map((a) {
      if (a.id != attachmentId) return a;
      return NoteAttachmentEntity(
        id: a.id,
        mimeType: a.mimeType,
        createdAt: a.createdAt,
        localUri: localUri,
        driveFileId: a.driveFileId,
        uploaded: a.uploaded,
      );
    }).toList();

    final updated = NoteEntity(
      id: existing.id,
      title: existing.title,
      contentDeltaJson: existing.contentDeltaJson,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      lastModifiedByDevice: existing.lastModifiedByDevice,
      attachments: updatedAttachments,
      isDirty: existing.isDirty,
      lastSyncedAt: existing.lastSyncedAt,
      syncStatus: existing.syncStatus,
      categoryId: existing.categoryId,
      isMarkdown: existing.isMarkdown,
    );

    // Local cache only: do not enqueue sync.
    await _repo.upsert(updated);
  }

  Future<void> _enqueueUpsert(String noteId) async {
    final payload = _repo.getSyncPayload(noteId);
    if (payload == null) return;
    final op = SyncOperation(
      id: const Uuid().v4(),
      type: SyncOperationType.update.index,
      entityType: 'note',
      entityId: noteId,
      createdAt: DateTime.now(),
      data: payload,
    );
    await _syncService.enqueueOperation(op);
    unawaited(_syncService.syncOnce());
  }

  String _plainText(NoteEntity n) {
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
}
