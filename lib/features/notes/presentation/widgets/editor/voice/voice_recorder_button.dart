import 'package:flutter/material.dart';
import 'package:nexus/core/services/note_embed_service.dart';
import 'package:nexus/core/services/storage/drive_auth_exception.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/widgets/drive_password_dialog.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:nexus/features/notes/domain/entities/note_attachment_entity.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class VoiceRecorderButton extends StatefulWidget {
  const VoiceRecorderButton({super.key, required this.note});

  final NoteEntity note;

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> {
  final _embedService = NoteEmbedService();
  bool _recording = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
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
      onPressed: () => _toggleVoice(context),
    );
  }

  Future<void> _toggleVoice(BuildContext context) async {
    final controller = context.read<NoteController>();
    if (!_recording) {
      setState(() => _recording = true);
      await _embedService.recordVoiceNote(noteId: widget.note.id);
      return;
    }

    final saved = await _embedService.stopRecording();
    setState(() => _recording = false);
    if (saved == null) return;

    final attachment = NoteAttachmentEntity(
      id: const Uuid().v4(),
      mimeType: 'audio/mp4',
      createdAt: DateTime.now(),
      localUri: saved,
      driveFileId: null,
      uploaded: false,
    );

    try {
      await controller.addVoiceAttachment(widget.note, attachment);
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
            await controller.addVoiceAttachment(widget.note, attachment);
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
                await controller.addVoiceAttachment(widget.note, attachment);
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
}
