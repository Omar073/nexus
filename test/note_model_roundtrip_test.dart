import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/features/notes/models/note.dart';

void main() {
  test('Note delta json is stored as string and round-trips', () {
    final deltaJson = jsonEncode([
      {'insert': 'مرحبا'},
      {'insert': '\n'},
    ]);
    final note = Note(
      id: 'n1',
      title: 't',
      contentDeltaJson: deltaJson,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      lastModifiedByDevice: 'd',
    );
    expect(note.contentDeltaJson, deltaJson);
  });

  test('Note isMarkdown defaults to false when missing in firestore', () {
    final now = DateTime(2025, 1, 1);
    final json = {
      'id': 'n1',
      'title': 't',
      'contentDeltaJson': '[]',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'lastModifiedByDevice': 'd',
      'attachments': const [],
    };

    final note = Note.fromFirestoreJson(json);
    expect(note.isMarkdown, false);
  });

  test('Note isMarkdown round-trips via firestore json', () {
    final deltaJson = jsonEncode([
      {'insert': '# Title\n'},
    ]);
    final note = Note(
      id: 'n2',
      title: 'Markdown',
      contentDeltaJson: deltaJson,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      lastModifiedByDevice: 'd',
      isMarkdown: true,
    );

    final json = note.toFirestoreJson();
    expect(json['isMarkdown'], true);

    final roundTripped = Note.fromFirestoreJson(json);
    expect(roundTripped.isMarkdown, true);
  });

  test('Note isMarkdown round-trips via Hive adapter', () async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(HiveTypeIds.note)) {
      Hive.registerAdapter(NoteAdapter());
    }
    final box = await Hive.openBox<Note>(HiveBoxes.notes);

    final note = Note(
      id: 'n3',
      title: 'Hive',
      contentDeltaJson: '[]',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      lastModifiedByDevice: 'd',
      isMarkdown: true,
    );

    await box.put(note.id, note);
    final loaded = box.get(note.id);

    expect(loaded, isNotNull);
    expect(loaded!.isMarkdown, true);

    await box.close();
    await tearDownTestHive();
  });
}
