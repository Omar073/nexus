import 'package:flutter/material.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';

({String title, String subtitle}) colorSectionCopy({required bool isPrimary}) {
  if (isPrimary) {
    return (
      title: 'Primary Color',
      subtitle: 'Used for buttons, highlights, and key elements',
    );
  }
  return (
    title: 'Secondary Color',
    subtitle: 'Used for accents and secondary actions',
  );
}

void applyPrimaryColorSelection({
  required SettingsController settings,
  required Brightness brightness,
  required Color color,
}) {
  settings.updatePrimaryColor(brightness, color);
}

void applySecondaryColorSelection({
  required SettingsController settings,
  required Brightness brightness,
  required Color color,
}) {
  settings.updateSecondaryColor(brightness, color);
}
