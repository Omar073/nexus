import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/nexus_card.dart';

/// Titled group container for settings tiles.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.child});

  /// The section title (displayed in uppercase).
  final String title;

  /// The section content widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: NexusCard(
            padding: EdgeInsets.zero,
            borderRadius: 16,
            child: child,
          ),
        ),
      ],
    );
  }
}
