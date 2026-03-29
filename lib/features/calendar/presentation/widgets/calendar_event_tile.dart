import 'package:flutter/material.dart';
import 'package:nexus/features/calendar/presentation/state_management/calendar_controller.dart';

/// One row for a task, reminder, or habit on a date.
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
