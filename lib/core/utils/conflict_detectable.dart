/// Minimal contract for conflict detection between local and remote entities.
///
/// Used by [TaskConflictDetector] and [NoteConflictDetector] so core/utils
/// stays free of feature imports. Feature entities (Task, Note) implement this.
abstract class ConflictDetectable {
  DateTime? get lastSyncedAt;
  bool get isDirty;
  DateTime get updatedAt;
}
