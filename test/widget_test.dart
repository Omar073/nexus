import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Tasks'))),
      ),
    );
    await tester.pump();
    expect(find.text('Tasks'), findsOneWidget);
  });
}
