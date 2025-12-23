import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AttachmentStorageService {
  static const _uuid = Uuid();

  Future<Directory> _taskDir(String taskId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'attachments', 'tasks', taskId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> copyIntoTaskDir({
    required String taskId,
    required File source,
    String? preferredName,
  }) async {
    final dir = await _taskDir(taskId);
    final ext = p.extension(source.path);
    final filename = preferredName ?? '${_uuid.v4()}$ext';
    final dest = File(p.join(dir.path, filename));
    return source.copy(dest.path);
  }

  Future<String> newAudioPath({required String taskId, String ext = '.m4a'}) async {
    final dir = await _taskDir(taskId);
    return p.join(dir.path, '${_uuid.v4()}$ext');
  }
}

