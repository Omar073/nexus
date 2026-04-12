import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/settings/presentation/pages/developer_options_screen.dart';

import '../../helpers/fake_notification_service.dart';

void main() {
  group('DeveloperOptionsScreen', () {
    testWidgets('posts test reminder notification on Android', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final fake = FakeNotificationService();
        await tester.pumpWidget(
          MaterialApp(home: DeveloperOptionsScreen(notifications: fake)),
        );

        await tester.tap(find.text('Show test reminder notification'));
        await tester.pumpAndSettle();

        expect(fake.shownNow[kDeveloperTestNotificationId], isNotNull);
        expect(
          fake.shownNow[kDeveloperTestNotificationId],
          contains('Developer test'),
        );
        expect(find.text('Test notification posted'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('shows unsupported hint on non-mobile desktop', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: DeveloperOptionsScreen(
              notifications: FakeNotificationService(),
            ),
          ),
        );

        expect(
          find.textContaining('Local notifications are only exercised'),
          findsOneWidget,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
