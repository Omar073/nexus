# Nexus — Developer Contributor Guide

Nexus is an **offline-first** personal life management app (Tasks, Reminders, Notes, Habits, Calendar, Analytics) built with **Flutter**.

**Design principle:** Hive is the local source-of-truth. Every user action writes locally first and then syncs to the cloud when possible.

- **Platforms**: Android + Windows
- **UI language**: English-only
- **Arabic support**: user-entered content (Tasks/Notes) auto-renders RTL when text contains Arabic characters

This README is meant to onboard developer contributors quickly: how the repo is structured, how data flows, and where to implement changes.

If you’re looking for a **non-technical, end-user overview**, see `README_APP.md`.

## Getting started (step-by-step)

### 1) Install dependencies

```bash
flutter pub get; flutter gen-l10n
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

1) UI triggers an action on a controller (e.g., create task)\n2) Controller writes to **Hive** immediately (instant UX)\n3) Controller enqueues a **SyncOperation** (local queue)\n4) `SyncService` pushes queued ops to Firestore when online\n5) `SyncService` pulls remote changes and updates Hive\n6) Conflicts are surfaced via conflict dialogs (user chooses local vs remote)

### MVC + Provider

- **Models**: Hive-backed classes (plus Firestore JSON mapping)\n- **Controllers**: `ChangeNotifier` (business logic)\n- **Views**: screens/widgets\n- **Services**: cross-cutting infrastructure\n
Providers are initialized in `lib/main.dart` and injected app-wide.

### App services architecture

The app uses a **composer pattern** to manage widget wrappers and background services, avoiding deep widget nesting:

- **Widget wrappers**: Composed via `wrapWithAppServices()` in `lib/app/services/app_services_composer.dart`. These wrap the app UI (e.g., `GlobalDebugOverlay`).

- **Background services**: Singleton services that run independently of the widget tree. They are initialized in `App.initState()` via `initializeBackgroundServices()` and disposed in `App.dispose()` via `disposeBackgroundServices()`. Examples:
  - `ConnectivityMonitorService`: Monitors network connectivity and shows snackbars when connection changes
  - Future services can be added by extending the composer functions

- **Global ScaffoldMessenger**: `appMessengerKey` in `lib/app/app_globals.dart` allows services and other code to show snackbars without BuildContext. Use `CommonSnackbar.showGlobal()` for context-free snackbars.

**Data flow for background services:**

1) `App` widget (StatefulWidget) initializes in `initState`
2) After first frame, `initializeBackgroundServices(context)` is called
3) Services access Provider context to read dependencies (e.g., `ConnectivityService`)
4) Services subscribe to streams/events and use `appMessengerKey` to show UI updates
5) On app disposal, `disposeBackgroundServices()` cleans up all service subscriptions

## Repository map (where everything lives)

### App bootstrap / routing / UI shell

- `lib/main.dart`: Firebase init, Hive init, Provider wiring\n- `lib/app/app.dart`: `StatefulWidget` with `MaterialApp.router`, themes, localization delegates, service lifecycle management\n- `lib/app/app_globals.dart`: Global `ScaffoldMessengerKey` for context-free snackbars\n- `lib/app/services/app_services_composer.dart`: Composes widget wrappers and manages background service initialization/disposal\n- `lib/app/router/app_router.dart`: `go_router` routes (bottom-nav shell)\n- `lib/features/shell/views/app_shell.dart`: bottom navigation UI\n- `lib/app/theme/app_theme.dart`: Material 3 themes\n- `lib/l10n/`: English-only app strings (generated via `flutter gen-l10n`)\n

### Core data + infra

- `lib/core/data/hive_type_ids.dart`: stable Hive type IDs (never reuse)\n- `lib/core/data/hive_boxes.dart`: Hive box names\n- `lib/core/data/hive_bootstrap.dart`: adapter registration + box opening\n- `lib/core/data/sync_queue.dart`: sync operation queue model\n- `lib/core/data/sync_metadata.dart`: last successful sync timestamp\n

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

- `tasks/{taskId}`: task docs\n- `notes/{noteId}`: note docs\n

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

- Enable **Google Drive API**\n- Configure **OAuth consent screen**\n- Create **OAuth Client ID (Android)** matching `applicationId` in `android/app/build.gradle.kts`\n

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

### Key files

- Models: `lib/features/tasks/models/task.dart`, `task_attachment.dart`, `task_enums.dart`\n- Local storage: `lib/features/tasks/data/task_local_datasource.dart`\n- Repository: `lib/features/tasks/repositories/task_repository.dart`\n- Controller: `lib/features/tasks/controllers/task_controller.dart`\n- UI: `lib/features/tasks/views/tasks_screen.dart`\n

### How it works

- CRUD writes to Hive first.\n- Each write sets `isDirty=true` and enqueues a `SyncOperation(entityType: 'task')`.\n- Attachments (images/voice) are stored locally and best-effort uploaded to Drive.\n- A sync status icon in the Tasks app bar shows queue/sync/conflict state.\n

## Reminders

### Key files

- Models: `lib/features/reminders/models/reminder.dart`\n- Controller: `lib/features/reminders/controllers/reminder_controller.dart`\n- UI: `lib/features/reminders/views/reminders_screen.dart`\n- Notification scheduling: `lib/core/services/notifications/notification_service.dart`\n

### How it works

- Creating/updating schedules a local notification.\n- Completing/deleting cancels the scheduled notification.\n

## Sync + conflict handling

### Key files

- Queue model: `lib/core/data/sync_queue.dart`\n- Sync engine: `lib/core/services/sync/sync_service.dart`\n- UI state: `lib/features/sync/controllers/sync_controller.dart`\n- Sync icon: `lib/features/sync/views/sync_status_widget.dart`\n- Task conflicts: `lib/features/sync/views/conflict_resolution_dialog.dart`\n- Note conflicts: `lib/features/notes/views/note_conflict_resolution_dialog.dart`\n

### How it works

- Controllers enqueue `SyncOperation` entries.\n- `SyncService` pushes ops to Firestore, then pulls changes since last sync.\n- Conflicts occur when local is dirty and remote updated after local last sync.\n- User resolves by choosing **Keep Local** or **Keep Remote**.\n

## Notes (Rich text + inline voice notes)

### Key files

- Models: `lib/features/notes/models/note.dart`, `note_attachment.dart`\n- Controller: `lib/features/notes/controllers/note_controller.dart`\n- UI: `lib/features/notes/views/notes_list_screen.dart`, `note_editor_screen.dart`\n- RTL helper: `lib/features/notes/views/widgets/rtl_aware_text.dart`\n- Voice helper: `lib/core/services/note_embed_service.dart`\n

### Storage format

- `Note.contentDeltaJson` stores Quill Delta JSON as a String.\n- Voice notes are stored as `NoteAttachment` entries referencing local file paths (and Drive ids when uploaded).\n

## Habits

### Key files

- Models: `lib/features/habits/models/habit.dart`, `habit_log.dart`\n- Controller: `lib/features/habits/controllers/habit_controller.dart`\n- UI: `lib/features/habits/views/habits_screen.dart`, `habit_details_screen.dart`\n

### How streaks work

- Each completion is a `HabitLog` keyed by local `YYYY-MM-DD`.\n- Streak is computed by counting consecutive completed days back from today.\n

## Analytics

### Key files

- Controller: `lib/features/analytics/controllers/analytics_controller.dart`\n- UI: `lib/features/analytics/views/analytics_screen.dart`\n
Provides basic KPIs and a simple pie chart.\n

## Calendar

### Key files

- Controller: `lib/features/calendar/controllers/calendar_controller.dart`\n- UI: `lib/features/calendar/views/calendar_screen.dart`\n- Device calendar wrapper: `lib/core/services/device_calendar_service.dart`\n
Calendar overlays tasks (due dates) and reminders (scheduled times).\n

## Settings

### Key files

- Controller: `lib/features/settings/controllers/settings_controller.dart`\n- UI: `lib/features/settings/views/settings_screen.dart`\n
Includes theme mode, retention, sync status, Drive sign-in/out, connectivity status checks (Firebase, Hive, Google Drive), and permissions.\n

## Testing + CI

### Tests

Tests live in `test/` and can be run with:

```bash
flutter test
```

### CI

GitHub Actions workflow is at `.github/workflows/flutter.yml`:\n- `flutter pub get; flutter analyze; flutter test`\n

## Contributor workflow

### Adding a new feature module (recommended approach)

1) Add models to `lib/features/<feature>/models/` (with Hive adapter)\n2) Add datasources/repositories in `data/` and `repositories/`\n3) Add controller in `controllers/` (`ChangeNotifier`)\n4) Add views in `views/`\n5) Register adapters/open boxes in `lib/core/data/hive_bootstrap.dart`\n6) Wire routes in `lib/app/router/app_router.dart`\n7) Add/extend tests in `test/`\n

### Project command conventions

```bash
flutter pub get; flutter gen-l10n; flutter analyze; flutter test
flutter build apk; flutter build windows
```
