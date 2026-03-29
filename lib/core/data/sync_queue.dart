import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';

enum SyncOperationType { create, update, delete }

enum SyncOperationStatus { pending, syncing, failed, completed }

/// Queued create/update/delete for background cloud sync.
/// Carries entity type, id, JSON snapshot, and retry metadata for [SyncService].

@HiveType(typeId: HiveTypeIds.syncOperation)
class SyncOperation extends HiveObject {
  SyncOperation({
    required this.id,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
    this.data,
    this.retryCount = 0,
    this.lastAttemptAt,
    this.status = 0,
  });

  @HiveField(0)
  final String id;

  /// create/update/delete
  @HiveField(1)
  final int type;

  /// task/category/reminder
  @HiveField(2)
  final String entityType;

  @HiveField(3)
  final String entityId;

  /// JSON snapshot for retry.
  @HiveField(4)
  final Map<String, dynamic>? data;

  @HiveField(5)
  int retryCount;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  DateTime? lastAttemptAt;

  @HiveField(8)
  int status;
}
