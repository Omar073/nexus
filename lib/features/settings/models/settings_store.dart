import 'package:flutter/material.dart';
import 'package:nexus/app/theme/app_colors.dart';
import 'package:nexus/features/settings/models/nav_bar_style.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  static const _keyThemeMode = 'settings.theme_mode';
  static const _keyCompletedRetentionDays = 'settings.completed_retention_days';
  static const _keyAutoDeleteCompletedTasks =
      'settings.auto_delete_completed_tasks';
  static const _keyNavBarStyle = 'settings.nav_bar_style';
  static const _keyDarkPalette = 'settings.dark_palette';

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyThemeMode);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'dark',
    };
    await prefs.setString(_keyThemeMode, value);
  }

  Future<int> loadCompletedRetentionDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCompletedRetentionDays) ?? 30;
  }

  Future<void> saveCompletedRetentionDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCompletedRetentionDays, days);
  }

  Future<bool> loadAutoDeleteCompletedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoDeleteCompletedTasks) ?? false;
  }

  Future<void> saveAutoDeleteCompletedTasks(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoDeleteCompletedTasks, enabled);
  }

  Future<NavBarStyle> loadNavBarStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyNavBarStyle);
    return switch (raw) {
      'curved' => NavBarStyle.curved,
      'notch' => NavBarStyle.notch,
      'google' => NavBarStyle.google,
      _ => NavBarStyle.standard,
    };
  }

  Future<void> saveNavBarStyle(NavBarStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNavBarStyle, style.name);
  }

  Future<DarkPalette> loadDarkPalette() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyDarkPalette);
    return switch (raw) {
      'amoled' => DarkPalette.amoled,
      _ => DarkPalette.navy, // Navy is default
    };
  }

  Future<void> saveDarkPalette(DarkPalette palette) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDarkPalette, palette.name);
  }
}
