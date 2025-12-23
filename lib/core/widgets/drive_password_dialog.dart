import 'package:flutter/material.dart';

/// Dialog for entering Drive access password
class DrivePasswordDialog extends StatefulWidget {
  const DrivePasswordDialog({super.key});

  @override
  State<DrivePasswordDialog> createState() => _DrivePasswordDialogState();
}

class _DrivePasswordDialogState extends State<DrivePasswordDialog> {
  final _controller = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context, Function(String) onAuthenticate) async {
    final password = _controller.text.trim();
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await onAuthenticate(password);
      if (success && context.mounted) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Incorrect password';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Drive Access'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter the password to access the Drive folder for media storage.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: _obscureText,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _errorMessage,
              suffixIcon: IconButton(
                icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
            onSubmitted: (_) => _submit(context, (p) async {
              // This will be passed from the caller
              return false;
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading
              ? null
              : () => _submit(
                    context,
                    (password) async {
                      // This callback will be provided by the caller
                      return false;
                    },
                  ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Authenticate'),
        ),
      ],
    );
  }
}

/// Helper function to show password dialog and authenticate
Future<bool> showDrivePasswordDialog(
  BuildContext context,
  Future<bool> Function(String) authenticate,
) async {
  final controller = TextEditingController();
  bool obscureText = true;
  bool isLoading = false;
  String? errorMessage;

  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Drive Access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the password to access the Drive folder for media storage.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: obscureText,
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: errorMessage,
                suffixIcon: IconButton(
                  icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      obscureText = !obscureText;
                    });
                  },
                ),
              ),
              onSubmitted: (_) async {
                final password = controller.text.trim();
                if (password.isEmpty) {
                  setState(() {
                    errorMessage = 'Please enter a password';
                  });
                  return;
                }

                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });

                try {
                  final success = await authenticate(password);
                  if (success && context.mounted) {
                    Navigator.of(context).pop(true);
                  } else {
                    setState(() {
                      isLoading = false;
                      errorMessage = 'Incorrect password';
                    });
                  }
                } catch (e) {
                  setState(() {
                    isLoading = false;
                    errorMessage = 'Authentication failed. Please try again.';
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: isLoading
                ? null
                : () async {
                    final password = controller.text.trim();
                    if (password.isEmpty) {
                      setState(() {
                        errorMessage = 'Please enter a password';
                      });
                      return;
                    }

                    setState(() {
                      isLoading = true;
                      errorMessage = null;
                    });

                    try {
                      final success = await authenticate(password);
                      if (success && context.mounted) {
                        Navigator.of(context).pop(true);
                      } else {
                        setState(() {
                          isLoading = false;
                          errorMessage = 'Incorrect password';
                        });
                      }
                    } catch (e) {
                      setState(() {
                        isLoading = false;
                        errorMessage = 'Authentication failed. Please try again.';
                      });
                    }
                  },
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Authenticate'),
          ),
        ],
      ),
    ),
  ) ?? false;
}

