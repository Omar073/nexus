import 'package:nexus/features/notes/domain/entities/note_attachment_entity.dart';

/// Classification helpers for note attachments (by MIME type).
///
/// All attachments share [NoteAttachmentEntity]; this file keeps type rules
/// in one place for inline markers, UI sections, etc.
class NoteAttachmentKinds {
  NoteAttachmentKinds._();

  static bool isAudio(String mimeType) =>
      mimeType.toLowerCase().startsWith('audio/');

  static bool isImage(String mimeType) =>
      mimeType.toLowerCase().startsWith('image/');

  /// Inline marker inserted into note text at attach time.
  /// Keep stable prefixes so existing notes and search keep working.
  static String inlineMarker(NoteAttachmentEntity attachment) {
    if (isAudio(attachment.mimeType)) {
      return '[[voice:${attachment.id}]]';
    }
    if (isImage(attachment.mimeType)) {
      return '[[image:${attachment.id}]]';
    }
    return '[[attachment:${attachment.id}]]';
  }
}
