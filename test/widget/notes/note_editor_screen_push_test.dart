import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/data/sync_operation_adapter.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/features/categories/data/models/category.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:nexus/features/notes/data/models/note.dart';
import 'package:nexus/features/notes/data/models/note_attachment.dart';
import 'package:nexus/features/notes/data/repositories/note_repository_impl.dart';
import 'package:nexus/features/notes/domain/repositories/note_repository_interface.dart';
import 'package:nexus/features/notes/presentation/pages/note_editor_screen.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_google_drive_service.dart';
import '../../helpers/fake_sync_service.dart';

/// Guards against [ProviderNotFoundException] when opening the note editor from a
/// [Navigator] route that uses [Navigator.of] with [rootNavigator] true.
///
/// Uses a missing note id so [NoteEditorScreen] stops at the lightweight
/// "Note not found" branch (no Quill), which keeps the test fast and stable.
///
/// Related: `test/widget/screens/imperative_route_provider_test.dart` (theme +
/// habit pushes), `test/widget/screens/shell_screen_provider_test.dart` (tab
/// shell screens).
void main() {
  late NoteRepositoryInterface repo;
  late FakeSyncService syncService;
  late FakeGoogleDriveService driveService;
  late NoteController controller;
  late CategoryController categories;

  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(HiveTypeIds.category)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.note)) {
      Hive.registerAdapter(NoteAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.noteAttachment)) {
      Hive.registerAdapter(NoteAttachmentAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.syncOperation)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }

    await Hive.openBox<Category>(HiveBoxes.categories);
    await Hive.openBox<Note>(HiveBoxes.notes);
    await Hive.openBox<SyncOperation>(HiveBoxes.syncOps);

    repo = NoteRepositoryImpl();
    syncService = FakeSyncService();
    driveService = FakeGoogleDriveService();

    controller = NoteController(
      repo: repo,
      syncService: syncService,
      googleDrive: driveService,
      deviceId: 'test-device',
    );
    categories = CategoryController();
  });

  tearDown(() async {
    controller.dispose();
    categories.dispose();
    await tearDownTestHive();
  });

  testWidgets(
    'NoteEditorScreen.push provides NoteController on root navigator route',
    (tester) async {
      const id = '__missing_note__';

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<NoteController>.value(value: controller),
            ChangeNotifierProvider<CategoryController>.value(value: categories),
            Provider<GoogleDriveService>.value(value: driveService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: TextButton(
                    onPressed: () => NoteEditorScreen.push(context, id),
                    child: const Text('Open editor'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open editor'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Note not found'), findsOneWidget);
    },
  );

  testWidgets('wrapWithRequiredProviders provides editor dependencies', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<NoteController>.value(value: controller),
          ChangeNotifierProvider<CategoryController>.value(value: categories),
          Provider<GoogleDriveService>.value(value: driveService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => NoteEditorScreen.wrapWithRequiredProviders(
                context,
                child: const _ProviderProbe(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('ok'), findsOneWidget);
  });
}

class _ProviderProbe extends StatelessWidget {
  const _ProviderProbe();

  @override
  Widget build(BuildContext context) {
    context.watch<NoteController>();
    context.watch<CategoryController>();
    context.read<GoogleDriveService>();
    return const Text('ok');
  }
}
