import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/core/services/storage/attachment_storage_service.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AttachmentStorageService service;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('attachment_test');
    service = AttachmentStorageService(docDirProvider: () async => tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AttachmentStorageService', () {
    test('copyIntoTaskDir copies file to task folder', () async {
      // Create a dummy source file
      final sourceFile = File(p.join(tempDir.path, 'source.txt'));
      await sourceFile.writeAsString('dummy content');

      final taskId = 'task-123';
      final newFile = await service.copyIntoTaskDir(
        source: sourceFile,
        taskId: taskId,
      );

      expect(await newFile.exists(), isTrue);
      expect(p.dirname(newFile.path), endsWith(taskId));
      expect(p.extension(newFile.path), p.extension(sourceFile.path));
    });

    test('newAudioPath generates valid path in task folder', () async {
      final taskId = 'task-123';
      final path = await service.newAudioPath(taskId: taskId);

      expect(path, endsWith('.m4a'));
      expect(path, contains(taskId));

      // Verify folder was created
      final file = File(path);
      expect(await file.parent.exists(), isTrue);
    });
  });
}
