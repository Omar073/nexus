import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/core/utils/task_conflict_detector.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';

void main() {
  test(
    'conflict when local dirty and remote updated after local lastSyncedAt',
    () {
      final local = Task(
        id: '1',
        title: 't',
        status: TaskStatus.active.index,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
        lastModifiedByDevice: 'A',
        isDirty: true,
        lastSyncedAt: DateTime(2025, 1, 2, 0, 0),
        syncStatus: SyncStatus.idle.index,
      );
      final remote = Task(
        id: '1',
        title: 't2',
        status: TaskStatus.active.index,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 3),
        lastModifiedByDevice: 'B',
        isDirty: false,
        lastSyncedAt: DateTime(2025, 1, 3),
        syncStatus: SyncStatus.synced.index,
      );

      expect(
        TaskConflictDetector.hasConflict(local: local, remote: remote),
        true,
      );
    },
  );

  test('no conflict when local not dirty', () {
    final local = Task(
      id: '1',
      title: 't',
      status: TaskStatus.active.index,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 2),
      lastModifiedByDevice: 'A',
      isDirty: false,
      lastSyncedAt: DateTime(2025, 1, 2),
      syncStatus: SyncStatus.synced.index,
    );
    final remote = Task(
      id: '1',
      title: 't2',
      status: TaskStatus.active.index,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 3),
      lastModifiedByDevice: 'B',
      isDirty: false,
      lastSyncedAt: DateTime(2025, 1, 3),
      syncStatus: SyncStatus.synced.index,
    );

    expect(
      TaskConflictDetector.hasConflict(local: local, remote: remote),
      false,
    );
  });
}
