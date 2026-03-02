import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/tasks/presentation/widgets/sections/category_header.dart';

void main() {
  group('CategoryHeader', () {
    testWidgets('renders title and task count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryHeader(
              title: 'Work Tasks',
              taskCount: 5,
              isExpanded: true,
            ),
          ),
        ),
      );

      // Title is uppercased in the widget
      expect(find.text('WORK TASKS'), findsOneWidget);
      // Task count is displayed as just the number
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows expand icon when collapsed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryHeader(
              title: 'Collapsed',
              taskCount: 0,
              isExpanded: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.keyboard_arrow_right), findsOneWidget);
    });

    testWidgets('shows collapse icon when expanded', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryHeader(
              title: 'Expanded',
              taskCount: 0,
              isExpanded: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });
  });
}
