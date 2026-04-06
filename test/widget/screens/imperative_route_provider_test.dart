import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/theme_customization/presentation/pages/theme_customization_screen.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_settings_controller.dart';

/// Pushes that mirror production: [ThemeCustomizationScreen] uses
/// [rootNavigator] with [ChangeNotifierProvider.value].
void main() {
  group('ThemeCustomizationScreen (root navigator)', () {
    testWidgets(
      'has SettingsController after push (same pattern as ThemeSection)',
      (tester) async {
        final settings = FakeSettingsController();

        await tester.pumpWidget(
          ChangeNotifierProvider<SettingsController>.value(
            value: settings,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () {
                      final s = context.read<SettingsController>();
                      Navigator.of(context, rootNavigator: true).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ChangeNotifierProvider<SettingsController>.value(
                                value: s,
                                child: const ThemeCustomizationScreen(),
                              ),
                        ),
                      );
                    },
                    child: const Text('Open theme'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open theme'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        expect(find.text('Customize Appearance'), findsOneWidget);
      },
    );
  });
}
