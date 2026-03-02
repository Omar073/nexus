import 'dart:async';

import 'package:nexus/features/notes/data/mappers/note_mapper.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/domain/repositories/note_repository_interface.dart';
import 'package:nexus/features/notes/data/data_sources/note_local_datasource.dart';

class NoteRepositoryImpl implements NoteRepositoryInterface {
  NoteRepositoryImpl({NoteLocalDatasource? local})
    : _local = local ?? NoteLocalDatasource() {
    _local.listenable().addListener(_onBoxChanged);
  }

  final NoteLocalDatasource _local;
  final _changeController = StreamController<void>.broadcast();

  void _onBoxChanged() {
    if (!_changeController.isClosed) {
      _changeController.add(null);
    }
  }

  @override
  List<NoteEntity> getAll() =>
      _local.getAll().map(NoteMapper.toEntity).toList();

  @override
  NoteEntity? getById(String id) {
    final n = _local.getById(id);
    return n != null ? NoteMapper.toEntity(n) : null;
  }

  @override
  Future<void> upsert(NoteEntity note) async {
    final model = NoteMapper.toModel(note);
    await _local.put(model);
  }

  @override
  Future<void> delete(String id) async {
    await _local.delete(id);
  }

  @override
  Stream<void> get changes => _changeController.stream;

  @override
  Map<String, dynamic>? getSyncPayload(String id) {
    final n = _local.getById(id);
    return n?.toFirestoreJson();
  }
}
