import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/analytics/presentation/widgets/quick_stat_tile.dart';

void main() {
  testWidgets('QuickStatTile renders icon, label, and value', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuickStatTile(
            icon: Icons.trending_up,
            label: 'Completion Rate',
            value: '85%',
            iconColor: Colors.green,
          ),
        ),
      ),
    );

    expect(find.text('Completion Rate'), findsOneWidget);
    expect(find.text('85%'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsOneWidget);

    // Check icon color
    final icon = tester.widget<Icon>(find.byIcon(Icons.trending_up));
    expect(icon.color, Colors.green);
  });
}
