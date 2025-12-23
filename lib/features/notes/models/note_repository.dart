import 'package:flutter/foundation.dart';
import 'package:nexus/features/notes/models/note_local_datasource.dart';
import 'package:nexus/features/notes/models/note.dart';

class NoteRepository {
  NoteRepository({NoteLocalDatasource? local})
    : _local = local ?? NoteLocalDatasource();

  final NoteLocalDatasource _local;

  List<Note> getAll() => _local.getAll();

  Note? getById(String id) => _local.getById(id);

  Future<void> upsert(Note note) => _local.put(note);

  Future<void> delete(String id) => _local.delete(id);

  ValueListenable listenable() => _local.listenable();
}
