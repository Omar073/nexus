import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/settings/models/nav_bar_style.dart';
import 'package:nexus/features/wrapper/views/widgets/nav_bar_builder.dart';
import 'package:nexus/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget(NavBarStyle style) {
    return MaterialApp(
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        bottomNavigationBar: NavBarBuilder(
          style: style,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      ),
    );
  }

  testWidgets('NavBarBuilder renders standard NavigationBar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(NavBarStyle.standard));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('NavBarBuilder onDestinationSelected callback works', (
    WidgetTester tester,
  ) async {
    int? selectedIndex;

    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          bottomNavigationBar: NavBarBuilder(
            style: NavBarStyle.standard,
            selectedIndex: 0,
            onDestinationSelected: (index) => selectedIndex = index,
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
