import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus/app/theme/app_colors.dart';
import 'package:nexus/core/widgets/nexus_card.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/markdown/markdown_editor_area.dart';

/// 3-dot overflow menu for [NoteEditorAppBar].
class NoteEditorOverflowMenu extends StatefulWidget {
  const NoteEditorOverflowMenu({
    super.key,
    required this.isMarkdown,
    required this.markdownLayout,
    required this.showVoiceNotes,
    required this.onFindInNote,
    required this.onToggleMarkdown,
    required this.onLayoutChanged,
    required this.onToggleVoiceNotes,
    required this.onDeleteNote,
  });

  final bool isMarkdown;
  final MarkdownLayout markdownLayout;
  final bool showVoiceNotes;
  final VoidCallback onFindInNote;
  final ValueChanged<bool> onToggleMarkdown;
  final ValueChanged<MarkdownLayout> onLayoutChanged;
  final ValueChanged<bool> onToggleVoiceNotes;
  final VoidCallback onDeleteNote;

  @override
  State<NoteEditorOverflowMenu> createState() => _NoteEditorOverflowMenuState();
}

class _NoteEditorOverflowMenuState extends State<NoteEditorOverflowMenu> {
  final _link = LayerLink();
  OverlayEntry? _entry;

  @override
  void dispose() {
    _removeEntry();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: IconButton(
        tooltip: 'Note options',
        icon: const Icon(Icons.more_vert),
        onPressed: _toggle,
      ),
    );
  }

  void _toggle() {
    if (_entry != null) {
      _removeEntry();
    } else {
      _showEntry();
    }
  }

  void _showEntry() {
    final overlay = Overlay.of(context);
    final theme = Theme.of(context);

    _entry = OverlayEntry(
      builder: (overlayContext) {
        final colors = AppColors.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              surface: theme.colorScheme.surface.withValues(
                alpha: isDark ? 0.8 : 0.9,
              ),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _removeEntry,
                  child: Container(color: Colors.black.withValues(alpha: 0.05)),
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                followerAnchor: Alignment.topRight,
                targetAnchor: Alignment.bottomRight,
                offset: const Offset(0, 8),
                child: Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: NexusCard(
                            borderRadius: 16,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _menuItem(
                                  icon: Icons.search,
                                  title: 'Find in note',
                                  onTap: () {
                                    _removeEntry();
                                    widget.onFindInNote();
                                  },
                                ),
                                const Divider(height: 1),
                                SwitchListTile.adaptive(
                                  secondary: const Icon(Icons.code),
                                  title: const Text('Markdown mode'),
                                  activeTrackColor: colors.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  activeThumbColor: colors.primary,
                                  value: widget.isMarkdown,
                                  onChanged: (v) {
                                    widget.onToggleMarkdown(v);
                                    // Keep menu open for switches
                                  },
                                ),
                                if (widget.isMarkdown) ...[
                                  const Divider(height: 1),
                                  _menuItem(
                                    icon: Icons.view_agenda_outlined,
                                    title: 'Markdown view',
                                    subtitle:
                                        widget.markdownLayout ==
                                            MarkdownLayout.tabs
                                        ? 'Tabs'
                                        : 'Split',
                                    onTap: () {},
                                    trailing: DropdownButtonHideUnderline(
                                      child: DropdownButton<MarkdownLayout>(
                                        value: widget.markdownLayout,
                                        items: const [
                                          DropdownMenuItem(
                                            value: MarkdownLayout.tabs,
                                            child: Text('Tabs'),
                                          ),
                                          DropdownMenuItem(
                                            value: MarkdownLayout.split,
                                            child: Text('Split'),
                                          ),
                                        ],
                                        onChanged: (v) {
                                          if (v == null) return;
                                          widget.onLayoutChanged(v);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                                const Divider(height: 1),
                                SwitchListTile.adaptive(
                                  secondary: const Icon(Icons.mic_none),
                                  title: const Text('Show voice notes'),
                                  activeTrackColor: colors.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  activeThumbColor: colors.primary,
                                  value: widget.showVoiceNotes,
                                  onChanged: (v) =>
                                      widget.onToggleVoiceNotes(v),
                                ),
                                const Divider(height: 1),
                                _menuItem(
                                  icon: Icons.delete_outline,
                                  title: 'Delete note',
                                  titleColor: theme.colorScheme.error,
                                  iconColor: theme.colorScheme.error,
                                  onTap: () {
                                    _removeEntry();
                                    widget.onDeleteNote();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(_entry!);
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: titleColor)),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
