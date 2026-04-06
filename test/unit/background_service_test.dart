import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus/core/services/notifications/reminder_notifications.dart';
import 'package:nexus/features/reminders/data/services/reminder_workmanager_callback.dart';
import 'package:nexus/features/reminders/data/models/reminder.dart';

/// Mock Hive [Box] for reminder background tests.

class MockBox extends Mock implements Box<Reminder> {}

/// Mock notification port for background tests.

class MockReminderNotifications extends Mock implements ReminderNotifications {}

/// Mock [Reminder] model for scheduler tests.

class MockReminder extends Mock implements Reminder {}

void main() {
  late MockBox mockBox;
  late MockReminderNotifications mockNotifications;

  setUp(() {
    mockBox = MockBox();
    mockNotifications = MockReminderNotifications();
    // Register fallback values if needed
    registerFallbackValue(
      Reminder(
        id: 'fallback',
        title: 'fallback',
        time: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notificationId: 0,
      ),
    );
  });

  test(
    'handleBackgroundCheck finds due reminders and triggers notification',
    () async {
      // Arrange
      final now = DateTime.now();
      final pastTime = now.subtract(const Duration(minutes: 5));

      final reminder = MockReminder();
      when(() => reminder.completedAt).thenReturn(null);
      when(() => reminder.notifiedAt).thenReturn(null);
      when(() => reminder.time).thenReturn(pastTime);
      when(() => reminder.notificationId).thenReturn(1);
      when(() => reminder.title).thenReturn('Test Reminder');
      when(() => reminder.id).thenReturn('r1');
      when(() => reminder.save()).thenAnswer((_) async {});

      when(() => mockBox.values).thenReturn([reminder]);
      when(
        () => mockNotifications.showNow(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      // Act
      final result = await handleBackgroundCheck(
        box: mockBox,
        notifications: mockNotifications,
      );

      // Assert
      expect(result, true);
      verify(
        () => mockNotifications.showNow(
          id: 1,
          title: 'Reminder',
          body: 'Test Reminder',
          payload: 'r1',
        ),
      ).called(1);
    },
  );

  test('handleBackgroundCheck ignores completed reminders', () async {
    // Arrange
    final now = DateTime.now();
    final pastTime = now.subtract(const Duration(minutes: 5));

    final reminder = MockReminder();
    when(() => reminder.completedAt).thenReturn(now); // Completed
    when(() => reminder.notifiedAt).thenReturn(null);
    when(() => reminder.time).thenReturn(pastTime);

    when(() => mockBox.values).thenReturn([reminder]);

    // Act
    await handleBackgroundCheck(box: mockBox, notifications: mockNotifications);

    // Assert
    verifyNever(
      () => mockNotifications.showNow(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    );
  });

  test('handleBackgroundCheck ignores future reminders', () async {
    // Arrange
    final now = DateTime.now();
    final futureTime = now.add(const Duration(minutes: 5)); // Future

    final reminder = MockReminder();
    when(() => reminder.completedAt).thenReturn(null);
    when(() => reminder.notifiedAt).thenReturn(null);
    when(() => reminder.time).thenReturn(futureTime);

    when(() => mockBox.values).thenReturn([reminder]);

    // Act
    await handleBackgroundCheck(box: mockBox, notifications: mockNotifications);

    // Assert
    verifyNever(
      () => mockNotifications.showNow(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    );
  });
}
