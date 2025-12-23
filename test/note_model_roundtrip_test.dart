import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/notes/models/note.dart';

void main() {
  test('Note delta json is stored as string and round-trips', () {
    final deltaJson = jsonEncode([
      {'insert': 'مرحبا'},
      {'insert': '\n'}
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
}


