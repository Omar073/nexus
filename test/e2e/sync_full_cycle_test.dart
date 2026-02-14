import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/data/sync_metadata.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_attachment.dart';
import 'package:nexus/features/tasks/sync/task_sync_handler.dart';

import '../helpers/fake_connectivity_service.dart';

/// Hive adapter for SyncOperation (duplicated from unit test).
class _SyncOpAdapter extends TypeAdapter<SyncOperation> {
  @override
  final int typeId = HiveTypeIds.syncOperation;

  @override
  SyncOperation read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return SyncOperation(
      id: fields[0] as String,
      type: fields[1] as int,
      entityType: fields[2] as String,
      entityId: fields[3] as String,
      data: (fields[4] as Map?)?.cast<String, dynamic>(),
      retryCount: (fields[5] as int?) ?? 0,
      createdAt: fields[6] as DateTime,
      lastAttemptAt: fields[7] as DateTime?,
      status: (fields[8] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, SyncOperation obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.entityType)
      ..writeByte(3)
      ..write(obj.entityId)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.retryCount)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.lastAttemptAt)
      ..writeByte(8)
      ..write(obj.status);
  }
}

/// E2E: Full sync cycle with real SyncService +
/// FakeFirebaseFirestore + Hive.
void main() {
  late FakeConnectivityService connectivity;
  late FakeFirebaseFirestore firestore;
  late SyncService syncService;

  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(HiveTypeIds.syncOperation)) {
      Hive.registerAdapter(_SyncOpAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.syncMetadata)) {
      Hive.registerAdapter(SyncMetadataAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.task)) {
      Hive.registerAdapter(TaskAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.taskAttachment)) {
      Hive.registerAdapter(TaskAttachmentAdapter());
    }
    await Hive.openBox<SyncOperation>(HiveBoxes.syncOps);
    await Hive.openBox<SyncMetadata>(HiveBoxes.syncMetadata);
    await Hive.openBox<Task>(HiveBoxes.tasks);

    connectivity = FakeConnectivityService(online: true);
    firestore = FakeFirebaseFirestore();
    final taskHandler = TaskSyncHandler(
      firestore: firestore,
      deviceId: 'test-device',
    );
    syncService = SyncService(
      connectivity: connectivity,
      handlers: [taskHandler],
    );
  });

  tearDown(() async {
    connectivity.dispose();
    await tearDownTestHive();
  });

  group('Sync full cycle E2E', () {
    test('enqueue → push → pull round-trip', () async {
      // 1. Enqueue a create op
      final now = DateTime.now();
      final task = Task(
        id: 'e2e-t1',
        title: 'E2E Task',
        status: 0,
        createdAt: now,
        updatedAt: now,
        lastModifiedByDevice: 'test-device',
      );
      // Use plain map data with ISO 8601 strings (not Timestamps,
      // which Hive can't serialize).
      final taskData = <String, dynamic>{
        'id': task.id,
        'title': task.title,
        'status': task.status,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'lastModifiedByDevice': 'test-device',
        'recurringRule': 0,
        'attachments': <Map<String, dynamic>>[],
      };
      final op = SyncOperation(
        id: 'e2e-op1',
        type: SyncOperationType.create.index,
        entityType: 'task',
        entityId: task.id,
        createdAt: now,
        data: taskData,
      );
      await syncService.enqueueOperation(op);

      // 2. Sync pushes op to FakeFirestore
      await syncService.syncOnce();

      final doc = await firestore.collection('tasks').doc('e2e-t1').get();
      expect(doc.exists, isTrue);

      // 3. Simulate remote update
      await firestore.collection('tasks').doc('e2e-t1').update({
        'title': 'Updated Remotely',
        'updatedAt': Timestamp.fromDate(now.add(const Duration(hours: 1))),
      });

      // 4. Sync pulls remote change into Hive
      await syncService.syncOnce();

      final taskBox = Hive.box<Task>(HiveBoxes.tasks);
      final pulled = taskBox.get('e2e-t1');
      expect(pulled, isNotNull);
      expect(pulled!.title, 'Updated Remotely');
    });

    test('skips sync when offline', () async {
      connectivity.online = false;

      final op = SyncOperation(
        id: 'offline-op',
        type: SyncOperationType.create.index,
        entityType: 'task',
        entityId: 'offline-t1',
        createdAt: DateTime.now(),
        data: {'id': 'offline-t1', 'title': 'Offline'},
      );
      await syncService.enqueueOperation(op);
      await syncService.syncOnce();

      // Op should remain in queue (not pushed)
      final box = Hive.box<SyncOperation>(HiveBoxes.syncOps);
      expect(box.get('offline-op'), isNotNull);
    });
  });
}
