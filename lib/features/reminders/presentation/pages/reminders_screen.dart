import 'package:flutter/material.dart';

import 'package:nexus/features/reminders/domain/entities/reminder_entity.dart';
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
  bool _selectionMode = false;
  final Set<String> _selectedReminderIds = <String>{};

  void _enterSelection(String id) {
    setState(() {
      _selectionMode = true;
      _selectedReminderIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedReminderIds.remove(id)) {
        if (_selectedReminderIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectionMode = true;
        _selectedReminderIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedReminderIds.clear();
    });
  }

  void _selectAllReminders(Iterable<ReminderEntity> reminders) {
    setState(() {
      _selectionMode = true;
      _selectedReminderIds
        ..clear()
        ..addAll(reminders.map((r) => r.id));
    });
  }

  Future<void> _deleteSelected(ReminderController controller) async {
    final ids = _selectedReminderIds.toList();
    _clearSelection();
    for (final id in ids) {
      final reminder = controller.reminders.cast<dynamic>().firstWhere(
        (r) => r.id == id,
        orElse: () => null,
      );
      if (reminder != null) {
        await controller.delete(reminder);
      }
    }
  }

  Future<void> _toggleCompletedForSelected(
    ReminderController controller,
  ) async {
    final ids = _selectedReminderIds.toList();
    _clearSelection();
    for (final id in ids) {
      final reminder = controller.reminders.cast<dynamic>().firstWhere(
        (r) => r.id == id,
        orElse: () => null,
      );
      if (reminder != null) {
        if (reminder.completedAt == null) {
          await controller.complete(reminder);
        } else {
          await controller.uncomplete(reminder);
        }
      }
    }
  }

  Future<void> _snoozeSelected(ReminderController controller) async {
    final ids = _selectedReminderIds.toList();
    _clearSelection();
    for (final id in ids) {
      final reminder = controller.reminders.cast<dynamic>().firstWhere(
        (r) => r.id == id,
        orElse: () => null,
      );
      if (reminder != null) {
        await controller.snooze(reminder);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReminderController>();
    final navBarStyle = context.watch<SettingsController>().navBarStyle;
    final allReminders = controller.reminders;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter reminders: Only show past incomplete ones and today's reminders
    final displayReminders = allReminders.where((r) {
      final rDate = DateTime(r.time.year, r.time.month, r.time.day);
      if (rDate.isBefore(today) && r.completedAt == null) {
        return true; // Overdue
      }
      if (rDate.isAtSameMomentAs(today)) return true; // Today
      return false; // Future or others
    }).toList();

    // Sort: Overdue first, then by time
    displayReminders.sort((a, b) => a.time.compareTo(b.time));

    return Scaffold(
      body: RemindersBody(
        reminders: displayReminders,
        navBarStyle: navBarStyle,
        selectionMode: _selectionMode,
        selectedIds: _selectedReminderIds,
        onEnterSelection: _enterSelection,
        onToggleSelection: _toggleSelection,
      ),
      floatingActionButton: _selectionMode
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: navBarStyle.fabOffset(context)),
              child: FloatingActionButton(
                heroTag: 'reminders_fab',
                onPressed: () => showReminderEditorDialog(context),
                child: const Icon(Icons.add),
              ),
            ),
      bottomNavigationBar: _selectionMode
          ? ReminderSelectionBar(
              selectedCount: _selectedReminderIds.length,
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
