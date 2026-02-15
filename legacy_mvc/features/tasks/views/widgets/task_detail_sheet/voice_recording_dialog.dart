import 'package:flutter/material.dart';
import 'package:record/record.dart';

/// Shows a dialog for recording a voice note.
/// Returns the saved file path if recording was completed, null otherwise.
Future<String?> showVoiceRecordingDialog(
  BuildContext context,
  String destinationPath,
) async {
  return showDialog<String?>(
    context: context,
    builder: (dialogContext) {
      bool recording = false;
      final record = AudioRecorder();

      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Record voice note'),
            content: Text(
              recording ? 'Recording…' : 'Tap Start to begin recording.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (recording) {
                    await record.stop();
                  }
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(null);
                  }
                },
                child: const Text('Cancel'),
              ),
              if (!recording)
                FilledButton(
                  onPressed: () async {
                    final ok = await record.hasPermission();
                    if (!ok) return;
                    await record.start(
                      const RecordConfig(),
                      path: destinationPath,
                    );
                    setState(() => recording = true);
                  },
                  child: const Text('Start'),
                )
              else
                FilledButton(
                  onPressed: () async {
                    final saved = await record.stop();
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(saved);
                    }
                  },
                  child: const Text('Stop & Save'),
                ),
            ],
          );
        },
      );
    },
  );
}
