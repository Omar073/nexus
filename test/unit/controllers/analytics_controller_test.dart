import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus/features/analytics/presentation/state_management/analytics_controller.dart';
import 'package:nexus/features/habits/presentation/state_management/habit_controller.dart';
import 'package:nexus/features/habits/data/models/habit.dart';
import 'package:nexus/features/reminders/presentation/state_management/reminder_controller.dart';
import 'package:nexus/features/reminders/data/models/reminder.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:nexus/features/tasks/data/mappers/task_mapper.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:nexus/features/tasks/data/models/task.dart';
import 'package:nexus/features/reminders/data/mappers/reminder_mapper.dart';
import 'package:nexus/features/habits/data/mappers/habit_mapper.dart';

class MockTaskController extends Mock implements TaskController {}

class MockReminderController extends Mock implements ReminderController {}

class MockHabitController extends Mock implements HabitController {}

void main() {
  late MockTaskController mockTasks;
  late MockReminderController mockReminders;
  late MockHabitController mockHabits;
  late AnalyticsController controller;

  setUpAll(() {
    registerFallbackValue(TaskStatus.active);
    registerFallbackValue(() {});
  });

  setUp(() {
    mockTasks = MockTaskController();
    mockReminders = MockReminderController();
    mockHabits = MockHabitController();

    // Default stubs
    when(() => mockTasks.addListener(any())).thenReturn(null);
    when(() => mockTasks.removeListener(any())).thenReturn(null);
    when(() => mockReminders.addListener(any())).thenReturn(null);
    when(() => mockReminders.removeListener(any())).thenReturn(null);
    when(() => mockHabits.addListener(any())).thenReturn(null);
    when(() => mockHabits.removeListener(any())).thenReturn(null);

    // Default data stubs
    when(() => mockTasks.tasksForStatus(any())).thenReturn([]);
    when(() => mockReminders.upcoming).thenReturn([]);
    when(() => mockHabits.habits).thenReturn([]);
    when(() => mockHabits.isCompletedToday(any())).thenReturn(false);
  });

  void createController() {
    controller = AnalyticsController(
      tasks: mockTasks,
      reminders: mockReminders,
      habits: mockHabits,
    );
  }

  group('AnalyticsController', () {
    test('initial snapshot should be empty', () {
      createController();
      final s = controller.snapshot;
      expect(s.activeTasks, 0);
      expect(s.completedTasks, 0);
      expect(s.overdueTasks, 0);
      expect(s.upcomingReminders, 0);
      expect(s.totalHabits, 0);
      expect(s.habitsDoneToday, 0);
    });

    test('should calculate active and completed tasks', () {
      final activeTask = Task(
        id: '1',
        title: 'Active',
        status: TaskStatus.active.index,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastModifiedByDevice: 'test',
      );
      final completedTask = Task(
        id: '2',
        title: 'Done',
        status: TaskStatus.completed.index,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastModifiedByDevice: 'test',
      );

      when(
        () => mockTasks.tasksForStatus(TaskStatus.active),
      ).thenReturn([TaskMapper.toEntity(activeTask)]);
      when(
        () => mockTasks.tasksForStatus(TaskStatus.completed),
      ).thenReturn([TaskMapper.toEntity(completedTask)]);

      createController();

      expect(controller.snapshot.activeTasks, 1);
      expect(controller.snapshot.completedTasks, 1);
    });

    test('should identify overdue tasks', () {
      final overdueTask = Task(
        id: '1',
        title: 'Overdue',
        status: TaskStatus.active.index,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastModifiedByDevice: 'test',
      );
      final futureTask = Task(
        id: '2',
        title: 'Future',
        status: TaskStatus.active.index,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastModifiedByDevice: 'test',
      );

      when(() => mockTasks.tasksForStatus(TaskStatus.active)).thenReturn([
        TaskMapper.toEntity(overdueTask),
        TaskMapper.toEntity(futureTask),
      ]);

      createController();

      expect(controller.snapshot.activeTasks, 2);
      expect(controller.snapshot.overdueTasks, 1);
    });

    test('should count upcoming reminders', () {
      final reminder = Reminder(
        id: '1',
        notificationId: 1,
        title: 'Test',
        time: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(
        () => mockReminders.upcoming,
      ).thenReturn([ReminderMapper.toEntity(reminder)]);

      createController();

      expect(controller.snapshot.upcomingReminders, 1);
    });

    test('should calculate habits progress', () {
      final habit1 = Habit(
        id: '1',
        title: 'H1',
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final habit2 = Habit(
        id: '2',
        title: 'H2',
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockHabits.habits).thenReturn([
        HabitMapper.toEntity(habit1),
        HabitMapper.toEntity(habit2),
      ]);
      when(() => mockHabits.isCompletedToday('1')).thenReturn(true);
      when(() => mockHabits.isCompletedToday('2')).thenReturn(false);

      createController();

      expect(controller.snapshot.totalHabits, 2);
      expect(controller.snapshot.habitsDoneToday, 1);
    });
  });
}
