import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/app_drawer_button.dart';
import 'package:nexus/core/widgets/filter_chip_bar.dart';
import 'package:nexus/features/categories/data/models/category.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:nexus/features/notes/presentation/widgets/tiles/note_tile.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:provider/provider.dart';

/// Scrollable note list with selection mode and empty states.

class NotesBody extends StatelessWidget {
  const NotesBody({
    super.key,
    required this.notes,
    required this.categories,
    required this.filterLabels,
    required this.selectedFilterIndex,
    required this.onFilterSelected,
    required this.selectionMode,
    required this.selectedNoteIds,
    required this.onEnterSelection,
    required this.onToggleSelection,
    required this.navBarStyle,
    required this.searchController,
  });

  final List<NoteEntity> notes;
  final List<Category> categories;
  final List<String> filterLabels;
  final int selectedFilterIndex;
  final ValueChanged<int> onFilterSelected;
  final bool selectionMode;
  final Set<String> selectedNoteIds;
  final void Function(String id) onEnterSelection;
  final void Function(String id) onToggleSelection;
  final NavBarStyle navBarStyle;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = context.read<NoteController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const AppDrawerButton(),
                  const SizedBox(width: 8),
                  Text(
                    'Notes',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.sort),
                              title: const Text('Sort by Date'),
                              onTap: () => Navigator.pop(context),
                            ),
                            ListTile(
                              leading: const Icon(Icons.sort_by_alpha),
                              title: const Text('Sort by Name'),
                              onTap: () => Navigator.pop(context),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  ),
                  // Profile avatar placeholder
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 20),
              hintText: 'Search your thoughts...',
              filled: true,
              fillColor: isDark ? theme.colorScheme.surface : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: controller.setQuery,
          ),
        ),
        const SizedBox(height: 12),
        // Filter chips
        FilterChipBar(
          labels: filterLabels,
          selectedIndex: selectedFilterIndex,
          onSelected: onFilterSelected,
        ),
        const SizedBox(height: 16),
        // Notes list
        Expanded(
          child: notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_alt_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notes yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to create your first note',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    navBarStyle.contentPadding,
                  ),
                  itemCount: notes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    final selected = selectedNoteIds.contains(note.id);
                    return NoteTile(
                      note: note,
                      selectionMode: selectionMode,
                      isSelected: selected,
                      onSelectionToggle: () => onToggleSelection(note.id),
                      onLongPress: () => onEnterSelection(note.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
