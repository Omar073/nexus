import 'package:flutter/material.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/note_editor_view.dart';
import 'package:provider/provider.dart';

/// Loads a note by id and hosts [NoteEditorView].
class NoteEditorScreen extends StatelessWidget {
  const NoteEditorScreen({super.key, required this.noteId});

  final String noteId;

  /// Wraps editor routes with the app-level providers the editor depends on.
  ///
  /// This is required because pushes on the root navigator can sit outside the
  /// shell’s provider scope.
  static Widget wrapWithRequiredProviders(
    BuildContext context, {
    required Widget child,
  }) {
    final notes = context.read<NoteController>();
    final categories = context.read<CategoryController>();
    final drive = context.read<GoogleDriveService>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NoteController>.value(value: notes),
        ChangeNotifierProvider<CategoryController>.value(value: categories),
        Provider<GoogleDriveService>.value(value: drive),
      ],
      // Root-navigator routes can occasionally end up with a default theme
      // if pushed from a different overlay context; force the caller's theme.
      child: Theme(data: Theme.of(context), child: child),
    );
  }

  /// Opens the editor on the [rootNavigator] (full-screen above the bottom bar).
  ///
  /// Re-wraps [NoteController] on the pushed route. Imperative pushes on the
  /// root navigator can sit outside the shell’s provider scope, which caused
  /// [ProviderNotFoundException] for [NoteEditorScreen] when only [MultiProvider]
  /// wrapped [MaterialApp] above the shell (see [ThemeCustomizationScreen]
  /// for the same pattern with [SettingsController]).
  static Future<void> push(BuildContext context, String noteId) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => wrapWithRequiredProviders(
          context,
          child: NoteEditorScreen(noteId: noteId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NoteController>();
    final note = notes.byId(noteId);

    if (note == null) {
      return const Scaffold(body: Center(child: Text('Note not found')));
    }

    return NoteEditorView(note: note);
  }
}
