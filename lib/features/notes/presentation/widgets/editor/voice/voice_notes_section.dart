import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nexus/core/services/note_embed_service.dart';
import 'package:nexus/core/services/storage/attachment_storage_service.dart';
import 'package:nexus/core/services/storage/drive_auth_exception.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/widgets/nexus_card.dart';
import 'package:nexus/core/widgets/drive_password_dialog.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/domain/note_attachment_kinds.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/voice/voice_note_item.dart';
import 'package:provider/provider.dart';

/// Lists audio attachments with play/delete and Drive recovery.

class VoiceNotesSection extends StatelessWidget {
  const VoiceNotesSection({
    super.key,
    required this.note,
    required this.embedService,
  });

  final NoteEntity note;
  final NoteEmbedService embedService;

  @override
  Widget build(BuildContext context) {
    final audioAttachments = note.attachments
        .where((a) => NoteAttachmentKinds.isAudio(a.mimeType))
        .toList();

    if (audioAttachments.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final notes = context.read<NoteController>();
    final drive = context.read<GoogleDriveService>();
    final storage = AttachmentStorageService();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: NexusCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mic, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Voice Notes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${audioAttachments.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...audioAttachments.map(
              (a) => VoiceNoteItem(
                attachment: a,
                onPlay: () async {
                  final localPath = a.localUri;
                  if (localPath != null && localPath.isNotEmpty) {
                    await embedService.playLocal(localPath);
                    return;
                  }

                  final driveId = a.driveFileId;
                  if (driveId == null || driveId.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This voice note is not available.'),
                        ),
                      );
                    }
                    return;
                  }

                  try {
                    final destPath = await storage.newAudioPath(
                      taskId: 'notes_${note.id}',
                      ext: '.m4a',
                    );
                    final destFile = File(destPath);
                    await drive.downloadFile(
                      driveFileId: driveId,
                      destination: destFile,
                    );
                    await notes.cacheAttachmentLocalUri(
                      noteId: note.id,
                      attachmentId: a.id,
                      localUri: destPath,
                    );
                    await embedService.playLocal(destPath);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Unable to access Google Drive for this voice note.',
                        ),
                        action: SnackBarAction(
                          label: 'Access Drive',
                          onPressed: () => _recoverDriveAccess(context, drive),
                        ),
                      ),
                    );
                  }
                },
                onDelete: () async {
                  await notes.removeAttachment(
                    noteId: note.id,
                    attachmentId: a.id,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recoverDriveAccess(
    BuildContext context,
    GoogleDriveService drive,
  ) async {
    final navigator = Navigator.of(context);
    try {
      final authed = await drive.isAuthenticated();
      if (!authed && context.mounted) {
        await showDrivePasswordDialog(
          context,
          (password) => drive.authenticate(password),
        );
      }
    } catch (_) {}

    if (!context.mounted) return;

    try {
      final signedIn = await drive.isSignedIn();
      if (!context.mounted) return;
      if (!signedIn) {
        final shouldSignIn = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Sign in to Google'),
            content: const Text(
              'Sign in to access voice notes stored in Google Drive.',
            ),
            actions: [
              TextButton(
                onPressed: () => navigator.pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => navigator.pop(true),
                child: const Text('Sign In'),
              ),
            ],
          ),
        );

        if (shouldSignIn == true && context.mounted) {
          await drive.signIn();
        }
      }
    } on DriveAuthRequiredException {
      // If DriveAuthRequiredException bubbles up (platform support / store state), just ignore.
    } catch (_) {}
  }
}
