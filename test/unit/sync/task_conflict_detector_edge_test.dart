import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/core/utils/task_conflict_detector.dart';
import 'package:nexus/features/tasks/data/models/task.dart';

void main() {
  Task makeTask({
    required bool isDirty,
    required DateTime updatedAt,
    DateTime? lastSyncedAt,
  }) {
    return Task(
      id: 't1',
      title: 'Test',
      status: 0,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: updatedAt,
      lastModifiedByDevice: 'device-test',
      isDirty: isDirty,
      lastSyncedAt: lastSyncedAt,
    );
  }

  group('TaskConflictDetector edge cases', () {
    test('no conflict when remote is older than lastSyncedAt', () {
      final local = makeTask(
        isDirty: true,
        updatedAt: DateTime(2025, 6, 1),
        lastSyncedAt: DateTime(2025, 6, 5),
      );
      final remote = makeTask(
        isDirty: false,
        updatedAt: DateTime(2025, 6, 3),
        lastSyncedAt: null,
      );

      expect(
        TaskConflictDetector.hasConflict(local: local, remote: remote),
        isFalse,
      );
    });

    test('no conflict when lastSyncedAt is null', () {
      final local = makeTask(isDirty: true, updatedAt: DateTime(2025, 6, 1));
      final remote = makeTask(
        isDirty: false,
        updatedAt: DateTime(2025, 6, 2),
        lastSyncedAt: null,
      );

      expect(
        TaskConflictDetector.hasConflict(local: local, remote: remote),
        isFalse,
      );
    });

    test('no conflict when remote updatedAt equals lastSyncedAt', () {
      final syncTime = DateTime(2025, 6, 1);
      final local = makeTask(
        isDirty: true,
        updatedAt: DateTime(2025, 6, 1),
        lastSyncedAt: syncTime,
      );
      final remote = makeTask(
        isDirty: false,
        updatedAt: syncTime,
        lastSyncedAt: null,
      );

      // isAfter returns false when equal, so no conflict.
      expect(
        TaskConflictDetector.hasConflict(local: local, remote: remote),
        isFalse,
      );
    });
  });
}
