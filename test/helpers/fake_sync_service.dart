import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'fake_connectivity_service.dart';

/// Minimal stub replacing [SyncService] for controller tests.
///
/// Records enqueued operations so tests can assert what was queued.
class FakeSyncService extends SyncService {
  FakeSyncService() : super(connectivity: FakeConnectivityService());

  final List<SyncOperation> enqueuedOps = [];

  @override
  Future<void> enqueueOperation(SyncOperation op) async {
    enqueuedOps.add(op);
  }

  @override
  Future<void> syncOnce() async {
    // no-op
  }
}
