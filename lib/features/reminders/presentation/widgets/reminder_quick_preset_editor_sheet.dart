import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/bottom_sheet/nexus_bottom_sheet.dart';

/// Opens an editor for reminder quick preset minute values.
Future<List<int>?> showReminderQuickPresetEditorSheet(
  BuildContext context, {
  required List<int> initialMinutes,
}) {
  return showNexusBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) =>
        _ReminderQuickPresetEditorSheet(initialMinutes: initialMinutes),
  );
}

class _ReminderQuickPresetEditorSheet extends StatefulWidget {
  const _ReminderQuickPresetEditorSheet({required this.initialMinutes});

  final List<int> initialMinutes;

  @override
  State<_ReminderQuickPresetEditorSheet> createState() =>
      _ReminderQuickPresetEditorSheetState();
}

class _ReminderQuickPresetEditorSheetState
    extends State<_ReminderQuickPresetEditorSheet> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.initialMinutes
        .map((v) => TextEditingController(text: v.toString()))
        .toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height * 0.85;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: mediaQuery.viewInsets.bottom + 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit quick presets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Set each preset in minutes.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _controllers.length,
                itemBuilder: (context, index) {
                  final controller = _controllers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Preset ${index + 1} (minutes)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final values = _controllers
                        .map((c) => int.tryParse(c.text.trim()) ?? 1)
                        .map((v) => v.clamp(1, 24 * 60))
                        .toList();
                    Navigator.of(context).pop(values);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
