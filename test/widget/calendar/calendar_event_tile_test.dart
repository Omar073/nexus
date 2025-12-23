import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/calendar/controllers/calendar_controller.dart';
import 'package:nexus/features/calendar/views/widgets/calendar_event_tile.dart';

void main() {
  testWidgets('CalendarEventTile renders task item correctly', (
    WidgetTester tester,
  ) async {
    final item = CalendarItem(
      id: '1',
      title: 'Test Task',
      when: DateTime(2024, 1, 15, 10, 30),
      type: 'task',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CalendarEventTile(item: item)),
      ),
    );

    expect(find.text('Test Task'), findsOneWidget);
    expect(find.byIcon(Icons.checklist), findsOneWidget);
  });

  testWidgets('CalendarEventTile renders reminder item correctly', (
    WidgetTester tester,
  ) async {
    final item = CalendarItem(
      id: '2',
      title: 'Test Reminder',
      when: DateTime(2024, 1, 15, 14, 0),
      type: 'reminder',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CalendarEventTile(item: item)),
      ),
    );

    expect(find.text('Test Reminder'), findsOneWidget);
    expect(find.byIcon(Icons.alarm), findsOneWidget);
  });
}
