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

import '../../helpers/fake_google_drive_service.dart';
import '../../helpers/fake_sync_service.dart';

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

  Note makeNote({
    required String id,
    String? title,
    String content = 'hello',
    String? categoryId,
  }) {
    final now = DateTime.now();
    final delta = jsonEncode([
      {'insert': '$content\n'},
    ]);
    return Note(
      id: id,
      title: title,
      contentDeltaJson: delta,
      createdAt: now,
      updatedAt: now,
      lastModifiedByDevice: 'test-device',
      categoryId: categoryId,
    );
  }

  group('NoteController', () {
    test('createEmpty inserts note with default delta JSON', () async {
      final note = await controller.createEmpty();

      expect(repo.getById(note.id), isNotNull);

      final decoded = jsonDecode(note.contentDeltaJson) as List;
      expect(decoded.length, 1);
      expect(decoded.first['insert'], '\n');
    });

    test('visibleNotes filters by query (title + plain text)', () async {
      await repo.upsert(
        NoteMapper.toEntity(makeNote(id: 'n1', title: 'Shopping list')),
      );
      await repo.upsert(
        NoteMapper.toEntity(
          makeNote(id: 'n2', title: 'Meeting notes', content: 'buy groceries'),
        ),
      );
      await repo.upsert(
        NoteMapper.toEntity(makeNote(id: 'n3', title: 'Workout plan')),
      );

      controller.setQuery('groceries');
      final results = controller.visibleNotes;

      // n2 matches via plain text content.
      expect(results.length, 1);
      expect(results.first.id, 'n2');
    });

    test('setCategoryFilter restricts to matching categoryId', () async {
      await repo.upsert(
        NoteMapper.toEntity(
          makeNote(id: 'n1', title: 'Work', categoryId: 'cat-work'),
        ),
      );
      await repo.upsert(
        NoteMapper.toEntity(
          makeNote(id: 'n2', title: 'Personal', categoryId: 'cat-personal'),
        ),
      );

      controller.setCategoryFilter('cat-work');
      final results = controller.visibleNotes;

      expect(results.length, 1);
      expect(results.first.id, 'n1');
    });

    test('delete removes from repo and enqueues sync delete op', () async {
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

    test('updateCategory sets categoryId and marks dirty', () async {
      final note = await controller.createEmpty();
      await controller.updateCategory(note, 'cat-new');

      final updated = controller.byId(note.id)!;
      expect(updated.categoryId, 'cat-new');
      expect(updated.isDirty, isTrue);
    });
  });
}
