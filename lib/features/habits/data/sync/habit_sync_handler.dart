import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/handlers/entity_sync_handler.dart';
import 'package:nexus/core/services/sync/models/sync_conflict.dart';
import 'package:nexus/features/habits/data/models/habit.dart';

/// Sync handler for habits (Hive <-> Firestore).
///
/// For now this handler does not surface conflicts; remote updates overwrite
/// local when they are pulled. If we need full conflict resolution later we
/// can introduce a HabitConflictDetector similar to tasks/reminders.
class HabitSyncHandler implements EntitySyncHandler<Habit> {
  HabitSyncHandler({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  final _conflictsController =
      StreamController<List<SyncConflict<Habit>>>.broadcast();

  @override
  String get entityType => 'habit';

  @override
  Stream<List<SyncConflict<Habit>>> get conflictsStream =>
      _conflictsController.stream;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('habits');

  @override
  Future<void> push(SyncOperation op) async {
    final doc = _collection.doc(op.entityId);
    final type = SyncOperationType.values[op.type];

    switch (type) {
      case SyncOperationType.create:
      case SyncOperationType.update:
        final data = (op.data ?? <String, dynamic>{});
        await doc.set(data, SetOptions(merge: true));
      case SyncOperationType.delete:
        await doc.delete();
    }
  }

  @override
  Future<void> pull(DateTime? lastSyncAt) async {
    final box = Hive.box<Habit>(HiveBoxes.habits);

    Query<Map<String, dynamic>> q = _collection;
    if (lastSyncAt != null) {
      q = q.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncAt));
    }

    final snap = await q.get();

    for (final doc in snap.docs) {
      final remote = Habit.fromFirestoreJson(doc.data());
      final local = box.get(remote.id);

      // If we don't have it locally, just save the remote version.
      if (local == null) {
        await box.put(remote.id, remote);
        continue;
      }

      // For now remote wins; existing local changes are considered resolved
      // once the remote document is written.
      await box.put(remote.id, remote);
    }
  }
}
