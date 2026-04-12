import 'package:flutter/material.dart';

class NavIconMapper {
  /// Maps a page name to its current selected icon code point.
  /// If no icon is set, returns a default icon.
  static IconData getIconForPage(
    String page,
    Map<String, int> selections, {
    bool isSelected = false,
  }) {
    final codePoint = selections[page];
    final IconData baseIcon;

    if (codePoint == null) {
      baseIcon = _getDefaultIcon(page);
    } else {
      baseIcon = IconData(codePoint, fontFamily: 'MaterialIcons');
    }

    if (!isSelected) return baseIcon;

    // Return the filled counterpart if it exists
    return _filledCounterparts[baseIcon] ?? baseIcon;
  }

  /// Returns the best \"selected\" (typically filled) variant for a given icon.
  /// If no filled counterpart exists, returns the original icon.
  static IconData selectedVariant(IconData icon) {
    return _filledCounterparts[icon] ?? icon;
  }

  /// A unified superset of all icons available across pages.
  ///
  /// Useful for \"Show all icons\" experiences while still keeping per-page
  /// curated defaults.
  static List<IconData> get allSelectableIcons {
    final seen = <int>{};
    final result = <IconData>[];

    for (final icons in selectableIcons.values) {
      for (final icon in icons) {
        if (seen.add(icon.codePoint)) {
          result.add(icon);
        }
      }
    }

    return result;
  }

  static IconData _getDefaultIcon(String page) {
    return switch (page) {
      'dashboard' => Icons.space_dashboard_outlined,
      'tasks' => Icons.check_circle_outline,
      'reminders' => Icons.all_inclusive,
      'notes' => Icons.edit_note_rounded,
      'settings' => Icons.tune_rounded,
      'habits' => Icons.insights_outlined,
      'calendar' => Icons.calendar_month_outlined,
      'analytics' => Icons.analytics_outlined,
      _ => Icons.circle_outlined,
    };
  }

  /// Maps outlined icons to their filled counterparts.
  static final Map<IconData, IconData> _filledCounterparts = {
    Icons.space_dashboard_outlined: Icons.space_dashboard,
    Icons.grid_view_outlined: Icons.grid_view,
    Icons.bubble_chart_outlined: Icons.bubble_chart,
    Icons.insights: Icons.insights,
    Icons.track_changes: Icons.track_changes,

    Icons.check_circle_outline: Icons.check_circle,
    Icons.task_alt: Icons.task_alt,
    Icons.format_list_bulleted_rounded: Icons.format_list_bulleted_rounded,
    Icons.checklist_rtl_outlined: Icons.checklist_rtl,

    Icons.edit_note_rounded: Icons.edit_note_rounded,
    Icons.sticky_note_2_outlined: Icons.sticky_note_2,
    Icons.text_snippet_outlined: Icons.text_snippet,
    Icons.subject_rounded: Icons.subject_rounded,

    Icons.all_inclusive: Icons.all_inclusive,
    Icons.loop_rounded: Icons.loop_rounded,
    Icons.change_circle_outlined: Icons.change_circle,
    Icons.route_outlined: Icons.route,

    Icons.tune_rounded: Icons.tune_rounded,
    Icons.person_outline_rounded: Icons.person_rounded,
    Icons.settings_outlined: Icons.settings,

    Icons.dashboard_outlined: Icons.dashboard,
    Icons.checklist_outlined: Icons.checklist,
    Icons.alarm_outlined: Icons.alarm,
    Icons.note_outlined: Icons.note,
    Icons.insights_outlined: Icons.insights,
    Icons.calendar_month_outlined: Icons.calendar_month,
    Icons.analytics_outlined: Icons.analytics,
  };

  /// Lists of selectable icons for each page category as requested by the user.
  static const Map<String, List<IconData>> selectableIcons = {
    'dashboard': [
      Icons.space_dashboard_outlined,
      Icons.grid_view_outlined,
      Icons.bubble_chart_outlined,
      Icons.insights,
      Icons.track_changes,
    ],
    'tasks': [
      Icons.check_circle_outline,
      Icons.task_alt,
      Icons.format_list_bulleted_rounded,
      Icons.checklist_rtl_outlined,
      Icons.checklist_outlined,
    ],
    'reminders': [
      Icons.all_inclusive,
      Icons.loop_rounded,
      Icons.change_circle_outlined,
      Icons.route_outlined,
      Icons.alarm_outlined,
    ],
    'notes': [
      Icons.edit_note_rounded,
      Icons.sticky_note_2_outlined,
      Icons.text_snippet_outlined,
      Icons.subject_rounded,
      Icons.note_outlined,
    ],
    'settings': [
      Icons.tune_rounded,
      Icons.person_outline_rounded,
      Icons.settings_outlined,
    ],
    'habits': [
      Icons.insights_outlined,
      Icons.track_changes,
      Icons.loop_rounded,
    ],
    'calendar': [Icons.calendar_month_outlined, Icons.grid_view_outlined],
    'analytics': [
      Icons.analytics_outlined,
      Icons.insights,
      Icons.bubble_chart_outlined,
    ],
  };
}
