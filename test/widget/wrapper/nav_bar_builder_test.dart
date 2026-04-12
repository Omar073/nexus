import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/wrapper/presentation/widgets/nav_bar_builder.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_settings_repository.dart';

void main() {
  Widget buildTestWidget(NavBarStyle style) {
    return ChangeNotifierProvider(
      create: (_) => SettingsController(FakeSettingsRepository()),
      child: MaterialApp(
        home: Scaffold(
          bottomNavigationBar: NavBarBuilder(
            style: style,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('NavBarBuilder renders standard navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(NavBarStyle.standard));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('NavBarBuilder onDestinationSelected callback works', (
    WidgetTester tester,
  ) async {
    int? selectedIndex;

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsController(FakeSettingsRepository()),
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: NavBarBuilder(
              style: NavBarStyle.standard,
              selectedIndex: 0,
              onDestinationSelected: (index) => selectedIndex = index,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on Tasks tab (index 1)
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    expect(selectedIndex, 1);
  });
}
