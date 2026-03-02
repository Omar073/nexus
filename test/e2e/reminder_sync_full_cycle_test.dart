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
import 'package:nexus/features/reminders/data/models/reminder.dart';
import 'package:nexus/features/reminders/data/sync/reminder_sync_handler.dart';

import '../helpers/fake_connectivity_service.dart';

/// Hive adapter for SyncOperation (duplicated from other sync tests).
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

/// E2E: Full sync cycle for reminders with real SyncService +
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
    if (!Hive.isAdapterRegistered(HiveTypeIds.reminder)) {
      Hive.registerAdapter(ReminderAdapter());
    }

    await Hive.openBox<SyncOperation>(HiveBoxes.syncOps);
    await Hive.openBox<SyncMetadata>(HiveBoxes.syncMetadata);
    await Hive.openBox<Reminder>(HiveBoxes.reminders);

    connectivity = FakeConnectivityService(online: true);
    firestore = FakeFirebaseFirestore();
    final reminderHandler = ReminderSyncHandler(firestore: firestore);
    syncService = SyncService(
      connectivity: connectivity,
      handlers: [reminderHandler],
    );
  });

  tearDown(() async {
    connectivity.dispose();
    await tearDownTestHive();
  });

  group('Reminder sync full cycle E2E', () {
    test('enqueue → push → pull round-trip', () async {
      // 1. Enqueue a create op for a reminder
      final now = DateTime.now();
      final reminderData = <String, dynamic>{
        'id': 'e2e-r1',
        'notificationId': 1,
        'title': 'E2E Reminder',
        // Store dates as ISO strings so Hive can serialize the payload snapshot.
        'time': now.toIso8601String(),
        'snoozeMinutes': null,
        'taskId': null,
        'completedAt': null,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final op = SyncOperation(
        id: 'e2e-rem-op1',
        type: SyncOperationType.create.index,
        entityType: 'reminder',
        entityId: 'e2e-r1',
        createdAt: now,
        data: reminderData,
      );

      await syncService.enqueueOperation(op);

      // 2. Sync pushes op to FakeFirestore
      await syncService.syncOnce();

      final doc = await firestore.collection('reminders').doc('e2e-r1').get();
      expect(doc.exists, isTrue);

      // 3. Simulate remote update
      await firestore.collection('reminders').doc('e2e-r1').update({
        'title': 'Updated remotely',
        'updatedAt': Timestamp.fromDate(now.add(const Duration(hours: 1))),
      });

      // 4. Sync pulls remote change into Hive
      await syncService.syncOnce();

      final reminderBox = Hive.box<Reminder>(HiveBoxes.reminders);
      final pulled = reminderBox.get('e2e-r1');
      expect(pulled, isNotNull);
      expect(pulled!.title, 'Updated remotely');
    });
  });
}
