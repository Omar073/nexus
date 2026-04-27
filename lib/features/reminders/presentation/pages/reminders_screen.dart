import 'package:flutter/material.dart';

import 'package:nexus/features/reminders/domain/entities/reminder_entity.dart';
import 'package:nexus/features/reminders/presentation/logic/reminders_bulk_actions_logic.dart';
import 'package:nexus/features/reminders/presentation/logic/reminders_display_filter_logic.dart';
import 'package:nexus/features/reminders/presentation/state/reminders_selection_state.dart';
import 'package:nexus/features/reminders/presentation/state_management/reminder_controller.dart';
import 'package:nexus/features/reminders/presentation/widgets/reminder_editor_dialog.dart';
import 'package:nexus/features/reminders/presentation/widgets/reminder_selection_bar.dart';
import 'package:nexus/features/reminders/presentation/widgets/reminders_body.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:provider/provider.dart';

/// Tabbed reminder list with add/edit flows.

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final RemindersSelectionState _selectionState = RemindersSelectionState();

  void _enterSelection(String id) {
    setState(() {
      _selectionState.enter(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      _selectionState.toggle(id);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionState.clear();
    });
  }

  void _selectAllReminders(Iterable<ReminderEntity> reminders) {
    setState(() {
      _selectionState.selectAll(reminders);
    });
  }

  Future<void> _deleteSelected(ReminderController controller) async {
    final ids = _selectionState.selectedIds.toList();
    _clearSelection();
    await deleteRemindersByIds(controller: controller, ids: ids);
  }

  Future<void> _toggleCompletedForSelected(
    ReminderController controller,
  ) async {
    final ids = _selectionState.selectedIds.toList();
    _clearSelection();
    await toggleCompletedForReminders(controller: controller, ids: ids);
  }

  Future<void> _snoozeSelected(ReminderController controller) async {
    final ids = _selectionState.selectedIds.toList();
    _clearSelection();
    await snoozeRemindersByIds(controller: controller, ids: ids);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReminderController>();
    final navBarStyle = context.watch<SettingsController>().navBarStyle;
    final displayReminders = buildDisplayReminders(controller.reminders);

    return Scaffold(
      body: RemindersBody(
        reminders: displayReminders,
        navBarStyle: navBarStyle,
        selectionMode: _selectionState.selectionMode,
        selectedIds: _selectionState.selectedIds,
        onEnterSelection: _enterSelection,
        onToggleSelection: _toggleSelection,
      ),
      floatingActionButton: _selectionState.selectionMode
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: navBarStyle.fabOffset(context)),
              child: FloatingActionButton(
                heroTag: 'reminders_fab',
                onPressed: () => showReminderEditorDialog(context),
                child: const Icon(Icons.add),
              ),
            ),
      bottomNavigationBar: _selectionState.selectionMode
          ? ReminderSelectionBar(
              selectedCount: _selectionState.selectedIds.length,
              onSelectAll: () => _selectAllReminders(displayReminders),
              onExitSelection: _clearSelection,
              onToggleComplete: () => _toggleCompletedForSelected(controller),
              onSnooze: () => _snoozeSelected(controller),
              onDelete: () => _deleteSelected(controller),
            )
          : null,
    );
  }
}
