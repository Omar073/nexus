import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:nexus/core/services/note_embed_service.dart';
import 'package:nexus/core/services/storage/attachment_storage_service.dart';
import 'package:nexus/features/notes/domain/entities/note_attachment_entity.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/helpers/note_attachment_drive_upload_helper.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

/// Captures gallery, camera, or voice and adds an attachment.
class AttachmentButton extends StatefulWidget {
  const AttachmentButton({
    super.key,
    required this.note,
    this.onAttachmentAdded,
  });

  final NoteEntity note;
  final ValueChanged<NoteAttachmentEntity>? onAttachmentAdded;

  @override
  State<AttachmentButton> createState() => _AttachmentButtonState();
}

class _AttachmentButtonState extends State<AttachmentButton> {
  final _embedService = NoteEmbedService();
  bool _recording = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _recording ? 'Stop recording' : 'Attach',
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _recording
              ? Colors.red.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _recording ? Icons.stop : Icons.attach_file_outlined,
          color: _recording ? Colors.red : null,
        ),
      ),
      onPressed: () {
        if (_recording) {
          _finishVoiceRecording(context);
        } else {
          _showAttachmentOptions(context);
        }
      },
    );
  }

  Future<void> _showAttachmentOptions(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(sheetContext, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(sheetContext, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.mic_none),
            title: const Text('Record voice note'),
            onTap: () => Navigator.pop(sheetContext, 'voice'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (result == null || !context.mounted) return;

    if (result == 'voice') {
      await _startVoiceRecording(context);
    } else if (result == 'gallery' || result == 'camera') {
      await _pickAndAttachImage(context, result);
    }
  }

  Future<void> _startVoiceRecording(BuildContext context) async {
    setState(() => _recording = true);
    try {
      await _embedService.recordVoiceNote(noteId: widget.note.id);
    } catch (_) {
      if (mounted) setState(() => _recording = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start recording (check microphone).'),
          ),
        );
      }
    }
  }

  Future<void> _finishVoiceRecording(BuildContext context) async {
    final saved = await _embedService.stopRecording();
    if (mounted) setState(() => _recording = false);
    if (saved == null || !context.mounted) return;

    final attachment = NoteAttachmentEntity(
      id: const Uuid().v4(),
      mimeType: 'audio/mp4',
      createdAt: DateTime.now(),
      localUri: saved,
      driveFileId: null,
      uploaded: false,
    );

    final controller = context.read<NoteController>();
    await NoteAttachmentDriveUploadHelper.addWithDriveRecovery(
      context: context,
      controller: controller,
      note: widget.note,
      attachment: attachment,
    );
    widget.onAttachmentAdded?.call(attachment);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Voice note attached')));
    }
  }

  Future<void> _pickAndAttachImage(BuildContext context, String source) async {
    final picker = ImagePicker();
    final XFile? picked = switch (source) {
      'gallery' => await picker.pickImage(source: ImageSource.gallery),
      'camera' => await picker.pickImage(source: ImageSource.camera),
      _ => null,
    };
    if (picked == null || !context.mounted) return;

    final controller = context.read<NoteController>();
    final storage = AttachmentStorageService();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final ext = p.extension(picked.path);
      final attachmentId = const Uuid().v4();
      final copied = await storage.copyIntoTaskDir(
        taskId: 'notes_${widget.note.id}',
        source: File(picked.path),
        preferredName: '$attachmentId$ext',
      );

      final mimeType =
          lookupMimeType(copied.path) ??
          (ext.toLowerCase() == '.png' ? 'image/png' : 'image/jpeg');

      final attachment = NoteAttachmentEntity(
        id: attachmentId,
        mimeType: mimeType,
        createdAt: DateTime.now(),
        localUri: copied.path,
        driveFileId: null,
        uploaded: false,
      );

      if (!context.mounted) return;
      await NoteAttachmentDriveUploadHelper.addWithDriveRecovery(
        context: context,
        controller: controller,
        note: widget.note,
        attachment: attachment,
      );
      widget.onAttachmentAdded?.call(attachment);

      if (context.mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Image attached')));
      }
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Failed to attach image')),
        );
      }
    }
  }
}
