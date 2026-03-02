import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/dashboard/presentation/widgets/stat_card.dart';

void main() {
  testWidgets('StatCard renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatCard(
            icon: Icons.abc,
            label: 'Test Label',
            value: '42',
            color: Colors.red,
          ),
        ),
      ),
    );

    expect(find.text('Test Label'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.byIcon(Icons.abc), findsOneWidget);

    // Check color
    final icon = tester.widget<Icon>(find.byIcon(Icons.abc));
    expect(icon.color, Colors.red);
  });
}
