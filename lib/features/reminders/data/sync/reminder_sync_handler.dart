import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/handlers/entity_sync_handler.dart';
import 'package:nexus/core/services/sync/models/sync_conflict.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/core/utils/reminder_conflict_detector.dart';
import 'package:nexus/features/reminders/data/models/reminder.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';

/// Pushes and pulls reminders through sync.
class ReminderSyncHandler implements EntitySyncHandler<Reminder> {
  ReminderSyncHandler({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  final _conflictsController =
      StreamController<List<SyncConflict<Reminder>>>.broadcast();

  @override
  String get entityType => 'reminder';

  @override
  Stream<List<SyncConflict<Reminder>>> get conflictsStream =>
      _conflictsController.stream;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('reminders');

  /// Pushes a local operation to Firestore.
  ///
  /// - [create] or [update]: Writes reminder data into the Firestore document.
  /// - [delete]: Deletes the document from Firestore.
  ///
  /// Throws an error if the operation fails, which triggers a retry in [SyncService].
  @override
  Future<void> push(SyncOperation op) async {
    final doc = _collection.doc(op.entityId);
    final type = SyncOperationType.values[op.type];

    switch (type) {
      case SyncOperationType.create:
      case SyncOperationType.update:
        final data = (op.data ?? <String, dynamic>{});
        await doc.set(data, SetOptions(merge: true));
      case SyncOperationType.delete:
        await doc.delete();
    }
  }

  /// Pulls remote updates from Firestore since [lastSyncAt].
  ///
  /// 1. Queries reminders where `updatedAt > lastSyncAt`.
  /// 2. Compares each remote reminder with local.
  /// 3. Uses [ReminderConflictDetector] to detect conflicts.
  /// 4. Emits conflicts and marks local as conflicted.
  /// 5. Overwrites local with remote when no conflict.
  @override
  Future<void> pull(DateTime? lastSyncAt) async {
    final remindersBox = Hive.box<Reminder>(HiveBoxes.reminders);

    Query<Map<String, dynamic>> q = _collection;
    if (lastSyncAt != null) {
      q = q.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncAt));
    }

    final snap = await q.get();
    final conflicts = <SyncConflict<Reminder>>[];

    for (final doc in snap.docs) {
      final remote = Reminder.fromFirestoreJson(doc.data());
      final local = remindersBox.get(remote.id);

      // If we don't have it locally, just save the remote version.
      if (local == null) {
        await remindersBox.put(remote.id, remote);
        continue;
      }

      if (ReminderConflictDetector.hasConflict(local: local, remote: remote)) {
        local.syncStatusEnum = SyncStatus.conflict;
        await local.save();
        conflicts.add(
          SyncConflict(entityId: remote.id, local: local, remote: remote),
        );
        continue;
      }

      // No conflict: Remote version wins.
      await remindersBox.put(remote.id, remote);
    }

    if (conflicts.isNotEmpty) {
      _conflictsController.add(conflicts);
    }
  }
}
