import 'package:flutter/material.dart';
import 'package:nexus/features/calendar/controllers/calendar_controller.dart';

/// A list tile for displaying a calendar event (task or reminder).
class CalendarEventTile extends StatelessWidget {
  const CalendarEventTile({super.key, required this.item});

  final CalendarItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(item.type == 'task' ? Icons.checklist : Icons.alarm),
      title: Text(item.title),
      subtitle: Text(item.when.toString()),
    );
  }
}
