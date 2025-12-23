import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nexus/core/services/storage/drive_auth_exception.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/note_embed_service.dart';
import 'package:nexus/core/widgets/drive_password_dialog.dart';
import 'package:nexus/features/notes/controllers/note_controller.dart';
import 'package:nexus/features/notes/models/note.dart';
import 'package:nexus/features/notes/models/note_attachment.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

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
        title: const Text('Edit Note'),
        actions: [
          IconButton(
            tooltip: _recording ? 'Stop recording' : 'Record voice note',
            icon: Icon(_recording ? Icons.stop : Icons.mic_none),
            onPressed: () => _toggleVoice(context, note),
          ),
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.save_outlined),
            onPressed: () async {
              await notes.saveEditor(note: note, controller: _controller!, title: _title.text);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          quill.QuillSimpleToolbar(
            controller: _controller!,
            config: const quill.QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: false,
              showCodeBlock: false,
              showInlineCode: false,
              showSearchButton: false,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
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
          if (note.attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Voice notes'),
                  const SizedBox(height: 8),
                  for (final a in note.attachments)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.play_arrow),
                      title: Text(a.id),
                      subtitle: Text(a.uploaded ? 'Uploaded' : 'Local only'),
                      onTap: () async {
                        final path = a.localUri;
                        if (path == null) return;
                        await _embedService.playLocal(path);
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  quill.QuillController _buildController(Note note) {
    try {
      final decoded = jsonDecode(note.contentDeltaJson);
      final doc = quill.Document.fromJson((decoded as List).cast<Map<String, dynamic>>());
      return quill.QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
    } catch (_) {
      final doc = quill.Document()..insert(0, ' ');
      return quill.QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
    }
  }

  static bool _looksArabic(String s) {
    for (final code in s.runes) {
      final isArabic = (code >= 0x0600 && code <= 0x06FF) ||
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
      
      // Check if it's a password or Google Sign-In issue
      final message = e.message.toLowerCase();
      
      if (message.contains('password')) {
        // Show password dialog
        final authenticated = await showDrivePasswordDialog(
          context,
          (password) => driveService.authenticate(password),
        );
        
        if (authenticated && context.mounted) {
          // Retry after password authentication
          try {
            await controller.addVoiceAttachment(note, attachment);
          } catch (_) {
            // Silently fail - attachment is saved locally
          }
        }
      } else if (message.contains('sign in') || message.contains('google')) {
        // Show Google Sign-In dialog
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
          // Show loading indicator
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          try {
            final signedIn = await driveService.signIn();
            
            if (context.mounted) {
              Navigator.of(context).pop(); // Close loading
            }
            
            if (signedIn && context.mounted) {
              // Retry after Google Sign-In
              try {
                await controller.addVoiceAttachment(note, attachment);
              } catch (_) {
                // Silently fail - attachment is saved locally
              }
            } else if (context.mounted) {
              // Show error if sign-in failed
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to sign in to Google. Please try again.'),
                ),
              );
            }
          } catch (error) {
            if (context.mounted) {
              Navigator.of(context).pop(); // Close loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error signing in: ${error.toString()}'),
                ),
              );
            }
          }
        }
      }
    } catch (_) {
      // Silently fail - attachment is saved locally
    }
  }
}


