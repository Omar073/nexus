import 'package:flutter/material.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/settings/presentation/utils/nav_icon_mapper.dart';
import 'package:provider/provider.dart';

class IconSelectionSection extends StatefulWidget {
  const IconSelectionSection({super.key});

  @override
  State<IconSelectionSection> createState() => _IconSelectionSectionState();
}

class _IconSelectionSectionState extends State<IconSelectionSection> {
  final Map<String, bool> _showAllByPage = {};

  bool _showAllForPage(String page) => _showAllByPage[page] ?? false;

  void _setShowAllForPage(String page, bool value) {
    setState(() => _showAllByPage[page] = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Navigation Icons',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildIconPicker(context, 'dashboard', 'Dashboard'),
        _buildIconPicker(context, 'tasks', 'Tasks'),
        _buildIconPicker(context, 'reminders', 'Reminders'),
        _buildIconPicker(context, 'notes', 'Notes'),
        _buildIconPicker(context, 'settings', 'Settings'),
        _buildIconPicker(context, 'habits', 'Habits'),
        _buildIconPicker(context, 'calendar', 'Calendar'),
        _buildIconPicker(context, 'analytics', 'Analytics'),
        const SizedBox(height: 16),
      ],
    );
  }

  List<IconData> _dedupeByCodePoint(Iterable<IconData> icons) {
    final seen = <int>{};
    final result = <IconData>[];
    for (final icon in icons) {
      if (seen.add(icon.codePoint)) {
        result.add(icon);
      }
    }
    return result;
  }

  Widget _buildIconPicker(BuildContext context, String page, String label) {
    final controller = context.read<SettingsController>();
    final selections = controller.navigationIcons;
    final currentIcon = NavIconMapper.getIconForPage(page, selections);
    final curated = NavIconMapper.selectableIcons[page] ?? const [];
    final showAll = _showAllForPage(page);
    final baseOptions = showAll
        ? NavIconMapper.allSelectableIcons
        : List<IconData>.from(curated);
    final options = _dedupeByCodePoint([
      // Always keep the current selection visible even when curated list is active.
      currentIcon,
      ...baseOptions,
    ]);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Show all icons',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Switch.adaptive(
                value: showAll,
                onChanged: (value) => _setShowAllForPage(page, value),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final icon = options[index];
              final isSelected = currentIcon.codePoint == icon.codePoint;
              final displayIcon = isSelected
                  ? NavIconMapper.selectedVariant(icon)
                  : icon;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => controller.setNavIcon(page, icon),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      displayIcon,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
