import 'package:flutter/material.dart';
import 'package:nexus/features/settings/data/models/color_preset.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:provider/provider.dart';

void applyPreset(BuildContext context, ColorPreset preset) {
  context.read<SettingsController>().applyPreset(preset);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Applied "${preset.name}"'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void deletePreset(BuildContext context, ColorPreset preset) {
  showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Preset'),
      content: Text('Delete "${preset.name}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  ).then((confirmed) {
    if (confirmed == true && context.mounted) {
      context.read<SettingsController>().deletePreset(preset.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${preset.name}"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  });
}
