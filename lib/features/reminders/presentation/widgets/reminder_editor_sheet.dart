import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/core/widgets/time_picker/nexus_time_picker.dart';
import 'package:nexus/features/reminders/domain/entities/reminder_entity.dart';
import 'package:nexus/features/reminders/presentation/logic/reminder_editor_logic.dart';
import 'package:nexus/features/reminders/presentation/utils/reminder_quick_presets_store.dart';
import 'package:nexus/features/reminders/presentation/utils/reminder_time_utils.dart';
import 'package:nexus/features/reminders/presentation/models/reminder_editor_result.dart';
import 'package:nexus/features/reminders/presentation/widgets/reminder_quick_preset_editor_sheet.dart';

class ReminderEditorSheet extends StatefulWidget {
  const ReminderEditorSheet({super.key, this.reminder});

  final ReminderEntity? reminder;

  @override
  State<ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<ReminderEditorSheet> {
  final _titleFocusNode = FocusNode();
  final _quickPresetsStore = ReminderQuickPresetsStore();

  late final TextEditingController _titleController;
  late DateTime _selected;
  List<ReminderQuickPreset> _quickPresets = [];
  bool _didRequestFocus = false;

  bool get _canSave => _titleController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.reminder?.title ?? '',
    );
    _selected =
        widget.reminder?.time ?? DateTime.now().add(const Duration(minutes: 1));
    _loadQuickPresets();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reminder == null && !_didRequestFocus) {
      _didRequestFocus = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_titleFocusNode.canRequestFocus) {
          _titleFocusNode.requestFocus();
        }
      });
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.reminder == null ? 'Add reminder' : 'Edit reminder',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter reminder name',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _QuickSetHeader(onEditQuickPresets: _editQuickPresets),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickPresets.map((preset) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _QuickTimeChip(
                      label: preset.label,
                      onTap: () {
                        setState(() {
                          _selected = DateTime.now().add(
                            Duration(minutes: preset.durationMinutes),
                          );
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Time'),
              subtitle: Text(DateFormat.jm().format(_selected)),
              trailing: const Icon(Icons.schedule),
              onTap: _pickManualTime,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _canSave ? _save : null,
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Future<void> _loadQuickPresets() async {
    final presets = await loadReminderQuickPresets(_quickPresetsStore);
    if (!mounted) return;
    setState(() {
      _quickPresets = presets;
    });
  }

  Future<void> _editQuickPresets() async {
    final updatedPresets = await editReminderQuickPresets(
      store: _quickPresetsStore,
      currentPresets: _quickPresets,
      showEditor: (currentMinutes) => showReminderQuickPresetEditorSheet(
        context,
        initialMinutes: currentMinutes,
      ),
    );
    if (updatedPresets == null) return;
    setState(() => _quickPresets = updatedPresets);
  }

  Future<void> _pickManualTime() async {
    FocusScope.of(context).unfocus();
    final time = await showNexusTimePicker(
      context,
      initialTime: TimeOfDay.fromDateTime(_selected),
      title: 'Select reminder time',
    );
    if (time == null) return;
    final now = DateTime.now();
    setState(() {
      _selected = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _save() {
    final scheduledTime = rollReminderTimeToFuture(_selected);
    Navigator.of(context).pop(
      ReminderEditorResult(title: _titleController.text, time: scheduledTime),
    );
  }
}

class _QuickSetHeader extends StatelessWidget {
  const _QuickSetHeader({required this.onEditQuickPresets});

  final VoidCallback onEditQuickPresets;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Quick set',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Edit quick presets',
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          onPressed: onEditQuickPresets,
          icon: const Icon(Icons.settings),
        ),
      ],
    );
  }
}

class _QuickTimeChip extends StatelessWidget {
  const _QuickTimeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface),
    );
  }
}
