import 'package:flutter/material.dart';
import 'package:nexus/core/services/storage/drive_auth_exception.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/widgets/drive_password_dialog.dart';
import 'package:nexus/features/notes/domain/entities/note_attachment_entity.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:provider/provider.dart';

/// Drive sign-in and retry when upload fails.
class NoteAttachmentDriveUploadHelper {
  NoteAttachmentDriveUploadHelper._();

  static Future<void> addWithDriveRecovery({
    required BuildContext context,
    required NoteController controller,
    required NoteEntity note,
    required NoteAttachmentEntity attachment,
  }) async {
    try {
      await controller.addAttachment(note, attachment);
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
            await controller.addAttachment(note, attachment);
          } catch (_) {}
        }
      } else if (message.contains('sign in') || message.contains('google')) {
        if (!context.mounted) return;
        final navigator = Navigator.of(context);
        final shouldSignIn = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Sign in to Google'),
            content: const Text(
              'You need to sign in to your Google account to upload files to Drive.',
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
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          try {
            final signedIn = await driveService.signIn();

            if (context.mounted) {
              Navigator.of(context).pop();
            }

            if (signedIn && context.mounted) {
              try {
                await controller.addAttachment(note, attachment);
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
