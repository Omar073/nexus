import 'package:nexus/features/reminders/presentation/utils/reminder_quick_presets_store.dart';

class ReminderQuickPreset {
  const ReminderQuickPreset({
    required this.label,
    required this.durationMinutes,
  });

  factory ReminderQuickPreset.fromMinutes(int minutes) {
    final clamped = minutes.clamp(1, 24 * 60);
    return ReminderQuickPreset(
      label: _formatQuickPresetLabel(clamped),
      durationMinutes: clamped,
    );
  }

  final String label;
  final int durationMinutes;
}

Future<List<ReminderQuickPreset>> loadReminderQuickPresets(
  ReminderQuickPresetsStore store,
) async {
  final minutes = await store.loadPresetMinutes();
  return minutes.map(ReminderQuickPreset.fromMinutes).toList();
}

Future<List<ReminderQuickPreset>?> editReminderQuickPresets({
  required ReminderQuickPresetsStore store,
  required List<ReminderQuickPreset> currentPresets,
  required Future<List<int>?> Function(List<int> currentMinutes) showEditor,
}) async {
  final updatedMinutes = await showEditor(
    currentPresets.map((preset) => preset.durationMinutes).toList(),
  );
  if (updatedMinutes == null) return null;
  await store.savePresetMinutes(updatedMinutes);
  return updatedMinutes.map(ReminderQuickPreset.fromMinutes).toList();
}

String _formatQuickPresetLabel(int minutes) {
  if (minutes < 60) return '$minutes ${minutes == 1 ? 'min' : 'mins'}';
  if (minutes % 60 == 0) {
    final hours = minutes ~/ 60;
    return '$hours ${hours == 1 ? 'hour' : 'hours'}';
  }
  return '$minutes mins';
}
