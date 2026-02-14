import 'dart:async';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/models/sync_conflict.dart';

/// Strategy Interface for syncing specific entity types.
///
/// Implement this to support new entity types (e.g. Habits, Reminders).
abstract class EntitySyncHandler<T> {
  /// The collection name (and Hive box name generally) for this entity.
  /// Also used to route [SyncOperation.entityType].
  String get entityType;

  /// Stream of conflicts detected during pull operations.
  Stream<List<SyncConflict<T>>> get conflictsStream;

  /// Pushes a single operation to Firestore.
  /// Should throw if the operation fails, so the sync service can retry.
  Future<void> push(SyncOperation op);

  /// Pulls remote updates from Firestore since [lastSyncAt].
  /// Handles conflict detection internally and emits to [conflictsStream].
  Future<void> pull(DateTime? lastSyncAt);
}
