/// Represents a conflict between local and remote versions of an entity.
/// See `developer_README.md` (Section 9.3) for conflict logic.
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
