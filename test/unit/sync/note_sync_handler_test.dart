import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/features/notes/models/note.dart';
import 'package:nexus/features/notes/models/note_attachment.dart';
import 'package:nexus/features/notes/sync/note_sync_handler.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late NoteSyncHandler handler;

  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(HiveTypeIds.note)) {
      Hive.registerAdapter(NoteAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.noteAttachment)) {
      Hive.registerAdapter(NoteAttachmentAdapter());
    }
    await Hive.openBox<Note>(HiveBoxes.notes);
    firestore = FakeFirebaseFirestore();
    handler = NoteSyncHandler(firestore: firestore, deviceId: 'test-device');
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('NoteSyncHandler.push', () {
    test('create merges doc with lastModifiedByDevice', () async {
      final op = SyncOperation(
        id: 'op1',
        type: SyncOperationType.create.index,
        entityType: 'note',
        entityId: 'n1',
        createdAt: DateTime.now(),
        data: {'id': 'n1', 'title': 'Test Note'},
      );

      await handler.push(op);

      final doc = await firestore.collection('notes').doc('n1').get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['title'], 'Test Note');
      expect(doc.data()!['lastModifiedByDevice'], 'test-device');
    });

    test('delete removes doc from Firestore', () async {
      await firestore.collection('notes').doc('n1').set({
        'id': 'n1',
        'title': 'Delete Me',
      });

      final op = SyncOperation(
        id: 'op2',
        type: SyncOperationType.delete.index,
        entityType: 'note',
        entityId: 'n1',
        createdAt: DateTime.now(),
      );

      await handler.push(op);

      final doc = await firestore.collection('notes').doc('n1').get();

      expect(doc.exists, isFalse);
    });
  });

  group('NoteSyncHandler.pull', () {
    test('saves new remote note locally', () async {
      final now = DateTime.now();
      await firestore.collection('notes').doc('n1').set({
        'id': 'n1',
        'title': 'Remote Note',
        'contentDeltaJson': '[]',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'lastModifiedByDevice': 'remote-device',
        'attachments': <Map<String, dynamic>>[],
      });

      await handler.pull(null);

      final box = Hive.box<Note>(HiveBoxes.notes);
      final local = box.get('n1');

      expect(local, isNotNull);
      expect(local!.title, 'Remote Note');
    });

    test('overwrites local when no conflict', () async {
      final now = DateTime.now();
      final older = now.subtract(const Duration(hours: 1));

      final box = Hive.box<Note>(HiveBoxes.notes);
      await box.put(
        'n1',
        Note(
          id: 'n1',
          title: 'Old Local',
          contentDeltaJson: '[]',
          createdAt: older,
          updatedAt: older,
          lastModifiedByDevice: 'device',
          isDirty: false,
          lastSyncedAt: older,
        ),
      );

      await firestore.collection('notes').doc('n1').set({
        'id': 'n1',
        'title': 'Updated Remote',
        'contentDeltaJson': '[{"insert":"hello"}]',
        'createdAt': Timestamp.fromDate(older),
        'updatedAt': Timestamp.fromDate(now),
        'lastModifiedByDevice': 'remote-device',
        'attachments': <Map<String, dynamic>>[],
      });

      await handler.pull(null);

      final updated = box.get('n1');
      expect(updated!.title, 'Updated Remote');
    });

    test('emits conflict when dirty and remote newer', () async {
      final now = DateTime.now();
      final syncTime = now.subtract(const Duration(hours: 2));

      final box = Hive.box<Note>(HiveBoxes.notes);
      await box.put(
        'n1',
        Note(
          id: 'n1',
          title: 'Dirty Local',
          contentDeltaJson: '[]',
          createdAt: syncTime,
          updatedAt: now,
          lastModifiedByDevice: 'device',
          isDirty: true,
          lastSyncedAt: syncTime,
        ),
      );

      await firestore.collection('notes').doc('n1').set({
        'id': 'n1',
        'title': 'Remote Newer',
        'contentDeltaJson': '[]',
        'createdAt': Timestamp.fromDate(syncTime),
        'updatedAt': Timestamp.fromDate(now.add(const Duration(minutes: 1))),
        'lastModifiedByDevice': 'remote-device',
        'attachments': <Map<String, dynamic>>[],
      });

      // Subscribe BEFORE pull so we catch the emission.
      final future = handler.conflictsStream.first;

      await handler.pull(null);

      final conflicts = await future;
      expect(conflicts, isNotEmpty);
    });
  });
}
