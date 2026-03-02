import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/wrapper/presentation/widgets/app_drawer.dart';

void main() {
  group('AppDrawer', () {
    testWidgets('renders all navigation items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const Scaffold(body: AppDrawer())),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Habits'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
    });

    testWidgets('renders Nexus header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const Scaffold(body: AppDrawer())),
      );

      expect(find.text('Nexus'), findsOneWidget);
      expect(find.text('Your productivity hub'), findsOneWidget);
    });

    testWidgets('has correct icons for each item', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const Scaffold(body: AppDrawer())),
      );

      expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
      expect(find.byIcon(Icons.insights_outlined), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
    });
  });
}
