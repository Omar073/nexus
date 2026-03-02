import 'package:flutter/material.dart';
import 'package:nexus/features/settings/data/models/color_preset.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:provider/provider.dart';

/// Displays saved color presets as a horizontal scrollable list
class PresetListSection extends StatelessWidget {
  final bool isLight;

  const PresetListSection({super.key, required this.isLight});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final presets = settings.presets;
    final textColor = isLight ? Colors.black87 : Colors.white;

    if (presets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Presets',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to apply, long-press to delete',
          style: TextStyle(
            fontSize: 12,
            color: textColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: presets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final preset = presets[index];
              return _PresetChip(
                preset: preset,
                isLight: isLight,
                onTap: () => _applyPreset(context, preset),
                onLongPress: () => _deletePreset(context, preset),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  //todo: extract following code to a separate file
  void _applyPreset(BuildContext context, ColorPreset preset) {
    context.read<SettingsController>().applyPreset(preset);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied "${preset.name}"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deletePreset(BuildContext context, ColorPreset preset) {
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
}

class _PresetChip extends StatelessWidget {
  final ColorPreset preset;
  final bool isLight;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PresetChip({
    required this.preset,
    required this.isLight,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isLight ? preset.lightPrimary : preset.darkPrimary;
    final secondary = isLight ? preset.lightSecondary : preset.darkSecondary;
    final textColor = isLight ? Colors.black87 : Colors.white;
    final bgColor = isLight
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF2A2A2A);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: secondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                preset.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
