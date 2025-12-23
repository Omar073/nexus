import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/analytics/views/widgets/legend_item.dart';

void main() {
  testWidgets('LegendItem renders color and label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LegendItem(color: Colors.blue, label: 'Active'),
        ),
      ),
    );

    expect(find.text('Active'), findsOneWidget);

    // Check colored container
    final containerFinder = find.byType(Container);
    expect(containerFinder, findsOneWidget);

    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, Colors.blue);
  });
}
