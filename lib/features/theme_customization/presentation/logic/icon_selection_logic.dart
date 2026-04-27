import 'package:flutter/material.dart';

typedef NavIconTab = ({String id, String label});

const navIconTabs = <NavIconTab>[
  (id: 'dashboard', label: 'Dashboard'),
  (id: 'tasks', label: 'Tasks'),
  (id: 'reminders', label: 'Reminders'),
  (id: 'notes', label: 'Notes'),
  (id: 'settings', label: 'Settings'),
  (id: 'habits', label: 'Habits'),
  (id: 'calendar', label: 'Calendar'),
  (id: 'analytics', label: 'Analytics'),
];

List<IconData> dedupeIconsByCodePoint(Iterable<IconData> icons) {
  final seen = <int>{};
  final result = <IconData>[];
  for (final icon in icons) {
    if (seen.add(icon.codePoint)) {
      result.add(icon);
    }
  }
  return result;
}
