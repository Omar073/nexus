import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/core/utils/note_conflict_detector.dart';
import 'package:nexus/features/notes/models/note.dart';

void main() {
  Note makeNote({
    required bool isDirty,
    required DateTime updatedAt,
    DateTime? lastSyncedAt,
  }) {
    return Note(
      id: 'n1',
      contentDeltaJson: '[]',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: updatedAt,
      lastModifiedByDevice: 'device-test',
      isDirty: isDirty,
      lastSyncedAt: lastSyncedAt,
    );
  }

  group('NoteConflictDetector', () {
    test('conflict when local is dirty and remote is newer', () {
      final local = makeNote(
        isDirty: true,
        updatedAt: DateTime(2025, 6, 1),
        lastSyncedAt: DateTime(2025, 6, 1),
      );
      final remote = makeNote(
        isDirty: false,
        updatedAt: DateTime(2025, 6, 2),
        lastSyncedAt: null,
      );

      expect(
        NoteConflictDetector.hasConflict(local: local, remote: remote),
        isTrue,
      );
    });

    test('no conflict when local is not dirty', () {
      final local = makeNote(
        isDirty: false,
        updatedAt: DateTime(2025, 6, 1),
        lastSyncedAt: DateTime(2025, 6, 1),
      );
      final remote = makeNote(
        isDirty: false,
        updatedAt: DateTime(2025, 6, 2),
        lastSyncedAt: null,
      );

      expect(
        NoteConflictDetector.hasConflict(local: local, remote: remote),
        isFalse,
      );
    });

    test('no conflict when remote is older than lastSyncedAt', () {
      final local = makeNote(
        isDirty: true,
        updatedAt: DateTime(2025, 6, 1),
        lastSyncedAt: DateTime(2025, 6, 3),
      );
      final remote = makeNote(
        isDirty: false,
        updatedAt: DateTime(2025, 6, 2),
        lastSyncedAt: null,
      );

      expect(
        NoteConflictDetector.hasConflict(local: local, remote: remote),
        isFalse,
      );
    });

    test('no conflict when lastSyncedAt is null', () {
      final local = makeNote(isDirty: true, updatedAt: DateTime(2025, 6, 1));
      final remote = makeNote(
        isDirty: false,
        updatedAt: DateTime(2025, 6, 2),
        lastSyncedAt: null,
      );

      expect(
        NoteConflictDetector.hasConflict(local: local, remote: remote),
        isFalse,
      );
    });
  });
}
