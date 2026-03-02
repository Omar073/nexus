import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/app/router/app_routes.dart';
import 'package:nexus/features/habits/presentation/state_management/habit_controller.dart';
import 'package:nexus/features/habits/presentation/widgets/habit_card.dart';
import 'package:nexus/features/habits/presentation/widgets/habit_create_dialog.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:provider/provider.dart';
import 'package:nexus/core/widgets/app_drawer_button.dart';
import 'package:nexus/features/wrapper/presentation/widgets/app_drawer.dart';

/// Habits screen following Nexus design system.
/// Features large header with drawer button, habit cards with streak info.
class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<HabitController>();
    final habits = controller.habits;
    final navBarStyle = context.watch<SettingsController>().navBarStyle;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const AppDrawerButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () {
              context.push(AppRoute.calendar.path);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Habits',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Build consistency, one day at a time',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Habits list
            Expanded(
              child: habits.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.loop,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No habits yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to create your first habit',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        navBarStyle.contentPadding,
                      ),
                      itemCount: habits.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return HabitCard(habit: habits[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: navBarStyle.fabOffset),
        child: FloatingActionButton(
          heroTag: 'habits_fab',
          onPressed: () => showHabitCreateDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
