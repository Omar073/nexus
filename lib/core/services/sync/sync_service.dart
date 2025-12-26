import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/sync_metadata.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/utils/sync_backoff.dart';
import 'package:nexus/core/utils/task_conflict_detector.dart';
import 'package:nexus/features/notes/models/note.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';

class SyncConflict<T> {
  SyncConflict({
    required this.entityId,
    required this.local,
    required this.remote,
  });
  final String entityId;
  final T local;
  final T remote;
}

class SyncService {
  SyncService({
    required FirebaseFirestore firestore,
    required ConnectivityService connectivity,
    required String deviceId,
  }) : _firestore = firestore,
       _connectivity = connectivity,
       _deviceId = deviceId;

  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivity;
  final String _deviceId;

  final _conflictsController =
      StreamController<List<SyncConflict<Task>>>.broadcast();
  Stream<List<SyncConflict<Task>>> get conflictsStream =>
      _conflictsController.stream;

  final _noteConflictsController =
      StreamController<List<SyncConflict<Note>>>.broadcast();
  Stream<List<SyncConflict<Note>>> get noteConflictsStream =>
      _noteConflictsController.stream;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  CollectionReference<Map<String, dynamic>> get _tasksCol =>
      _firestore.collection('tasks');
  CollectionReference<Map<String, dynamic>> get _notesCol =>
      _firestore.collection('notes');

  Future<void> startAutoSync() async {
    _connectivity.onlineStream().listen((online) {
      if (online) {
        unawaited(syncOnce());
      }
    });
  }

  Future<void> enqueueOperation(SyncOperation op) async {
    final box = Hive.box<SyncOperation>(HiveBoxes.syncOps);
    await box.put(op.id, op);
  }

  Future<void> syncOnce() async {
    if (_isSyncing) return;
    if (!await _connectivity.isOnline) return;
    _isSyncing = true;

    try {
      await _pushQueue();
      await _pullTasks();
      await _pullNotes();
      await _markSuccessfulSync();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushQueue() async {
    final box = Hive.box<SyncOperation>(HiveBoxes.syncOps);
    final ops =
        box.values
            .where((o) => o.status != SyncOperationStatus.completed.index)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final op in ops) {
      if (!await _connectivity.isOnline) return;
      await _processOperation(op);
    }
  }

  Future<void> _processOperation(SyncOperation op) async {
    op.status = SyncOperationStatus.syncing.index;
    op.lastAttemptAt = DateTime.now();
    await op.save();

    try {
      if (op.entityType == 'task') {
        await _applyTaskOperation(op);
      } else if (op.entityType == 'note') {
        await _applyNoteOperation(op);
      } else {
        // Unknown entity type; mark failed.
        throw StateError('Unknown entityType: ${op.entityType}');
      }
      op.status = SyncOperationStatus.completed.index;
      await op.save();
      await op.delete();
    } catch (_) {
      op.retryCount += 1;
      op.status = SyncOperationStatus.failed.index;
      await op.save();
      // Exponential backoff (1,2,4,8,16,32s) capped at 5 retries.
      if (op.retryCount <= 5) {
        final seconds = computeBackoffSeconds(op.retryCount);
        await Future<void>.delayed(Duration(seconds: seconds));
      }
    }
  }

  Future<void> _applyTaskOperation(SyncOperation op) async {
    final doc = _tasksCol.doc(op.entityId);
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

  Future<void> _applyNoteOperation(SyncOperation op) async {
    final doc = _notesCol.doc(op.entityId);
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

  Future<void> _pullTasks() async {
    final tasksBox = Hive.box<Task>(HiveBoxes.tasks);
    final metaBox = Hive.box<SyncMetadata>(HiveBoxes.syncMetadata);
    final meta = metaBox.get('default');
    final lastSyncAt = meta?.lastSuccessfulSyncAt;

    Query<Map<String, dynamic>> q = _tasksCol;
    if (lastSyncAt != null) {
      q = q.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncAt));
    }

    final snap = await q.get();
    final conflicts = <SyncConflict<Task>>[];

    for (final doc in snap.docs) {
      final remote = Task.fromFirestoreJson(doc.data());
      final local = tasksBox.get(remote.id);

      if (local == null) {
        await tasksBox.put(remote.id, remote);
        continue;
      }

      // Conflict: local has unsynced changes and remote changed after last local sync.
      if (TaskConflictDetector.hasConflict(local: local, remote: remote)) {
        local.syncStatusEnum = SyncStatus.conflict;
        await local.save();
        conflicts.add(
          SyncConflict(entityId: remote.id, local: local, remote: remote),
        );
        continue;
      }

      // No conflict: accept remote as source of truth.
      await tasksBox.put(remote.id, remote);
    }

    if (conflicts.isNotEmpty) {
      _conflictsController.add(conflicts);
    }
  }

  Future<void> _pullNotes() async {
    final notesBox = Hive.box<Note>(HiveBoxes.notes);
    final metaBox = Hive.box<SyncMetadata>(HiveBoxes.syncMetadata);
    final meta = metaBox.get('default');
    final lastSyncAt = meta?.lastSuccessfulSyncAt;

    Query<Map<String, dynamic>> q = _notesCol;
    if (lastSyncAt != null) {
      q = q.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncAt));
    }

    final snap = await q.get();
    final conflicts = <SyncConflict<Note>>[];

    for (final doc in snap.docs) {
      final remote = Note.fromFirestoreJson(doc.data());
      final local = notesBox.get(remote.id);

      if (local == null) {
        await notesBox.put(remote.id, remote);
        continue;
      }

      final localLastSync = local.lastSyncedAt;
      final localDirty = local.isDirty;
      final remoteNewerThanLocalSync =
          localLastSync != null && remote.updatedAt.isAfter(localLastSync);

      if (localDirty && remoteNewerThanLocalSync) {
        local.syncStatusEnum = SyncStatus.conflict;
        await local.save();
        conflicts.add(
          SyncConflict(entityId: remote.id, local: local, remote: remote),
        );
        continue;
      }

      await notesBox.put(remote.id, remote);
    }

    if (conflicts.isNotEmpty) {
      _noteConflictsController.add(conflicts);
    }
  }

  Future<void> _markSuccessfulSync() async {
    final metaBox = Hive.box<SyncMetadata>(HiveBoxes.syncMetadata);
    final existing = metaBox.get('default');
    if (existing == null) {
      await metaBox.put(
        'default',
        SyncMetadata(id: 'default', lastSuccessfulSyncAt: DateTime.now()),
      );
    } else {
      existing.lastSuccessfulSyncAt = DateTime.now();
      await existing.save();
    }
  }
}
