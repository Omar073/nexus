import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';

/// Debounced local save and lifecycle flush for the editor.

class NoteEditorAutosaveController {
  NoteEditorAutosaveController({
    required NoteController notes,
    required String noteId,
    required TextEditingController titleController,
    required TextEditingController markdownController,
    required quill.QuillController quillController,
    required bool Function() isMarkdown,
    this.debounceDuration = const Duration(milliseconds: 300),
  }) : _notes = notes,
       _noteId = noteId,
       _titleController = titleController,
       _markdownController = markdownController,
       _quillController = quillController,
       _isMarkdown = isMarkdown;

  final NoteController _notes;
  final String _noteId;
  final TextEditingController _titleController;
  final TextEditingController _markdownController;
  final quill.QuillController _quillController;
  final bool Function() _isMarkdown;

  final Duration debounceDuration;

  bool _isSaving = false;
  bool _queuedSyncSave = false;
  Timer? _debounce;
  String _lastSavedSignature = '';

  void init() {
    _lastSavedSignature = _currentSignature();
  }

  void dispose() {
    _debounce?.cancel();
  }

  void scheduleLocalSave() {
    _debounce?.cancel();
    _debounce = Timer(debounceDuration, () {
      unawaited(flush(syncRemote: false));
    });
  }

  void cancelPending() {
    _debounce?.cancel();
  }

  Future<void> flush({required bool syncRemote}) async {
    if (_isSaving) {
      _queuedSyncSave = _queuedSyncSave || syncRemote;
      return;
    }

    final signature = _currentSignature();
    if (!syncRemote && signature == _lastSavedSignature) {
      return;
    }

    _isSaving = true;
    try {
      await _notes.saveEditor(
        noteId: _noteId,
        title: _titleController.text,
        contentDeltaJson: _currentDeltaJson(),
        isMarkdown: _isMarkdown(),
        enqueueSync: syncRemote,
      );
      _lastSavedSignature = signature;
    } finally {
      _isSaving = false;
    }

    if (_queuedSyncSave) {
      _queuedSyncSave = false;
      await flush(syncRemote: true);
    }
  }

  String _currentDeltaJson() {
    if (_isMarkdown()) {
      final text = _markdownController.text;
      final doc = quill.Document()..insert(0, text.isEmpty ? '\n' : '$text\n');
      return jsonEncode(doc.toDelta().toJson());
    }
    return jsonEncode(_quillController.document.toDelta().toJson());
  }

  String _currentSignature() {
    final isMd = _isMarkdown();
    final content = isMd
        ? _markdownController.text
        : _quillController.document.toPlainText();
    return '${_titleController.text.trim()}|$isMd|$content';
  }
}
