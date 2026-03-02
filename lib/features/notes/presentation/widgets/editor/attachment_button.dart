import 'package:flutter/material.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';

class AttachmentButton extends StatelessWidget {
  const AttachmentButton({super.key, required this.note});

  final NoteEntity note;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Add image',
      icon: const Icon(Icons.image_outlined),
      onPressed: () => _showAttachmentOptions(context),
    );
  }

  Future<void> _showAttachmentOptions(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (result == null || !context.mounted) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image picked from $result - embedding coming soon'),
        ),
      );
    }
  }
}
