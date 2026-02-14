import 'dart:async';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/handlers/entity_sync_handler.dart';
import 'package:nexus/core/services/sync/models/sync_conflict.dart';

/// Test stub for [EntitySyncHandler].
///
/// Records push/pull calls and can be configured to throw.
class FakeEntitySyncHandler<T> extends EntitySyncHandler<T> {
  FakeEntitySyncHandler({required this.type, this.shouldThrow = false});

  final String type;
  bool shouldThrow;
  Duration? pullDelay;

  final List<SyncOperation> pushedOps = [];
  final List<DateTime?> pullCalls = [];

  final StreamController<List<SyncConflict<T>>> _conflictController =
      StreamController<List<SyncConflict<T>>>.broadcast();

  @override
  String get entityType => type;

  @override
  Stream<List<SyncConflict<T>>> get conflictsStream =>
      _conflictController.stream;

  @override
  Future<void> push(SyncOperation op) async {
    if (shouldThrow) throw Exception('FakeHandler push error');
    pushedOps.add(op);
  }

  @override
  Future<void> pull(DateTime? lastSyncAt) async {
    if (shouldThrow) throw Exception('FakeHandler pull error');
    if (pullDelay != null) await Future<void>.delayed(pullDelay!);
    pullCalls.add(lastSyncAt);
  }

  void emitConflicts(List<SyncConflict<T>> conflicts) {
    _conflictController.add(conflicts);
  }

  void dispose() {
    _conflictController.close();
  }
}
