import 'package:flutter/material.dart';
import 'package:nexus/features/settings/models/custom_colors_store.dart';

class ColorOptionGrid extends StatelessWidget {
  final List<ColorOption> options;
  final Color selectedColor;
  final Color defaultColor;
  final ValueChanged<Color> onColorSelected;

  const ColorOptionGrid({
    super.key,
    required this.options,
    required this.selectedColor,
    required this.defaultColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((option) {
        final isSelected = option.color == selectedColor;
        final isDefault = option.color == defaultColor;

        return GestureDetector(
          onTap: () => onColorSelected(option.color),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: option.color,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 3,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: option.color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: _contrastColor(option.color),
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                option.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (isDefault)
                Text(
                  'Default',
                  style: TextStyle(
                    fontSize: 8,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _contrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
