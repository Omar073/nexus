import 'package:nexus/features/categories/domain/category_sortable_item.dart';
import 'package:nexus/features/tasks/domain/entities/task_attachment_entity.dart';

/// Domain task with category, due, reminders, and sync fields.
class TaskEntity implements CategorySortableItem {
  const TaskEntity({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.lastModifiedByDevice,
    this.description,
    this.categoryId,
    this.subcategoryId,
    this.startDate,
    this.dueDate,
    this.priority,
    this.difficulty,
    this.completedAt,
    this.recurringRule = 0,
    this.attachments = const [],
    this.isDirty = true,
    this.lastSyncedAt,
    this.syncStatus = 0,
  });

  final String id;
  final String title;
  final String? description;
  @override
  final String? categoryId;
  final String? subcategoryId;
  final DateTime? dueDate;
  final int? priority;
  final int? difficulty;
  final int status;
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final DateTime? completedAt;
  final int recurringRule;
  final List<TaskAttachmentEntity> attachments;
  final bool isDirty;
  final DateTime? lastSyncedAt;
  final int syncStatus;
  final String lastModifiedByDevice;
  final DateTime? startDate;
}
