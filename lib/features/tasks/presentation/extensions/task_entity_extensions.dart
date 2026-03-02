import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';

/// Presentation-layer extension: enum getters for [TaskEntity] (domain stays pure).
extension TaskEntityExtensions on TaskEntity {
  TaskStatus get statusEnum => TaskStatus.values[status];
  TaskPriority? get priorityEnum =>
      priority == null ? null : TaskPriority.values[priority!];
  TaskDifficulty? get difficultyEnum =>
      difficulty == null ? null : TaskDifficulty.values[difficulty!];
  TaskRecurrenceRule get recurringRuleEnum =>
      TaskRecurrenceRule.values[recurringRule];
  SyncStatus get syncStatusEnum => SyncStatus.values[syncStatus];
}
