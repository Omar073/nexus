import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/handlers/entity_sync_handler.dart';
import 'package:nexus/core/services/sync/models/sync_conflict.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/core/utils/task_conflict_detector.dart';
import 'package:nexus/features/tasks/data/models/task.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';

class TaskSyncHandler implements EntitySyncHandler<Task> {
  TaskSyncHandler({
    required FirebaseFirestore firestore,
    required String deviceId,
  }) : _firestore = firestore,
       _deviceId = deviceId;

  final FirebaseFirestore _firestore;
  final String _deviceId;

  final _conflictsController =
      StreamController<List<SyncConflict<Task>>>.broadcast();

  @override
  String get entityType => 'task';

  @override
  Stream<List<SyncConflict<Task>>> get conflictsStream =>
      _conflictsController.stream;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('tasks');

  /// Pushes a local operation to Firestore.
  ///
  /// - [create] or [update]: Merges the task data into the Firestore document.
  ///   We also append `lastModifiedByDevice` to help trace who made the change.
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
        final data = (op.data ?? <String, dynamic>{})
          ..['lastModifiedByDevice'] = _deviceId;
        await doc.set(data, SetOptions(merge: true));
      case SyncOperationType.delete:
        await doc.delete();
    }
  }

  /// Fetches remote updates from Firestore since [lastSyncAt].
  ///
  /// 1. Queries tasks where `updatedAt > lastSyncAt`.
  /// 2. Iterates through results and compares with local version.
  /// 3. Uses [TaskConflictDetector] to identify conflicts (remote newer + local dirty).
  /// 4. If conflict: emits to [conflictsStream] and marks local as conflicted.
  /// 5. If no conflict: overwrites local task with remote version (resolving `isDirty`).
  @override
  Future<void> pull(DateTime? lastSyncAt) async {
    final tasksBox = Hive.box<Task>(HiveBoxes.tasks);

    Query<Map<String, dynamic>> q = _collection;
    if (lastSyncAt != null) {
      q = q.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncAt));
    }

    final snap = await q.get();
    final conflicts = <SyncConflict<Task>>[];

    for (final doc in snap.docs) {
      final remote = Task.fromFirestoreJson(doc.data());
      final local = tasksBox.get(remote.id);

      // If we don't have it locally, just save the remote version.
      if (local == null) {
        await tasksBox.put(remote.id, remote);
        continue;
      }

      // Check for conflicts:
      // A conflict exists if we have unsynced local changes (isDirty) AND
      // the remote version is newer than our last sync.
      if (TaskConflictDetector.hasConflict(local: local, remote: remote)) {
        local.syncStatusEnum = SyncStatus.conflict;
        await local.save();
        conflicts.add(
          SyncConflict(entityId: remote.id, local: local, remote: remote),
        );
        continue;
      }

      // No conflict: Remote version wins (overwrites local).
      // This also resets `isDirty` to false via `Task.fromFirestoreJson`.
      await tasksBox.put(remote.id, remote);
    }

    if (conflicts.isNotEmpty) {
      _conflictsController.add(conflicts);
    }
  }
}
