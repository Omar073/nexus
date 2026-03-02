import 'package:flutter/material.dart';

class ThemePreviewCard extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final bool isLight;

  const ThemePreviewCard({
    super.key,
    required this.primary,
    required this.secondary,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isLight ? Colors.white : const Color(0xFF1E1E1E);
    final textColor = isLight ? Colors.black87 : Colors.white;

    return Card(
      color: bgColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: primary),
                    onPressed: () {},
                    child: const Text('Primary'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: secondary),
                    onPressed: () {},
                    child: const Text('Secondary'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.check, color: _contrastColor(primary)),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.star, color: _contrastColor(secondary)),
                ),
                const Spacer(),
                Switch(
                  value: true,
                  activeThumbColor: primary,
                  activeTrackColor: primary.withValues(alpha: 0.5),
                  onChanged: (_) {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _contrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
