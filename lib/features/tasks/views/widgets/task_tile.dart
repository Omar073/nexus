import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:nexus/core/extensions/l10n_x.dart';
import 'package:nexus/core/services/platform/permission_service.dart';
import 'package:nexus/core/services/storage/attachment_storage_service.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_attachment.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:nexus/features/tasks/views/utils/attachment_auth_helper.dart';
import 'package:nexus/features/tasks/views/widgets/attachments/attachments_list.dart';
import 'package:nexus/features/tasks/views/widgets/task_editor_dialog.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

/// A list tile widget for displaying a single task.
class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TaskController>();
    final completed = task.statusEnum == TaskStatus.completed;

    return ListTile(
      leading: Checkbox(
        value: completed,
        onChanged: (v) => controller.toggleCompleted(task, v ?? false),
      ),
      title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: task.description == null
          ? null
          : Text(
              task.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: IconButton(
        tooltip: context.l10n.editTask,
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => showTaskEditorDialog(context, task: task),
      ),
      onTap: () => _showDetails(context, task),
    );
  }

  static Future<void> _showDetails(BuildContext context, Task task) async {
    final l10n = context.l10n;
    final controller = context.read<TaskController>();
    final storage = AttachmentStorageService();
    final picker = ImagePicker();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              if (task.description != null) ...[
                const SizedBox(height: 8),
                Text(task.description!),
              ],
              const SizedBox(height: 16),
              const Text('Attachments'),
              const SizedBox(height: 8),
              AttachmentsList(task: task),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await context
                          .read<PermissionService>()
                          .ensureGalleryRead();
                      if (!ok) return;
                      if (!context.mounted) return;
                      final xfile = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (xfile == null) return;
                      final copied = await storage.copyIntoTaskDir(
                        taskId: task.id,
                        source: File(xfile.path),
                      );
                      final mime = lookupMimeType(copied.path) ?? 'image/*';
                      final attachment = TaskAttachment(
                        id: const Uuid().v4(),
                        mimeType: mime,
                        createdAt: DateTime.now(),
                        localUri: copied.path,
                        uploaded: false,
                      );
                      if (context.mounted) {
                        await addAttachmentWithAuth(
                          context,
                          controller,
                          task,
                          attachment,
                        );
                      }
                    },
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Add image'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await context
                          .read<PermissionService>()
                          .ensureMicrophone();
                      if (!ok) return;
                      if (!context.mounted) return;
                      final path = await storage.newAudioPath(taskId: task.id);
                      if (!context.mounted) return;
                      final record = AudioRecorder();
                      await showDialog<void>(
                        context: context,
                        builder: (dialogContext) {
                          bool recording = false;
                          return StatefulBuilder(
                            builder: (dialogContext, setState) {
                              return AlertDialog(
                                title: const Text('Record voice note'),
                                content: Text(
                                  recording
                                      ? 'Recording…'
                                      : 'Tap Start to begin recording.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      if (recording) {
                                        await record.stop();
                                      }
                                      if (dialogContext.mounted) {
                                        Navigator.of(dialogContext).pop();
                                      }
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  if (!recording)
                                    FilledButton(
                                      onPressed: () async {
                                        final ok = await record.hasPermission();
                                        if (!ok) return;
                                        await record.start(
                                          const RecordConfig(),
                                          path: path,
                                        );
                                        setState(() => recording = true);
                                      },
                                      child: const Text('Start'),
                                    )
                                  else
                                    FilledButton(
                                      onPressed: () async {
                                        final saved = await record.stop();
                                        if (saved != null) {
                                          final attachment = TaskAttachment(
                                            id: const Uuid().v4(),
                                            mimeType: 'audio/mp4',
                                            createdAt: DateTime.now(),
                                            localUri: saved,
                                            uploaded: false,
                                          );
                                          if (context.mounted) {
                                            await addAttachmentWithAuth(
                                              context,
                                              controller,
                                              task,
                                              attachment,
                                            );
                                          }
                                        }
                                        if (dialogContext.mounted) {
                                          Navigator.of(dialogContext).pop();
                                        }
                                      },
                                      child: const Text('Stop & Save'),
                                    ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.mic_none),
                    label: const Text('Add voice'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await controller.deleteTask(task);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.delete),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
