import 'package:flutter/material.dart';
import 'package:nexus/features/settings/data/models/color_preset.dart';

class PresetChip extends StatelessWidget {
  const PresetChip({
    super.key,
    required this.preset,
    required this.isLight,
    required this.onTap,
    required this.onLongPress,
  });

  final ColorPreset preset;
  final bool isLight;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

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
