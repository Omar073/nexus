import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/features/tasks/data/models/task.dart';
import 'package:nexus/features/tasks/data/models/task_attachment.dart';
import 'package:nexus/features/tasks/data/sync/task_sync_handler.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late TaskSyncHandler handler;

  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(HiveTypeIds.task)) {
      Hive.registerAdapter(TaskAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.taskAttachment)) {
      Hive.registerAdapter(TaskAttachmentAdapter());
    }
    await Hive.openBox<Task>(HiveBoxes.tasks);
    firestore = FakeFirebaseFirestore();
    handler = TaskSyncHandler(firestore: firestore, deviceId: 'test-device');
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('TaskSyncHandler.push', () {
    test('create merges doc with lastModifiedByDevice', () async {
      final op = SyncOperation(
        id: 'op1',
        type: SyncOperationType.create.index,
        entityType: 'task',
        entityId: 't1',
        createdAt: DateTime.now(),
        data: {'id': 't1', 'title': 'Test'},
      );

      await handler.push(op);

      final doc = await firestore.collection('tasks').doc('t1').get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['title'], 'Test');
      expect(doc.data()!['lastModifiedByDevice'], 'test-device');
    });

    test('delete removes doc from Firestore', () async {
      await firestore.collection('tasks').doc('t1').set({
        'id': 't1',
        'title': 'Test',
      });

      final op = SyncOperation(
        id: 'op2',
        type: SyncOperationType.delete.index,
        entityType: 'task',
        entityId: 't1',
        createdAt: DateTime.now(),
      );

      await handler.push(op);

      final doc = await firestore.collection('tasks').doc('t1').get();

      expect(doc.exists, isFalse);
    });
  });

  group('TaskSyncHandler.pull', () {
    test('saves new remote task locally', () async {
      final now = DateTime.now();
      await firestore.collection('tasks').doc('t1').set({
        'id': 't1',
        'title': 'Remote Task',
        'status': 0,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'lastModifiedByDevice': 'remote-device',
        'recurringRule': 0,
        'attachments': <Map<String, dynamic>>[],
      });

      await handler.pull(null);

      final box = Hive.box<Task>(HiveBoxes.tasks);
      final local = box.get('t1');

      expect(local, isNotNull);
      expect(local!.title, 'Remote Task');
    });

    test('overwrites local when no conflict exists', () async {
      final now = DateTime.now();
      final older = now.subtract(const Duration(hours: 1));

      final box = Hive.box<Task>(HiveBoxes.tasks);
      await box.put(
        't1',
        Task(
          id: 't1',
          title: 'Old Local',
          status: 0,
          createdAt: older,
          updatedAt: older,
          lastModifiedByDevice: 'device',
          isDirty: false,
          lastSyncedAt: older,
        ),
      );

      await firestore.collection('tasks').doc('t1').set({
        'id': 't1',
        'title': 'Updated Remote',
        'status': 0,
        'createdAt': Timestamp.fromDate(older),
        'updatedAt': Timestamp.fromDate(now),
        'lastModifiedByDevice': 'remote-device',
        'recurringRule': 0,
        'attachments': <Map<String, dynamic>>[],
      });

      await handler.pull(null);

      final updated = box.get('t1');
      expect(updated!.title, 'Updated Remote');
    });

    test('emits conflict when local is dirty and remote newer', () async {
      final now = DateTime.now();
      final syncTime = now.subtract(const Duration(hours: 2));

      final box = Hive.box<Task>(HiveBoxes.tasks);
      await box.put(
        't1',
        Task(
          id: 't1',
          title: 'Local Dirty',
          status: 0,
          createdAt: syncTime,
          updatedAt: now,
          lastModifiedByDevice: 'device',
          isDirty: true,
          lastSyncedAt: syncTime,
        ),
      );

      await firestore.collection('tasks').doc('t1').set({
        'id': 't1',
        'title': 'Remote Newer',
        'status': 0,
        'createdAt': Timestamp.fromDate(syncTime),
        'updatedAt': Timestamp.fromDate(now.add(const Duration(minutes: 1))),
        'lastModifiedByDevice': 'remote-device',
        'recurringRule': 0,
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
