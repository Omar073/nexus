// Curated doc text for public classes (no `///` prefix on each line here).
// Use `\n` in a string (or adjacent string literals) for 2–3 lines when a class is central.
// apply_public_class_docs.dart turns each non-empty line into one `///` line in source.
// Merged with curated_public_class_docs_supplement.dart.
// --sync skips replacing a multi-line file doc when the map entry is still a single line.

const Map<String, String> kCuratedPublicClassDocs = {
  // app
  'App':
      'Root [MaterialApp]: theme mode, [GoRouter], and keyboard shortcuts.\n'
      'Hosts the navigator below splash once [AppInitializer] finishes.',
  'AppRouter':
      'Single place for Nexus route paths, redirects, and deep links.\n'
      'Keeps shell vs full-screen routes (e.g. note editor) consistent.',

  // core — data
  'DeviceIdStore': 'Persists a stable device id for sync and analytics.',
  'HiveBoxes': 'Names and helpers for opening typed Hive boxes.',
  'SyncMetadata': 'Hive model: last successful sync timestamp per sync scope.',
  'SyncMetadataAdapter': 'Serializes [SyncMetadata] for Hive.',
  'SyncOperation':
      'Queued create/update/delete for background cloud sync.\n'
      'Carries entity type, id, JSON snapshot, and retry metadata for [SyncService].',

  // core — services / utils / widgets
  'DebugLogEntry': 'One in-memory log row (time, level, message, source).',
  'NotificationService':
      'Schedules, shows, and cancels local reminder notifications.',
  'PermissionService':
      'Wraps OS permission prompts (mic, notifications, etc.).',
  'AttachmentStorageService':
      'Writes and reads note/task attachment files on disk.',
  'AttachmentCleanupService':
      'Best-effort deletion of attachment files after removal.',
  'NoteConflictDetector':
      'Compares local vs remote note payloads for edit conflicts.',
  'SyncOperationAdapter': 'Serializes [SyncOperation] for Hive.',
  'TaskConflictDetector':
      'Compares local vs remote task payloads for edit conflicts.',
  'AppDrawerButton': 'Icon button that opens the navigation drawer.',

  // analytics
  'AnalyticsSnapshot': 'Immutable counts for tasks, reminders, and habits.',
  'AnalyticsController':
      'Read-only view model for the analytics dashboard.\n'
      'Pulls counts from task, reminder, and habit controllers without owning their data.',

  // calendar
  'CalendarItem': 'Unified list row: task, reminder, or habit for a date.',
  'CalendarController':
      'Builds per-day agenda rows from tasks, reminders, and habits.\n'
      'Exposes a flat list of [CalendarItem] for the calendar UI to render.',

  // categories
  'Category': 'Hive model: id, display name, optional parent category.',
  'CategoryAdapter': 'Serializes [Category] for Hive.',

  // habits
  'HabitLocalDatasource': 'CRUD for [Habit] records in Hive.',
  'HabitLogLocalDatasource': 'CRUD for per-day [HabitLog] completion rows.',
  'HabitMapper': 'Maps [Habit] Hive model to domain entity and back.',
  'HabitLogMapper': 'Maps [HabitLog] Hive model to domain entity and back.',
  'Habit': 'Hive model: habit definition, streak fields, sync metadata.',
  'HabitAdapter': 'Serializes [Habit] for Hive.',
  'HabitLog': 'Hive model: one habit completion entry for a given day.',
  'HabitLogAdapter': 'Serializes [HabitLog] for Hive.',
  'HabitRepositoryImpl': 'Implements habit persistence via local datasource.',
  'HabitLogRepositoryImpl':
      'Implements habit log persistence via local datasource.',
  'CreateHabitUseCase': 'Creates a new habit and stores it locally.',
  'ToggleHabitTodayUseCase': 'Marks today complete/incomplete for a habit.',
  'HabitDetailsScreen': 'Read-only habit summary and history context.',
  'HabitController':
      'Primary habit list + today-toggle API for the habits feature.\n'
      'Coordinates [HabitRepositoryImpl] and exposes [ChangeNotifier] updates to widgets.',

  // notes — data
  'NoteLocalDatasource':
      'CRUD for [Note] and embedded attachment metadata in Hive.',
  'NoteMapper': 'Maps [Note] Hive model to domain entity and back.',
  'Note': 'Hive model: note body, category, attachments, sync/conflict fields.',
  'NoteAdapter': 'Serializes [Note] for Hive.',
  'NoteAttachment':
      'Hive model: one attachment path, MIME, and optional Drive id.',
  'NoteAttachmentAdapter': 'Serializes [NoteAttachment] for Hive.',
  'NoteRepositoryImpl':
      'Hive-backed implementation of the notes repository contract.\n'
      'Maps models, applies conflict rules, and surfaces streams for the list UI.',
  'NoteSyncHandler':
      'Entity handler that serializes [Note] for [SyncService] push/pull.\n'
      'Translates remote documents to local rows and enqueues outbound changes.',
  'AddNoteAttachmentUseCase':
      'Adds a file-backed attachment and updates the note.',
  'CreateEmptyNoteUseCase': 'Inserts a new blank note and returns its id.',
  'DeleteNoteUseCase': 'Removes a note locally and enqueues remote delete.',
  'SaveNoteUseCase':
      'Writes note content and metadata through the repository.\n'
      'Debounced callers still funnel here; triggers sync when the note is dirty.',
  'UpdateNoteCategoryUseCase': 'Assigns or clears a note\'s category.',
  'NoteController':
      'Notes feature facade: list, selection, search, and editor wiring.\n'
      'Owns attachment add/remove, category changes, and coordinates [SaveNoteUseCase].\n'
      'Listeners include [NotesListScreen], [NoteEditorView], and tiles.',
  'NoteConflictResolutionDialog':
      'Lets the user pick local vs remote when a note conflicts.',
  'CategorySelector': 'Dropdown of categories for the note editor toolbar.',
  'NoteEditorAutosaveController':
      'Debounced local save and lifecycle flush for the editor.',
  'NoteEditorMarkerInserter':
      'Inserts Quill markers for attachments in note content.',
  'MarkdownEditorArea': 'Markdown mode editor surface for a note.',
  'VoiceNotesSection':
      'Lists audio attachments with play/delete and Drive recovery.',
  'NoteEditorBody':
      'Chooses Quill vs markdown editor and applies RTL when needed.',
  'NotesBody': 'Scrollable note list with selection mode and empty states.',
  'NotesSelectionBar': 'Bulk actions when multiple notes are selected.',

  // reminders
  'ReminderLocalDatasource': 'CRUD for [Reminder] rows in Hive.',
  'ReminderMapper': 'Maps [Reminder] Hive model to domain entity and back.',
  'Reminder': 'Hive model: title, schedule, completion, snooze, sync fields.',
  'ReminderAdapter': 'Serializes [Reminder] for Hive.',
  'ReminderRepositoryImpl':
      'Implements reminder persistence via local datasource.',
  'CompleteReminderUseCase': 'Marks a reminder done and updates notifications.',
  'CreateReminderUseCase': 'Creates a reminder and schedules notifications.',
  'DeleteReminderUseCase':
      'Deletes a reminder locally and cancels notifications.',
  'SnoozeReminderUseCase': 'Moves fire time forward and reschedules.',
  'UncompleteReminderUseCase': 'Reopens a completed reminder.',
  'UpdateReminderUseCase': 'Edits fields and refreshes scheduling.',
  'RemindersScreen': 'Tabbed reminder list with add/edit flows.',
  'ReminderController':
      'Reminder CRUD, list filters, bulk selection, and scheduling hooks.\n'
      'Talks to [ReminderRepositoryImpl] and [NotificationService] for alarms.',
  'ReminderSelectionBar': 'Actions for bulk-selected reminders.',
  'RemindersBody': 'Main list + empty state for the reminders tab.',

  // settings
  'SettingsStore':
      'Key-value access for theme, sort, nav bar, and retention prefs.',
  'DeletePresetUseCase': 'Removes a saved color preset from storage.',
  'LoadSettingsUseCase': 'Builds the settings entity from repositories.',
  'ResetColorsUseCase': 'Restores default light/dark palette values.',
  'SavePresetUseCase': 'Stores the current colors as a named preset.',
  'UpdateAutoDeleteCompletedTasksUseCase':
      'Toggles auto-removal of old completed tasks.',
  'UpdateCategorySortOptionUseCase': 'Persists how categories are ordered.',
  'UpdateCompletedRetentionDaysUseCase':
      'How long completed tasks stay visible.',
  'UpdateDarkPaletteUseCase': 'Updates dark-theme accent and surface colors.',
  'UpdateNavBarStyleUseCase': 'Switches bottom navigation presentation style.',
  'UpdatePrimaryColorUseCase':
      'Sets the primary seed color for light/dark themes.',
  'UpdateSecondaryColorUseCase': 'Sets the secondary accent color.',
  'UpdateTaskSortOptionUseCase': 'Persists default task ordering.',
  'UpdateThemeModeUseCase': 'Switches light, dark, or system theme mode.',
  'SettingsController':
      'In-memory [AppSettingsEntity] plus theme/nav/task preference writes.\n'
      'Each `update*` method delegates to a small use case and notifies listeners.',
  'ConnectivityStatusTile':
      'Shows online/offline and last connectivity change.',

  // sync UI
  'SyncStatusWidget': 'Compact sync progress / error indicator for the shell.',

  // task editor widgets
  'TaskAttributeSelectors':
      'Priority, due date, and reminder chips for the editor.',
  'TaskCategorySelector': 'Category picker row in the task editor sheet.',
  'TaskEditorHeader': 'Title row and close/done actions for the task editor.',
  'TaskEditorInputs': 'Title and notes text fields for a task.',
  'TaskQuickOptions': 'One-tap chips for common task editor shortcuts.',

  // tasks
  'TaskLocalDatasource': 'CRUD for [Task] rows and attachments in Hive.',
  'TaskMapper': 'Maps [Task] Hive model to domain entity and back.',
  'Task': 'Hive model: title, category, due, reminders, attachments, sync.',
  'TaskAdapter': 'Serializes [Task] for Hive.',
  'TaskAttachment': 'Hive model: file path and MIME for a task attachment.',
  'TaskAttachmentAdapter': 'Serializes [TaskAttachment] for Hive.',
  'TaskSyncHandler':
      'Entity handler for [Task] in the shared sync pipeline.\n'
      'Converts Firestore maps to Hive models and enqueues local changes outbound.',
  'AddTaskAttachmentUseCase': 'Attaches a file to a task and persists it.',
  'ClearCategoryOnTasksUseCase':
      'Sets category to null when a category is deleted.',
  'CreateTaskUseCase': 'Creates a task with defaults and stores locally.',
  'DeleteTaskUseCase': 'Removes a task and enqueues remote delete.',
  'ToggleTaskCompletedUseCase': 'Flips completion and updates ordering.',
  'UpdateTaskUseCase': 'Persists field changes to an existing task and syncs.',
  'TaskController':
      'Central tasks state: tabs, categories, selection, and ordering.\n'
      'Drives [TasksScreen], editor sheets, and bulk actions via [TaskBulkActions].',
  'CategoryHeader':
      'Expandable section header for a category on the tasks tab.',
  'CategorySectionTaskItem': 'Single task row inside a category section.',
  'TaskSelectionBar': 'Bulk actions when tasks are multi-selected.',
  'TasksTabBody': 'Category-grouped task list for one filter tab.',
  'TaskConflictResolutionDialog':
      'Resolves task edit conflicts (local vs remote).',
  'TaskMoreMenu': 'Overflow menu for per-task actions on the list.',

  // theme customization
  'ColorOptionGrid': 'Tappable color swatches for theme customization.',
  'ThemePreviewCard': 'Sample card showing theme colors in context.',

  // wrapper
  'AppWrapper':
      'Main shell after login: [AppDrawer], body, and bottom navigation.\n'
      'Hosts [NavBarBuilder], sync indicator, and coordinates back gesture with nested navigators.',
  'AppDrawer': 'Navigation drawer destinations and header.',

  // test
  'FakeDeviceCalendarPlugin': 'Fake [DeviceCalendarPlugin] for calendar tests.',
  'MockBox': 'Mock Hive [Box] for reminder background tests.',
  'MockReminderNotifications': 'Mock notification port for background tests.',
  'MockReminder': 'Mock [Reminder] model for scheduler tests.',
  'MockConnectivity': 'Fake [Connectivity] with controllable status.',
  'MockTaskController': 'Mockito stub for [TaskController] in analytics tests.',
  'MockReminderController':
      'Mockito stub for [ReminderController] in analytics tests.',
  'MockHabitController':
      'Mockito stub for [HabitController] in analytics tests.',
  'FakeTaskController': 'Minimal [TaskController] for widget tests.',
};
