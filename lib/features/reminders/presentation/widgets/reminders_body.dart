import 'package:flutter/material.dart';
import 'package:nexus/features/reminders/domain/entities/reminder_entity.dart';
import 'package:nexus/features/reminders/presentation/widgets/reminder_tile.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:nexus/features/wrapper/presentation/pages/app_wrapper.dart';

/// Main list + empty state for the reminders tab.

class RemindersBody extends StatelessWidget {
  const RemindersBody({
    super.key,
    required this.reminders,
    required this.navBarStyle,
    required this.selectionMode,
    required this.selectedIds,
    required this.onEnterSelection,
    required this.onToggleSelection,
  });

  final List<ReminderEntity> reminders;
  final NavBarStyle navBarStyle;
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(String id) onEnterSelection;
  final void Function(String id) onToggleSelection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => AppWrapper.scaffoldKey.currentState?.openDrawer(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            title: Text(
              'Reminders',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (reminders.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reminders for today',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, navBarStyle.contentPadding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final reminder = reminders[index];
                final selected = selectedIds.contains(reminder.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ReminderTile(
                    reminder: reminder,
                    selectionMode: selectionMode,
                    isSelected: selected,
                    onSelectionToggle: () => onToggleSelection(reminder.id),
                    onLongPress: () => onEnterSelection(reminder.id),
                  ),
                );
              }, childCount: reminders.length),
            ),
          ),
      ],
    );
  }
}
