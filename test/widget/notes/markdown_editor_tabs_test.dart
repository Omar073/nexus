import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/markdown/markdown_editor_area.dart';

void main() {
  testWidgets('MarkdownEditorArea defaults to Edit tab when content is empty', (
    tester,
  ) async {
    final controller = TextEditingController(text: '');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownEditorArea(
            controller: controller,
            layout: MarkdownLayout.tabs,
          ),
        ),
      ),
    );

    final tabController = DefaultTabController.of(
      tester.element(find.byType(TabBar)),
    );
    expect(tabController.index, 0);
  });

  testWidgets(
    'MarkdownEditorArea defaults to Preview tab when content is not empty',
    (tester) async {
      final controller = TextEditingController(text: 'Some content');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownEditorArea(
              controller: controller,
              layout: MarkdownLayout.tabs,
            ),
          ),
        ),
      );

      final tabController = DefaultTabController.of(
        tester.element(find.byType(TabBar)),
      );
      expect(tabController.index, 1);
    },
  );
}
