import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nexus/core/services/note_embed_service.dart';
import 'package:nexus/features/notes/domain/entities/note_attachment_entity.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/domain/note_attachment_kinds.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/helpers/note_editor_autosave_controller.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/helpers/note_editor_marker_inserter.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/markdown/markdown_editor_area.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/note_editor_app_bar.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/widgets/note_editor_body.dart';
import 'package:provider/provider.dart';

/// Main editor view with all state and logic for editing a note.
/// Hosted by [NoteEditorScreen] which handles loading and "not found".
class NoteEditorView extends StatefulWidget {
  const NoteEditorView({super.key, required this.note});

  final NoteEntity note;

  @override
  State<NoteEditorView> createState() => _NoteEditorViewState();
}

class _NoteEditorViewState extends State<NoteEditorView>
    with WidgetsBindingObserver {
  late quill.QuillController _controller;
  final _title = TextEditingController();
  final _embedService = NoteEmbedService();
  final _markdownController = TextEditingController();

  bool _isMarkdown = false;
  MarkdownLayout _markdownLayout = MarkdownLayout.tabs;
  NoteController? _notes;
  late final NoteEditorMarkerInserter _markerInserter;
  NoteEditorAutosaveController? _autosave;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _markerInserter = const NoteEditorMarkerInserter();
    _initializeFromNote(widget.note);
    _title.addListener(_onTitleChanged);
    _markdownController.addListener(_onMarkdownChangedText);
    _controller.addListener(_onQuillChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notes ??= context.read<NoteController>();
    _autosave ??= NoteEditorAutosaveController(
      notes: _notes!,
      noteId: widget.note.id,
      titleController: _title,
      markdownController: _markdownController,
      quillController: _controller,
      isMarkdown: () => _isMarkdown,
    )..init();
  }

  @override
  void didUpdateWidget(covariant NoteEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id != widget.note.id) {
      _autosave?.dispose();
      _autosave = null;
      _controller.removeListener(_onQuillChanged);
      _controller.dispose();
      _initializeFromNote(widget.note);
      _controller.addListener(_onQuillChanged);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autosave?.dispose();
    _controller.removeListener(_onQuillChanged);
    _controller.dispose();
    _title.removeListener(_onTitleChanged);
    _markdownController.removeListener(_onMarkdownChangedText);
    _title.dispose();
    _markdownController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _autosave?.cancelPending();
      unawaited(_autosave?.flush(syncRemote: true) ?? Future.value());
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) return;
        _autosave?.cancelPending();
        unawaited(_autosave?.flush(syncRemote: true) ?? Future.value());
      },
      child: Scaffold(
        appBar: NoteEditorAppBar(
          note: note,
          titleController: _title,
          onAttachmentAdded: _insertAttachmentMarker,
        ),
        body: NoteEditorBody(
          note: note,
          isMarkdown: _isMarkdown,
          markdownLayout: _markdownLayout,
          onMarkdownChanged: _onMarkdownModeChanged,
          onLayoutChanged: (v) => setState(() => _markdownLayout = v),
          quillController: _controller,
          markdownController: _markdownController,
          embedService: _embedService,
        ),
      ),
    );
  }

  void _initializeFromNote(NoteEntity note) {
    _controller = _buildController(note);
    _title.text = note.title ?? '';
    _isMarkdown = note.isMarkdown;
    if (_isMarkdown) {
      _markdownController.text = _controller.document.toPlainText();
    }
  }

  void _onTitleChanged() {
    _autosave?.scheduleLocalSave();
  }

  void _onQuillChanged() {
    if (!_isMarkdown) {
      _autosave?.scheduleLocalSave();
    }
  }

  void _onMarkdownChangedText() {
    if (_isMarkdown) {
      _autosave?.scheduleLocalSave();
    }
  }

  void _onMarkdownModeChanged(bool value) {
    setState(() {
      _isMarkdown = value;
      if (_isMarkdown && _markdownController.text.isEmpty) {
        _markdownController.text = _controller.document.toPlainText();
      }
    });
    _autosave?.scheduleLocalSave();
  }

  void _insertAttachmentMarker(NoteAttachmentEntity attachment) {
    _markerInserter.insert(
      isMarkdown: _isMarkdown,
      markdownController: _markdownController,
      quillController: _controller,
      marker: NoteAttachmentKinds.inlineMarker(attachment),
    );
  }

  quill.QuillController _buildController(NoteEntity note) {
    try {
      final decoded = jsonDecode(note.contentDeltaJson);
      final doc = quill.Document.fromJson(
        (decoded as List).cast<Map<String, dynamic>>(),
      );
      return quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      final doc = quill.Document()..insert(0, ' ');
      return quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }
}
