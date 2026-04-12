import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/wrapper/presentation/widgets/app_drawer.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_settings_repository.dart';

void main() {
  group('AppDrawer', () {
    Widget wrapWithSettings(Widget child) {
      return ChangeNotifierProvider(
        create: (_) => SettingsController(FakeSettingsRepository()),
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    testWidgets('renders all navigation items', (tester) async {
      await tester.pumpWidget(wrapWithSettings(const AppDrawer()));

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Habits'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
    });

    testWidgets('renders Nexus header', (tester) async {
      await tester.pumpWidget(wrapWithSettings(const AppDrawer()));

      expect(find.text('Nexus'), findsOneWidget);
      expect(find.text('Your productivity hub'), findsOneWidget);
    });

    testWidgets('has icons for each item', (tester) async {
      await tester.pumpWidget(wrapWithSettings(const AppDrawer()));

      expect(find.byType(Icon), findsWidgets);
    });
  });
}
