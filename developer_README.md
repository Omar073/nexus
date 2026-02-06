# Nexus — Developer Contributor Guide

Nexus is an **offline-first** personal life management app (Tasks, Reminders, Notes, Habits, Calendar, Analytics) built with **Flutter**.

**Design principle:** Hive is the local source-of-truth. Every user action writes locally first and then syncs to the cloud when possible.

- **Platforms**: Android + Windows
- **UI language**: English-only (hardcoded strings)
- **Arabic support**: user-entered content (Tasks/Notes) auto-renders RTL when text contains Arabic characters

This README is meant to onboard developer contributors quickly: how the repo is structured, how data flows, and where to implement changes.

If you're looking for a **non-technical, end-user overview**, see `README.md`.

## Getting started (step-by-step)

### 1) Install dependencies

```bash
flutter pub get
```

### 2) Run static checks

```bash
flutter analyze; flutter test
```

### 3) Build artifacts (per project workflow rules)

```bash
flutter build apk; flutter build windows
```

## High-level architecture

### Offline-first data flow

1) UI triggers an action on a controller (e.g., create task)
2) Controller writes to **Hive** immediately (instant UX)
3) Controller enqueues a **SyncOperation** (local queue)
4) `SyncService` pushes queued ops to Firestore when online
5) `SyncService` pulls remote changes and updates Hive
6) Conflicts are surfaced via conflict dialogs (user chooses local vs remote)

### MVC + Provider

- **Models**: Hive-backed classes (plus Firestore JSON mapping)
- **Controllers**: `ChangeNotifier` (business logic)
- **Views**: screens/widgets
- **Services**: cross-cutting infrastructure

Providers are initialized in `lib/main.dart` and injected app-wide.

### App services architecture

The app uses a **composer pattern** to manage widget wrappers and background services, avoiding deep widget nesting:

- **Widget wrappers**: Composed via `wrapWithAppServices()` in `lib/app/services/app_services_composer.dart`. These wrap the app UI (e.g., `GlobalDebugOverlay`).

- **Background services**: Singleton services that run independently of the widget tree. They are initialized in `App.initState()` via `initializeBackgroundServices()` and disposed in `App.dispose()` via `disposeBackgroundServices()`. Examples:
  - `ConnectivityMonitorService`: Monitors network connectivity and shows snackbars when connection changes
  - Future services can be added by extending the composer functions

- **Global ScaffoldMessenger**: `appMessengerKey` in `lib/app/app_globals.dart` allows services and other code to show snackbars without BuildContext. Use `CommonSnackbar.showGlobal()` for context-free snackbars.

### App Initialization Flow (`lib/features/splash/`)

The app startup is managed by `AppInitializer` (`lib/features/splash/controllers/app_initializer.dart`) in two phases:

1. **Critical Initialization** (`initializeCritical`):
   - Runs before `runApp`.
   - Initializes Firebase, Hive, Device ID, and Settings.
   - **Failure handling**: If this fails, the app throws an error immediately (fail fast).
2. **Complete Initialization** (`completeInitialization`):
   - Runs after the Splash Screen is visible.
   - Initializes heavier services: `NotificationService`, `Workmanager`, `GoogleDriveService`, and all Repositories/Controllers.
   - **User Experience**: The Splash Screen waits for this to complete before navigating to the Dashboard.

**Data flow for background services:**

1) `App` widget (StatefulWidget) initializes in `initState`
2) After first frame, `initializeBackgroundServices(context)` is called
3) Services access Provider context to read dependencies (e.g., `ConnectivityService`)
4) Services subscribe to streams/events and use `appMessengerKey` to show UI updates
5) On app disposal, `disposeBackgroundServices()` cleans up all service subscriptions

## Repository map (where everything lives)

### App bootstrap / routing / UI shell

- `lib/main.dart`: Firebase init, Hive init, Provider wiring
- `lib/app/app.dart`: `StatefulWidget` with `MaterialApp.router`, themes
- `lib/app/app_globals.dart`: Global `ScaffoldMessengerKey` for context-free snackbars
- `lib/app/services/app_services_composer.dart`: Composes widget wrappers and manages background service initialization/disposal
- `lib/app/router/app_router.dart`: `go_router` routes (bottom-nav shell)
- `lib/features/wrapper/views/app_wrapper.dart`: App shell with drawer and bottom navigation
- `lib/features/wrapper/views/app_drawer.dart`: Navigation drawer
- `lib/app/theme/app_theme.dart`: Material 3 themes

### Core data + infra

- `lib/core/data/hive_type_ids.dart`: stable Hive type IDs (never reuse)
- `lib/core/data/hive_boxes.dart`: Hive box names
- `lib/core/data/hive_bootstrap.dart`: adapter registration + box opening
- `lib/core/data/sync_queue.dart`: sync operation queue model
- `lib/core/data/sync_metadata.dart`: last successful sync timestamp

Core services were reorganized into subfolders under `lib/core/services/`:

- **Platform**:
  - `lib/core/services/platform/connectivity_service.dart`: online/offline detection
  - `lib/core/services/platform/connectivity_status_service.dart`: connectivity status checks (Firebase, Hive, Google Drive)
  - `lib/core/services/platform/permission_service.dart`: runtime permissions
  - `lib/core/services/platform/device_calendar_service.dart`: device calendar wrapper
- **Sync**:
  - `lib/core/services/sync/sync_service.dart`: sync engine (push/pull + conflict detection)
- **Notifications**:
  - `lib/core/services/notifications/notification_service.dart`: local notifications
  - `lib/core/services/notifications/workmanager_dispatcher.dart`: Android background dispatcher
  - `lib/core/services/notifications/reminder_notifications.dart`: notifications interface
- **Storage**:
  - `lib/core/services/storage/attachment_storage_service.dart`: local file storage layout
  - `lib/core/services/storage/google_drive_service.dart`: **facade** for Drive operations
  - `lib/core/services/storage/google_drive_auth.dart`: password gate + Google Sign-In
  - `lib/core/services/storage/google_drive_api_client.dart`: Drive API client creation
  - `lib/core/services/storage/google_drive_folders.dart`: folder management
  - `lib/core/services/storage/google_drive_files.dart`: upload/list/download/delete
  - `lib/core/services/storage/drive_auth_store.dart`: device auth state (SharedPreferences)
  - `lib/core/services/storage/drive_auth_exception.dart`: `DriveAuthRequiredException`
- **Background Services**:
  - `lib/core/services/connectivity_monitor_service.dart`: singleton service that monitors network connectivity and shows snackbars on connection changes (runs independently of widget tree)

### Core widgets

- `lib/core/widgets/common_snackbar.dart`: reusable snackbar utility with `show()` (BuildContext-based) and `showGlobal()` (context-free) methods
- `lib/core/widgets/debug/global_debug_overlay.dart`: hidden overlay UI for production debug logs (triple-tap / Ctrl+Shift+D)

### Production debug logs (Android + Windows)

- `lib/core/services/debug/debug_logger_service.dart`: in-memory logs (max 500) + 30-min archive
- `lib/core/services/debug/debug_log_archiver_io.dart`: writes archive to app documents dir (Android/Windows)
- `lib/core/widgets/debug/global_debug_overlay.dart`: hidden overlay UI (triple-tap / Ctrl+Shift+D)

## App Shell & Navigation (`lib/features/wrapper/`)

The `Wrapper` feature manages the persistent UI shell that surrounds the entire app.

**Key files**:

- `lib/features/wrapper/views/app_wrapper.dart`: Main Scaffold containing the `ScaffoldKey` for drawer control.
- `lib/features/wrapper/views/app_drawer.dart`: The side navigation drawer accessible globally.
- `lib/features/dashboard/views/dashboard_screen.dart`: The home screen aggregator.

## Dashboard (`lib/features/dashboard/`)

The Dashboard acts as an aggregator view, pulling data from multiple controllers to show a daily summary.

**Key files**:

- `lib/features/dashboard/views/dashboard_screen.dart`
- `lib/features/dashboard/controllers/dashboard_controller.dart` (if applicable)

**How it works**:
It listens to `TaskController`, `ReminderController`, `NoteController`, and `HabitController` to display:

- Today's pending tasks
- Upcoming reminders
- Quick access buttons
- Recent activity stats

## Firebase (Firestore sync) — setup + layout

Firebase bootstrap exists in `lib/firebase_setup/firebase_options.dart` and is initialized in `lib/main.dart`.

### Firebase API keys (kept out of Git)

Firebase API keys/App IDs are stored using a template + git-ignore pattern:

- **Template** (committed): `lib/firebase_setup/apiKeys.dart.example`
- **Local secrets** (git-ignored): `lib/firebase_setup/apiKeys.dart`
- **Firebase options** (committed): `lib/firebase_setup/firebase_options.dart` (imports `apiKeys.dart`)

Setup for new contributors:

```bash
Copy-Item lib/firebase_setup/apiKeys.dart.example lib/firebase_setup/apiKeys.dart
```

Then fill in real values in `lib/firebase_setup/apiKeys.dart`. Confirm it is ignored:

```bash
git check-ignore lib/firebase_setup/apiKeys.dart
```

### Enable Firestore

- In Firebase console, enable **Cloud Firestore** (Spark plan compatible).

### Firestore collections used

- `tasks/{taskId}`: task docs
- `notes/{noteId}`: note docs

### Firestore rules (no authentication)

This app currently has **no auth**. For development, permissive rules are OK. **Do not ship this to production** without adding auth.

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /tasks/{taskId} { allow read, write: if true; }
    match /notes/{noteId} { allow read, write: if true; }
  }
}
```

## Google Drive (attachments) — setup

Attachments are stored locally first, then **best-effort uploaded to Google Drive**.

### Configure Google Drive API

- Enable **Google Drive API**
- Configure **OAuth consent screen**
- Create **OAuth Client ID (Android)** matching `applicationId` in `android/app/build.gradle.kts`

### Current auth behavior (what contributors should know)

- **Password gate (device-level)**: user enters an in-app password once; saved locally via `SharedPreferences`.
- **Google Sign-In (API-level)**: required for actual Drive API calls (uploads/folder creation). The app prompts the user when an upload happens.
- **Shared folder**: uploads target the shared folder ID in `GoogleDriveFolders.mediaFolderId`.

Drive integration code lives in `lib/core/services/storage/` (see repo map above).

## Secret debug logs (production-only) — Android + Windows

This feature is intentionally hidden and only active in **non-debug builds** (`kDebugMode == false`).

### Why it's disabled in debug mode

When running `flutter run` (debug mode), you have full access to DevTools and console output, so the overlay is unnecessary. The overlay is designed for diagnosing issues in **profile** or **release** builds where console access isn't available.

### How to access the debug overlay

**Option 1: Run in profile mode**

```bash
flutter run --profile -d <device_id>
```

Profile mode enables the overlay while still providing reasonable performance for testing.

**Option 2: Enable in debug mode (for development)**

If you need the overlay during debug mode, remove the `kDebugMode` checks in `lib/core/widgets/debug/global_debug_overlay.dart`:

```dart
// In _handleTapDown() - remove or comment out:
// if (kDebugMode) return;

// In build() - remove or comment out:
// if (kDebugMode) return widget.child;
```

### Open the debug panel

- **Android + Windows**: triple-tap/click the **top-right 50×50px** area
- **Windows only**: `Ctrl+Shift+D`

### What it provides

- In-memory logs (max 500)
- Copy last 10/20/30 logs or all logs to clipboard
- Color-coded levels (info/warn/error)
- Auto-archive to a file every ~30 minutes (clears in-memory logs after archiving)

## Feature-by-feature guide

## Tasks

### Tasks Architecture

**Key files:**

- Models: `lib/features/tasks/models/task.dart`, `task_attachment.dart`, `task_enums.dart`, `task_editor_result.dart`
- Local storage: `lib/features/tasks/data/task_local_datasource.dart`
- Repository: `lib/features/tasks/repositories/task_repository.dart`
- Controller: `lib/features/tasks/controllers/task_controller.dart`
- UI: `lib/features/tasks/views/tasks_screen.dart`
- Widgets:
  - `lib/features/tasks/views/widgets/task_tile.dart`
  - `lib/features/tasks/views/widgets/task_search_bar.dart`
  - `lib/features/tasks/views/widgets/task_filter_sheet.dart`
  - `lib/features/tasks/views/widgets/task_editor_dialog.dart`: **Main Task Editor**. Handles creation and editing logic, differentiating it from the list view.
- `lib/features/tasks/views/widgets/task_detail_sheet/`: Modular components for the task detail bottom sheet (e.g., specific rows for priority, due date).
- `lib/features/tasks/views/utils/attachment_picker_utils.dart`: Helper for picking files/images.

### How it works

- CRUD writes to Hive first.
- Each write sets `isDirty=true` and enqueues a `SyncOperation(entityType: 'task')`.
- Attachments (images/voice) are stored locally and best-effort uploaded to Drive.
- A sync status icon in the Tasks app bar shows queue/sync/conflict state.

## Reminders

### Reminders Architecture

**Key files:**

- Models: `lib/features/reminders/models/reminder.dart`
- Controller: `lib/features/reminders/controllers/reminder_controller.dart`
- UI: `lib/features/reminders/views/reminders_screen.dart`
- Notification scheduling: `lib/core/services/notifications/notification_service.dart`

### How it works

- Creating/updating schedules a local notification.
- Completing/deleting cancels the scheduled notification.

### Background Reliability Strategy (Hybrid Approach)

To ensure notifications are delivered reliably (especially on Samsung/Android 12+), the app uses a **hybrid** timing strategy:

1. **Primary (Exact)**: `zonedSchedule` (AlarmManager)
    - Used for exact notification timing.
    - Works best when the app is running or device is standard Android.
2. **Secondary (Foreground Accuracy)**: In-App Timer
    - `ReminderController` runs a 30-second periodic timer while the app is open.
    - Checks for due reminders and triggers `showNow` immediately.
    - Ensures 100% reliability while the user is using the app.
3. **Tertiary (Background Safety Net)**: `Workmanager`
    - Runs every ~15 minutes (Android minimum for periodic background jobs).
    - **Data Flow**: `Workmanager` -> `workmanagerCallbackDispatcher` -> Initialize Hive (Read-Only) -> Check Due Reminders -> Trigger `NotificationService.showNow`.
    - Catches any reminders that were missed by the OS alarm manager (e.g. if the app was killed).

## Sync + conflict handling

### Sync Architecture

**Key files:**

- Queue model: `lib/core/data/sync_queue.dart`
- Sync engine: `lib/core/services/sync/sync_service.dart`
- UI state: `lib/features/sync/controllers/sync_controller.dart`
- Sync icon: `lib/features/sync/views/sync_status_widget.dart`
- Task conflicts: `lib/features/sync/views/conflict_resolution_dialog.dart`
- Note conflicts: `lib/features/notes/views/note_conflict_resolution_dialog.dart`

### How it works

- Controllers enqueue `SyncOperation` entries.
- `SyncService` pushes ops to Firestore, then pulls changes since last sync.
- Conflicts occur when local is dirty and remote updated after local last sync.
- User resolves by choosing **Keep Local** or **Keep Remote**.

## Notes (Rich text + inline voice notes)

### Notes Architecture

**Key files:**

- Models: `lib/features/notes/models/note.dart`, `note_attachment.dart`
- Controller: `lib/features/notes/controllers/note_controller.dart`
- UI: `lib/features/notes/views/notes_list_screen.dart`, `note_editor_screen.dart`
- RTL helper: `lib/features/notes/views/widgets/rtl_aware_text.dart`
- Voice helper: `lib/core/services/note_embed_service.dart`

### Storage format

- `Note.contentDeltaJson` stores Quill Delta JSON as a String.
- Voice notes are stored as `NoteAttachment` entries referencing local file paths (and Drive ids when uploaded).

## Habits

### Habits Architecture

**Key files:**

- Models: `lib/features/habits/models/habit.dart`, `habit_log.dart`
- Controller: `lib/features/habits/controllers/habit_controller.dart`
- UI: `lib/features/habits/views/habits_screen.dart`, `habit_details_screen.dart`

### How streaks work

- Each completion is a `HabitLog` keyed by local `YYYY-MM-DD`.
- Streak is computed by counting consecutive completed days back from today.

## Analytics

### Analytics Architecture

**Key files:**

- Controller: `lib/features/analytics/controllers/analytics_controller.dart`
- UI: `lib/features/analytics/views/analytics_screen.dart`
- Utils: `lib/features/analytics/utils/analytics_utils.dart`
- Widgets:
  - `lib/features/analytics/views/widgets/tasks_pie_chart.dart`
  - `lib/features/analytics/views/widgets/habits_progress_circle.dart`
  - `lib/features/analytics/views/widgets/legend_item.dart`
  - `lib/features/analytics/views/widgets/quick_stat_tile.dart`

Provides basic KPIs and a simple pie chart.

## Calendar

### Calendar Architecture

**Key files:**

- Controller: `lib/features/calendar/controllers/calendar_controller.dart`
- UI: `lib/features/calendar/views/calendar_screen.dart`
- Device calendar wrapper: `lib/core/services/device_calendar_service.dart`

Calendar overlays tasks (due dates) and reminders (scheduled times).

## Settings

### Settings Architecture

**Key files:**

- Controller: `lib/features/settings/controllers/settings_controller.dart`
- Connectivity Helper: `lib/features/settings/controllers/settings_connectivity_helper.dart`
- Connectivity Utils: `lib/features/settings/controllers/connectivity_status_utils.dart`
- State Mixin: `lib/features/settings/controllers/settings_connectivity_mixin.dart`
- UI: `lib/features/settings/views/settings_screen.dart`
- Sections (organized under `views/sections/`):
  - `theme_section.dart`
  - `task_management_section.dart`
  - `sync_section.dart`
  - `connectivity_status_section.dart`
  - `drive_access_section.dart`
  - `permissions_section.dart`
- Section Widgets: `views/sections/widgets/connectivity_status_tile.dart`

Includes theme mode, retention, sync status, Drive sign-in/out, connectivity status checks (Firebase, Hive, Google Drive), and permissions.

## Theme Customization (`lib/features/theme_customization/`)

Manages the app's visual style, including dynamic color generation.

**Key files**:

- `lib/features/theme_customization/services/theme_service.dart`: Handles theme switching logic.
- `lib/features/theme_customization/views/theme_customization_screen.dart`: UI for selecting colors/modes.
- `lib/app/theme/app_theme.dart`: Defines light/dark theme data.

## Testing + CI

### Tests

Tests live in `test/` and can be run with:

```bash
flutter test
```

### CI

GitHub Actions workflow is at `.github/workflows/flutter.yml`:

- `flutter pub get; flutter analyze; flutter test`

## Contributor workflow

### Adding a new feature module (recommended approach)

1) Add models to `lib/features/<feature>/models/` (with Hive adapter)
2) Add datasources/repositories in `data/` and `repositories/`
3) Add controller in `controllers/` (`ChangeNotifier`)
4) Add views in `views/`
5) Register adapters/open boxes in `lib/core/data/hive_bootstrap.dart`
6) Wire routes in `lib/app/router/app_router.dart`
7) Add/extend tests in `test/`

### Project command conventions

```bash
flutter pub get; flutter analyze; flutter test
flutter build apk; flutter build windows
```

## Localization (Removed)

The app previously used Flutter's l10n infrastructure with ARB files. This has been **removed** in favor of hardcoded English strings for simplicity. All UI text is now directly in the Dart code.

If you need to add/modify UI text, simply edit the string literals in the relevant widget files.

## Deep architecture & implementation guide

This section is a deeper, **implementation-level** walkthrough for new contributors. Read it top‑to‑bottom once, then jump back here as a reference when you build features.

### Layered mental model

- **Presentation layer**: Widgets, screens, dialogs, sheets
  - Reads state from controllers via Provider (`context.watch` / `select`).
  - Emits user intents back into controllers via methods (e.g. `taskController.createTask()`).
- **Controller layer**: `ChangeNotifier` classes
  - Own all feature-specific business logic.
  - Orchestrate repositories/services (e.g. schedule notifications after saving a reminder).
  - Expose derived view-models (sorted lists, sectioned lists, counts).
- **Repository & data layer**
  - Map between Hive models and other representations (Firestore JSON, DTOs).
  - Encapsulate querying/filtering logic so controllers stay thin.
- **Services layer**
  - Cross-cutting capabilities (sync, notifications, storage, connectivity, debug logging).
  - Explicitly **do not** depend on presentation widgets; they talk via controllers and global keys.

**Rule of thumb**: UI never manipulates Hive or Firestore directly. UI → Controller → Repository/Service → Hive/Firestore/Drive.

### Provider & controller lifecycle

- Controllers are registered in `main.dart` (or a dedicated provider setup file) using `MultiProvider`.
- Each top-level feature has a long-lived controller:
  - `TaskController`, `ReminderController`, `NoteController`, `HabitController`, `AnalyticsController`, `CalendarController`, `SettingsController`, etc.
- Controllers should:
  - Be **idempotent**: calling `load()` twice should not corrupt state.
  - Avoid doing heavy work in constructors—prefer explicit `init()` methods called during app initialization or first use.
  - Call `notifyListeners()` only when **publicly observable** state changes (avoid unnecessary rebuilds).

### Error handling & logging philosophy

- **User-facing errors**:
  - Prefer short, actionable snackbars using `CommonSnackbar.show()` / `showGlobal()`.
  - Do not leak low-level messages (HTTP codes, stack traces) to end users.
- **Developer diagnostics**:
  - Use `DebugLoggerService` to log structured messages (`info`, `warn`, `error`).
  - When something *should never happen*, log an error and add a clear comment.
- **Background tasks**:
  - Always log both **entry** and **exit** of background jobs (e.g. Workmanager callback) with counts and durations.

## Background services deep dive

### Connectivity monitoring

- **Files to know**:
  - `core/services/platform/connectivity_service.dart`
  - `core/services/platform/connectivity_status_service.dart`
  - `core/services/connectivity_monitor_service.dart`
- **Responsibilities**:
  - Track whether the device appears online/offline.
  - Provide a higher-level "is the backend ecosystem healthy?" status (Firebase, Drive, local storage checks).
  - Surface connectivity issues via global snackbars so all features benefit.

### Notifications & Workmanager

- **Key components**:
  - `NotificationService` — encapsulates `flutter_local_notifications` setup and APIs.
  - `ReminderNotifications` — reminder-specific scheduling helpers.
  - `workmanager_dispatcher.dart` — entry point that Workmanager calls in the background.
- **Lifecycle**:
  1. App starts → background services initialized → `NotificationService` configures channels and timezone.
  2. User creates/updates a reminder → `ReminderController` calls scheduling helpers.
  3. If OS kills the app or misses an alarm:
     - Workmanager job wakes periodically,
     - Rebuilds minimal read-only Hive context,
     - Checks for due reminders,
     - Fires `NotificationService.showNow` as a safety net.

### Storage & Google Drive

- **Local-first**:
  - All attachments are written to a deterministic local path (e.g. by feature and date).
  - Entities keep both a local path and optional Drive ID.
- **Drive sync**:
  - Uploads happen via a facade (`GoogleDriveService`) that hides Drive API details.
  - Authentication state is handled separately (`drive_auth_store.dart` and `google_drive_auth.dart`).
  - Failed uploads should never block core functionality; they only affect cloud availability.

## Feature deep dives

### Tasks — lifecycle, lists, and editor

- **User flow**:
  1. User opens Tasks screen (`tasks_screen.dart`), which subscribes to `TaskController`.
  2. User taps "Add" or edits an existing task → `TaskEditorDialog` (and related sheet widgets) opens.
  3. On save:
     - Controller validates input,
     - Writes to Hive via `TaskRepository`,
     - Marks entity as dirty and enqueues a sync operation,
     - Manages attachments via `AttachmentStorageService` (if any),
     - Notifies listeners so lists and analytics refresh.
- **Lists & grouping**:
  - Task lists are usually grouped by **status**, **due date bucket**, or **category/subcategory**.
  - Sectioning/grouping code lives in specialized widgets under `views/widgets/lists/` and `views/widgets/sections/`.
  - Controllers should expose **plain lists** (e.g. `List<Task>`); widgets are responsible for turning them into grouped visual sections.
- **Editor behavior** (high level):
  - Editor components (sheet/dialog) take a `TaskEditorResult` that encodes user choices.
  - They avoid direct writes; they coordinate with `TaskController` for actual saves/deletes.
  - This keeps business rules centralized and makes it easier to adjust validation or side effects.

### Reminders — scheduling pipeline details

- **Core responsibilities of `ReminderController`**:
  - Maintain the in-memory list of reminders.
  - Persist reminder entities to Hive.
  - Coordinate with `NotificationService` to:
    - Schedule one-time or repeating notifications.
    - Cancel notifications when reminders are changed or deleted.
  - Update in-app timer logic used while the app is open to ensure timely delivery.
- **Implementation notes**:
  - All scheduling functions should be **idempotent**: calling "schedule" twice for the same reminder should not result in duplicate notifications.
  - Timezone handling must be consistent—always convert to the user’s local timezone when scheduling.
  - Background dispatcher must stay minimal: initialize only what you need (Hive, timezones, notifications) to keep startup overhead low.

### Notes — editor, voice, and RTL

- **Rich text**:
  - Uses a Quill-style Delta JSON to store content, making it safe to evolve UI formatting over time.
  - The editor converts between Delta and the UI representation; note entities only know about the JSON string.
- **Voice embeddings**:
  - Voice note files are stored locally and referenced by `NoteAttachment`.
  - The editor and supporting services are responsible for:
    - Recording / picking audio,
    - Saving it to the correct folder,
    - Creating/updating the associated `NoteAttachment`,
    - Optionally triggering Drive upload.
- **RTL-aware text**:
  - `rtl_aware_text.dart` determines text direction based on content.
  - UI should use this widget where mixed Arabic/English notes might appear.

### Habits — logs & streak calculations

- **Data model**:
  - `Habit` defines the configuration (name, frequency, etc.).
  - `HabitLog` captures completions keyed by date.
- **Streak logic**:
  - Streak is **derived data**; never persisted.
  - Controllers compute streaks on the fly using logs, walking backwards from "today" until they hit a non-completed day.
  - This makes it easy to support retroactive edits of completions.

### Analytics — where data comes from

- Pulls aggregated stats from:
  - Tasks (completed vs pending, by category).
  - Habits (streak lengths, completion rates).
  - Potentially notes/reminders in the future.
- The analytics controller should:
  - Subscribe to core feature controllers (or repositories) rather than duplicating storage logic.
  - Cache expensive computations when possible and invalidate intelligently.

### Calendar — overlaying multiple sources

- The calendar controller:
  - Reads tasks’ due dates and reminders’ scheduled times.
  - Maps them into a unified day/time-slot model.
  - Optionally syncs with the device calendar (through `DeviceCalendarService`) if enabled by user.

## How to implement common changes

### Add a new field to an existing model (e.g., `Task`)

1. **Update the Hive model**:
   - Add the new field to the Dart class.
   - Assign a new, unused `@HiveField` index (never reuse old ones).
2. **Regenerate / update adapter**:
   - If using build_runner, regenerate; otherwise manually update the adapter.
3. **Migrate defaults**:
   - Decide what the default value should be when old data is read (e.g. `null`, `false`, or an enum case).
4. **Update repository and sync mapping**:
   - Ensure Firestore/JSON mapping includes the new field (with backward compatibility for missing keys).
5. **Wire into controllers**:
   - Extend controller state and methods (create/update) to handle the new field.
6. **Expose in UI**:
   - Update relevant screens/dialogs/sheets to display/edit the new field.
7. **Add tests**:
   - At least one test that:
     - Creates an entity with the new field,
     - Persists and reloads it,
     - Verifies the field survives round-trip and sync (if applicable).

### Add a new toggle/setting

1. Add the field to `SettingsController` and its persisted state (using Hive or SharedPreferences depending on where settings live).
2. Extend `settings_screen.dart` with a new row/section:
   - Read the current value via Provider.
   - Call `SettingsController.updateX` on change.
3. If the setting affects services (e.g. sync or notifications):
   - Inject `SettingsController` into those services (via Provider or constructor params).
   - Respect the toggle on startup and when it changes (listen to controller or re-evaluate on each operation).

### Add a new background job

1. Decide whether it’s:
   - **UI-bound** (only active while app is open) → Use a timer inside a controller/service.
   - **True background** (runs while app is closed) → Use Workmanager.
2. Implement a **small, testable core function** (no Flutter dependencies) that does the actual work.
3. Call that function from:
   - A controller/service for UI-bound jobs.
   - The Workmanager dispatcher for background jobs.
4. Log start/end + any notable outcomes using `DebugLoggerService`.

## Coding style & project conventions

- **Dart & Flutter style**:
  - Follow `dart format` defaults.
  - Prefer `final` for values that don’t change.
  - Avoid giant widgets—extract into smaller widgets when a build method exceeds ~150 lines or has multiple logical sections.
- **Naming**:
  - Controllers end with `Controller`.
  - Repositories end with `Repository`.
  - Widgets end with `...Screen`, `...Dialog`, `...Sheet`, or `...Tile` based on function.
- **File organization**:
  - Features live under `lib/features/<feature>/` with `models/`, `data/`, `repositories/`, `controllers/`, `views/`.
  - Shared/core code lives under `lib/core/` and `lib/app/`.
- **Null safety**:
  - Prefer non-nullable fields with sensible defaults where possible.
  - Use nullable fields only when a value is truly optional, and handle them explicitly in UI.

## Glossary (quick reference)

- **Hive**: Local key-value store used as the app’s primary source of truth.
- **SyncOperation**: A queued instruction describing what needs to be synchronized with Firestore.
- **Controller**: `ChangeNotifier`-based class that owns business logic and exposes state to the UI.
- **Repository**: Abstraction over data access (Hive, Firestore, Drive) for a given feature.
- **Service**: Cross-cutting infrastructure (notifications, connectivity, storage, debug logging, etc.).
- **Attachment**: Any non-text asset (image, audio, file) associated with a Task or Note.
- **Background service**: Long-lived object outside of widget tree that listens to system/app events and reacts (e.g. connectivity monitor).

## Per-feature walkthroughs (`lib/features/…`)

This section mirrors the `lib/features` folder and explains **what each feature does**, **how its pieces talk to each other**, and **how data flows through it**.

### `features/wrapper` — app shell & navigation

- **Purpose**: Provides the persistent shell around the whole app (drawer + bottom navigation).
- **Key files**:
  - `app_wrapper.dart`: Top-level `Scaffold` with `Drawer` and a body that hosts the current route from `go_router`.
  - `app_drawer.dart`: The side drawer with navigation items.
  - `nav_bar_wrappers/*.dart`: Abstractions around different nav bar visual styles.
  - `nav_bar_builder.dart` and `drawer_item.dart`: Small helpers to make the shell composable.
- **Data & communication flow**:
  - Does **not** own business data; it delegates to child routes.
  - Reads the current route from the router and displays the appropriate screen.
  - Routes deeper into feature screens where controllers provide actual state.

### `features/splash` — app initialization

- **Purpose**: Orchestrates app startup so the user sees a controlled Splash instead of a blank screen.
- **Key files**:
  - `controllers/app_initializer.dart`: Implements the two-phase initialization (`initializeCritical` then `completeInitialization`).
  - `controllers/provider_factory.dart`: Central place to create and wire controllers/providers.
  - `views/splash_wrapper.dart`: Hosts the Splash UI while initialization runs.
  - `views/splash_screen.dart`: Visual splash screen.
- **Data & communication flow**:
  - Startup sequence:
    1. `main.dart` calls `AppInitializer.initializeCritical()` before `runApp`.
    2. After the root widget tree is ready, `completeInitialization()` is called from the Splash layer using `ProviderFactory` to construct controllers and repositories.
    3. Once everything is initialized, navigation transitions to the main `Wrapper`/Dashboard route.
  - Any failure in critical initialization is treated as fatal; failures in non-critical init are surfaced via snackbars or debug logs.

### `features/dashboard` — daily summary

- **Purpose**: Aggregates information from tasks, reminders, habits, and analytics into a single home screen.
- **Key files**:
  - `views/dashboard_screen.dart`: Main widget that composes multiple dashboard cards.
  - Widgets: `daily_progress_card.dart`, `upcoming_task_card.dart`, `quick_reminder_card.dart`, `stat_card.dart`.
- **Data & communication flow**:
  - Reads from multiple controllers via Provider (e.g. `TaskController`, `ReminderController`, `HabitController`, `AnalyticsController`).
  - Each card performs **lightweight projection** of controller data (e.g. filter today’s tasks) but leaves core logic in controllers.
  - Dashboard never writes; it only triggers navigation (e.g. “See all tasks”) or opens editors.

### `features/tasks` — tasks domain

- **Purpose**: Owns everything related to tasks: models, categories, CRUD, lists, detail views, and attachment handling.
- **Key files**:
  - Controllers:
    - `task_controller.dart`: Main task business logic and list state.
    - `category_controller.dart`: Category and subcategory management.
    - `task_crud_mixin.dart`: Reusable CRUD helpers shared by controllers.
    - `attachment_helper.dart`: Helpers around task attachments and their life cycle.
  - Models / data:
    - `task.dart`, `task_attachment.dart`, `task_enums.dart`, `task_editor_result.dart`.
    - `task_local_datasource.dart`: Hive access for tasks.
    - `task_repository.dart`: High-level repository responsible for fetching/persisting with proper flags and sync queue updates.
    - `category.dart`, `category_sort_option.dart`, `task_sort_option.dart`.
  - Views:
    - `tasks_screen.dart`: Main list view for tasks.
    - `views/utils/*.dart`: Utilities for attachments, date formatting, etc.
    - `views/widgets/…`: All UI components (tiles, sections, drawers, editors).
- **Data & communication flow**:
  - `tasks_screen.dart` subscribes to `TaskController` and `CategoryController` via Provider.
  - User interactions (create/edit/delete, change status, move category) call into `TaskController` methods.
  - `TaskController` delegates:
    - Persistence to `TaskRepository` → `TaskLocalDataSource` → Hive.
    - Attachments to `AttachmentStorageService` (core service) via helpers.
    - Sync responsibilities (set `isDirty`, enqueue `SyncOperation`).
  - Views such as `grouped_task_list.dart` + section widgets transform `List<Task>` from the controller into grouped UI by due date, status, and category without touching Hive directly.

### `features/task_editor` — task editing UI

- **Purpose**: Provides a reusable, rich editing surface for tasks separate from the list.
- **Key files**:
  - `task_editor_sheet.dart`: High-level bottom sheet entry point for editing.
  - `widgets/*`: Modular pieces (header, inputs, selectors, chips, quick options).
- **Data & communication flow**:
  - Receives an existing `Task` (for edit) or null (for create) plus callbacks / `TaskController` reference.
  - Produces a `TaskEditorResult` describing the user’s choices.
  - Delegates actual persistence to `TaskController`; the editor itself never writes to Hive.

### `features/reminders` — reminders domain

- **Purpose**: Manages reminder entities and the link between reminder data and notification scheduling.
- **Key files**:
  - `models/reminder.dart`: Core reminder entity.
  - `controllers/reminder_controller.dart`: Business logic and in-memory list.
  - `views/reminders_screen.dart`: List and management UI.
- **Data & communication flow**:
  - `reminders_screen.dart` reads the list of reminders from `ReminderController`.
  - When a reminder is created/updated/deleted:
    - Controller persists to Hive (through its data layer),
    - Calls `NotificationService` / `ReminderNotifications` to schedule or cancel OS-level notifications,
    - Ensures any in-app timer logic is updated so callbacks fire correctly while app is open.
  - Background Workmanager jobs use core notification logic to catch missed reminders, sharing common code paths where possible.

### `features/notes` — rich notes domain

- **Purpose**: Rich text + embedded audio notes with optional sync and attachments.
- **Key files**:
  - `controllers/note_controller.dart`: In-memory list, filtering/search, CRUD.
  - `models/*.dart`: Note entities and attachments (including voice note references).
  - `views/notes_list_screen.dart`, `note_editor_screen.dart`: List and editor UIs.
  - `views/widgets/rtl_aware_text.dart`: Smart text direction helper.
- **Data & communication flow**:
  - User opens note list → `NoteController` loads notes from Hive via its data layer.
  - When creating/editing:
    - Editor converts the Quill-style Delta content to JSON (`contentDeltaJson`) and passes to controller.
    - Controller persists entity and updates any sync queue entries.
  - Voice notes:
    - `NoteEmbedService` coordinates recording/picking audio and storing files.
    - `NoteAttachment` tracks local paths and Drive IDs.

### `features/habits` — habits + streaks

- **Purpose**: Tracks recurring habits and daily completions.
- **Key files**:
  - `controllers/habit_controller.dart`: Core business logic and view state.
  - Models:
    - `habit.dart`, `habit_log.dart`: Main entities.
    - `habit_local_datasource.dart`, `habit_log_local_datasource.dart`: Hive access.
    - `habit_repository.dart`, `habit_log_repository.dart`: Repositories.
  - Views:
    - `habits_screen.dart`, `habit_details_screen.dart`, dialog widgets, tiles.
- **Data & communication flow**:
  - User marks a habit as done for a date → `HabitController` writes a `HabitLog` via repository.
  - Controller recomputes streaks and exposes them to the UI.
  - Analytics feature can read habit data (through controller or repository) to show progress charts.

### `features/analytics` — KPIs and charts

- **Purpose**: Visualizes KPIs around tasks and habits.
- **Key files**:
  - `controllers/analytics_controller.dart`: Central place to compute aggregates.
  - `utils/analytics_utils.dart`: Shared math/utility functions.
  - `views/analytics_screen.dart` and widget files (charts, legend, quick stats).
- **Data & communication flow**:
  - Analytics controller subscribes to / queries from Task and Habit controllers/repositories.
  - Computes:
    - Counts of pending vs completed tasks,
    - Habit completion rates,
    - Velocity or trend metrics as applicable.
  - Widgets bind to simple view models (e.g. `List<ChartSlice>`) rather than raw entities.

### `features/calendar` — calendar overlay

- **Purpose**: Consolidates time-based data (tasks with due dates + reminders) into a unified calendar view.
- **Key files**:
  - `controllers/calendar_controller.dart`: Maps domain entities into calendar events.
  - `views/calendar_screen.dart`: Calendar UI and interactions.
  - `views/widgets/calendar_event_tile.dart`: Event representation.
- **Data & communication flow**:
  - Controller reads from Task and Reminder data sources (or controllers) and produces a stream/list of calendar events.
  - Optionally syncs with device calendar via `DeviceCalendarService` when user enables it in Settings.
  - UI selects a date/time slot and triggers navigation to the related entity detail (task/reminder).

### `features/settings` — configuration & diagnostics

- **Purpose**: Central place for toggles (theme, sync, notifications, Drive, connectivity checks, etc.).
- **Key files** (see earlier section for more detail):
  - `controllers/settings_controller.dart` and related helpers/mixins.
  - `views/settings_screen.dart` and its `views/sections/*` widgets.
- **Data & communication flow**:
  - Settings controller persists configuration to local storage (Hive/SharedPreferences).
  - Other services/controllers read settings on startup or listen for changes to alter behavior (e.g. disabling sync, changing theme).

### `features/theme_customization` — theming UX

- **Purpose**: UX for choosing themes, colors, and nav bar styles.
- **Key files**:
  - `views/theme_customization_screen.dart`: Main entry point.
  - `views/widgets/colors/*`, `nav_bar_styles/*`, `presets/*`, `preview/*`: Smaller widgets and config structures.
- **Data & communication flow**:
  - Reads/writes via `ThemeService` and `SettingsController` (for persisted theme prefs).
  - Generates preview state that is applied to `AppTheme` before persisting.

### `features/sync` — sync UI

- **Purpose**: UI representation of sync state and conflict resolution.
- **Key files**:
  - `controllers/sync_controller.dart`: Tracks sync state (queue size, last sync time, current status).
  - `views/sync_status_widget.dart`: Icon/button that shows sync progress or problems.
  - `views/conflict_resolution_dialog.dart`: Dialog for resolving task-related conflicts.
- **Data & communication flow**:
  - `SyncController` subscribes to `SyncService` (core service) and to queue metadata stored in Hive.
  - When conflicts are detected, controller launches appropriate dialogs (tasks vs notes) and passes conflicting entities.
  - User choices are persisted through repositories and may generate additional sync operations.

## Per-service walkthroughs (`lib/core/services/…`)

This section covers infrastructure services and how they interact with features and each other.

### Connectivity services

- **`platform/connectivity_service.dart`**:
  - Thin wrapper around platform APIs (e.g. connectivity_plus).
  - Exposes a stream of connectivity changes and a way to query current status.
- **`platform/connectivity_status_service.dart`**:
  - Builds on `ConnectivityService` to perform **deeper health checks** (can we reach Firebase? is Drive authenticated? are Hive boxes open?).
  - Produces a richer status model consumed by Settings and debug UIs.
- **`connectivity_monitor_service.dart`**:
  - Background service that subscribes to connectivity streams and health checks.
  - Shows snackbars via `CommonSnackbar.showGlobal()` when connectivity status changes (e.g. “Offline mode”, “Back online”).  
  - Helps all features behave consistently in offline/online transitions.

### Debug logging services

- **Files**: `debug_logger_service.dart`, `debug_log_archiver.dart`, `debug_log_archiver_io.dart`, `debug_log_archiver_stub.dart`.
- **Responsibilities**:
  - Provide a central API for logging structured debug messages.
  - Keep an in-memory ring buffer (up to N entries) for the overlay.
  - Periodically archive logs to disk on supported platforms via the IO implementation.
  - Use a stub implementation on platforms where IO isn’t available.
- **Data & communication flow**:
  - Any part of the app can log via `DebugLoggerService` (injected where needed).
  - `GlobalDebugOverlay` reads from logger and archives to present logs to the user.

### Note embed service

- **`note_embed_service.dart`**:
  - Coordinates embedding of media (especially voice notes) into notes.
  - Provides a higher-level API so note UI doesn’t have to know about file system paths or Drive IDs.
  - Talks to `AttachmentStorageService` and Drive services when necessary.

### Notification services

- **`notifications/notification_service.dart`**:
  - Encapsulates `flutter_local_notifications` initialization and channel setup.
  - Provides methods for scheduling, updating, canceling, and showing notifications immediately.
- **`notifications/reminder_notifications.dart`**:
  - Reminder-specific helpers for building notification payloads and IDs.
  - Implements conventions like how notification IDs map to reminder IDs.
- **`notifications/workmanager_dispatcher.dart`**:
  - Entry function invoked by Workmanager in the background.
  - Initializes minimal app context (Hive, notification plugin, time zones) and executes the reminder catch-up logic.
- **Data & communication flow**:
  - UI → `ReminderController` → `NotificationService`/`ReminderNotifications` for scheduling.
  - System (Workmanager) → `workmanager_dispatcher.dart` → same notification paths for missed reminders.

### Platform services

- **`platform/device_calendar_service.dart`**:
  - Wraps platform calendar APIs with a simplified interface (create/read events, request permissions).
  - Used by Calendar feature and possibly Settings.
- **`platform/permission_service.dart`**:
  - Central authority for requesting/checking runtime permissions (notifications, calendar, storage, microphone, etc.).
  - Features should avoid calling platform permission APIs directly; go through this service.

### Storage & Google Drive services

- **`storage/attachment_storage_service.dart`**:
  - Defines the on-disk layout for attachments (by feature/entity).
  - Provides APIs for saving, reading, and deleting files.
- **`storage/google_drive_service.dart`**:
  - High-level facade for Drive operations: ensure folders exist, upload/download/list/delete files.
  - Hides the details of API clients, folder structure, and error handling.
- **Supporting files**:
  - `google_drive_api_client.dart`: Creates the authenticated HTTP client for Drive.
  - `google_drive_auth.dart`: Orchestrates sign-in, sign-out, and token refresh flows.
  - `drive_auth_store.dart`: Persists auth state locally (e.g. tokens, last sign-in).
  - `drive_auth_exception.dart`: Typed exception for “auth required” and related cases.
  - `google_drive_folders.dart`, `google_drive_files.dart`: Low-level helpers for specific Drive operations.
- **Data & communication flow**:
  - Feature controllers request uploads/downloads via `GoogleDriveService`.
  - `GoogleDriveService` checks auth state via `DriveAuthStore`; if missing/expired, it triggers `GoogleDriveAuth` to resolve.
  - On success, Drive file IDs are written back to entities stored in Hive (e.g. `TaskAttachment`, `NoteAttachment`), enabling future sync.

### Sync service

- **`sync/sync_service.dart`**:
  - The central engine that processes `SyncOperation` entries and coordinates Firestore interactions.
  - Steps for a typical sync:
    1. Read queued `SyncOperation`s from Hive.
    2. For each operation, map local entities to Firestore documents and push changes.
    3. Fetch remote changes since last sync timestamp.
    4. Apply remote changes to Hive, resolving conflicts or marking them for user resolution.
    5. Update sync metadata (last sync timestamp, queue size).
  - Exposes status updates for `SyncController` and may emit progress events for UI.
