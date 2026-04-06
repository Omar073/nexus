import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/data/sync_metadata.dart';
import 'package:nexus/core/services/sync/sync_service.dart';

import '../../helpers/fake_connectivity_service.dart';
import '../../helpers/fake_entity_sync_handler.dart';

/// Hive adapters for SyncOperation and SyncMetadata.
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

void main() {
  late FakeConnectivityService connectivity;
  late FakeEntitySyncHandler<dynamic> taskHandler;
  late SyncService syncService;

  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(HiveTypeIds.syncOperation)) {
      Hive.registerAdapter(_SyncOpAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.syncMetadata)) {
      Hive.registerAdapter(SyncMetadataAdapter());
    }
    await Hive.openBox<SyncOperation>(HiveBoxes.syncOps);
    await Hive.openBox<SyncMetadata>(HiveBoxes.syncMetadata);

    connectivity = FakeConnectivityService(online: true);
    taskHandler = FakeEntitySyncHandler<dynamic>(type: 'task');
    syncService = SyncService(
      connectivity: connectivity,
      handlers: [taskHandler],
    );
  });

  tearDown(() async {
    connectivity.dispose();
    taskHandler.dispose();
    await tearDownTestHive();
  });

  group('SyncService.syncOnce', () {
    test('skips when already syncing', () async {
      // Make pull slow so the first sync is still running
      // when we start the second.
      taskHandler.pullDelay = const Duration(milliseconds: 100);

      final first = syncService.syncOnce();
      // Small delay to let first sync reach _isSyncing = true
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final second = syncService.syncOnce();
      await first;
      await second;

      // Only one pull should have happened
      expect(taskHandler.pullCalls.length, 1);
    });

    test('skips when offline', () async {
      connectivity.online = false;

      await syncService.syncOnce();

      expect(taskHandler.pullCalls, isEmpty);
    });

    test('pushes then pulls when online', () async {
      await syncService.syncOnce();

      expect(taskHandler.pullCalls.length, 1);
    });

    test('delegates push to correct handler', () async {
      final box = Hive.box<SyncOperation>(HiveBoxes.syncOps);
      final op = SyncOperation(
        id: 'op1',
        type: SyncOperationType.create.index,
        entityType: 'task',
        entityId: 't1',
        createdAt: DateTime.now(),
        data: {'id': 't1', 'title': 'Test'},
      );
      await box.put(op.id, op);

      await syncService.syncOnce();

      expect(taskHandler.pushedOps.length, 1);
      expect(taskHandler.pushedOps.first.entityId, 't1');
    });

    test('deletes op with unknown entity type', () async {
      final box = Hive.box<SyncOperation>(HiveBoxes.syncOps);
      final op = SyncOperation(
        id: 'op-unknown',
        type: SyncOperationType.create.index,
        entityType: 'unknown_entity',
        entityId: 'x1',
        createdAt: DateTime.now(),
      );
      await box.put(op.id, op);

      await syncService.syncOnce();

      // Op should be deleted from box
      expect(box.get('op-unknown'), isNull);
    });
  });

  group('SyncService._markFailed', () {
    test('writes through Hive box for detached ops', () async {
      final box = Hive.box<SyncOperation>(HiveBoxes.syncOps);

      // Not put in box (detached HiveObject).
      final op = SyncOperation(
        id: 'detached-op',
        type: SyncOperationType.update.index,
        entityType: 'task',
        entityId: 't-detached',
        createdAt: DateTime.now(),
      );

      await syncService.markFailedForTesting(op);

      final stored = box.get('detached-op');
      expect(stored, isNotNull);
      expect(stored!.status, SyncOperationStatus.failed.index);
      expect(stored.retryCount, 1);
    });
  });

  group('SyncService.enqueueOperation', () {
    test('stores operation in Hive box', () async {
      final op = SyncOperation(
        id: 'eq1',
        type: SyncOperationType.update.index,
        entityType: 'task',
        entityId: 't2',
        createdAt: DateTime.now(),
      );

      await syncService.enqueueOperation(op);

      final box = Hive.box<SyncOperation>(HiveBoxes.syncOps);
      expect(box.get('eq1'), isNotNull);
    });
  });
}
