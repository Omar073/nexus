import 'package:shared_preferences/shared_preferences.dart';

const List<int> defaultReminderQuickPresetMinutes = [1, 5, 10, 15, 60];

class ReminderQuickPresetsStore {
  static const _keyQuickPresetMinutes = 'reminders.quick_preset_minutes';

  Future<List<int>> loadPresetMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_keyQuickPresetMinutes);
    if (saved == null || saved.isEmpty) {
      return List<int>.from(defaultReminderQuickPresetMinutes);
    }
    final parsed = saved
        .map(int.tryParse)
        .whereType<int>()
        .map(_sanitizeMinutes)
        .toList();
    if (parsed.isEmpty) {
      return List<int>.from(defaultReminderQuickPresetMinutes);
    }
    return parsed;
  }

  Future<void> savePresetMinutes(List<int> minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final sanitized = minutes.map(_sanitizeMinutes).toList();
    await prefs.setStringList(
      _keyQuickPresetMinutes,
      sanitized.map((v) => v.toString()).toList(),
    );
  }

  int _sanitizeMinutes(int value) {
    return value.clamp(1, 24 * 60);
  }
}
