import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/l10n/app_localizations.dart';

void main() {
  testWidgets('Localization delegates load (en)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Text(AppLocalizations.of(context)!.navTasks),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Tasks'), findsOneWidget);
  });
}
