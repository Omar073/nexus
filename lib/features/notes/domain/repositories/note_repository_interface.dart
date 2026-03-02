import 'package:nexus/features/notes/domain/entities/note_entity.dart';

/// Contract for note persistence (pure Dart).
abstract class NoteRepositoryInterface {
  List<NoteEntity> getAll();
  NoteEntity? getById(String id);
  Future<void> upsert(NoteEntity note);
  Future<void> delete(String id);
  Stream<void> get changes;

  /// Returns Firestore-ready payload for sync enqueue (data layer concern exposed for sync use case).
  Map<String, dynamic>? getSyncPayload(String id);
}
