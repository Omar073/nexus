import 'package:flutter/material.dart';
import 'package:nexus/core/services/storage/drive_auth_exception.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/widgets/drive_password_dialog.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_attachment.dart';
import 'package:provider/provider.dart';

/// Helper to add attachment with automatic authentication prompt.
///
/// This handles both password-based and Google Sign-In authentication
/// when uploading attachments to Google Drive.
Future<void> addAttachmentWithAuth(
  BuildContext context,
  TaskController controller,
  Task task,
  TaskAttachment attachment,
) async {
  final driveService = context.read<GoogleDriveService>();

  try {
    await controller.addAttachment(task, attachment);
  } on DriveAuthRequiredException catch (e) {
    if (!context.mounted) return;

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
          await controller.addAttachment(task, attachment);
        } catch (_) {
          // Silently fail - attachment is saved locally
        }
      }
    } else if (message.contains('sign in') || message.contains('google')) {
      // Show Google Sign-In dialog
      if (!context.mounted) return;
      final shouldSignIn = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sign in to Google'),
          content: const Text(
            'You need to sign in to your Google account to upload files to Drive.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
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
            builder: (dialogContext) =>
                const Center(child: CircularProgressIndicator()),
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
              await controller.addAttachment(task, attachment);
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
              SnackBar(content: Text('Error signing in: ${error.toString()}')),
            );
          }
        }
      }
    }
  } catch (_) {
    // Silently fail - attachment is saved locally
  }
}
