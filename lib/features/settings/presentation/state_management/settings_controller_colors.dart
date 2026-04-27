part of 'settings_controller.dart';

void settingsUpdatePrimaryColor(
  SettingsController self,
  Brightness brightness,
  Color color,
) {
  if (brightness == Brightness.light) {
    self._lightColors = CustomColors(
      primary: color,
      secondary: self._lightColors.secondary,
    );
  } else {
    self._darkColors = CustomColors(
      primary: color,
      secondary: self._darkColors.secondary,
    );
  }
  self._updatePrimaryColor.call(
    brightness == Brightness.light ? 'light' : 'dark',
    color.toARGB32(),
  );
}

void settingsUpdateSecondaryColor(
  SettingsController self,
  Brightness brightness,
  Color color,
) {
  if (brightness == Brightness.light) {
    self._lightColors = CustomColors(
      primary: self._lightColors.primary,
      secondary: color,
    );
  } else {
    self._darkColors = CustomColors(
      primary: self._darkColors.primary,
      secondary: color,
    );
  }
  self._updateSecondaryColor.call(
    brightness == Brightness.light ? 'light' : 'dark',
    color.toARGB32(),
  );
}

void settingsResetColors(SettingsController self) {
  self._lightColors = const CustomColors();
  self._darkColors = const CustomColors();
  self._resetColors.call();
}

Future<void> settingsSaveCurrentAsPreset(
  SettingsController self,
  String name,
) async {
  final preset = ColorPresetEntity(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: name,
    lightPrimary:
        (self._lightColors.primary ?? SettingsController._defaultLightPrimary)
            .toARGB32(),
    lightSecondary:
        (self._lightColors.secondary ??
                SettingsController._defaultLightSecondary)
            .toARGB32(),
    darkPrimary:
        (self._darkColors.primary ?? SettingsController._defaultDarkPrimary)
            .toARGB32(),
    darkSecondary:
        (self._darkColors.secondary ?? SettingsController._defaultDarkSecondary)
            .toARGB32(),
    createdAtIso: DateTime.now().toIso8601String(),
  );
  await self._savePreset.call(preset);
  self._presets.add(colorPresetFromEntity(preset));
}

void settingsApplyPreset(SettingsController self, ColorPreset preset) {
  self._lightColors = CustomColors(
    primary: preset.lightPrimary,
    secondary: preset.lightSecondary,
  );
  self._darkColors = CustomColors(
    primary: preset.darkPrimary,
    secondary: preset.darkSecondary,
  );
  self._updatePrimaryColor.call('light', preset.lightPrimary.toARGB32());
  self._updateSecondaryColor.call('light', preset.lightSecondary.toARGB32());
  self._updatePrimaryColor.call('dark', preset.darkPrimary.toARGB32());
  self._updateSecondaryColor.call('dark', preset.darkSecondary.toARGB32());
}

Future<void> settingsDeletePreset(SettingsController self, String id) async {
  await self._deletePreset.call(id);
  self._presets.removeWhere((p) => p.id == id);
}
