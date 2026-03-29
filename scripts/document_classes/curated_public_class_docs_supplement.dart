// Additional curated class docs (merged in apply_public_class_docs.dart).
// Split to keep the main map file readable. Multi-line values use `\n` like curated_public_class_docs.dart.

const Map<String, String> kCuratedPublicClassDocsSupplement = {
  // app bootstrap & theme
  'HiveBootstrap': 'Registers Hive adapters and opens boxes at startup.',
  'AppColorsLight': 'Light theme seed [ColorScheme] and derived surfaces.',
  'AppColorsDarkNavy': 'Dark navy palette derived from the app color seeds.',
  'AppColorsDarkAmoled': 'Near-black dark palette for OLED-friendly UI.',
  'AppTheme': 'Builds [ThemeData] for light/dark from settings and seeds.',

  // core — hive / connectivity / embed / health
  'HiveTypeIds': 'Stable @HiveType numeric ids; append only, never reuse.',
  'ConnectivityMonitorService': 'Observes connectivity and notifies listeners.',
  'DebugLoggerService': 'In-memory/file debug log buffer and optional overlay.',
  'NoteEmbedService':
      'Records and plays local voice attachments for notes (paths via [AttachmentStorageService]).',
  'BackendHealthChecker': 'Lightweight reachability check for sync backends.',
  'ConnectivityService': 'Exposes online/offline state from the OS plugin.',
  'DeviceCalendarService': 'Reads/writes device calendar events via plugin.',

  // Drive stack
  'DriveAuthRequiredException': 'Thrown when Drive operations need re-auth.',
  'DriveAuthStore': 'Securely persists Drive OAuth tokens and refresh state.',
  'GoogleDriveApiClient': 'Low-level HTTP wrapper for Drive REST calls.',
  'GoogleDriveAuth': 'OAuth sign-in, token refresh, and sign-out for Drive.',
  'GoogleDriveFiles': 'Upload, download, and delete file operations on Drive.',
  'GoogleDriveFolders': 'Resolves and creates app folders on Drive.',
  'GoogleDriveService': 'Facade combining Drive auth, folders, and files.',

  // sync core
  'SyncConflict': 'Describes a version mismatch during pull/push.',
  'SyncService':
      'Processes [SyncOperation] queue: push local changes, pull remotes.\n'
      'Dispatches to registered [EntitySyncHandler] implementations per entity type.',

  'ReminderConflictDetector':
      'Compares local vs remote reminders for conflicts.',

  // core widgets
  'CircularCheckbox': 'Round checkbox matching Nexus list tile styling.',
  'CommonSnackbar': 'Shared snackbar helpers for consistent messaging.',
  'DebugPanel': 'Scrollable log list for the in-app debug overlay.',
  'DebugPanelFooter': 'Footer actions for the debug overlay panel.',
  'DebugPanelHeader': 'Title and dismiss controls for the debug overlay.',
  'GlobalDebugOverlay':
      'Draggable FAB + panel hosting [DebugLoggerService] output.',
  'DrivePasswordDialog': 'Collects encryption/password input for Drive flows.',
  'FilterChipBar': 'Horizontal row of selectable filter chips.',
  'HabitPill': 'Compact habit label chip for dashboards and lists.',
  'HabitPillBar': 'Row of [HabitPill] widgets with overflow handling.',
  'HabitPillData': 'Immutable habit id + label for pill rendering.',
  'NexusCard': 'Standard elevated card with consistent padding and radius.',
  'SectionHeader': 'Title row for grouped settings or list sections.',
  'SegmentedControl': 'Two- or three-way segmented selector control.',
  'ThemeToggleButton': 'Icon toggle between light, dark, and system theme.',

  // analytics UI
  'AnalyticsScreen': 'Dashboard of charts and quick stats for productivity.',
  'HabitHeatmap': 'Calendar-style heatmap of habit completion density.',
  'HabitsProgressCircle': 'Radial progress for habits completed this period.',
  'LegendItem': 'Swatch + label for chart legends.',
  'QuickStatTile': 'Compact numeric stat with caption for analytics grids.',
  'TaskVelocityChart': 'Time-series of completed tasks for velocity insight.',
  'TasksPieChart': 'Distribution of task states as a pie chart.',

  // calendar UI
  'CalendarScreen': 'Month/agenda view backed by [CalendarController].',
  'CalendarEventTile': 'One row for a task, reminder, or habit on a date.',

  // categories
  'CategoryController':
      'Loads categories and coordinates drawer/list consumers.',
  'CategoryDrawer': 'Bottom sheet listing categories for jump-to navigation.',
  'CategoryDrawerItem': 'One selectable category row inside [CategoryDrawer].',
  'CategoryTile': 'List tile showing category name and optional task count.',

  // dashboard
  'DashboardScreen': 'Home hub with tasks, reminders, habits, and stats.',
  'DailyProgressCard': 'Rings or bars for today’s completion progress.',
  'DashboardHabitsSection': 'Habit pills and shortcuts on the dashboard.',
  'DashboardRemindersSection': 'Upcoming reminders strip on the dashboard.',
  'DashboardTasksSection': 'High-priority or due-soon tasks on the dashboard.',
  'QuickReminderCard': 'Single reminder summary card with snooze/complete.',
  'QuickReminderData': 'View-model for a quick reminder card.',
  'QuickRemindersGrid': 'Grid of [QuickReminderCard] on the dashboard.',
  'StatCard': 'Icon + value + subtitle for dashboard statistics.',
  'UpcomingTaskCard': 'Preview of the next due task with metadata.',

  // habits — domain / sync / UI
  'HabitSyncHandler': 'Pushes and pulls habits through the sync pipeline.',
  'HabitEntity': 'Domain habit: title, schedule, streaks, and sync fields.',
  'HabitLogEntity': 'Domain model for a habit completion on one day.',
  'HabitsScreen': 'Scrollable habit list with streaks and quick toggle.',
  'HabitCard': 'Rich card layout for a habit on the habits screen.',
  'HabitTile': 'Dense habit row variant for lists and pickers.',

  // notes — domain / editor
  'NoteAttachmentEntity': 'Domain attachment: path, MIME, Drive id, kind.',
  'NoteEntity': 'Domain note: content, category, attachments, sync metadata.',
  'NoteAttachmentKinds':
      'MIME-based rules for voice, image, and file attachments.',
  'NoteEditorScreen': 'Loads a note by id and hosts [NoteEditorView].',
  'NotesListScreen': 'Searchable note list with filters and selection mode.',
  'AttachmentButton':
      'Captures gallery, camera, or voice and adds an attachment.',
  'NoteAttachmentDriveUploadHelper':
      'Drive sign-in and retry when upload fails.',
  'NoteMarkdownToggleRow': 'Toggles between markdown and rich text for a note.',
  'NoteRichToolbar': 'Formatting toolbar for the Quill-based editor.',
  'NoteEditorAppBar': 'Title field, mode actions, and overflow for the editor.',
  'NoteEditorView': 'Owns editor state: Quill/markdown, autosave, attachments.',
  'VoiceNoteItem': 'Play/pause, duration, and delete for one voice attachment.',
  'NoteTile': 'List tile with title, preview snippet, and timestamp.',

  // reminders — services / domain / UI
  'ReminderTimerService': 'Schedules periodic work for reminder firing.',
  'ReminderSyncHandler': 'Pushes and pulls reminders through sync.',
  'ReminderEntity': 'Domain reminder with schedule and completion state.',
  'CleanupCompletedRemindersUseCase':
      'Prunes old completed reminders per policy.',
  'ReminderEditorResult': 'Payload returned when the reminder editor closes.',
  'ReminderTile': 'List row for one reminder with actions and schedule text.',

  // settings — models / repo / sections
  'ColorPreset': 'Hive model for a named saved color palette.',
  'ColorOption': 'One selectable swatch entry inside custom color storage.',
  'CustomColors': 'Serializable light/dark color set for presets.',
  'CustomColorsStore': 'Loads and saves custom colors per brightness.',
  'SettingsRepositoryImpl':
      'Maps [SettingsStore] and color stores to domain settings.',
  'AppSettingsEntity': 'Immutable snapshot of all user-facing settings.',
  'ColorPresetEntity': 'Domain color preset with display metadata.',
  'SettingsScreen': 'Grouped settings: theme, sync, tasks, and permissions.',
  'ConnectivityStatusUtils': 'Formats connectivity labels and detail strings.',
  'SettingsConnectivityHelper': 'Wires settings UI to connectivity streams.',
  'ConnectivityStatusSection': 'Settings block for network status.',
  'DriveAccessSection': 'Drive account, folder, and auth troubleshooting.',
  'PermissionsSection': 'Explains and requests OS permissions.',
  'SyncSection': 'Manual sync triggers and last-sync messaging.',
  'TaskManagementSection': 'Retention, auto-delete, and sort preferences.',
  'ThemeSection': 'Theme mode, seeds, and nav bar style entry points.',
  'SettingsHeader': 'Large title header for the settings screen.',
  'SettingsSection': 'Titled group container for settings tiles.',

  // splash / init
  'AppInitializer': 'Runs Hive, Firebase, and notification setup in order.',
  'AppProviderFactory': 'Builds the [MultiProvider] tree for the running app.',
  'AppInitializationResult': 'Outcome and error details after bootstrap.',
  'CriticalInitializationResult': 'Whether the app may continue past splash.',
  'SplashScreen': 'Branding and progress while initialization runs.',
  'SplashWrapper': 'Chooses splash vs main shell based on init state.',

  'SyncController': 'Surface-level sync triggers and status for the UI.',

  // task editor sheet
  'TaskEditorSheet': 'Modal sheet for creating or editing a single task.',
  'TaskOptionChip': 'Selectable chip for a boolean task option.',
  'TaskPriorityButton': 'Priority picker control in the task editor.',

  // tasks — repo / domain / presentation
  'TaskRepositoryImpl':
      'Implements task persistence via [TaskLocalDatasource].',
  'TaskAttachmentEntity': 'Domain task attachment metadata.',
  'TaskEntity': 'Domain task with category, due, reminders, and sync fields.',
  'TasksScreen': 'Tabbed task views with categories and bulk actions.',
  'TaskSelectionState': 'Tracks multi-select ids and selection mode flag.',
  'TaskBulkActions': 'Applies delete/move/complete to selected tasks.',
  'TaskDateFormatter': 'Human-readable due and reminder date strings.',
  'TaskSortingHelper': 'Sorts tasks per user preference inside sections.',
  'MoveTasksToCategorySheet': 'Bulk reassignment of tasks to another category.',
  'CategoryScrollHelper': 'Scrolls the task list to a chosen category.',
  'SliverTabBarDelegate': 'Pinned tab bar delegate for task filter tabs.',
  'GroupedTaskList': 'List of tasks grouped under category headers.',
  'JumpToCategoryButton': 'Opens [CategoryDrawer] from the tasks app bar.',
  'CategorySection': 'Collapsible block of tasks under one category.',
  'SubcategorySection': 'Nested grouping when parent/child categories exist.',
  'TasksHeader': 'Title, search, and actions for the tasks screen.',
  'EmptyTasksState': 'Placeholder when a filter has no tasks.',
  'TaskDateRow': 'Due date and reminder icons for a task row.',
  'TaskItem': 'Interactive row for a task (checkbox, content, menu).',
  'TaskItemContent': 'Inner layout for title, subtitle, and metadata.',
  'TaskTextContent': 'Title and notes text styling inside a task item.',

  // theme customization
  'ThemeCustomizationScreen': 'Colors, presets, and nav bar style tuning.',
  'ColorSection': 'Grouped color pickers for primary, secondary, and surfaces.',
  'NavBarPreview': 'Live tappable preview of the selected nav bar style.',
  'NavBarStyleCard': 'Selectable card describing one nav bar style.',
  'NavBarStylePreview': 'Static illustration for a nav bar style thumbnail.',
  'NotchPreviewPainter': 'Paints the notch-shaped preview for the notch style.',
  'NavBarStyleSection': 'Settings rows linking to nav bar customization.',
  'PresetListSection': 'Saved color presets list with apply/delete.',
  'SavePresetDialog': 'Prompts for a name when saving the current colors.',

  // wrapper / nav
  'DrawerItem': 'Icon + label row used in [AppDrawer].',
  'NavBarBuilder': 'Selects curved, notch, Google, or Rive nav implementation.',
  'AnimatedNotchNavBarWrapper': 'Hosts the animated notch bottom bar package.',
  'CurvedNavBarWrapper': 'Hosts the curved labeled bottom navigation bar.',
  'GoogleNavBarWrapper': 'Hosts the Google-style bottom navigation bar.',
  'RiveAnimatedNavBar': 'Bottom bar whose tab icons are Rive artboards.',
  'RiveModel': 'Asset path, artboard, and state machine for one Rive icon.',
  'RiveNavItem': 'Tab title paired with a [RiveModel] for the Rive nav bar.',

  // generated
  'DefaultFirebaseOptions':
      'Generated Firebase options per platform (see firebase_options.dart).',

  // test doubles (also listed in main curated file where overlaps)
  'FakeConnectivityService':
      'Controllable [ConnectivityService] for unit tests.',
  'FakeEntitySyncHandler': 'Records sync calls for entity handler tests.',
  'FakeGoogleDriveService': 'No-op Drive with configurable auth state.',
  'FakeNotificationService':
      'Records schedule/cancel/show for notification tests.',
  'FakeSettingsController': 'Minimal [SettingsController] for dependent tests.',
  'FakeSettingsRepository':
      'Returns defaults; no-op writes for settings tests.',
  'FakeSyncService': 'Records enqueued operations for sync tests.',
};
