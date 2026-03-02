import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/features/notes/data/models/note.dart';

class NoteLocalDatasource {
  Box<Note> get _box => Hive.box<Note>(HiveBoxes.notes);

  List<Note> getAll() => _box.values.toList(growable: false);

  Note? getById(String id) => _box.get(id);

  Future<void> put(Note note) => _box.put(note.id, note);

  Future<void> delete(String id) => _box.delete(id);

  ValueListenable<Box<Note>> listenable() => _box.listenable();
}
