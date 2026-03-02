import 'package:nexus/features/tasks/domain/entities/task_entity.dart';

/// Contract for task persistence (pure Dart).
abstract class TaskRepositoryInterface {
  List<TaskEntity> getAll();
  TaskEntity? getById(String id);
  Future<void> upsert(TaskEntity task);
  Future<void> delete(String id);
  Stream<void> get changes;
  Map<String, dynamic>? getSyncPayload(String id);
}
