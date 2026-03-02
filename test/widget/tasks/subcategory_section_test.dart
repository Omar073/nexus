import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/tasks/presentation/widgets/sections/subcategory_section.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';

// Simple fake TaskController for testing (no actual implementation needed)
class FakeTaskController extends ChangeNotifier implements TaskController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeTaskController fakeTaskController;

  setUp(() {
    fakeTaskController = FakeTaskController();
  });

  group('SubcategorySection', () {
    testWidgets('renders subcategory name and task count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubcategorySection(
              name: 'Test Subcategory',
              tasks:
                  const [], // Use empty list to avoid Task constructor complexity
              taskController: fakeTaskController,
              isExpanded: true,
              onToggle: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Subcategory'), findsOneWidget);
      expect(find.text('(0)'), findsOneWidget);
    });

    testWidgets('shows expand icon when collapsed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubcategorySection(
              name: 'Collapsed Sub',
              tasks: const [],
              taskController: fakeTaskController,
              isExpanded: false,
              onToggle: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.keyboard_arrow_right), findsOneWidget);
    });

    testWidgets('shows collapse icon when expanded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubcategorySection(
              name: 'Expanded Sub',
              tasks: const [],
              taskController: fakeTaskController,
              isExpanded: true,
              onToggle: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('calls onToggle when header is tapped', (tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubcategorySection(
              name: 'Tappable Sub',
              tasks: const [],
              taskController: fakeTaskController,
              isExpanded: true,
              onToggle: () => toggled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(toggled, isTrue);
    });
  });
}
