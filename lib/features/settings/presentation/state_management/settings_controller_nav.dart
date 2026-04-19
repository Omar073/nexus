part of 'settings_controller.dart';

Future<void> settingsSetNavIcon(
  SettingsController self,
  String page,
  IconData icon,
) async {
  self._navigationIcons = Map<String, int>.from(self._navigationIcons);
  self._navigationIcons[page] = icon.codePoint;
  await self._updateNavIcons.call(self._navigationIcons);
}
