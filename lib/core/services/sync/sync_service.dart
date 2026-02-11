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

// =============================================================================
// SYNC CONFLICT MODEL
// =============================================================================

/// Represents a conflict between local and remote versions of an entity.
///
/// Conflicts occur when:
/// 1. Local entity has unsynced changes (isDirty = true)
/// 2. Remote entity was updated after our last sync
///
/// The UI can subscribe to conflict streams and present resolution options.
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

// =============================================================================
// SYNC SERVICE
// =============================================================================

/// Core synchronization service for offline-first data management.
///
/// ## Architecture Overview
/// ```
/// User Action → Local Write (Hive) → Queue SyncOperation → Push to Firestore
///                                                              ↓
/// UI Updated ← Local Write (Hive) ← Pull from Firestore ← Network Restored
/// ```
///
/// ## Key Responsibilities
/// - **Auto-sync**: Listens to connectivity changes, syncs when online
/// - **Push queue**: Sends pending local changes to Firestore
/// - **Pull updates**: Fetches remote changes since last sync
/// - **Conflict detection**: Identifies and emits sync conflicts for resolution
///
/// ## Usage
/// ```dart
/// final syncService = SyncService(
///   firestore: FirebaseFirestore.instance,
///   connectivity: connectivityService,
///   deviceId: 'device-123',
/// );
/// syncService.startAutoSync(); // Call once at app startup
/// ```
class SyncService {
  // ---------------------------------------------------------------------------
  // Constructor & Dependencies
  // ---------------------------------------------------------------------------

  SyncService({
    required FirebaseFirestore firestore,
    required ConnectivityService connectivity,
    required String deviceId,
  }) : _firestore = firestore,
       _connectivity = connectivity,
       _deviceId = deviceId;

  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivity;

  /// Device ID stamped on all synced documents for conflict detection.
  final String _deviceId;

  // ---------------------------------------------------------------------------
  // Conflict Streams
  // ---------------------------------------------------------------------------

  /// Stream of task conflicts detected during pull operations.
  /// Subscribe to this in your UI to show conflict resolution dialogs.
  final _conflictsController =
      StreamController<List<SyncConflict<Task>>>.broadcast();
  Stream<List<SyncConflict<Task>>> get conflictsStream =>
      _conflictsController.stream;

  /// Stream of note conflicts detected during pull operations.
  final _noteConflictsController =
      StreamController<List<SyncConflict<Note>>>.broadcast();
  Stream<List<SyncConflict<Note>>> get noteConflictsStream =>
      _noteConflictsController.stream;

  // ---------------------------------------------------------------------------
  // Sync State
  // ---------------------------------------------------------------------------

  /// Guards against concurrent sync operations.
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // ---------------------------------------------------------------------------
  // Firestore Collection References
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _tasksCol =>
      _firestore.collection('tasks');
  CollectionReference<Map<String, dynamic>> get _notesCol =>
      _firestore.collection('notes');

  // ===========================================================================
  // PUBLIC API
  // ===========================================================================

  /// Starts automatic sync when connectivity is restored.
  ///
  /// Call this **once** at app startup. Sets up a listener on the connectivity
  /// stream that triggers [syncOnce] whenever the device comes online.
  Future<void> startAutoSync() async {
    _connectivity.onlineStream().listen((online) {
      if (online) {
        unawaited(syncOnce());
      }
    });
  }

  /// Adds a sync operation to the queue for later processing.
  ///
  /// Operations are stored in Hive and processed in order during [syncOnce].
  Future<void> enqueueOperation(SyncOperation op) async {
    final box = Hive.box<SyncOperation>(HiveBoxes.syncOps);
    await box.put(op.id, op);
  }

  /// Executes a full sync cycle: push local changes, then pull remote updates.
  ///
  /// This method is idempotent and safe to call multiple times. It will:
  /// 1. Skip if already syncing (prevents concurrent syncs)
  /// 2. Skip if offline
  /// 3. Push all pending operations to Firestore
  /// 4. Pull all remote changes since last sync
  /// 5. Update the last successful sync timestamp
  Future<void> syncOnce() async {
    // Guard: prevent concurrent sync operations
    if (_isSyncing) return;

    // Guard: skip if offline
    if (!await _connectivity.isOnline) return;

    _isSyncing = true;

    try {
      await _pushQueue(); // Push local → Firestore
      await _pullTasks(); // Pull Firestore → local (tasks)
      await _pullNotes(); // Pull Firestore → local (notes)
      await _markSuccessfulSync(); // Update lastSuccessfulSyncAt
    } finally {
      _isSyncing = false;
    }
  }

  // ===========================================================================
  // PUSH OPERATIONS (Local → Firestore)
  // ===========================================================================

  /// Processes all pending sync operations in queue order.
  ///
  /// Operations are sorted by [createdAt] to maintain causality (e.g., create
  /// before update). Each operation is processed individually with retry logic.
  Future<void> _pushQueue() async {
    final box = Hive.box<SyncOperation>(HiveBoxes.syncOps);

    // Get pending/failed operations, sorted by creation time
    final ops =
        box.values
            .where((o) => o.status != SyncOperationStatus.completed.index)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final op in ops) {
      // Re-check connectivity before each operation
      if (!await _connectivity.isOnline) return;
      await _processOperation(op);
    }
  }

  /// Processes a single sync operation with retry and backoff.
  ///
  /// Flow:
  /// 1. Mark operation as "syncing"
  /// 2. Apply to Firestore based on entity type
  /// 3. On success: delete from queue
  /// 4. On failure: increment retry count, apply exponential backoff
  Future<void> _processOperation(SyncOperation op) async {
    // Update status to "syncing"
    op.status = SyncOperationStatus.syncing.index;
    op.lastAttemptAt = DateTime.now();
    await op.save();

    try {
      // Route to appropriate handler based on entity type
      if (op.entityType == 'task') {
        await _applyTaskOperation(op);
      } else if (op.entityType == 'note') {
        await _applyNoteOperation(op);
      } else {
        throw StateError('Unknown entityType: ${op.entityType}');
      }

      // Success: mark complete and remove from queue
      op.status = SyncOperationStatus.completed.index;
      await op.save();
      await op.delete();
    } catch (_) {
      // Failure: increment retry count and apply backoff
      op.retryCount += 1;
      op.status = SyncOperationStatus.failed.index;
      await op.save();

      // Exponential backoff: 1s, 2s, 4s, 8s, 16s (capped at 5 retries)
      if (op.retryCount <= 5) {
        final seconds = computeBackoffSeconds(op.retryCount);
        await Future<void>.delayed(Duration(seconds: seconds));
      }
    }
  }

  /// Applies a task sync operation to Firestore.
  Future<void> _applyTaskOperation(SyncOperation op) async {
    final doc = _tasksCol.doc(op.entityId);
    final type = SyncOperationType.values[op.type];

    switch (type) {
      case SyncOperationType.create:
      case SyncOperationType.update:
        // Merge data with device ID for conflict tracking
        final data = (op.data ?? <String, dynamic>{})
          ..['lastModifiedByDevice'] = _deviceId;
        await doc.set(data, SetOptions(merge: true));
      case SyncOperationType.delete:
        await doc.delete();
    }
  }

  /// Applies a note sync operation to Firestore.
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

  // ===========================================================================
  // PULL OPERATIONS (Firestore → Local)
  // ===========================================================================

  /// Pulls task updates from Firestore since last sync.
  ///
  /// Uses incremental sync: only fetches documents with `updatedAt` greater
  /// than our last successful sync timestamp. This reduces bandwidth and
  /// processing time significantly.
  ///
  /// Conflict Detection:
  /// - If local task has unsynced changes (isDirty) AND remote was updated
  ///   after our last sync → emit conflict for user resolution
  /// - Otherwise → accept remote as source of truth
  Future<void> _pullTasks() async {
    final tasksBox = Hive.box<Task>(HiveBoxes.tasks);
    final metaBox = Hive.box<SyncMetadata>(HiveBoxes.syncMetadata);
    final meta = metaBox.get('default');
    final lastSyncAt = meta?.lastSuccessfulSyncAt;

    // Build query: all tasks, or only those updated since last sync
    Query<Map<String, dynamic>> q = _tasksCol;
    if (lastSyncAt != null) {
      q = q.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncAt));
    }

    final snap = await q.get();
    final conflicts = <SyncConflict<Task>>[];

    for (final doc in snap.docs) {
      final remote = Task.fromFirestoreJson(doc.data());
      final local = tasksBox.get(remote.id);

      // New task: just save it
      if (local == null) {
        await tasksBox.put(remote.id, remote);
        continue;
      }

      // Check for conflict using TaskConflictDetector
      if (TaskConflictDetector.hasConflict(local: local, remote: remote)) {
        local.syncStatusEnum = SyncStatus.conflict;
        await local.save();
        conflicts.add(
          SyncConflict(entityId: remote.id, local: local, remote: remote),
        );
        continue;
      }

      // No conflict: accept remote version
      await tasksBox.put(remote.id, remote);
    }

    // Emit conflicts to stream for UI handling
    if (conflicts.isNotEmpty) {
      _conflictsController.add(conflicts);
    }
  }

  /// Pulls note updates from Firestore since last sync.
  ///
  /// Similar to [_pullTasks] but with note-specific conflict detection:
  /// - Conflict if local is dirty AND remote updatedAt > local lastSyncedAt
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

      // New note: just save it
      if (local == null) {
        await notesBox.put(remote.id, remote);
        continue;
      }

      // Conflict detection for notes
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

      // No conflict: accept remote version
      await notesBox.put(remote.id, remote);
    }

    if (conflicts.isNotEmpty) {
      _noteConflictsController.add(conflicts);
    }
  }

  // ===========================================================================
  // SYNC METADATA
  // ===========================================================================

  /// Updates the last successful sync timestamp.
  ///
  /// This timestamp is used for incremental pulls: next sync will only fetch
  /// documents updated after this time, significantly reducing data transfer.
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
