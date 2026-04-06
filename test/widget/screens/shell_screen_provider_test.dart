import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/features/analytics/presentation/pages/analytics_screen.dart';
import 'package:nexus/features/analytics/presentation/state_management/analytics_controller.dart';
import 'package:nexus/features/calendar/presentation/pages/calendar_screen.dart';
import 'package:nexus/features/calendar/presentation/state_management/calendar_controller.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:nexus/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:nexus/features/habits/data/repositories/habit_log_repository_impl.dart';
import 'package:nexus/features/habits/data/repositories/habit_repository_impl.dart';
import 'package:nexus/features/habits/domain/repositories/habit_log_repository_interface.dart';
import 'package:nexus/features/habits/domain/repositories/habit_repository_interface.dart';
import 'package:nexus/features/habits/presentation/pages/habits_screen.dart';
import 'package:nexus/features/habits/presentation/state_management/habit_controller.dart';
import 'package:nexus/features/notes/data/repositories/note_repository_impl.dart';
import 'package:nexus/features/notes/domain/repositories/note_repository_interface.dart';
import 'package:nexus/features/notes/presentation/pages/notes_list_screen.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:nexus/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:nexus/features/reminders/domain/repositories/reminder_repository_interface.dart';
import 'package:nexus/features/reminders/presentation/pages/reminders_screen.dart';
import 'package:nexus/features/reminders/presentation/state_management/reminder_controller.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:nexus/features/tasks/domain/repositories/task_repository_interface.dart';
import 'package:nexus/features/tasks/presentation/pages/tasks_screen.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:provider/provider.dart';
import '../../helpers/fake_google_drive_service.dart';
import '../../helpers/fake_notification_service.dart';
import '../../helpers/fake_settings_controller.dart';
import '../../helpers/fake_sync_service.dart';
import '../../helpers/test_hive_all_boxes.dart';

/// Smoke tests: each primary shell screen must build under a [MultiProvider]
/// stack that includes its [Provider]s, or a [ProviderNotFoundException] surfaces.
///
/// Not covered here (async / Firebase / connectivity on init): settings and
/// splash. See [imperative_route_provider_test.dart] and
/// [note_editor_screen_push_test.dart].
void main() {
  late FakeSettingsController settings;
  late FakeSyncService syncService;
  late FakeGoogleDriveService driveService;
  late FakeNotificationService notifications;

  late TaskRepositoryInterface taskRepo;
  late ReminderRepositoryInterface reminderRepo;
  late NoteRepositoryInterface noteRepo;
  late HabitRepositoryInterface habitRepo;
  late HabitLogRepositoryInterface habitLogRepo;

  late TaskController taskController;
  late ReminderController reminderController;
  late HabitController habitController;
  late NoteController noteController;
  late CategoryController categoryController;
  late CalendarController calendarController;
  late AnalyticsController analyticsController;

  Future<void> pumpWithAllProviders(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsController>.value(value: settings),
          ChangeNotifierProvider<TaskController>.value(value: taskController),
          ChangeNotifierProvider<ReminderController>.value(
            value: reminderController,
          ),
          ChangeNotifierProvider<HabitController>.value(value: habitController),
          ChangeNotifierProvider<NoteController>.value(value: noteController),
          ChangeNotifierProvider<CategoryController>.value(
            value: categoryController,
          ),
          ChangeNotifierProvider<CalendarController>.value(
            value: calendarController,
          ),
          ChangeNotifierProvider<AnalyticsController>.value(
            value: analyticsController,
          ),
        ],
        child: MaterialApp(home: home),
      ),
    );
  }

  setUp(() async {
    await setUpTestHiveAllBoxes();

    settings = FakeSettingsController();
    syncService = FakeSyncService();
    driveService = FakeGoogleDriveService();
    notifications = FakeNotificationService();

    taskRepo = TaskRepositoryImpl();
    reminderRepo = ReminderRepositoryImpl();
    noteRepo = NoteRepositoryImpl();
    habitRepo = HabitRepositoryImpl();
    habitLogRepo = HabitLogRepositoryImpl();

    taskController = TaskController(
      repo: taskRepo,
      syncService: syncService,
      googleDrive: driveService,
      settings: settings,
      deviceId: 'test-device',
    );
    reminderController = ReminderController(
      repo: reminderRepo,
      notifications: notifications,
      syncService: syncService,
    );
    habitController = HabitController(
      habits: habitRepo,
      logs: habitLogRepo,
      syncService: syncService,
    );
    noteController = NoteController(
      repo: noteRepo,
      syncService: syncService,
      googleDrive: driveService,
      deviceId: 'test-device',
    );
    categoryController = CategoryController();
    calendarController = CalendarController(
      tasks: taskController,
      reminders: reminderController,
    );
    analyticsController = AnalyticsController(
      tasks: taskController,
      reminders: reminderController,
      habits: habitController,
    );
  });

  tearDown(() async {
    analyticsController.dispose();
    calendarController.dispose();
    categoryController.dispose();
    noteController.dispose();
    habitController.dispose();
    reminderController.dispose();
    taskController.dispose();
    await tearDownTestHive();
  });

  testWidgets('DashboardScreen', (tester) async {
    await pumpWithAllProviders(tester, const DashboardScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('TasksScreen', (tester) async {
    await pumpWithAllProviders(tester, const TasksScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.byType(TasksScreen), findsOneWidget);
  });

  testWidgets('RemindersScreen', (tester) async {
    await pumpWithAllProviders(tester, const RemindersScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.byType(RemindersScreen), findsOneWidget);
  });

  testWidgets('NotesListScreen', (tester) async {
    await pumpWithAllProviders(tester, const NotesListScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.byType(NotesListScreen), findsOneWidget);
  });

  testWidgets('HabitsScreen', (tester) async {
    await pumpWithAllProviders(tester, const HabitsScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.byType(HabitsScreen), findsOneWidget);
  });

  testWidgets('CalendarScreen', (tester) async {
    await pumpWithAllProviders(tester, const CalendarScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.byType(CalendarScreen), findsOneWidget);
  });

  testWidgets('AnalyticsScreen', (tester) async {
    await pumpWithAllProviders(tester, const AnalyticsScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.byType(AnalyticsScreen), findsOneWidget);
  });
}
