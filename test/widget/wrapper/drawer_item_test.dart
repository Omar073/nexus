import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/wrapper/views/widgets/drawer_item.dart';

void main() {
  testWidgets('DrawerItem renders icon and label', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DrawerItem(
            icon: Icons.analytics,
            label: 'Analytics',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Analytics'), findsOneWidget);
    expect(find.byIcon(Icons.analytics), findsOneWidget);

    await tester.tap(find.byType(ListTile));
    expect(tapped, isTrue);
  });
}
