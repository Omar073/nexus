enum AppRoute {
  dashboard('/dashboard'),
  tasks('/tasks'),
  reminders('/reminders'),
  notes('/notes'),
  settings('/settings'),
  // Drawer items (not in bottom nav)
  habits('/habits'),
  calendar('/calendar'),
  analytics('/analytics');

  const AppRoute(this.path);
  final String path;
}
