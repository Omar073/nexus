import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/theme_customization/presentation/widgets/icons/icon_selection_section.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_settings_controller.dart';

void main() {
  testWidgets(
    'tapping an alternate dashboard icon updates SettingsController',
    (tester) async {
      final SettingsController settings = FakeSettingsController();

      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsController>.value(
          value: settings,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: IconSelectionSection()),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(settings.navigationIcons['dashboard'], isNull);

      await tester.tap(find.byIcon(Icons.grid_view_outlined).first);
      await tester.pump();

      expect(
        settings.navigationIcons['dashboard'],
        Icons.grid_view_outlined.codePoint,
      );
    },
  );

  testWidgets(
    'after switching to Tasks tab, tapping a tasks icon updates SettingsController',
    (tester) async {
      final SettingsController settings = FakeSettingsController();

      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsController>.value(
          value: settings,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: IconSelectionSection()),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      expect(settings.navigationIcons['tasks'], isNull);

      await tester.tap(find.byIcon(Icons.task_alt).first);
      await tester.pump();

      expect(settings.navigationIcons['tasks'], Icons.task_alt.codePoint);
    },
  );
}
