import 'package:flutter/material.dart';

/// Drive access authentication section
/// Handles both password gate authentication and Google Sign-In
class DriveAccessSection extends StatelessWidget {
  final bool isAuthenticated;
  final bool isGoogleSignedIn;
  final bool isSigningIn;
  final VoidCallback onAuthenticate;
  final VoidCallback onRevoke;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onGoogleSignOut;

  const DriveAccessSection({
    super.key,
    required this.isAuthenticated,
    required this.isGoogleSignedIn,
    required this.onAuthenticate,
    required this.onRevoke,
    required this.onGoogleSignIn,
    required this.onGoogleSignOut,
    this.isSigningIn = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Drive Access', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),

        // Password Gate Authentication
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            isAuthenticated ? Icons.lock_open : Icons.lock_outlined,
            color: isAuthenticated ? colorScheme.primary : null,
          ),
          title: Text(
            isAuthenticated ? 'Password Unlocked' : 'Password Locked',
          ),
          subtitle: const Text('Local password to access Drive features'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isAuthenticated)
                FilledButton(
                  onPressed: onAuthenticate,
                  child: const Text('Unlock'),
                )
              else
                OutlinedButton(onPressed: onRevoke, child: const Text('Lock')),
            ],
          ),
        ),

        const Divider(height: 16),

        // Google Sign-In
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.add_to_drive,
            color: isGoogleSignedIn ? colorScheme.primary : null,
          ),
          title: Text(
            isGoogleSignedIn
                ? 'Google Drive Connected'
                : 'Google Drive Not Connected',
          ),
          subtitle: Text(
            isGoogleSignedIn
                ? 'Your files will sync to Google Drive'
                : 'Sign in to sync files to Google Drive',
          ),
          trailing: isSigningIn
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isGoogleSignedIn)
                      FilledButton.icon(
                        onPressed: isAuthenticated ? onGoogleSignIn : null,
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Connect'),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: onGoogleSignOut,
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Disconnect'),
                      ),
                  ],
                ),
        ),

        // Show hint if password not authenticated
        if (!isAuthenticated && !isGoogleSignedIn)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unlock with password first to connect Google Drive',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
