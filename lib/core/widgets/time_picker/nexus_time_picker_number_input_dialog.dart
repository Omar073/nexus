import 'package:flutter/material.dart';

Future<int?> showTimePickerNumberInputDialog(
  BuildContext context, {
  required String title,
  required int initialValue,
  required int min,
  required int max,
}) async {
  final controller = TextEditingController(text: initialValue.toString());
  final parsed = await showDialog<int>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            final raw = int.tryParse(controller.text.trim());
            if (raw == null) return;
            Navigator.of(dialogContext).pop(raw.clamp(min, max));
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final raw = int.tryParse(controller.text.trim());
              if (raw == null) return;
              Navigator.of(dialogContext).pop(raw.clamp(min, max));
            },
            child: const Text('Apply'),
          ),
        ],
      );
    },
  );
  controller.dispose();
  return parsed;
}
