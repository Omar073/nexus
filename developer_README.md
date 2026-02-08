# Nexus — Developer Contributor Guide

Nexus is an **offline-first** personal life management app (Tasks, Reminders, Notes, Habits, Calendar, Analytics) built with **Flutter**.

**Design principle:** Hive is the local source-of-truth. Every user action writes locally first and then syncs to the cloud when possible.

- **Platforms**: Android + Windows
- **UI language**: English-only (hardcoded strings)
- **Arabic support**: user-entered content (Tasks/Notes) auto-renders RTL when text contains Arabic characters

This README is meant to onboard developer contributors quickly: how the repo is structured, how data flows, and where to implement changes.

If you're looking for a **non-technical, end-user overview**, see `README.md`.

## Table of contents

- [Getting started (step-by-step)](#getting-started-step-by-step)
- [High-level architecture](#high-level-architecture)
- [Repository map (where-everything-lives)](#repository-map-where-everything-lives)
- [App Shell & Navigation](#app-shell--navigation-libfeatureswrapper)
- [Dashboard](#dashboard-libfeaturesdashboard)
- [Firebase (Firestore sync)](#firebase-firestore-sync--setup--layout)
- [Google Drive (attachments)](#google-drive-attachments--setup)
- [Secret debug logs](#secret-debug-logs-production-only--android--windows)
- [Feature-by-feature guide](#feature-by-feature-guide)
  - [Tasks](#tasks)
  - [Reminders](#reminders)
  - [Sync + conflict handling](#sync--conflict-handling)
  - [Notes](#notes-rich-text--inline-voice-notes)
  - [Habits](#habits)
  - [Analytics](#analytics)
  - [Calendar](#calendar)
  - [Settings](#settings)
  - [Theme Customization](#theme-customization-libfeaturestheme_customization)
- [Testing + CI](#testing--ci)
- [Contributor workflow](#contributor-workflow)
- [Localization (Removed)](#localization-removed)
- [Deep architecture & implementation guide](#deep-architecture--implementation-guide)
  - [Background services deep dive](#background-services-deep-dive)
  - [Feature deep dives](#feature-deep-dives)
  - [How to implement common changes](#how-to-implement-common-changes)
  - [Coding style & project conventions](#coding-style--project-conventions)
  - [Glossary](#glossary-quick-reference)
- [Per-feature walkthroughs](#per-feature-walkthroughs-libfeatures)
- [Per-service walkthroughs](#per-service-walkthroughs-libcoreservices)

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

**Local-first write pattern (controller → repo → Hive) (simplified):**

- **Controller layer**: orchestrates user intent and business rules. It validates input, decides *what* should happen (e.g. “create a task and mark it dirty”), calls the repository, and then updates in-memory state and calls `notifyListeners()` so the UI rebuilds. *("Dirty" means the entity has local changes that haven't been synced to the cloud yet—it flags records for the sync queue.)*
- **Repository layer**: acts as a **gateway/abstraction layer** that encapsulates *how* data is stored and fetched. The controller calls simple methods like `upsert` *(insert-or-update: creates a new record if it doesn't exist, or updates it if it does)*, `getAll`, `delete` without knowing whether the data is going to Hive, Firestore, or any other backend. This separation means:
  - **Controller stays focused on business logic**: it decides *what* should happen (e.g., "save this task and mark it dirty") but never deals with Hive box operations, Firestore document writes, or JSON serialization.
  - **Repository handles all storage details**: it knows how to talk to `TaskLocalDatasource` (for Hive) or format data for Firestore sync. It also handles the mapping between Dart models and raw storage formats (Hive objects, JSON, etc.).
  - **Easy to swap or extend**: if you ever need to change how data is stored (e.g., switch databases or add caching), you only modify the repository—controllers remain untouched.
- **Hive**: the on-device database and **source of truth**. Repositories ultimately read/write Hive boxes so all controllers and services see a consistent local state, even while offline.

```dart
// Shape only — method names/types may differ in this project.
Future<void> createTask(Task draft) async {
  // 1) Create a copy with isDirty=true
  final taskToSave = draft.copyWith(isDirty: true);

  // 2) Save to Hive (local source of truth)
  final saved = await _taskRepository.upsert(taskToSave);

  // 3) Enqueue sync operation for background service
  await _syncQueue.enqueue(SyncOperation(
    entityType: 'task', 
    entityId: saved.id
  ));

  // 4) Update UI
  notifyListeners();
}
```

**Why this specific pattern?**

1. **`draft.copyWith(isDirty: true)`**
    - **Immutability**: Models are immutable (Hive/Freezed pattern), so we can't just set `draft.isDirty = true`. We must create a new instance. See [Why Immutable Models?](#why-immutable-models) for details.
    - **Separation of Concerns**: The UI provides the data (title, etc.), but the *Controller* is responsible for marking it as "dirty" (unsynced) before saving.

2. **`SyncOperation` vs. Enqueuing the Task object**
    - **Decoupling**: The background sync service only needs the `ID` and `Type` to know *what* to sync.
    - **Freshness**: When the sync runs later (e.g. when network is restored), it fetches the **latest** version from Hive. If we queued the `draft` object itself, it might be stale by the time the upload happens.

### MVC + Provider

- **Models**: Hive-backed classes (plus Firestore JSON mapping)
- **Controllers**: `ChangeNotifier` (business logic)
- **Views**: screens/widgets
- **Services**: cross-cutting infrastructure

Providers are initialized in [`lib/main.dart`](lib/main.dart) and injected app-wide.

**Typical Provider wiring (simplified):**

```dart
// Shape only — exact providers may differ.
runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => TaskController(/* deps */)),
      ChangeNotifierProvider(create: (_) => ReminderController(/* deps */)),
    ],
    child: const App(),
  ),
);
```

### App services architecture

The app uses a **composer pattern** to manage widget wrappers and background services. This pattern centralizes all cross-cutting concerns in one place instead of scattering them across the widget tree.

**Why use a composer pattern?**

Without a composer, you'd end up with deeply nested wrappers:

```dart
// ❌ Without composer — deeply nested, hard to manage
runApp(
  GlobalDebugOverlay(
    child: ConnectivityBanner(
      child: ThemeWrapper(
        child: App(),
      ),
    ),
  ),
);
```

With the composer, it's clean and maintainable:

```dart
// ✅ With composer — flat, easy to extend
// Used inside MaterialApp.router's builder callback:
MaterialApp.router(
  builder: (context, child) {
    return wrapWithOverlays(context, child ?? const SizedBox.shrink());
  },
);
```

**`wrapWithOverlays` parameters:**

| Parameter | Type | Purpose |
|-----------|------|---------|
| `context` | `BuildContext` | Needed so wrappers can access Provider, Theme, MediaQuery, etc. |
| `child` | `Widget` | The root widget to wrap (typically the router's child from `MaterialApp.router`). |

**How it works:**

- **Widget wrappers**: Composed via `wrapWithOverlays()` in [`lib/app/services/app_services_composer.dart`](lib/app/services/app_services_composer.dart). This function takes the root widget and wraps it with all necessary UI overlays (e.g., `GlobalDebugOverlay`). To add a new wrapper, you simply add it inside `wrapWithOverlays()` — no need to touch `main.dart` or other files.

> [!NOTE]
> **"Why does it only wrap with `GlobalDebugOverlay`?"**
>
> Currently, `GlobalDebugOverlay` is the only widget wrapper we need. However, the function is designed as an **extensibility point**. As the app grows, you might need more wrappers (e.g., `BannerOverlay`, `FeatureFlagWrapper`, `A/BTestingWrapper`). Instead of adding nested wrappers scattered across `main.dart` or `app.dart`, you add them in one place:
>
> ```dart
> Widget wrapWithOverlays(BuildContext context, Widget child) {
>   child = GlobalDebugOverlay(child: child);
>   child = FeatureFlagWrapper(child: child);  // Future wrapper
>   child = BannerOverlay(child: child);       // Future wrapper
>   return child;
> }
> ```

- **Background services**: Singleton services that run independently of the widget tree. They are initialized in `App.initState()` via `initializeBackgroundServices()` and disposed in `App.dispose()` via `disposeBackgroundServices()`.

#### How background services work

Background services are **singletons** — they exist as a single instance for the entire app lifecycle. They don't rebuild when the widget tree changes, making them ideal for continuous monitoring tasks.

**The pattern:**

```dart
// 1. Singleton pattern — one instance, always accessible
class ConnectivityMonitorService {
  static final _instance = ConnectivityMonitorService._internal();
  factory ConnectivityMonitorService() => _instance;
  ConnectivityMonitorService._internal();

  StreamSubscription<bool>? _subscription;

  // 2. Start listening to a stream (e.g., connectivity changes)
  void startMonitoring(ConnectivityService connectivityService) {
    _subscription = connectivityService.onlineStream().listen((isOnline) {
      // 3. React to changes — show UI feedback via global key
      _showSnackbar(isOnline ? 'Online' : 'Offline');
    });
  }

  void _showSnackbar(String message) {
    // 4. Access UI without BuildContext using global key
    appMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void dispose() => _subscription?.cancel();
}
```

**Understanding the singleton pattern:**

```dart
static final _instance = ConnectivityMonitorService._internal();
factory ConnectivityMonitorService() => _instance;
ConnectivityMonitorService._internal();  // ← What is this?
```

- `_internal()` is a **named constructor** marked private (underscore prefix).
- By making the real constructor private, we prevent external code from calling `ConnectivityMonitorService._internal()` directly.
- The `factory` constructor always returns `_instance` — the same single instance every time.
- **Result**: `ConnectivityMonitorService()` anywhere in the app returns the exact same object.

**How `onlineStream()` provides connectivity data:**

The data flows from the device → `connectivity_plus` package → `ConnectivityService` → `ConnectivityMonitorService`:

```dart
// lib/core/services/platform/connectivity_service.dart
class ConnectivityService {
  final Connectivity _connectivity;  // From connectivity_plus package

  // Async generator that yields bool values
  Stream<bool> onlineStream() async* {
    yield await isOnline;  // 1. Emit initial state immediately
    await for (final result in onChanged) {  // 2. Then listen for changes
      yield !result.contains(ConnectivityResult.none) && result.isNotEmpty;
    }
  }

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}
```

| Step | What happens |
|------|--------------|
| 1. `yield await isOnline` | Immediately emits current connectivity state (true/false) |
| 2. `await for (... in onChanged)` | Listens to the platform's connectivity change stream |
| 3. `yield !result.contains(...)` | Converts `List<ConnectivityResult>` to simple `bool` |

**Data flow diagram:**

```text
Device/OS → connectivity_plus → ConnectivityService.onlineStream() → bool stream
                                         ↓
                        ConnectivityMonitorService.startMonitoring()
                                         ↓
                                 _showSnackbar() via global key
```

**Why this works:**

| Concept | Purpose |
|---------|---------|
| **Singleton** | Single instance lives for the entire app, unaffected by widget rebuilds |
| **Stream subscription** | Listens for changes continuously in the background |
| **Global key** | `appMessengerKey` provides access to `ScaffoldMessengerState` without `BuildContext` |

**Lifecycle:**

1. `App.initState()` → calls `initializeBackgroundServices(context)` → starts monitoring
2. Service receives stream events → reacts (e.g., shows snackbar via global key)
3. `App.dispose()` → calls `disposeBackgroundServices()` → cancels subscriptions

- **Global ScaffoldMessenger**: `appMessengerKey` in [`lib/app/app_globals.dart`](lib/app/app_globals.dart) allows services and other code to show snackbars without BuildContext. Use `CommonSnackbar.showGlobal()` for context-free snackbars.

### App Initialization Flow ([`lib/features/splash/`](lib/features/splash/))

The app startup is managed by `AppInitializer` ([`lib/features/splash/controllers/app_initializer.dart`](lib/features/splash/controllers/app_initializer.dart)) in two phases:

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

- [`lib/main.dart`](lib/main.dart): Firebase init, Hive init, Provider wiring
- [`lib/app/app.dart`](lib/app/app.dart): `StatefulWidget` with `MaterialApp.router`, themes
- [`lib/app/app_globals.dart`](lib/app/app_globals.dart): Global `ScaffoldMessengerKey` for context-free snackbars
- [`lib/app/services/app_services_composer.dart`](lib/app/services/app_services_composer.dart): Composes widget wrappers and manages background service initialization/disposal
- [`lib/app/router/app_router.dart`](lib/app/router/app_router.dart): `go_router` routes (bottom-nav shell)
- [`lib/features/wrapper/views/app_wrapper.dart`](lib/features/wrapper/views/app_wrapper.dart): App shell with drawer and bottom navigation
- [`lib/features/wrapper/views/app_drawer.dart`](lib/features/wrapper/views/app_drawer.dart): Navigation drawer
- [`lib/app/theme/app_theme.dart`](lib/app/theme/app_theme.dart): Material 3 themes

### Core data + infra

- [`lib/core/data/hive_type_ids.dart`](lib/core/data/hive_type_ids.dart): stable Hive type IDs (never reuse)
- [`lib/core/data/hive_boxes.dart`](lib/core/data/hive_boxes.dart): Hive box names
- [`lib/core/data/hive_bootstrap.dart`](lib/core/data/hive_bootstrap.dart): adapter registration + box opening
- [`lib/core/data/sync_queue.dart`](lib/core/data/sync_queue.dart): sync operation queue model
- [`lib/core/data/sync_metadata.dart`](lib/core/data/sync_metadata.dart): last successful sync timestamp

Core services were reorganized into subfolders under [`lib/core/services/`](lib/core/services/):

- **Platform**:
  - [`lib/core/services/platform/connectivity_service.dart`](lib/core/services/platform/connectivity_service.dart): online/offline detection
  - [`lib/core/services/platform/connectivity_status_service.dart`](lib/core/services/platform/connectivity_status_service.dart): connectivity status checks (Firebase, Hive, Google Drive)
  - [`lib/core/services/platform/permission_service.dart`](lib/core/services/platform/permission_service.dart): runtime permissions
  - [`lib/core/services/platform/device_calendar_service.dart`](lib/core/services/platform/device_calendar_service.dart): device calendar wrapper
- **Sync**:
  - [`lib/core/services/sync/sync_service.dart`](lib/core/services/sync/sync_service.dart): sync engine (push/pull + conflict detection)
- **Notifications**:
  - [`lib/core/services/notifications/notification_service.dart`](lib/core/services/notifications/notification_service.dart): local notifications
  - [`lib/core/services/notifications/workmanager_dispatcher.dart`](lib/core/services/notifications/workmanager_dispatcher.dart): Android background dispatcher
  - [`lib/core/services/notifications/reminder_notifications.dart`](lib/core/services/notifications/reminder_notifications.dart): notifications interface
- **Storage**:
  - [`lib/core/services/storage/attachment_storage_service.dart`](lib/core/services/storage/attachment_storage_service.dart): local file storage layout
  - [`lib/core/services/storage/google_drive_service.dart`](lib/core/services/storage/google_drive_service.dart): **facade** for Drive operations
  - [`lib/core/services/storage/google_drive_auth.dart`](lib/core/services/storage/google_drive_auth.dart): password gate + Google Sign-In
  - [`lib/core/services/storage/google_drive_api_client.dart`](lib/core/services/storage/google_drive_api_client.dart): Drive API client creation
  - [`lib/core/services/storage/google_drive_folders.dart`](lib/core/services/storage/google_drive_folders.dart): folder management
  - [`lib/core/services/storage/google_drive_files.dart`](lib/core/services/storage/google_drive_files.dart): upload/list/download/delete
  - [`lib/core/services/storage/drive_auth_store.dart`](lib/core/services/storage/drive_auth_store.dart): device auth state (SharedPreferences)
  - [`lib/core/services/storage/drive_auth_exception.dart`](lib/core/services/storage/drive_auth_exception.dart): `DriveAuthRequiredException`
- **Background Services**:
  - [`lib/core/services/connectivity_monitor_service.dart`](lib/core/services/connectivity_monitor_service.dart): singleton service that monitors network connectivity and shows snackbars on connection changes (runs independently of widget tree)

### Core widgets

- [`lib/core/widgets/common_snackbar.dart`](lib/core/widgets/common_snackbar.dart): reusable snackbar utility with `show()` (BuildContext-based) and `showGlobal()` (context-free) methods
- [`lib/core/widgets/debug/global_debug_overlay.dart`](lib/core/widgets/debug/global_debug_overlay.dart): hidden overlay UI for production debug logs (triple-tap / Ctrl+Shift+D)

### Production debug logs (Android + Windows)

- [`lib/core/services/debug/debug_logger_service.dart`](lib/core/services/debug/debug_logger_service.dart): in-memory logs (max 500) + 30-min archive
- [`lib/core/services/debug/debug_log_archiver_io.dart`](lib/core/services/debug/debug_log_archiver_io.dart): writes archive to app documents dir (Android/Windows)
- [`lib/core/widgets/debug/global_debug_overlay.dart`](lib/core/widgets/debug/global_debug_overlay.dart): hidden overlay UI (triple-tap / Ctrl+Shift+D)

## App Shell & Navigation ([`lib/features/wrapper/`](lib/features/wrapper/))

The `Wrapper` feature manages the persistent UI shell that surrounds the entire app.

**Key files**:

- [`lib/features/wrapper/views/app_wrapper.dart`](lib/features/wrapper/views/app_wrapper.dart): Main Scaffold containing the `ScaffoldKey` for drawer control.
- [`lib/features/wrapper/views/app_drawer.dart`](lib/features/wrapper/views/app_drawer.dart): The side navigation drawer accessible globally.
- [`lib/features/dashboard/views/dashboard_screen.dart`](lib/features/dashboard/views/dashboard_screen.dart): The home screen aggregator.

## Dashboard ([`lib/features/dashboard/`](lib/features/dashboard/))

The Dashboard acts as an aggregator view, pulling data from multiple controllers to show a daily summary.

**Key files**:

- [`lib/features/dashboard/views/dashboard_screen.dart`](lib/features/dashboard/views/dashboard_screen.dart)
- Widgets (organized under [`lib/features/dashboard/views/widgets/`](lib/features/dashboard/views/widgets/)):
  - [`lib/features/dashboard/views/widgets/dashboard_habits_section.dart`](lib/features/dashboard/views/widgets/dashboard_habits_section.dart): Habits summary row.
  - [`lib/features/dashboard/views/widgets/dashboard_reminders_section.dart`](lib/features/dashboard/views/widgets/dashboard_reminders_section.dart): Reminders grid.
  - [`lib/features/dashboard/views/widgets/dashboard_tasks_section.dart`](lib/features/dashboard/views/widgets/dashboard_tasks_section.dart): Upcoming tasks list.

**How it works**:
It listens to `TaskController`, `ReminderController`, `NoteController`, and `HabitController` to display:

- Today's pending tasks
- Upcoming reminders
- Quick access buttons
- Recent activity stats

## Firebase (Firestore sync) — setup + layout

Firebase bootstrap exists in [`lib/firebase_setup/firebase_options.dart`](lib/firebase_setup/firebase_options.dart) and is initialized in [`lib/main.dart`](lib/main.dart).

### Firebase API keys (kept out of Git)

Firebase API keys/App IDs are stored using a template + git-ignore pattern:

- **Template** (committed): [`lib/firebase_setup/apiKeys.dart.example`](lib/firebase_setup/apiKeys.dart.example)
- **Local secrets** (git-ignored): [`lib/firebase_setup/apiKeys.dart`](lib/firebase_setup/apiKeys.dart)
- **Firebase options** (committed): [`lib/firebase_setup/firebase_options.dart`](lib/firebase_setup/firebase_options.dart) (imports `apiKeys.dart`)

Setup for new contributors:

```bash
Copy-Item lib/firebase_setup/apiKeys.dart.example lib/firebase_setup/apiKeys.dart
```

Then fill in real values in [`lib/firebase_setup/apiKeys.dart`](lib/firebase_setup/apiKeys.dart). Confirm it is ignored:

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

Drive integration code lives in [`lib/core/services/storage/`](lib/core/services/storage/) (see repo map above).

## Secret debug logs (production-only) — Android + Windows

This feature is intentionally hidden and only active in **non-debug builds** (`kDebugMode == false`).

### Why it's disabled in debug mode

When running `flutter run` (debug mode), you have full access to DevTools and console output, so the overlay is unnecessary. The overlay is designed for diagnosing issues in **profile** or **release** builds where console access isn't available.

### How to access the debug overlay

#### Option 1: Run in profile mode

```bash
flutter run --profile -d <device_id>
```

Profile mode enables the overlay while still providing reasonable performance for testing.

#### Option 2: Enable in debug mode (for development)

If you need the overlay during debug mode, remove the `kDebugMode` checks in [`lib/core/widgets/debug/global_debug_overlay.dart`](lib/core/widgets/debug/global_debug_overlay.dart):

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

- Models: [`lib/features/tasks/models/task.dart`](lib/features/tasks/models/task.dart), `task_attachment.dart`, `task_enums.dart`, `task_editor_result.dart`
- Local storage: [`lib/features/tasks/models/task_local_datasource.dart`](lib/features/tasks/models/task_local_datasource.dart)
- Repository: [`lib/features/tasks/models/task_repository.dart`](lib/features/tasks/models/task_repository.dart)
- Controller: [`lib/features/tasks/controllers/task_controller.dart`](lib/features/tasks/controllers/task_controller.dart)
- UI: [`lib/features/tasks/views/tasks_screen.dart`](lib/features/tasks/views/tasks_screen.dart)
- Widgets:
  - [`lib/features/tasks/views/widgets/task_tile.dart`](lib/features/tasks/views/widgets/task_tile.dart)
  - [`lib/features/tasks/views/widgets/task_search_bar.dart`](lib/features/tasks/views/widgets/task_search_bar.dart)
  - [`lib/features/tasks/views/widgets/task_filter_sheet.dart`](lib/features/tasks/views/widgets/task_filter_sheet.dart)
  - [`lib/features/tasks/views/widgets/task_editor_dialog.dart`](lib/features/tasks/views/widgets/task_editor_dialog.dart): **Main Task Editor**. Handles creation and editing logic, differentiating it from the list view.
- Helpers:
  - [`lib/features/tasks/views/widgets/helpers/category_scroll_helper.dart`](lib/features/tasks/views/widgets/helpers/category_scroll_helper.dart): Manages scroll-to-category navigation logic.
- [`lib/features/tasks/views/task_detail_sheet/`](lib/features/tasks/views/task_detail_sheet/): Modular components for the task detail bottom sheet (e.g., specific rows for priority, due date).
- [`lib/features/tasks/views/utils/attachment_picker_utils.dart`](lib/features/tasks/views/utils/attachment_picker_utils.dart): Helper for picking files/images.

### How Tasks work

- CRUD writes to Hive first.
- Each write sets `isDirty=true` and enqueues a `SyncOperation(entityType: 'task')`.
- Attachments (images/voice) are stored locally and best-effort uploaded to Drive.
- A sync status icon in the Tasks app bar shows queue/sync/conflict state.

## Reminders

### Reminders Architecture

**Key files:**

- Models: [`lib/features/reminders/models/reminder.dart`](lib/features/reminders/models/reminder.dart)
- Controller: [`lib/features/reminders/controllers/reminder_controller.dart`](lib/features/reminders/controllers/reminder_controller.dart)
- UI: [`lib/features/reminders/views/reminders_screen.dart`](lib/features/reminders/views/reminders_screen.dart)
- Notification scheduling: [`lib/core/services/notifications/notification_service.dart`](lib/core/services/notifications/notification_service.dart)

### How Reminders work

- Creating/updating schedules a local notification.
- Completing/deleting cancels the scheduled notification.

**Scheduling a reminder notification (typical shape):**

```dart
await notificationService.scheduleReminder(
  reminderId: reminder.id,
  title: reminder.title,
  scheduledAt: reminder.scheduledAtLocal,
);
```

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

**Workmanager dispatcher entry (high-level skeleton):**

```dart
// lib/core/services/notifications/workmanager_dispatcher.dart (shape only)
@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // 1) Minimal bootstrap (Hive adapters/boxes, timezone, notifications)
    // 2) Read due reminders (read-only)
    // 3) notificationService.showNow(...)
    return Future.value(true);
  });
}
```

## Sync + conflict handling

### Sync Architecture

**Key files:**

- Queue model: [`lib/core/data/sync_queue.dart`](lib/core/data/sync_queue.dart)
- Sync engine: [`lib/core/services/sync/sync_service.dart`](lib/core/services/sync/sync_service.dart)
- UI state: [`lib/features/sync/controllers/sync_controller.dart`](lib/features/sync/controllers/sync_controller.dart)
- Sync icon: [`lib/features/sync/views/sync_status_widget.dart`](lib/features/sync/views/sync_status_widget.dart)
- Task conflicts: [`lib/features/sync/views/conflict_resolution_dialog.dart`](lib/features/sync/views/conflict_resolution_dialog.dart)
- Note conflicts: [`lib/features/notes/views/note_conflict_resolution_dialog.dart`](lib/features/notes/views/note_conflict_resolution_dialog.dart)

### How Sync works

- Controllers enqueue `SyncOperation` entries.
- `SyncService` pushes ops to Firestore, then pulls changes since last sync.
- Conflicts occur when local is dirty and remote updated after local last sync.
- User resolves by choosing **Keep Local** or **Keep Remote**.

**Enqueueing a sync operation (typical shape):**

```dart
await syncQueue.enqueue(
  SyncOperation(
    entityType: 'task',
    entityId: task.id,
    operation: SyncOperationType.upsert,
    createdAt: DateTime.now(),
  ),
);
```

## Notes (Rich text + inline voice notes)

### Notes Architecture

**Key files:**

- Models: [`lib/features/notes/models/note.dart`](lib/features/notes/models/note.dart), `note_attachment.dart`
- Controller: [`lib/features/notes/controllers/note_controller.dart`](lib/features/notes/controllers/note_controller.dart)
- UI: [`lib/features/notes/views/notes_list_screen.dart`](lib/features/notes/views/notes_list_screen.dart), `note_editor_screen.dart`
- RTL helper: [`lib/features/notes/views/widgets/rtl_aware_text.dart`](lib/features/notes/views/widgets/rtl_aware_text.dart)
- Voice helper: [`lib/core/services/note_embed_service.dart`](lib/core/services/note_embed_service.dart)

### Storage format

- `Note.contentDeltaJson` stores Quill Delta JSON as a String.
- Voice notes are stored as `NoteAttachment` entries referencing local file paths (and Drive ids when uploaded).

## Habits

### Habits Architecture

**Key files:**

- Models: [`lib/features/habits/models/habit.dart`](lib/features/habits/models/habit.dart), `habit_log.dart`
- Controller: [`lib/features/habits/controllers/habit_controller.dart`](lib/features/habits/controllers/habit_controller.dart)
- UI: [`lib/features/habits/views/habits_screen.dart`](lib/features/habits/views/habits_screen.dart), `habit_details_screen.dart`
- Widgets:
  - [`lib/features/habits/views/widgets/habit_card.dart`](lib/features/habits/views/widgets/habit_card.dart): Styled habit card with keyword-based icon/color mapping.

### How streaks work

- Each completion is a `HabitLog` keyed by local `YYYY-MM-DD`.
- Streak is computed by counting consecutive completed days back from today.

## Analytics

### Analytics Architecture

**Key files:**

- Controller: [`lib/features/analytics/controllers/analytics_controller.dart`](lib/features/analytics/controllers/analytics_controller.dart)
- UI: [`lib/features/analytics/views/analytics_screen.dart`](lib/features/analytics/views/analytics_screen.dart)
- Utils: [`lib/features/analytics/utils/analytics_utils.dart`](lib/features/analytics/utils/analytics_utils.dart)
- Widgets:
  - [`lib/features/analytics/views/widgets/tasks_pie_chart.dart`](lib/features/analytics/views/widgets/tasks_pie_chart.dart)
  - [`lib/features/analytics/views/widgets/habits_progress_circle.dart`](lib/features/analytics/views/widgets/habits_progress_circle.dart)
  - [`lib/features/analytics/views/widgets/legend_item.dart`](lib/features/analytics/views/widgets/legend_item.dart)
  - [`lib/features/analytics/views/widgets/quick_stat_tile.dart`](lib/features/analytics/views/widgets/quick_stat_tile.dart)

Provides basic KPIs and a simple pie chart.

## Calendar

### Calendar Architecture

**Key files:**

- Controller: [`lib/features/calendar/controllers/calendar_controller.dart`](lib/features/calendar/controllers/calendar_controller.dart)
- UI: [`lib/features/calendar/views/calendar_screen.dart`](lib/features/calendar/views/calendar_screen.dart)
- Device calendar wrapper: [`lib/core/services/platform/device_calendar_service.dart`](lib/core/services/platform/device_calendar_service.dart)

Calendar overlays tasks (due dates) and reminders (scheduled times).

## Settings

### Settings Architecture

**Key files:**

- Controller: [`lib/features/settings/controllers/settings_controller.dart`](lib/features/settings/controllers/settings_controller.dart)
- Connectivity Helper: [`lib/features/settings/controllers/settings_connectivity_helper.dart`](lib/features/settings/controllers/settings_connectivity_helper.dart)
- Connectivity Utils: [`lib/features/settings/controllers/connectivity_status_utils.dart`](lib/features/settings/controllers/connectivity_status_utils.dart)
- State Mixin: [`lib/features/settings/controllers/settings_connectivity_mixin.dart`](lib/features/settings/controllers/settings_connectivity_mixin.dart)
- UI: [`lib/features/settings/views/settings_screen.dart`](lib/features/settings/views/settings_screen.dart)
- Sections (organized under [`lib/features/settings/views/sections/`](lib/features/settings/views/sections/)):
  - [`lib/features/settings/views/sections/theme_section.dart`](lib/features/settings/views/sections/theme_section.dart)
  - [`lib/features/settings/views/sections/task_management_section.dart`](lib/features/settings/views/sections/task_management_section.dart)
  - [`lib/features/settings/views/sections/sync_section.dart`](lib/features/settings/views/sections/sync_section.dart)
  - [`lib/features/settings/views/sections/connectivity_status_section.dart`](lib/features/settings/views/sections/connectivity_status_section.dart)
  - [`lib/features/settings/views/sections/drive_access_section.dart`](lib/features/settings/views/sections/drive_access_section.dart)
  - [`lib/features/settings/views/sections/permissions_section.dart`](lib/features/settings/views/sections/permissions_section.dart)
- Section Widgets: [`lib/features/settings/views/sections/widgets/connectivity_status_tile.dart`](lib/features/settings/views/sections/widgets/connectivity_status_tile.dart)
- Reusable Widgets:
  - [`lib/features/settings/views/widgets/settings_section.dart`](lib/features/settings/views/widgets/settings_section.dart): Styled section wrapper with title and NexusCard.
  - [`lib/features/settings/views/widgets/settings_header.dart`](lib/features/settings/views/widgets/settings_header.dart): Header with title text and profile card.

Includes theme mode, retention, sync status, Drive sign-in/out, connectivity status checks (Firebase, Hive, Google Drive), and permissions.

## Theme Customization ([`lib/features/theme_customization/`](lib/features/theme_customization/))

Manages the app's visual style, including dynamic color generation.

**Key files**:

- [`lib/features/theme_customization/views/theme_customization_screen.dart`](lib/features/theme_customization/views/theme_customization_screen.dart): UI for selecting colors/modes.
- [`lib/app/theme/app_theme.dart`](lib/app/theme/app_theme.dart): Defines light/dark theme data.

## Testing + CI

### Tests

Tests live in [`test/`](test/) and can be run with:

```bash
flutter test
```

### CI

GitHub Actions workflow is at [`.github/workflows/flutter.yml`](.github/workflows/flutter.yml):

- `flutter pub get; flutter analyze; flutter test`

## Contributor workflow

### Adding a new feature module (recommended approach)

1) Add models to `lib/features/<feature>/models/` (with Hive adapter)
2) Add datasources/repositories in `data/` and `repositories/`
3) Add controller in `controllers/` (`ChangeNotifier`)
4) Add views in `views/`
5) Register adapters/open boxes in [`lib/core/data/hive_bootstrap.dart`](lib/core/data/hive_bootstrap.dart)
6) Wire routes in [`lib/app/router/app_router.dart`](lib/app/router/app_router.dart)
7) Add/extend tests in `test/`

### Project command conventions

```bash
flutter pub get; flutter analyze; flutter test
flutter build apk; flutter build windows
```

## Localization (Removed)

The app previously used Flutter's l10n infrastructure with ARB files. This has been **removed** in favor of hardcoded English strings for simplicity. All UI text is now directly in the Dart code.

If you need to add/modify UI text, simply edit the string literals in the relevant widget files.

### Why Immutable Models?

All core data models (Task, Note, etc.) are **immutable**. You cannot change fields directly (e.g. `task.title = "new"`). Instead, you use `copyWith`:

```dart
final updatedTask = task.copyWith(title: "New Title");
```

**Why this matters:**

1. **Predictable State (Source of Truth)**:
    - If you hold a reference to a `Task`, it will never change "under your feet."
    - This eliminates bugs where a background service modifies an object while the UI is rendering it.

2. **Efficient UI Rebuilds (Provider/Selector)**:
    - Flutter's `context.select` and `Selector` widgets rely on reference equality (`==`).
    - If `oldTask == newTask`, the framework knows *nothing changed* and skips the rebuild.
    - Mutable objects would break this optimization (same reference, different content).

3. **Undo/Redo & History**:
    - Immutability makes it trivial to store history snapshots (just keep a list of old objects).

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

- Controllers are registered in [`lib/main.dart`](lib/main.dart) (or a dedicated provider setup file) using `MultiProvider`.
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

**Logging example (typical shape):**

```dart
debugLogger.info('Sync started', data: {'queueSize': queueSize});
try {
  await syncService.run();
  debugLogger.info('Sync finished');
} catch (e, st) {
  debugLogger.error('Sync failed', error: e, stackTrace: st);
}
```

## Background services deep dive

### Connectivity monitoring

- **Files to know**:
  - [`lib/core/services/platform/connectivity_service.dart`](lib/core/services/platform/connectivity_service.dart)
  - [`lib/core/services/platform/connectivity_status_service.dart`](lib/core/services/platform/connectivity_status_service.dart)
  - [`lib/core/services/connectivity_monitor_service.dart`](lib/core/services/connectivity_monitor_service.dart)
- **Responsibilities**:
  - Track whether the device appears online/offline.
  - Provide a higher-level "is the backend ecosystem healthy?" status (Firebase, Drive, local storage checks).
  - Surface connectivity issues via global snackbars so all features benefit.

### Notifications & Workmanager

- **Key components**:
  - `NotificationService` — encapsulates `flutter_local_notifications` setup and APIs.
  - `ReminderNotifications` — reminder-specific scheduling helpers.
  - [`lib/core/services/notifications/workmanager_dispatcher.dart`](lib/core/services/notifications/workmanager_dispatcher.dart) — entry point that Workmanager calls in the background.
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
  - Authentication state is handled separately ([`lib/core/services/storage/drive_auth_store.dart`](lib/core/services/storage/drive_auth_store.dart) and [`lib/core/services/storage/google_drive_auth.dart`](lib/core/services/storage/google_drive_auth.dart)).
  - Failed uploads should never block core functionality; they only affect cloud availability.

## Feature deep dives

### Tasks — lifecycle, lists, and editor

- **User flow**:
  1. User opens Tasks screen ([`lib/features/tasks/views/tasks_screen.dart`](lib/features/tasks/views/tasks_screen.dart)), which subscribes to `TaskController`.
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

**Where `TaskRepository` lives and how the pipeline works**

- **Repository location & wiring**:
  - Code: [`lib/features/tasks/models/task_repository.dart`](lib/features/tasks/models/task_repository.dart).
  - It is provided to the widget tree in [`provider_factory.dart`](lib/features/splash/controllers/provider_factory.dart) as a `Provider<TaskRepository>`, and then injected into `TaskController` via the `_createTaskControllerProvider` factory.
  - `TaskController` holds a `TaskRepository` instance (`_repo`) and exposes it via the `TaskControllerBase.repo` getter for use in mixins like `TaskCrudMixin`.
- **Pipeline (Controller → Repository → Local datasource → Hive)**:
  - `TaskController` (and its mixins) only talk to the **repository**:
    - e.g. `repo.getAll()`, `repo.upsert(task)`, `repo.delete(task.id)`.
  - `TaskRepository` is a thin **gateway** that delegates to `TaskLocalDatasource`:
    - File: [`lib/features/tasks/models/task_local_datasource.dart`](lib/features/tasks/models/task_local_datasource.dart).
    - Methods like `getAll/getById/put/delete/listenable` encapsulate all Hive box access.
  - `TaskLocalDatasource` is the only place that knows about the **Hive** API:
    - It opens the `tasks` box via `Hive.box<Task>(HiveBoxes.tasks)`.
    - All reads/writes (`get`, `put`, `delete`, `values`) happen here.
  - **End-to-end summary**:
    - UI → `TaskController` → `TaskRepository` → `TaskLocalDatasource` → Hive box.
    - This keeps controllers free of storage details and lets you swap/change persistence in one place.

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
  - [`lib/features/notes/views/widgets/rtl_aware_text.dart`](lib/features/notes/views/widgets/rtl_aware_text.dart) determines text direction based on content.
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

## Per-feature walkthroughs ([`lib/features/…`](lib/features/))

This section mirrors the `lib/features` folder and explains **what each feature does**, **how its pieces talk to each other**, and **how data flows through it**.

### [`features/wrapper`](lib/features/wrapper/) — app shell & navigation

- **Purpose**: Provides the persistent shell around the whole app (drawer + bottom navigation).
- **Key files**:
  - [`lib/features/wrapper/views/app_wrapper.dart`](lib/features/wrapper/views/app_wrapper.dart): Top-level `Scaffold` with `Drawer` and a body that hosts the current route from `go_router`.
  - [`lib/features/wrapper/views/app_drawer.dart`](lib/features/wrapper/views/app_drawer.dart): The side drawer with navigation items.
  - [`lib/features/wrapper/views/nav_bar_wrappers/`](lib/features/wrapper/views/nav_bar_wrappers/): Abstractions around different nav bar visual styles.
  - [`lib/features/wrapper/views/widgets/nav_bar_builder.dart`](lib/features/wrapper/views/widgets/nav_bar_builder.dart) and [`lib/features/wrapper/views/widgets/drawer_item.dart`](lib/features/wrapper/views/widgets/drawer_item.dart): Small helpers to make the shell composable.
- **Data & communication flow**:
  - Does **not** own business data; it delegates to child routes.
  - Reads the current route from the router and displays the appropriate screen.
  - Routes deeper into feature screens where controllers provide actual state.

### [`features/splash`](lib/features/splash/) — app initialization

- **Purpose**: Orchestrates app startup so the user sees a controlled Splash instead of a blank screen.
- **Key files**:
  - [`lib/features/splash/controllers/app_initializer.dart`](lib/features/splash/controllers/app_initializer.dart): Implements the two-phase initialization (`initializeCritical` then `completeInitialization`).
  - [`lib/features/splash/controllers/provider_factory.dart`](lib/features/splash/controllers/provider_factory.dart): Central place to create and wire controllers/providers.
  - [`lib/features/splash/views/splash_wrapper.dart`](lib/features/splash/views/splash_wrapper.dart): Hosts the Splash UI while initialization runs.
  - [`lib/features/splash/views/splash_screen.dart`](lib/features/splash/views/splash_screen.dart): Visual splash screen.
- **Data & communication flow**:
  - Startup sequence:
    1. [`lib/main.dart`](lib/main.dart) calls `AppInitializer.initializeCritical()` before `runApp`.
    2. After the root widget tree is ready, `completeInitialization()` is called from the Splash layer using `ProviderFactory` to construct controllers and repositories.
    3. Once everything is initialized, navigation transitions to the main `Wrapper`/Dashboard route.
  - Any failure in critical initialization is treated as fatal; failures in non-critical init are surfaced via snackbars or debug logs.

### [`features/dashboard`](lib/features/dashboard/) — daily summary

- **Purpose**: Aggregates information from tasks, reminders, habits, and analytics into a single home screen.
- **Key files**:
  - [`lib/features/dashboard/views/dashboard_screen.dart`](lib/features/dashboard/views/dashboard_screen.dart): Main widget that composes multiple dashboard cards.
  - Widgets: [`lib/features/dashboard/views/widgets/daily_progress_card.dart`](lib/features/dashboard/views/widgets/daily_progress_card.dart), [`lib/features/dashboard/views/widgets/upcoming_task_card.dart`](lib/features/dashboard/views/widgets/upcoming_task_card.dart), [`lib/features/dashboard/views/widgets/quick_reminder_card.dart`](lib/features/dashboard/views/widgets/quick_reminder_card.dart), [`lib/features/dashboard/views/widgets/stat_card.dart`](lib/features/dashboard/views/widgets/stat_card.dart).
- **Data & communication flow**:
  - Reads from multiple controllers via Provider (e.g. `TaskController`, `ReminderController`, `HabitController`, `AnalyticsController`).
  - Each card performs **lightweight projection** of controller data (e.g. filter today’s tasks) but leaves core logic in controllers.
  - Dashboard never writes; it only triggers navigation (e.g. “See all tasks”) or opens editors.

### [`features/tasks`](lib/features/tasks/) — tasks domain

- **Purpose**: Owns everything related to tasks: models, categories, CRUD, lists, detail views, and attachment handling.
- **Key files**:
  - Controllers:
    - [`lib/features/tasks/controllers/task_controller.dart`](lib/features/tasks/controllers/task_controller.dart): Main task business logic and list state.
    - [`lib/features/tasks/controllers/category_controller.dart`](lib/features/tasks/controllers/category_controller.dart): Category and subcategory management.
    - [`lib/features/tasks/controllers/task_crud_mixin.dart`](lib/features/tasks/controllers/task_crud_mixin.dart): Reusable CRUD helpers shared by controllers.
    - [`lib/features/tasks/controllers/attachment_helper.dart`](lib/features/tasks/controllers/attachment_helper.dart): Helpers around task attachments and their life cycle.
  - Models / data:
    - [`lib/features/tasks/models/task.dart`](lib/features/tasks/models/task.dart), [`lib/features/tasks/models/task_attachment.dart`](lib/features/tasks/models/task_attachment.dart), [`lib/features/tasks/models/task_enums.dart`](lib/features/tasks/models/task_enums.dart), [`lib/features/tasks/models/task_editor_result.dart`](lib/features/tasks/models/task_editor_result.dart).
    - [`lib/features/tasks/models/task_local_datasource.dart`](lib/features/tasks/models/task_local_datasource.dart): Hive access for tasks.
    - [`lib/features/tasks/models/task_repository.dart`](lib/features/tasks/models/task_repository.dart): High-level repository responsible for fetching/persisting with proper flags and sync queue updates.
    - [`lib/features/tasks/models/category.dart`](lib/features/tasks/models/category.dart), [`lib/features/tasks/models/category_sort_option.dart`](lib/features/tasks/models/category_sort_option.dart), [`lib/features/tasks/models/task_sort_option.dart`](lib/features/tasks/models/task_sort_option.dart).
  - Views:
    - [`lib/features/tasks/views/tasks_screen.dart`](lib/features/tasks/views/tasks_screen.dart): Main list view for tasks.
    - [`lib/features/tasks/views/utils/`](lib/features/tasks/views/utils/): Utilities for attachments, date formatting, etc.
    - [`lib/features/tasks/views/widgets/`](lib/features/tasks/views/widgets/): All UI components (tiles, sections, drawers, editors).
- **Data & communication flow**:
  - [`lib/features/tasks/views/tasks_screen.dart`](lib/features/tasks/views/tasks_screen.dart) subscribes to `TaskController` and `CategoryController` via Provider.
  - User interactions (create/edit/delete, change status, move category) call into `TaskController` methods.
  - `TaskController` delegates:
    - Persistence to `TaskRepository` → `TaskLocalDataSource` → Hive.
    - Attachments to `AttachmentStorageService` (core service) via helpers.
    - Sync responsibilities (set `isDirty`, enqueue `SyncOperation`).
  - Views such as [`lib/features/tasks/views/widgets/lists/grouped_task_list.dart`](lib/features/tasks/views/widgets/lists/grouped_task_list.dart) + section widgets transform `List<Task>` from the controller into grouped UI by due date, status, and category without touching Hive directly.

### `features/task_editor` — task editing UI

- **Purpose**: Provides a reusable, rich editing surface for tasks separate from the list.
- **Key files**:
  - `task_editor_sheet.dart`: High-level bottom sheet entry point for editing.
  - `widgets/*`: Modular pieces (header, inputs, selectors, chips, quick options).
- **Data & communication flow**:
  - Receives an existing `Task` (for edit) or null (for create) plus callbacks / `TaskController` reference.
  - Produces a `TaskEditorResult` describing the user’s choices.
  - Delegates actual persistence to `TaskController`; the editor itself never writes to Hive.

### [`features/reminders`](lib/features/reminders/) — reminders domain

- **Purpose**: Manages reminder entities and the link between reminder data and notification scheduling.
- **Key files**:
  - [`lib/features/reminders/models/reminder.dart`](lib/features/reminders/models/reminder.dart): Core reminder entity.
  - [`lib/features/reminders/controllers/reminder_controller.dart`](lib/features/reminders/controllers/reminder_controller.dart): Business logic and in-memory list.
  - [`lib/features/reminders/views/reminders_screen.dart`](lib/features/reminders/views/reminders_screen.dart): List and management UI.
- **Data & communication flow**:
  - [`lib/features/reminders/views/reminders_screen.dart`](lib/features/reminders/views/reminders_screen.dart) reads the list of reminders from `ReminderController`.
  - When a reminder is created/updated/deleted:
    - Controller persists to Hive (through its data layer),
    - Calls `NotificationService` / `ReminderNotifications` to schedule or cancel OS-level notifications,
    - Ensures any in-app timer logic is updated so callbacks fire correctly while app is open.
  - Background Workmanager jobs use core notification logic to catch missed reminders, sharing common code paths where possible.

### [`features/notes`](lib/features/notes/) — rich notes domain

- **Purpose**: Rich text + embedded audio notes with optional sync and attachments.
- **Key files**:
  - [`lib/features/notes/controllers/note_controller.dart`](lib/features/notes/controllers/note_controller.dart): In-memory list, filtering/search, CRUD.
  - [`lib/features/notes/models/`](lib/features/notes/models/): Note entities and attachments (including voice note references).
  - [`lib/features/notes/views/notes_list_screen.dart`](lib/features/notes/views/notes_list_screen.dart), `note_editor_screen.dart`: List and editor UIs.
  - [`lib/features/notes/views/widgets/rtl_aware_text.dart`](lib/features/notes/views/widgets/rtl_aware_text.dart): Smart text direction helper.
- **Data & communication flow**:
  - User opens note list → `NoteController` loads notes from Hive via its data layer.
  - When creating/editing:
    - Editor converts the Quill-style Delta content to JSON (`contentDeltaJson`) and passes to controller.
    - Controller persists entity and updates any sync queue entries.
  - Voice notes:
    - `NoteEmbedService` coordinates recording/picking audio and storing files.
    - `NoteAttachment` tracks local paths and Drive IDs.

### [`features/habits`](lib/features/habits/) — habits + streaks

- **Purpose**: Tracks recurring habits and daily completions.
- **Key files**:
  - [`lib/features/habits/controllers/habit_controller.dart`](lib/features/habits/controllers/habit_controller.dart): Core business logic and view state.
  - Models:
    - [`lib/features/habits/models/habit.dart`](lib/features/habits/models/habit.dart), `habit_log.dart`: Main entities.
    - `habit_local_datasource.dart`, `habit_log_local_datasource.dart`: Hive access.
    - `habit_repository.dart`, `habit_log_repository.dart`: Repositories.
  - Views:
    - [`lib/features/habits/views/habits_screen.dart`](lib/features/habits/views/habits_screen.dart), `habit_details_screen.dart`, dialog widgets, tiles.
- **Data & communication flow**:
  - User marks a habit as done for a date → `HabitController` writes a `HabitLog` via repository.
  - Controller recomputes streaks and exposes them to the UI.
  - Analytics feature can read habit data (through controller or repository) to show progress charts.

### [`features/analytics`](lib/features/analytics/) — KPIs and charts

- **Purpose**: Visualizes KPIs around tasks and habits.
- **Key files**:
  - [`lib/features/analytics/controllers/analytics_controller.dart`](lib/features/analytics/controllers/analytics_controller.dart): Central place to compute aggregates.
  - [`lib/features/analytics/utils/analytics_utils.dart`](lib/features/analytics/utils/analytics_utils.dart): Shared math/utility functions.
  - [`lib/features/analytics/views/analytics_screen.dart`](lib/features/analytics/views/analytics_screen.dart) and widget files (charts, legend, quick stats).
- **Data & communication flow**:
  - Analytics controller subscribes to / queries from Task and Habit controllers/repositories.
  - Computes:
    - Counts of pending vs completed tasks,
    - Habit completion rates,
    - Velocity or trend metrics as applicable.
  - Widgets bind to simple view models (e.g. `List<ChartSlice>`) rather than raw entities.

### [`features/calendar`](lib/features/calendar/) — calendar overlay

- **Purpose**: Consolidates time-based data (tasks with due dates + reminders) into a unified calendar view.
- **Key files**:
  - [`lib/features/calendar/controllers/calendar_controller.dart`](lib/features/calendar/controllers/calendar_controller.dart): Maps domain entities into calendar events.
  - [`lib/features/calendar/views/calendar_screen.dart`](lib/features/calendar/views/calendar_screen.dart): Calendar UI and interactions.
  - [`lib/features/calendar/views/widgets/calendar_event_tile.dart`](lib/features/calendar/views/widgets/calendar_event_tile.dart): Event representation.
- **Data & communication flow**:
  - Controller reads from Task and Reminder data sources (or controllers) and produces a stream/list of calendar events.
  - Optionally syncs with device calendar via `DeviceCalendarService` when user enables it in Settings.
  - UI selects a date/time slot and triggers navigation to the related entity detail (task/reminder).

### [`features/settings`](lib/features/settings/) — configuration & diagnostics

- **Purpose**: Central place for toggles (theme, sync, notifications, Drive, connectivity checks, etc.).
- **Key files** (see earlier section for more detail):
  - [`lib/features/settings/controllers/settings_controller.dart`](lib/features/settings/controllers/settings_controller.dart) and related helpers/mixins.
  - [`lib/features/settings/views/settings_screen.dart`](lib/features/settings/views/settings_screen.dart) and its `views/sections/*` widgets.
- **Data & communication flow**:
  - Settings controller persists configuration to local storage (Hive/SharedPreferences).
  - Other services/controllers read settings on startup or listen for changes to alter behavior (e.g. disabling sync, changing theme).

### [`features/theme_customization`](lib/features/theme_customization/) — theming UX

- **Purpose**: UX for choosing themes, colors, and nav bar styles.
- **Key files**:
  - [`lib/features/theme_customization/views/theme_customization_screen.dart`](lib/features/theme_customization/views/theme_customization_screen.dart): Main entry point.
  - `views/widgets/colors/*`, `nav_bar_styles/*`, `presets/*`, `preview/*`: Smaller widgets and config structures.
- **Data & communication flow**:
  - Reads/writes via `ThemeService` and `SettingsController` (for persisted theme prefs).
  - Generates preview state that is applied to `AppTheme` before persisting.

### [`features/sync`](lib/features/sync/) — sync UI

- **Purpose**: UI representation of sync state and conflict resolution.
- **Key files**:
  - [`lib/features/sync/controllers/sync_controller.dart`](lib/features/sync/controllers/sync_controller.dart): Tracks sync state (queue size, last sync time, current status).
  - [`lib/features/sync/views/sync_status_widget.dart`](lib/features/sync/views/sync_status_widget.dart): Icon/button that shows sync progress or problems.
  - [`lib/features/sync/views/conflict_resolution_dialog.dart`](lib/features/sync/views/conflict_resolution_dialog.dart): Dialog for resolving task-related conflicts.
- **Data & communication flow**:
  - `SyncController` subscribes to `SyncService` (core service) and to queue metadata stored in Hive.
  - When conflicts are detected, controller launches appropriate dialogs (tasks vs notes) and passes conflicting entities.
  - User choices are persisted through repositories and may generate additional sync operations.

## Per-service walkthroughs ([`lib/core/services/…`](lib/core/services/))

This section covers infrastructure services and how they interact with features and each other.

### Connectivity services

- **[`lib/core/services/platform/connectivity_service.dart`](lib/core/services/platform/connectivity_service.dart)**:
  - Thin wrapper around platform APIs (e.g. connectivity_plus).
  - Exposes a stream of connectivity changes and a way to query current status.
- **[`lib/core/services/platform/connectivity_status_service.dart`](lib/core/services/platform/connectivity_status_service.dart)**:
  - Builds on `ConnectivityService` to perform **deeper health checks** (can we reach Firebase? is Drive authenticated? are Hive boxes open?).
  - Produces a richer status model consumed by Settings and debug UIs.
- **[`lib/core/services/connectivity_monitor_service.dart`](lib/core/services/connectivity_monitor_service.dart)**:
  - Background service that subscribes to connectivity streams and health checks.
  - Shows snackbars via `CommonSnackbar.showGlobal()` when connectivity status changes (e.g. “Offline mode”, “Back online”).  
  - Helps all features behave consistently in offline/online transitions.

### Debug logging services

- **Files**: [`lib/core/services/debug/debug_logger_service.dart`](lib/core/services/debug/debug_logger_service.dart), [`lib/core/services/debug/debug_log_archiver.dart`](lib/core/services/debug/debug_log_archiver.dart), [`lib/core/services/debug/debug_log_archiver_io.dart`](lib/core/services/debug/debug_log_archiver_io.dart), [`lib/core/services/debug/debug_log_archiver_stub.dart`](lib/core/services/debug/debug_log_archiver_stub.dart).
- **Responsibilities**:
  - Provide a central API for logging structured debug messages.
  - Keep an in-memory ring buffer (up to N entries) for the overlay.
  - Periodically archive logs to disk on supported platforms via the IO implementation.
  - Use a stub implementation on platforms where IO isn’t available.
- **Data & communication flow**:
  - Any part of the app can log via `DebugLoggerService` (injected where needed).
  - `GlobalDebugOverlay` reads from logger and archives to present logs to the user.

### Note embed service

- **[`lib/core/services/note_embed_service.dart`](lib/core/services/note_embed_service.dart)**:
  - Coordinates embedding of media (especially voice notes) into notes.
  - Provides a higher-level API so note UI doesn’t have to know about file system paths or Drive IDs.
  - Talks to `AttachmentStorageService` and Drive services when necessary.

### Notification services

- **[`lib/core/services/notifications/notification_service.dart`](lib/core/services/notifications/notification_service.dart)**:
  - Encapsulates `flutter_local_notifications` initialization and channel setup.
  - Provides methods for scheduling, updating, canceling, and showing notifications immediately.
- **[`lib/core/services/notifications/reminder_notifications.dart`](lib/core/services/notifications/reminder_notifications.dart)**:
  - Reminder-specific helpers for building notification payloads and IDs.
  - Implements conventions like how notification IDs map to reminder IDs.
- **[`lib/core/services/notifications/workmanager_dispatcher.dart`](lib/core/services/notifications/workmanager_dispatcher.dart)**:
  - Entry function invoked by Workmanager in the background.
  - Initializes minimal app context (Hive, notification plugin, time zones) and executes the reminder catch-up logic.
- **Data & communication flow**:
  - UI → `ReminderController` → `NotificationService`/`ReminderNotifications` for scheduling.
  - System (Workmanager) → [`lib/core/services/notifications/workmanager_dispatcher.dart`](lib/core/services/notifications/workmanager_dispatcher.dart) → same notification paths for missed reminders.

### Platform services

- **[`lib/core/services/platform/device_calendar_service.dart`](lib/core/services/platform/device_calendar_service.dart)**:
  - Wraps platform calendar APIs with a simplified interface (create/read events, request permissions).
  - Used by Calendar feature and possibly Settings.
- **[`lib/core/services/platform/permission_service.dart`](lib/core/services/platform/permission_service.dart)**:
  - Central authority for requesting/checking runtime permissions (notifications, calendar, storage, microphone, etc.).
  - Features should avoid calling platform permission APIs directly; go through this service.

### Storage & Google Drive services

- **[`lib/core/services/storage/attachment_storage_service.dart`](lib/core/services/storage/attachment_storage_service.dart)**:
  - Defines the on-disk layout for attachments (by feature/entity).
  - Provides APIs for saving, reading, and deleting files.
- **[`lib/core/services/storage/google_drive_service.dart`](lib/core/services/storage/google_drive_service.dart)**:
  - High-level facade for Drive operations: ensure folders exist, upload/download/list/delete files.
  - Hides the details of API clients, folder structure, and error handling.
- **Supporting files**:
  - [`lib/core/services/storage/google_drive_api_client.dart`](lib/core/services/storage/google_drive_api_client.dart): Creates the authenticated HTTP client for Drive.
  - [`lib/core/services/storage/google_drive_auth.dart`](lib/core/services/storage/google_drive_auth.dart): Orchestrates sign-in, sign-out, and token refresh flows.
  - [`lib/core/services/storage/drive_auth_store.dart`](lib/core/services/storage/drive_auth_store.dart): Persists auth state locally (e.g. tokens, last sign-in).
  - [`lib/core/services/storage/drive_auth_exception.dart`](lib/core/services/storage/drive_auth_exception.dart): Typed exception for “auth required” and related cases.
  - [`lib/core/services/storage/google_drive_folders.dart`](lib/core/services/storage/google_drive_folders.dart), [`lib/core/services/storage/google_drive_files.dart`](lib/core/services/storage/google_drive_files.dart): Low-level helpers for specific Drive operations.
- **Data & communication flow**:
  - Feature controllers request uploads/downloads via `GoogleDriveService`.
  - `GoogleDriveService` checks auth state via `DriveAuthStore`; if missing/expired, it triggers `GoogleDriveAuth` to resolve.
  - On success, Drive file IDs are written back to entities stored in Hive (e.g. `TaskAttachment`, `NoteAttachment`), enabling future sync.

### Sync service

- **[`lib/core/services/sync/sync_service.dart`](lib/core/services/sync/sync_service.dart)**:
  - The central engine that processes `SyncOperation` entries and coordinates Firestore interactions.
  - Steps for a typical sync:
    1. Read queued `SyncOperation`s from Hive.
    2. For each operation, map local entities to Firestore documents and push changes.
    3. Fetch remote changes since last sync timestamp.
    4. Apply remote changes to Hive, resolving conflicts or marking them for user resolution.
    5. Update sync metadata (last sync timestamp, queue size).
  - Exposes status updates for `SyncController` and may emit progress events for UI.
