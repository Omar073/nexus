import 'package:flutter/material.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/theme_customization/presentation/widgets/presets/preset_chip.dart';
import 'package:nexus/features/theme_customization/presentation/widgets/presets/preset_list_actions.dart';
import 'package:provider/provider.dart';

/// Saved color presets list with apply/delete.
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
              return PresetChip(
                preset: preset,
                isLight: isLight,
                onTap: () => applyPreset(context, preset),
                onLongPress: () => deletePreset(context, preset),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
