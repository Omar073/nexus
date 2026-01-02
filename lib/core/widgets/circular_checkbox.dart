import 'package:flutter/material.dart';

/// Circular checkbox following Nexus design system.
/// Shows a round checkbox that fills with primary color when checked.
class CircularCheckbox extends StatelessWidget {
  const CircularCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 24,
    this.borderWidth = 2,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = value
        ? theme.colorScheme.primary
        : isDark
        ? Colors.white38
        : Colors.grey.shade400;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value ? theme.colorScheme.primary : Colors.transparent,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: value
            ? Icon(Icons.check, size: size * 0.6, color: Colors.white)
            : null,
      ),
    );
  }
}
