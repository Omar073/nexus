import 'package:nexus/features/reminders/domain/entities/reminder_entity.dart';

/// Contract for reminder persistence (pure Dart).
abstract class ReminderRepositoryInterface {
  List<ReminderEntity> getAll();
  ReminderEntity? getById(String id);
  Future<void> upsert(ReminderEntity reminder);
  Future<void> delete(String id);
  Stream<void> get changes;

  /// Returns Firestore-ready payload for sync enqueue (data layer concern).
  Map<String, dynamic>? getSyncPayload(String id);

  /// Stamps [notifiedAt] on the reminder so duplicate delivery is prevented.
  Future<void> markNotified(String id);
}
