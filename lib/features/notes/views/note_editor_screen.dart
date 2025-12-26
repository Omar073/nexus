import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nexus/core/services/storage/drive_auth_exception.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/note_embed_service.dart';
import 'package:nexus/core/widgets/drive_password_dialog.dart';
import 'package:nexus/core/widgets/nexus_card.dart';
import 'package:nexus/features/notes/controllers/note_controller.dart';
import 'package:nexus/features/notes/models/note.dart';
import 'package:nexus/features/notes/models/note_attachment.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

/// Note editor screen following Nexus design system.
/// Features styled title input, enhanced toolbar, and voice notes section.
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, required this.noteId});
  final String noteId;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  quill.QuillController? _controller;
  final _title = TextEditingController();
  final _embedService = NoteEmbedService();

  bool _recording = false;
  bool _titleInitialized = false;

  @override
  void dispose() {
    _controller?.dispose();
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notes = context.watch<NoteController>();
    final note = notes.byId(widget.noteId);
    if (note == null) {
      return const Scaffold(body: Center(child: Text('Note not found')));
    }

    _controller ??= _buildController(note);
    if (!_titleInitialized) {
      _title.text = note.title ?? '';
      _titleInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Voice note button
          IconButton(
            tooltip: _recording ? 'Stop recording' : 'Record voice note',
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _recording
                    ? Colors.red.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _recording ? Icons.stop : Icons.mic_none,
                color: _recording ? Colors.red : null,
              ),
            ),
            onPressed: () => _toggleVoice(context, note),
          ),
          // Image attachment button
          IconButton(
            tooltip: 'Add image',
            icon: const Icon(Icons.image_outlined),
            onPressed: () => _showAttachmentOptions(context, note),
          ),
          // Save button
          FilledButton.icon(
            onPressed: () async {
              await notes.saveEditor(
                note: note,
                controller: _controller!,
                title: _title.text,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Saved')));
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Save'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Title input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Untitled',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Toolbar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade300,
              ),
            ),
            child: quill.QuillSimpleToolbar(
              controller: _controller!,
              config: const quill.QuillSimpleToolbarConfig(
                showFontFamily: false,
                showFontSize: false,
                showCodeBlock: false,
                showInlineCode: false,
                showSearchButton: false,
                multiRowsDisplay: false,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Editor
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Directionality(
                textDirection: _looksArabic(_controller!.document.toPlainText())
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: quill.QuillEditor.basic(
                  controller: _controller!,
                  config: const quill.QuillEditorConfig(),
                ),
              ),
            ),
          ),
          // Attachments section
          if (note.attachments.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: NexusCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.mic,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Voice Notes',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${note.attachments.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...note.attachments.map(
                      (a) => _VoiceNoteItem(
                        attachment: a,
                        onPlay: () async {
                          final path = a.localUri;
                          if (path == null) return;
                          await _embedService.playLocal(path);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  quill.QuillController _buildController(Note note) {
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

  static bool _looksArabic(String s) {
    for (final code in s.runes) {
      final isArabic =
          (code >= 0x0600 && code <= 0x06FF) ||
          (code >= 0x0750 && code <= 0x077F) ||
          (code >= 0x08A0 && code <= 0x08FF) ||
          (code >= 0xFB50 && code <= 0xFDFF) ||
          (code >= 0xFE70 && code <= 0xFEFF);
      if (isArabic) return true;
    }
    return false;
  }

  Future<void> _toggleVoice(BuildContext context, Note note) async {
    final controller = context.read<NoteController>();
    if (!_recording) {
      setState(() => _recording = true);
      await _embedService.recordVoiceNote(noteId: note.id);
      return;
    }

    final saved = await _embedService.stopRecording();
    setState(() => _recording = false);
    if (saved == null) return;

    final attachment = NoteAttachment(
      id: const Uuid().v4(),
      mimeType: 'audio/mp4',
      createdAt: DateTime.now(),
      localUri: saved,
      uploaded: false,
    );

    try {
      await controller.addVoiceAttachment(note, attachment);
    } on DriveAuthRequiredException catch (e) {
      if (!context.mounted) return;
      final driveService = context.read<GoogleDriveService>();

      final message = e.message.toLowerCase();

      if (message.contains('password')) {
        final authenticated = await showDrivePasswordDialog(
          context,
          (password) => driveService.authenticate(password),
        );

        if (authenticated && context.mounted) {
          try {
            await controller.addVoiceAttachment(note, attachment);
          } catch (_) {}
        }
      } else if (message.contains('sign in') || message.contains('google')) {
        if (!context.mounted) return;
        final shouldSignIn = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sign in to Google'),
            content: const Text(
              'You need to sign in to your Google account to upload files to Drive.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sign In'),
              ),
            ],
          ),
        );

        if (shouldSignIn == true && context.mounted) {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            );
          }

          try {
            final signedIn = await driveService.signIn();

            if (context.mounted) {
              Navigator.of(context).pop();
            }

            if (signedIn && context.mounted) {
              try {
                await controller.addVoiceAttachment(note, attachment);
              } catch (_) {}
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Failed to sign in to Google. Please try again.',
                  ),
                ),
              );
            }
          } catch (error) {
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error signing in: ${error.toString()}'),
                ),
              );
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _showAttachmentOptions(BuildContext context, Note note) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (result == null || !mounted) return;

    // For now, show a message - full implementation would pick image and embed in quill
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image picked from $result - embedding coming soon'),
        ),
      );
    }
  }
}

/// Voice note item widget
class _VoiceNoteItem extends StatelessWidget {
  const _VoiceNoteItem({required this.attachment, required this.onPlay});

  final NoteAttachment attachment;
  final VoidCallback onPlay;

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
      child: Row(
        children: [
          GestureDetector(
            onTap: onPlay,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Note',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  attachment.uploaded ? 'Synced' : 'Local only',
                  style: TextStyle(
                    fontSize: 11,
                    color: attachment.uploaded
                        ? Colors.green
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (attachment.uploaded)
            Icon(Icons.cloud_done, size: 16, color: Colors.green),
        ],
      ),
    );
  }
}
