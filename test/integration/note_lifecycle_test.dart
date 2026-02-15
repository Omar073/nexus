import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/data/sync_operation_adapter.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/features/notes/controllers/note_controller.dart';
import 'package:nexus/features/notes/models/note.dart';
import 'package:nexus/features/notes/models/note_attachment.dart';
import 'package:nexus/features/notes/models/note_repository.dart';

import '../helpers/fake_google_drive_service.dart';
import '../helpers/fake_sync_service.dart';

void main() {
  late NoteRepository repo;
  late FakeSyncService syncService;
  late FakeGoogleDriveService driveService;
  late NoteController controller;

  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(HiveTypeIds.note)) {
      Hive.registerAdapter(NoteAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.noteAttachment)) {
      Hive.registerAdapter(NoteAttachmentAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.syncOperation)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }

    await Hive.openBox<Note>(HiveBoxes.notes);
    await Hive.openBox<SyncOperation>(HiveBoxes.syncOps);

    repo = NoteRepository();
    syncService = FakeSyncService();
    driveService = FakeGoogleDriveService();

    controller = NoteController(
      repo: repo,
      syncService: syncService,
      googleDrive: driveService,
      deviceId: 'test-device',
    );
  });

  tearDown(() async {
    controller.dispose();
    await tearDownTestHive();
  });

  group('Note Lifecycle Integration', () {
    test('Create -> Save -> Verify persistence', () async {
      final note = await controller.createEmpty();

      // Simulate typing (auto-save is usually debounced in UI, but here we call update)
      // NoteController doesn't have explicit "updateContent" method exposed easily
      // other than via Quill controller which we don't have here.
      // But we can check implicit save on creation.
      expect(repo.getById(note.id), isNotNull);

      // Verify default content
      final content = jsonDecode(note.contentDeltaJson);
      expect(content, isNotEmpty);
    });

    test('Search filters work across multiple notes', () async {
      // Create notes directly in repo to simulate existing state
      final n1 = Note(
        id: 'n1',
        title: 'Flutter',
        contentDeltaJson: jsonEncode([
          {'insert': 'Dart\n'},
        ]),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastModifiedByDevice: 'test-device',
      );
      final n2 = Note(
        id: 'n2',
        title: 'React',
        contentDeltaJson: jsonEncode([
          {'insert': 'JS\n'},
        ]),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastModifiedByDevice: 'test-device',
      );

      await repo.upsert(n1);
      await repo.upsert(n2);

      controller.setQuery('Flutter');
      var results = controller.visibleNotes;
      expect(results.length, 1);
      expect(results.first.id, 'n1');

      controller.setQuery('JS');
      results = controller.visibleNotes;
      expect(results.length, 1);
      expect(results.first.id, 'n2');
    });

    test('Delete note removes it and syncs', () async {
      final note = await controller.createEmpty();
      syncService.enqueuedOps.clear();

      await controller.delete(note);

      expect(repo.getById(note.id), isNull);
      expect(syncService.enqueuedOps.length, 1);
      expect(
        syncService.enqueuedOps.first.type,
        SyncOperationType.delete.index,
      );
    });
  });
}
