import 'package:nexus/core/data/sync_queue.dart';

/// Minimal stub replacing [SyncService] for controller tests.
///
/// Records enqueued operations so tests can assert what was queued.
class FakeSyncService {
  final List<SyncOperation> enqueuedOps = [];

  Future<void> enqueueOperation(SyncOperation op) async {
    enqueuedOps.add(op);
  }

  Future<void> syncOnce() async {
    // no-op
  }
}
