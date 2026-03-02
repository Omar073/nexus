import 'dart:async';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/habits/domain/entities/habit_entity.dart';
import 'package:nexus/features/habits/domain/repositories/habit_repository_interface.dart';
import 'package:uuid/uuid.dart';

class CreateHabitUseCase {
  CreateHabitUseCase(this._repo, this._syncService, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final HabitRepositoryInterface _repo;
  final SyncService _syncService;
  final Uuid _uuid;

  Future<HabitEntity> call({
    required String title,
    String? linkedRecurringTaskId,
  }) async {
    final now = DateTime.now();
    final entity = HabitEntity(
      id: _uuid.v4(),
      name: title.trim(),
      linkedRecurringTaskId: linkedRecurringTaskId,
      active: true,
      createdAt: now,
      updatedAt: now,
      isDirty: true,
      lastSyncedAt: null,
      syncStatus: 0,
    );
    await _repo.upsert(entity);

    final payload = _repo.getSyncPayload(entity.id);
    if (payload != null) {
      final op = SyncOperation(
        id: _uuid.v4(),
        type: SyncOperationType.create.index,
        entityType: 'habit',
        entityId: entity.id,
        createdAt: DateTime.now(),
        data: payload,
      );
      await _syncService.enqueueOperation(op);
      unawaited(_syncService.syncOnce());
    }

    return entity;
  }
}
