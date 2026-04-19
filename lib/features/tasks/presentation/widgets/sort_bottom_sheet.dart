import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/bottom_sheet/nexus_bottom_sheet.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/categories/domain/category_sort_option.dart';
import 'package:nexus/features/tasks/domain/task_sort_option.dart';
import 'package:provider/provider.dart';

/// Bottom sheet for selecting task and category sort options.
void showSortBottomSheet(BuildContext context) {
  showNexusBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _SortBottomSheetContent(),
  );
}

class _SortBottomSheetContent extends StatelessWidget {
  const _SortBottomSheetContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsController>();

    return Container(
      height: 500, // Fixed height for tabs
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Title & Tabs
            TabBar(
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Tasks'),
                Tab(text: 'Categories'),
              ],
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: TabBarView(
                children: [
                  _TaskSortList(settings: settings),
                  _CategorySortList(settings: settings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskSortList extends StatelessWidget {
  const _TaskSortList({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSort = settings.taskSortOption;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Urgent (due in 48h) and high priority tasks always appear first.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...TaskSortOption.values.map(
          (option) => _SortOptionTile(
            title: option.displayName,
            subtitle: option.description,
            icon: _iconForTaskOption(option),
            isSelected: option == currentSort,
            onTap: () {
              settings.setTaskSortOption(option);
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }

  IconData _iconForTaskOption(TaskSortOption option) => switch (option) {
    TaskSortOption.newestFirst => Icons.arrow_downward,
    TaskSortOption.oldestFirst => Icons.arrow_upward,
    TaskSortOption.recentlyModified => Icons.update,
    TaskSortOption.dueDateAsc => Icons.schedule,
    TaskSortOption.priorityDesc => Icons.priority_high,
  };
}

class _CategorySortList extends StatelessWidget {
  const _CategorySortList({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final currentSort = settings.categorySortOption;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: CategorySortOption.values
          .map(
            (option) => _SortOptionTile(
              title: option.displayName,
              subtitle: option.description,
              icon: _iconForCategoryOption(option),
              isSelected: option == currentSort,
              onTap: () {
                settings.setCategorySortOption(option);
                Navigator.pop(context);
              },
            ),
          )
          .toList(),
    );
  }

  IconData _iconForCategoryOption(CategorySortOption option) =>
      switch (option) {
        CategorySortOption.defaultOrder => Icons.menu,
        CategorySortOption.alphabeticalAsc => Icons.sort_by_alpha,
        CategorySortOption.alphabeticalDesc => Icons.sort_by_alpha, // Rotated?
        CategorySortOption.recentlyModified => Icons.access_time,
      };
}

class _SortOptionTile extends StatelessWidget {
  const _SortOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
    );
  }
}
