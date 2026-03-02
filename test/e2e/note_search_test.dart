import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/data/sync_operation_adapter.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:nexus/features/notes/data/models/note.dart';
import 'package:nexus/features/notes/data/models/note_attachment.dart';
import 'package:nexus/features/notes/data/mappers/note_mapper.dart';
import 'package:nexus/features/notes/domain/repositories/note_repository_interface.dart';
import 'package:nexus/features/notes/data/repositories/note_repository_impl.dart';

import '../helpers/fake_google_drive_service.dart';
import '../helpers/fake_sync_service.dart';

void main() {
  late NoteRepositoryInterface repo;
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

    repo = NoteRepositoryImpl();
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

  group('Note Search E2E', () {
    test(
      'Keyword search finds matching notes across titles and content',
      () async {
        final n1 = Note(
          id: 'n1',
          title: 'Project Alpha Requirements',
          contentDeltaJson: jsonEncode([
            {'insert': 'Discussion about roadmap\n'},
          ]),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastModifiedByDevice: 'test-device',
        );
        final n2 = Note(
          id: 'n2',
          title: 'Grocery List',
          contentDeltaJson: jsonEncode([
            {'insert': 'Milk, Eggs, Bread\n'},
          ]),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastModifiedByDevice: 'test-device',
        );
        final n3 = Note(
          id: 'n3',
          title: 'Ideas',
          contentDeltaJson: jsonEncode([
            {'insert': 'Alpha team feedback\n'},
          ]),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastModifiedByDevice: 'test-device',
        );

        await repo.upsert(NoteMapper.toEntity(n1));
        await repo.upsert(NoteMapper.toEntity(n2));
        await repo.upsert(NoteMapper.toEntity(n3));

        // Search 'Alpha' -> should find n1 (title) and n3 (content)
        controller.setQuery('Alpha');
        final results = controller.visibleNotes;

        expect(results.length, 2);
        expect(results.map((n) => n.id), containsAll(['n1', 'n3']));
      },
    );

    test('Category filter + search query works together', () async {
      final workId = 'cat-work';
      final personalId = 'cat-personal';

      final n1 = Note(
        id: 'n1',
        title: 'Work Meeting',
        categoryId: workId,
        contentDeltaJson: '[]',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastModifiedByDevice: 'test-device',
      );
      final n2 = Note(
        id: 'n2',
        title: 'Work Project',
        categoryId: workId,
        contentDeltaJson: '[]',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastModifiedByDevice: 'test-device',
      );
      final n3 = Note(
        id: 'n3',
        title: 'Personal Project',
        categoryId: personalId,
        contentDeltaJson: '[]',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastModifiedByDevice: 'test-device',
      );

      await repo.upsert(NoteMapper.toEntity(n1));
      await repo.upsert(NoteMapper.toEntity(n2));
      await repo.upsert(NoteMapper.toEntity(n3));

      // Filter by Work category
      controller.setCategoryFilter(workId);
      expect(controller.visibleNotes.length, 2);

      // Add query 'Project' -> should find n2 only (n1 is 'Meeting', n3 is wrong category)
      controller.setQuery('Project');
      final results = controller.visibleNotes;

      expect(results.length, 1);
      expect(results.first.id, 'n2');
    });
  });
}
