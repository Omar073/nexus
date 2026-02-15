import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/sync_metadata.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/notes/models/note.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/core/services/sync/models/sync_conflict.dart';

class SyncController extends ChangeNotifier {
  SyncController({required SyncService syncService})
    : _syncService = syncService {
    _syncOpsListenable = Hive.box<SyncOperation>(
      HiveBoxes.syncOps,
    ).listenable();
    _metaListenable = Hive.box<SyncMetadata>(
      HiveBoxes.syncMetadata,
    ).listenable();

    _syncOpsListenable.addListener(_refresh);
    _metaListenable.addListener(_refresh);

    _confSub = _syncService.conflictsStream.listen(replaceConflicts);
    _noteConfSub = _syncService.noteConflictsStream.listen(
      replaceNoteConflicts,
    );

    unawaited(_syncService.startAutoSync());
    _refresh();
  }

  final SyncService _syncService;

  late final ValueListenable<Box<SyncOperation>> _syncOpsListenable;
  late final ValueListenable<Box<SyncMetadata>> _metaListenable;
  StreamSubscription<List<SyncConflict<Task>>>? _confSub;
  StreamSubscription<List<SyncConflict<Note>>>? _noteConfSub;

  int _queueCount = 0;
  int get queueCount => _queueCount;

  DateTime? _lastSuccessfulSyncAt;
  DateTime? get lastSuccessfulSyncAt => _lastSuccessfulSyncAt;

  List<SyncConflict<Task>> _conflicts = const [];
  List<SyncConflict<Task>> get conflicts => _conflicts;

  void replaceConflicts(List<SyncConflict<Task>> conflicts) {
    _conflicts = List<SyncConflict<Task>>.unmodifiable(conflicts);
    notifyListeners();
  }

  List<SyncConflict<Note>> _noteConflicts = const [];
  List<SyncConflict<Note>> get noteConflicts => _noteConflicts;

  void replaceNoteConflicts(List<SyncConflict<Note>> conflicts) {
    _noteConflicts = List<SyncConflict<Note>>.unmodifiable(conflicts);
    notifyListeners();
  }

  bool get hasAnyConflicts =>
      _conflicts.isNotEmpty || _noteConflicts.isNotEmpty;

  bool get isSyncing => _syncService.isSyncing;

  Future<void> syncNow() async {
    await _syncService.syncOnce();
    _refresh();
  }

  void _refresh() {
    final opsBox = Hive.box<SyncOperation>(HiveBoxes.syncOps);
    _queueCount = opsBox.values
        .where((o) => o.status != SyncOperationStatus.completed.index)
        .length;

    final meta = Hive.box<SyncMetadata>(HiveBoxes.syncMetadata).get('default');
    _lastSuccessfulSyncAt = meta?.lastSuccessfulSyncAt;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncOpsListenable.removeListener(_refresh);
    _metaListenable.removeListener(_refresh);
    unawaited(_confSub?.cancel());
    unawaited(_noteConfSub?.cancel());
    super.dispose();
  }
}
