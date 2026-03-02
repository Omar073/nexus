import 'dart:async';

import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/sync_metadata.dart';
import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/services/sync/handlers/entity_sync_handler.dart';
import 'package:nexus/core/utils/sync_backoff.dart';

/// Core synchronization service (Orchestrator).
///
/// This service:
/// 1. Manages the Sync Queue (Push)
/// 2. Manages Connectivity events
/// 3. Delegates entity-specific logic to [EntitySyncHandler] implementations.
class SyncService {
  // Constructor & Dependencies
  SyncService({
    required ConnectivityService connectivity,
    List<EntitySyncHandler> handlers = const [],
  }) : _connectivity = connectivity {
    for (final handler in handlers) {
      _register(handler);
    }
  }

  final ConnectivityService _connectivity;

  // Strategy Handlers
  final Map<String, EntitySyncHandler> _handlers = {};

  void _register(EntitySyncHandler handler) {
    _handlers[handler.entityType] = handler;
  }

  /// Returns the conflict stream for [entityType] if a handler is registered.
  /// Type is untyped so core has no dependency on feature entities/models.
  /// Consumers (e.g. [SyncController]) cast to the concrete type (e.g. [Stream<List<SyncConflict<Task>>>]).
  Stream getConflictStream(String entityType) {
    final handler = _handlers[entityType];
    if (handler != null) {
      return (handler as dynamic).conflictsStream;
    }
    return const Stream.empty();
  }

  // Sync State
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // PUBLIC API
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
    // Then this queue is pushed to firestore by _pushQueue()
  }

  /// Executes a full sync cycle: push queue → pull updates.
  Future<void> syncOnce() async {
    if (_isSyncing) return;
    if (!await _connectivity.isOnline) return;

    _isSyncing = true;

    try {
      await _pushQueue();
      await _pullAll();
      await _markSuccessfulSync();
    } finally {
      _isSyncing = false;
    }
  }

  // PUSH OPERATIONS
  // -----------------------------------------------------------------------------
  // Orchestrator Role:
  // 1. Reads the queue (Manager).
  // 2. Directs work to the correct Handler (Worker).
  // 3. Handles retries/backoff if the Worker fails (Supervisor).
  // -----------------------------------------------------------------------------
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

    final handler = _handlers[op.entityType];
    if (handler == null) {
      DebugLoggerService.instance.error(
        'SyncService: No handler for entity type "${op.entityType}". Operation skipped.',
      );
      // Remove from queue so it doesn't block future syncs
      await op.delete();
      return;
    }

    try {
      // Delegate to the specialized worker
      await handler.push(op);

      op.status = SyncOperationStatus.completed.index;
      await op.save();
      await op.delete();
    } catch (_) {
      await _markFailed(op);
    }
  }

  Future<void> _markFailed(SyncOperation op) async {
    op.retryCount += 1;
    op.status = SyncOperationStatus.failed.index;
    await op.save();

    if (op.retryCount <= 5) {
      final seconds = computeBackoffSeconds(op.retryCount);
      await Future<void>.delayed(Duration(seconds: seconds));
    }
  }

  // PULL OPERATIONS
  Future<void> _pullAll() async {
    final metaBox = Hive.box<SyncMetadata>(HiveBoxes.syncMetadata);
    final meta = metaBox.get('default');
    final lastSyncAt = meta?.lastSuccessfulSyncAt;

    // Pull for every registered handler
    for (final handler in _handlers.values) {
      await handler.pull(lastSyncAt);
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
