import 'package:flutter/material.dart';

/// A styled card widget following the Nexus design system.
/// Features rounded corners, subtle borders, and optional shadow glow.
class NexusCard extends StatelessWidget {
  const NexusCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.onTap,
    this.leftBorderColor,
    this.leftBorderWidth = 4,
    this.elevation = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  /// Optional colored left border (for reminder cards)
  final Color? leftBorderColor;
  final double leftBorderWidth;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : theme.colorScheme.outline;

    Widget card = Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: leftBorderColor != null
            ? Row(
                children: [
                  Container(width: leftBorderWidth, color: leftBorderColor),
                  Expanded(
                    child: Padding(padding: padding, child: child),
                  ),
                ],
              )
            : Padding(padding: padding, child: child),
      ),
    );

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }
}
