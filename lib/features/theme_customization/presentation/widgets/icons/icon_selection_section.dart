import 'package:flutter/material.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/settings/presentation/utils/nav_icon_mapper.dart';
import 'package:provider/provider.dart';

/// Shell destinations that support custom nav icons (order matches tab strip).
const _kNavIconTabs = <({String id, String label})>[
  (id: 'dashboard', label: 'Dashboard'),
  (id: 'tasks', label: 'Tasks'),
  (id: 'reminders', label: 'Reminders'),
  (id: 'notes', label: 'Notes'),
  (id: 'settings', label: 'Settings'),
  (id: 'habits', label: 'Habits'),
  (id: 'calendar', label: 'Calendar'),
  (id: 'analytics', label: 'Analytics'),
];

class IconSelectionSection extends StatefulWidget {
  const IconSelectionSection({super.key});

  @override
  State<IconSelectionSection> createState() => _IconSelectionSectionState();
}

class _IconSelectionSectionState extends State<IconSelectionSection>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _kNavIconTabs.length,
      vsync: this,
      initialIndex: 0,
    );
    _tabController.addListener(_onTabControllerTick);
  }

  void _onTabControllerTick() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerTick);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selections = context.select<SettingsController, Map<String, int>>(
      (c) => c.navigationIcons,
    );
    final theme = Theme.of(context);
    final pageId = _kNavIconTabs[_tabController.index].id;

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
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [for (final t in _kNavIconTabs) Tab(text: t.label)],
        ),
        const SizedBox(height: 8),
        _IconGridForPage(pageId: pageId, selections: selections),
        const SizedBox(height: 16),
      ],
    );
  }
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

/// Fixed height: 4 rows of icon cells + spacing; scrolls horizontally.
class _IconGridForPage extends StatelessWidget {
  const _IconGridForPage({required this.pageId, required this.selections});

  final String pageId;
  final Map<String, int> selections;

  static const double _cellSize = 52;
  static const double _mainGap = 8;
  static const double _crossGap = 8;
  static const int _rows = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIcon = NavIconMapper.getIconForPage(pageId, selections);
    final options = _dedupeByCodePoint([
      currentIcon,
      ...NavIconMapper.allSelectableIcons,
    ]);

    if (options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'No icons available for this screen.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final gridHeight = _rows * _cellSize + (_rows - 1) * _crossGap;

    return SizedBox(
      height: gridHeight,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _rows,
          mainAxisSpacing: _mainGap,
          crossAxisSpacing: _crossGap,
          childAspectRatio: 1,
        ),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final icon = options[index];
          final isSelected = currentIcon.codePoint == icon.codePoint;
          final displayIcon = isSelected
              ? NavIconMapper.selectedVariant(icon)
              : icon;

          return InkWell(
            onTap: () =>
                context.read<SettingsController>().setNavIcon(pageId, icon),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
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
          );
        },
      ),
    );
  }
}
