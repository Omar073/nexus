# Nexus — Developer Contributor Guide

Nexus is an **offline-first** personal life management app (Tasks, Reminders, Notes, Habits, Calendar, Analytics) built with **Flutter**.

**Design principle:** Hive is the local source-of-truth. Every user action writes locally first and then syncs to the cloud when possible.

- **Platforms**: Android + Windows
- **UI language**: English-only (hardcoded strings)
- **Arabic support**: user-entered content (Tasks/Notes) auto-renders RTL when text contains Arabic characters

This README is meant to onboard developer contributors quickly: how the repo is structured, how data flows, and where to implement changes.

If you're looking for a **non-technical, end-user overview**, see `README.md`.

## Table of contents

- [1. Getting started](#1-getting-started-step-by-step)
- [2. High-level architecture](#2-high-level-architecture)
- [3. Repository map](#3-repository-map-where-everything-lives)
- [4. App Shell & Navigation](#4-app-shell--navigation-libfeatureswrapper)
- [5. Dashboard](#5-dashboard-libfeaturesdashboard)
- [6. Firebase (Firestore sync)](#6-firebase-firestore-sync--setup--layout)
- [7. Google Drive (attachments)](#7-google-drive-attachments--setup)
- [8. Secret debug logs](#8-secret-debug-logs-production-only--android--windows)
- [9. Feature-by-feature guide](#9-feature-by-feature-guide)
  - [9.1 Tasks](#91-tasks)
  - [9.2 Reminders](#92-reminders)
  - [9.3 Sync + conflict handling](#93-sync--conflict-handling)
  - [9.4 Notes](#94-notes-rich-text--inline-voice-notes)
  - [9.5 Habits](#95-habits)
  - [9.6 Analytics](#96-analytics)
  - [9.7 Calendar](#97-calendar)
  - [9.8 Settings](#98-settings)
  - [9.9 Theme Customization](#99-theme-customization-libfeaturestheme_customization)
- [10. Testing + CI](#10-testing--ci)
- [11. Contributor workflow](#11-contributor-workflow)
- [12. Deep architecture & implementation guide](#12-deep-architecture--implementation-guide)
  - [12.1 Background services deep dive](#121-background-services-deep-dive)
  - [12.2 Feature deep dives](#122-feature-deep-dives)
  - [12.3 How to implement common changes](#123-how-to-implement-common-changes)
  - [12.4 Coding style & project conventions](#124-coding-style--project-conventions)
  - [12.5 Glossary](#125-glossary-quick-reference)

## 1. Getting started (step-by-step)

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

## 2. High-level architecture

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

- **Widget wrappers**: Composed via [`wrapWithOverlays()`](lib/app/services/app_services_composer.dart#L11) in [`lib/app/services/app_services_composer.dart`](lib/app/services/app_services_composer.dart). This function takes the root widget and wraps it with all necessary UI overlays (e.g., `GlobalDebugOverlay`). To add a new wrapper, you simply add it inside `wrapWithOverlays()` — no need to touch `main.dart` or other files.

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

1. `App.initState()` → calls [`initializeBackgroundServices(context)`](lib/app/services/app_services_composer.dart#L19) → starts monitoring
2. Service receives stream events → reacts (e.g., shows snackbar via global key)
3. `App.dispose()` → calls [`disposeBackgroundServices()`](lib/app/services/app_services_composer.dart#L29) → cancels subscriptions

- **Global ScaffoldMessenger**: `appMessengerKey` in [`lib/app/app_globals.dart`](lib/app/app_globals.dart) allows services and other code to show snackbars without BuildContext. Use `CommonSnackbar.showGlobal()` for context-free snackbars.

### App Initialization Flow ([`lib/features/splash/`](lib/features/splash/))

The app startup is managed by `AppInitializer` ([`lib/features/splash/controllers/app_initializer.dart`](lib/features/splash/controllers/app_initializer.dart)) in two phases:

1. **Critical Initialization** ([`initializeCritical`](lib/features/splash/controllers/app_initializer.dart#L46)):
   - Runs before `runApp`.
   - Initializes Firebase, Hive, Device ID, and Settings.
   - **Failure handling**: If this fails, the app throws an error immediately (fail fast).
2. **Complete Initialization** ([`completeInitialization`](lib/features/splash/controllers/app_initializer.dart#L85)):
   - Runs after the Splash Screen is visible.
   - Initializes heavier services: `NotificationService`, `Workmanager`, `GoogleDriveService`, and all Repositories/Controllers.
   - **User Experience**: The Splash Screen waits for this to complete before navigating to the Dashboard.

**Data flow for background services:**

1) `App` widget (StatefulWidget) initializes in `initState`
2) After first frame, [`initializeBackgroundServices(context)`](lib/app/services/app_services_composer.dart#L19) is called
3) Services access Provider context to read dependencies (e.g., `ConnectivityService`)
4) Services subscribe to streams/events and use `appMessengerKey` to show UI updates
5) On app disposal, [`disposeBackgroundServices()`](lib/app/services/app_services_composer.dart#L29) cleans up all service subscriptions

## 3. Repository map (where everything lives)

### App bootstrap / routing / UI shell

- [`lib/main.dart`](lib/main.dart): Firebase init, Hive init, Provider wiring
- [`lib/app/app.dart`](lib/app/app.dart): `StatefulWidget` with `MaterialApp.router`, themes
- [`lib/app/app_globals.dart`](lib/app/app_globals.dart): Global `ScaffoldMessengerKey` for context-free snackbars
- [`lib/app/services/app_services_composer.dart`](lib/app/services/app_services_composer.dart): Composes widget wrappers and manages background service initialization/disposal
- [`lib/app/router/app_router.dart`](lib/app/router/app_router.dart): `go_router` routes (bottom-nav shell)
- [`lib/features/wrapper/views/app_wrapper.dart`](lib/features/wrapper/views/app_wrapper.dart): App shell with drawer and bottom navigation
- [`lib/features/wrapper/views/app_drawer.dart`](lib/features/wrapper/views/app_drawer.dart): Navigation drawer
- [`lib/app/theme/app_theme.dart`](lib/app/theme/app_theme.dart): Material 3 themes

### Core Data Infrastructure

The core data layer manages local storage (Hive) and sync operations.

#### How Hive Stores Data

Hive is a key-value store that serializes Dart objects to binary. Each model class needs:

1. **TypeAdapter** — Tells Hive how to read/write the object to binary
2. **Type ID** — Unique integer identifying the model type (defined in `hive_type_ids.dart`)
3. **Field annotations** — `@HiveField(n)` marks each field with a numeric index

When storing objects, Hive writes each field as `[field index][encoded value]`. This allows:

- **Backwards compatibility** — New fields can be added without breaking old data
- **Sparse storage** — Missing fields are handled gracefully with defaults

> See [Hive Binary Serialization](technical_concepts.md#hive-binary-serialization) in `technical_concepts.md` for detailed implementation patterns.

#### Hive Configuration ([`lib/core/data/hive/`](lib/core/data/hive/))

| File | Role |
|------|------|
| [`hive_type_ids.dart`](lib/core/data/hive/hive_type_ids.dart) | **Central registry of Hive type IDs.** Each model that Hive stores needs a unique integer ID. Once assigned, these IDs must NEVER be reused or changed—doing so corrupts existing data. Add new models at the end of the list. |
| [`hive_boxes.dart`](lib/core/data/hive/hive_boxes.dart) | **Box name constants.** Defines string names for each Hive box (e.g., `'tasks'`, `'notes'`). Centralizing these prevents typos and makes refactoring easier. |
| [`hive_bootstrap.dart`](lib/core/data/hive/hive_bootstrap.dart) | **App startup initialization.** Registers all Hive adapters and opens all boxes. Called once during app launch before any data access. |

#### Sync Infrastructure

The sync system implements an **offline-first queue** pattern. All writes happen locally first, then get pushed to Firestore when online.

##### How Sync Works

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│ 1. USER ACTION (e.g., create task)                                           │
│    Controller writes to Hive → sets isDirty=true                             │
│    Controller creates SyncOperation → adds to sync queue                     │
└──────────────────────────────────┬───────────────────────────────────────────┘
                                   ↓
┌──────────────────────────────────────────────────────────────────────────────┐
│ 2. SYNC QUEUE (Hive box)                                                     │
│    Stores pending operations: {id, type, entityType, entityId, data, ...}    │
│    Persists across app restarts                                              │
└──────────────────────────────────┬───────────────────────────────────────────┘
                                   ↓
┌──────────────────────────────────────────────────────────────────────────────┐
│ 3. SYNC SERVICE (triggered when online)                                      │
│    Reads pending operations from queue                                       │
│    Pushes each to Firestore                                                  │
│    On success: removes from queue, clears isDirty                            │
│    On failure: increments retryCount, updates lastAttemptAt                  │
└──────────────────────────────────────────────────────────────────────────────┘
```

##### Sync Queue Files

| File | Role |
|------|------|
| [`sync_queue.dart`](lib/core/data/sync_queue.dart) | **Model definition.** Contains `SyncOperation` (the queued operation) and two enums: `SyncOperationType` (create/update/delete) and `SyncOperationStatus` (pending/syncing/failed/completed). |
| [`sync_operation_adapter.dart`](lib/core/data/sync_operation_adapter.dart) | **Hive serialization.** Custom TypeAdapter that handles reading/writing `SyncOperation` to Hive. Includes `_convertTimestamps()` to convert Firestore `Timestamp` objects to Dart `DateTime` (Hive can't store Timestamps directly). |
| [`sync_metadata.dart`](lib/core/data/sync_metadata.dart) | **Sync state tracking.** Stores the timestamp of the last successful sync. Used to fetch only changes since then, avoiding full data pulls. |

##### SyncOperation Fields

| Field | Purpose |
|-------|---------|
| `id` | Unique ID for this sync operation |
| `type` | Operation type: 0=create, 1=update, 2=delete |
| `entityType` | What kind of entity: `'task'`, `'category'`, `'reminder'`, etc. |
| `entityId` | ID of the entity being synced |
| `data` | JSON snapshot of the entity (for retries if entity is deleted locally) |
| `retryCount` | How many times sync has failed for this operation |
| `createdAt` | When the operation was queued |
| `lastAttemptAt` | Last time sync was attempted |
| `status` | Current status: pending, syncing, failed, completed |

##### Why a Custom Adapter?

Firestore returns `Timestamp` objects for datetime fields. Hive can't serialize these directly—it throws an error. The `SyncOperationAdapter`:

1. **On read**: Reconstructs `SyncOperation` from binary data
2. **On write**: Recursively scans the `data` map and converts any `Timestamp` → `DateTime` before saving

This ensures data snapshots from Firestore can be safely stored in the local queue.

##### Connection Restoration Pipeline

When the device comes back online, here's the exact call chain that triggers sync:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. CONNECTIVITY SERVICE (lib/core/services/platform/connectivity_service.dart)
│    - Wraps the `connectivity_plus` package                                  │
│    - Exposes `onlineStream()` → Stream<bool> that emits true/false          │
│    - Device goes online → emits `true`                                      │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ 2. SYNC SERVICE LISTENER (lib/core/services/sync/sync_service.dart)         │
│    startAutoSync() subscribes to onlineStream:                              │
│                                                                             │
│    _connectivity.onlineStream().listen((online) {                           │
│      if (online) {                                                          │
│        unawaited(syncOnce());  // ← triggers full sync cycle                │
│      }                                                                      │
│    });                                                                      │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ 3. syncOnce() EXECUTES                                                      │
│    - Guards against concurrent syncs (_isSyncing flag)                      │
│    - Double-checks connectivity before proceeding                           │
│    - Runs the full sync cycle:                                              │
│                                                                             │
│    await _pushQueue();         // Push local changes to Firestore           │
│    await _pullTasks();         // Pull remote task changes                  │
│    await _pullNotes();         // Pull remote note changes                  │
│    await _markSuccessfulSync(); // Update lastSuccessfulSyncAt timestamp    │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Key methods in `SyncService`:**

| Method | What it does | Source |
|--------|--------------|--------|
| `startAutoSync()` | Called once at app startup. Sets up listener on connectivity stream. | [sync_service.dart:L127](lib/core/services/sync/sync_service.dart#L127) |
| `syncOnce()` | Full sync cycle: push queue → pull remote → save timestamp. | [sync_service.dart:L151](lib/core/services/sync/sync_service.dart#L151) |
| `_pushQueue()` | Iterates pending `SyncOperation`s, pushes each to Firestore. | [sync_service.dart:L179](lib/core/services/sync/sync_service.dart#L179) |
| `_pullTasks()` | Queries Firestore for tasks updated since `lastSuccessfulSyncAt`. Detects conflicts. | [sync_service.dart:L256](lib/core/services/sync/sync_service.dart#L256) |
| `_pullNotes()` | Same as above but for notes. | [sync_service.dart:L310](lib/core/services/sync/sync_service.dart#L310) |
| `_markSuccessfulSync()` | Updates `SyncMetadata.lastSuccessfulSyncAt` so next sync only pulls newer changes. | [sync_service.dart:L361](lib/core/services/sync/sync_service.dart#L361) |

**Key methods in `ConnectivityService`:**

| Method | What it does | Source |
|--------|--------------|--------|
| `onlineStream()` | Returns `Stream<bool>` that emits connectivity changes. | [connectivity_service.dart:L28](lib/core/services/platform/connectivity_service.dart#L28) |
| `isOnline` | Async getter that checks current connectivity. | [connectivity_service.dart:L22](lib/core/services/platform/connectivity_service.dart#L22) |

---

### Core Services ([`lib/core/services/`](lib/core/services/))

Services are organized by domain. Each service encapsulates a specific capability.

#### Platform Services (`platform/`)

| File | Role |
|------|------|
| [`connectivity_service.dart`](lib/core/services/platform/connectivity_service.dart) | **Network state provider.** Exposes a `Stream<bool>` that emits `true`/`false` as the device goes online/offline. Used by sync and Drive services to know when to attempt operations. |
| [`backend_health_checker.dart`](lib/core/services/platform/backend_health_checker.dart) | **Health check aggregator.** Tests connectivity to specific backends (Firebase reachable? Hive readable? Drive authenticated?) and reports status for the debug overlay. |
| [`permission_service.dart`](lib/core/services/platform/permission_service.dart) | **Runtime permissions wrapper.** Handles requesting and checking permissions (notifications, storage, calendar) with platform-specific logic. |
| [`device_calendar_service.dart`](lib/core/services/platform/device_calendar_service.dart) | **Native calendar integration.** Reads/writes events to the device's native calendar app. Wraps the `device_calendar` plugin. |

#### Sync Service (`sync/`)

| File | Role |
|------|------|
| [`sync_service.dart`](lib/core/services/sync/sync_service.dart) | **The sync engine.** Handles the full sync cycle: (1) Push local changes from `SyncQueue` to Firestore, (2) Pull remote changes since last sync, (3) Detect conflicts when both local and remote changed, (4) Surface conflicts to UI for user resolution. |

#### Notification Services (`notifications/`)

| File | Role |
|------|------|
| [`notification_service.dart`](lib/core/services/notifications/notification_service.dart) | **Local notification scheduler.** Uses `flutter_local_notifications` to schedule, show, and cancel notifications. Handles timezone-aware scheduling for reminders. |
| [`workmanager_dispatcher.dart`](lib/core/services/notifications/workmanager_dispatcher.dart) | **Background task entry point.** Android's `Workmanager` calls this when the app is killed. Bootstraps minimal Hive access, checks for due reminders, and triggers notifications as a fallback safety net. |
| [`reminder_notifications.dart`](lib/core/services/notifications/reminder_notifications.dart) | **Notification interface.** Defines the contract for scheduling reminder notifications. Implemented by `NotificationService`. |

#### Storage Services (`storage/`)

Google Drive integration is split into focused, single-responsibility files:

| File | Role |
|------|------|
| [`attachment_storage_service.dart`](lib/core/services/storage/attachment_storage_service.dart) | **Local file layout.** Manages where attachments are stored on the device filesystem (organized by entity type and ID). |
| [`google_drive_service.dart`](lib/core/services/storage/google_drive_service.dart) | **Façade pattern.** The single entry point for all Drive operations. Delegates to auth/folders/files internally. Other code only imports this file. |
| [`google_drive_auth.dart`](lib/core/services/storage/google_drive_auth.dart) | **Authentication flow.** Handles the in-app password gate and Google Sign-In. Returns authenticated HTTP client for Drive API calls. |
| [`google_drive_api_client.dart`](lib/core/services/storage/google_drive_api_client.dart) | **HTTP client factory.** Creates the authenticated `DriveApi` instance from Google's SDK. |
| [`google_drive_folders.dart`](lib/core/services/storage/google_drive_folders.dart) | **Folder management.** Creates and retrieves the app's folder hierarchy in Drive (e.g., `Nexus/Tasks/`, `Nexus/Notes/`). |
| [`google_drive_files.dart`](lib/core/services/storage/google_drive_files.dart) | **File operations.** Upload, download, list, and delete files in Drive. Used for attachments and backups. |
| [`drive_auth_store.dart`](lib/core/services/storage/drive_auth_store.dart) | **Persistent auth state.** Stores whether the user has authenticated with Drive (uses `SharedPreferences`). |
| [`drive_auth_exception.dart`](lib/core/services/storage/drive_auth_exception.dart) | **Custom exception.** `DriveAuthRequiredException` thrown when Drive operations fail due to missing authentication. |

#### Background Services (root level)

| File | Role |
|------|------|
| [`connectivity_monitor_service.dart`](lib/core/services/connectivity_monitor_service.dart) | **Singleton network monitor.** Runs independently of the widget tree. Listens to connectivity changes and shows snackbars ("Back online" / "No internet"). Initialized once at app start, never disposed. |

---

### Core Widgets ([`lib/core/widgets/`](lib/core/widgets/))

| File | Role |
|------|------|
| [`common_snackbar.dart`](lib/core/widgets/common_snackbar.dart) | **Snackbar utility.** Provides `show(context, message)` for widget-based calls and `showGlobal(message)` for context-free calls (e.g., from services). Uses `AppGlobals.scaffoldMessengerKey`. |
| [`debug/global_debug_overlay.dart`](lib/core/widgets/debug/global_debug_overlay.dart) | **Hidden debug UI.** Only active in production builds. Accessed via triple-tap (mobile) or Ctrl+Shift+D (desktop). Shows live logs and connectivity status. |

---

### Production Debug System

For debugging issues in production builds where you can't attach a debugger:

| File | Role |
|------|------|
| [`debug/debug_logger_service.dart`](lib/core/services/debug/debug_logger_service.dart) | **In-memory log buffer.** Singleton that stores the last 500 log entries. Auto-archives to disk every 30 minutes. Call `DebugLogger.log('message')` from anywhere. |
| [`debug/debug_log_archiver_io.dart`](lib/core/services/debug/debug_log_archiver_io.dart) | **Disk persistence.** Writes log archives to the app's documents directory as timestamped JSON files. |
| [`debug/global_debug_overlay.dart`](lib/core/widgets/debug/global_debug_overlay.dart) | **Visual log viewer.** Displays logs in a draggable overlay panel. Allows filtering, searching, and copying logs. |
| [`debug/debug_log_archiver_stub.dart`](lib/core/services/debug/debug_log_archiver_stub.dart) | **Stub implementation.** Used on platforms where IO isn’t available to prevent compilation errors. |

## 4. App Shell & Navigation ([`lib/features/wrapper/`](lib/features/wrapper/))

The `Wrapper` feature manages the persistent UI shell that surrounds the entire app.

**Key files**:

- [`lib/features/wrapper/views/app_wrapper.dart`](lib/features/wrapper/views/app_wrapper.dart): Main Scaffold containing the `ScaffoldKey` for drawer control.
- [`lib/features/wrapper/views/app_drawer.dart`](lib/features/wrapper/views/app_drawer.dart): The side navigation drawer accessible globally.
- [`lib/features/dashboard/views/dashboard_screen.dart`](lib/features/dashboard/views/dashboard_screen.dart): The home screen aggregator.

**Data & communication flow**:

- Does **not** own business data; it delegates to child routes.
- Reads the current route from the router and displays the appropriate screen.
- Routes deeper into feature screens where controllers provide actual state.

## 5. Dashboard ([`lib/features/dashboard/`](lib/features/dashboard/))

The Dashboard acts as an aggregator view, pulling data from multiple controllers to show a daily summary.

**Key files**:

- [`lib/features/dashboard/views/dashboard_screen.dart`](lib/features/dashboard/views/dashboard_screen.dart)
- Widgets (organized under [`lib/features/dashboard/views/widgets/`](lib/features/dashboard/views/widgets/)):
  - [`lib/features/dashboard/views/widgets/dashboard_habits_section.dart`](lib/features/dashboard/views/widgets/dashboard_habits_section.dart): Habits summary row.
  - [`lib/features/dashboard/views/widgets/dashboard_reminders_section.dart`](lib/features/dashboard/views/widgets/dashboard_reminders_section.dart): Reminders grid.
  - [`lib/features/dashboard/views/widgets/dashboard_tasks_section.dart`](lib/features/dashboard/views/widgets/dashboard_tasks_section.dart): Upcoming tasks list.

**Data & communication flow**:

- Reads from multiple controllers via Provider (e.g. `TaskController`, `ReminderController`, `HabitController`, `AnalyticsController`).
- Each card performs **lightweight projection** of controller data (e.g. filter today’s tasks) but leaves core logic in controllers.
- Dashboard never writes; it only triggers navigation (e.g. “See all tasks”) or opens editors.

## 6. Firebase (Firestore sync) — setup + layout

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

## 7. Google Drive (attachments) — setup

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

### Implementation Details

- [`google_drive_service.dart`](lib/core/services/storage/google_drive_service.dart): **Façade pattern.** The single entry point for all Drive operations. Delegates to auth/folders/files internally.
- [`google_drive_auth.dart`](lib/core/services/storage/google_drive_auth.dart): **Authentication flow.** Handles the in-app password gate and Google Sign-In.
- [`drive_auth_store.dart`](lib/core/services/storage/drive_auth_store.dart): **Persistent auth state.** Stores whether the user has authenticated with Drive.
- [`attachment_storage_service.dart`](lib/core/services/storage/attachment_storage_service.dart): **Local file layout.** Manages where attachments are stored on the device filesystem.

## 8. Secret debug logs (production-only) — Android + Windows

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

## 9. Feature-by-feature guide

## 9.1 Tasks

### Tasks Architecture

**Key files:**

- Models: [`lib/features/tasks/models/task.dart`](lib/features/tasks/models/task.dart), [`task_attachment.dart`](lib/features/tasks/models/task_attachment.dart), [`task_enums.dart`](lib/features/tasks/models/task_enums.dart), [`task_editor_result.dart`](lib/features/tasks/models/task_editor_result.dart)
- Local storage: [`lib/features/tasks/models/task_local_datasource.dart`](lib/features/tasks/models/task_local_datasource.dart)
- Repository: [`lib/features/tasks/models/task_repository.dart`](lib/features/tasks/models/task_repository.dart)
- Controllers:
  - [`lib/features/tasks/controllers/task_controller.dart`](lib/features/tasks/controllers/task_controller.dart): Main controller with filter state, queries, and lifecycle management.
  - [`lib/features/tasks/controllers/task_controller_base.dart`](lib/features/tasks/controllers/task_controller_base.dart): Abstract base class exposing dependencies to mixins.
  - [`lib/features/tasks/controllers/task_crud_mixin.dart`](lib/features/tasks/controllers/task_crud_mixin.dart): CRUD operations (create, update, delete, toggle).
  - [`lib/features/tasks/controllers/category_controller.dart`](lib/features/tasks/controllers/category_controller.dart): Category management with `getSortedCategories()` method.
- Controller Helpers:
  - [`lib/features/tasks/controllers/helpers/task_sorting_helper.dart`](lib/features/tasks/controllers/helpers/task_sorting_helper.dart): Smart sorting logic (urgent → high priority → normal).
- View Helpers:
  - [`lib/features/tasks/views/widgets/helpers/category_scroll_helper.dart`](lib/features/tasks/views/widgets/helpers/category_scroll_helper.dart): Scroll-to-category navigation logic.
- UI: [`lib/features/tasks/views/tasks_screen.dart`](lib/features/tasks/views/tasks_screen.dart)
- Widgets:
  - [`lib/features/tasks/views/widgets/task_tile.dart`](lib/features/tasks/views/widgets/task_tile.dart)
  - [`lib/features/tasks/views/widgets/task_search_bar.dart`](lib/features/tasks/views/widgets/task_search_bar.dart)
  - [`lib/features/tasks/views/widgets/task_editor_dialog.dart`](lib/features/tasks/views/widgets/task_editor_dialog.dart): **Main Task Editor**. Handles creation and editing logic.
- [`lib/features/tasks/views/task_detail_sheet/`](lib/features/tasks/views/task_detail_sheet/): Modular components for the task detail bottom sheet.
- [`lib/features/tasks/views/utils/attachment_picker_utils.dart`](lib/features/tasks/views/utils/attachment_picker_utils.dart): Helper for picking files/images.

### How Tasks work

- CRUD writes to Hive first.
- Each write sets `isDirty=true` and enqueues a `SyncOperation(entityType: 'task')`.
- Attachments (images/voice) are stored locally and best-effort uploaded to Drive.
- A sync status icon in the Tasks app bar shows queue/sync/conflict state.

### TaskController Structure (Base + Mixin)

The TaskController is split across three files to keep each file focused:

| File | Purpose |
|------|---------|
| [`task_controller_base.dart`](lib/features/tasks/controllers/task_controller_base.dart) | Abstract class defining dependencies (repo, syncService, etc.) |
| [`task_crud_mixin.dart`](lib/features/tasks/controllers/task_crud_mixin.dart) | CRUD operations ([`createTask:L12`](lib/features/tasks/controllers/task_crud_mixin.dart#L12), [`updateTask:L49`](lib/features/tasks/controllers/task_crud_mixin.dart#L49), [`deleteTask:L82`](lib/features/tasks/controllers/task_crud_mixin.dart#L82), [`toggleCompleted:L96`](lib/features/tasks/controllers/task_crud_mixin.dart#L96)) |
| [`task_controller.dart`](lib/features/tasks/controllers/task_controller.dart) | Main controller combining both, plus filters/queries/lifecycle ([`L15`](lib/features/tasks/controllers/task_controller.dart#L15)) |

**Why this pattern?**

- **Smaller files**: Each file has one clear responsibility
- **Mixin reuse**: CRUD logic could be shared with other controllers
- **Testability**: Can stub the base class to test mixin behavior

For a detailed technical explanation with code examples, see [`technical_concepts.md`](technical_concepts.md) → "Base Class + Mixin Pattern".

### Task Editor UI (`lib/features/task_editor/`)

- **Purpose**: Provides a reusable, rich editing surface for tasks separate from the list.
- **Key files**:
  - `task_editor_sheet.dart`: High-level bottom sheet entry point for editing.
  - `widgets/*`: Modular pieces (header, inputs, selectors, chips, quick options).
- **Data & communication flow**:
  - Receives an existing `Task` (for edit) or null (for create) plus callbacks / `TaskController` reference.
  - Produces a `TaskEditorResult` describing the user’s choices.
  - Delegates actual persistence to `TaskController`; the editor itself never writes to Hive.

## 9.2 Reminders

### Reminders Architecture

**Key files:**

- Models: [`lib/features/reminders/models/reminder.dart`](lib/features/reminders/models/reminder.dart)
- Controller: [`lib/features/reminders/controllers/reminder_controller.dart`](lib/features/reminders/controllers/reminder_controller.dart)
- UI: [`lib/features/reminders/views/reminders_screen.dart`](lib/features/reminders/views/reminders_screen.dart)
- Notification scheduling: [`lib/core/services/notifications/notification_service.dart`](lib/core/services/notifications/notification_service.dart)

### How Reminders work

- Creating/updating schedules a local notification via [`ReminderController.create()`](lib/features/reminders/controllers/reminder_controller.dart#L81) and [`update()`](lib/features/reminders/controllers/reminder_controller.dart#L107).
- Completing/deleting cancels the scheduled notification via [`complete()`](lib/features/reminders/controllers/reminder_controller.dart#L136) and [`delete()`](lib/features/reminders/controllers/reminder_controller.dart#L130).

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
    - `ReminderTimerService` runs a periodic timer while the app is open.
    - Checks for due reminders and triggers [`showNow()`](lib/core/services/notifications/notification_service.dart#L111) immediately.
    - Ensures 100% reliability while the user is using the app.
3. **Tertiary (Background Safety Net)**: `Workmanager`
    - Runs every ~15 minutes (Android minimum for periodic background jobs).
    - **Data Flow**: `Workmanager` → [`workmanagerCallbackDispatcher`](lib/core/services/notifications/workmanager_dispatcher.dart) → Initialize Hive (Read-Only) → Check Due Reminders → Trigger `NotificationService.showNow`.
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

## 9.3 Sync + conflict handling

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

## 9.4 Notes (Rich text + inline voice notes)

### Notes Architecture

**Key files:**

- Models: [`lib/features/notes/models/note.dart`](lib/features/notes/models/note.dart), [`lib/features/notes/models/note_attachment.dart`](lib/features/notes/models/note_attachment.dart)
- Controller: [`lib/features/notes/controllers/note_controller.dart`](lib/features/notes/controllers/note_controller.dart)
- UI:
  - [`lib/features/notes/views/notes_list_screen.dart`](lib/features/notes/views/notes_list_screen.dart): List of all notes.
  - [`lib/features/notes/views/note_editor_screen.dart`](lib/features/notes/views/note_editor_screen.dart): Rich text editor with Quill. **Save button exits editor automatically.**
- RTL helper: [`lib/features/notes/views/widgets/rtl_aware_text.dart`](lib/features/notes/views/widgets/rtl_aware_text.dart)
- Voice helper: [`lib/core/services/note_embed_service.dart`](lib/core/services/note_embed_service.dart)

### Storage format & Rich Text

- **Rich Text Engine**: [flutter_quill](https://pub.dev/packages/flutter_quill)
- **Data Model**: `Note.contentDeltaJson` stores the document as a **Quill Delta** JSON string.
  - *Delta* is a format representing changes (inserts, attributes) rather than HTML.
  - Example: `[{"insert":"Hello\n"}]`
- **Read-Only Previews**:
  - The list view and conflict dialogs render previews by parsing the Delta JSON and extracting plain text via `doc.toPlainText()`.
  - Conflict resolution shows a read-only Quill editor to display formatting without allowing edits.
- **Voice Notes**:
  - Stored as `NoteAttachment` entries referencing local file paths.
  - Synced to Google Drive (best-effort) with a reference ID in the attachment model.

## 9.5 Habits

### Habits Architecture

**Key files:**

- Models: [`lib/features/habits/models/habit.dart`](lib/features/habits/models/habit.dart), [`lib/features/habits/models/habit_log.dart`](lib/features/habits/models/habit_log.dart)
- Controller: [`lib/features/habits/controllers/habit_controller.dart`](lib/features/habits/controllers/habit_controller.dart)
- UI: [`lib/features/habits/views/habits_screen.dart`](lib/features/habits/views/habits_screen.dart), [`habit_details_screen.dart`](lib/features/habits/views/habit_details_screen.dart)
- Widgets:
  - [`lib/features/habits/views/widgets/habit_card.dart`](lib/features/habits/views/widgets/habit_card.dart): Styled habit card with keyword-based icon/color mapping.

### How streaks work

- Each completion is a `HabitLog` keyed by local `YYYY-MM-DD`.
- Streak is computed by counting consecutive completed days back from today.

## 9.6 Analytics

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

## 9.7 Calendar

### Calendar Architecture

**Key files:**

- Controller: [`lib/features/calendar/controllers/calendar_controller.dart`](lib/features/calendar/controllers/calendar_controller.dart)
- UI: [`lib/features/calendar/views/calendar_screen.dart`](lib/features/calendar/views/calendar_screen.dart)
- Device calendar wrapper: [`lib/core/services/platform/device_calendar_service.dart`](lib/core/services/platform/device_calendar_service.dart)

Calendar overlays tasks (due dates) and reminders (scheduled times).

## 9.8 Settings

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

## 9.9 Theme Customization ([`lib/features/theme_customization/`](lib/features/theme_customization/))

Manages the app's visual style, including dynamic color generation.

**Key files**:

- [`lib/features/theme_customization/views/theme_customization_screen.dart`](lib/features/theme_customization/views/theme_customization_screen.dart): UI for selecting colors/modes.
- [`lib/app/theme/app_theme.dart`](lib/app/theme/app_theme.dart): Defines light/dark theme data.

## 10. Testing + CI

### Tests

Tests live in [`test/`](test/) and can be run with:

```bash
flutter test
```

### CI

GitHub Actions workflow is at [`.github/workflows/flutter.yml`](.github/workflows/flutter.yml):

- `flutter pub get; flutter analyze; flutter test`

## 11. Contributor workflow

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

## 12. Deep architecture & implementation guide

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

## 12.1 Background services deep dive

### Connectivity monitoring

- **Files to know**:
  - [`lib/core/services/platform/connectivity_service.dart`](lib/core/services/platform/connectivity_service.dart)
  - [`lib/core/services/platform/backend_health_checker.dart`](lib/core/services/platform/backend_health_checker.dart)
  - [`lib/core/services/connectivity_monitor_service.dart`](lib/core/services/connectivity_monitor_service.dart)
- **Responsibilities**:
  - Track whether the device appears online/offline.
  - Provide a higher-level "is the backend ecosystem healthy?" status (Firebase, Drive, local storage checks).
  - Surface connectivity issues via global snackbars so all features benefit.

### Notifications & Workmanager (Deep Dive)

The notification system is critical for reminders. Because Android aggressively kills background apps (especially on Samsung/MIUI devices), we use a **hybrid reliability strategy** with three layers of redundancy.

#### Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                           NOTIFICATION SYSTEM                                │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────┐   ┌─────────────────────┐   ┌───────────────────┐  │
│  │   Layer 1: Exact    │   │   Layer 2: Smart    │   │  Layer 3: Safety  │  │
│  │   (AlarmManager)    │   │   (In-App Timer)    │   │  (Workmanager)    │  │
│  └──────────┬──────────┘   └──────────┬──────────┘   └─────────┬─────────┘  │
│             │                         │                        │            │
│     zonedSchedule()           ReminderTimerService     workmanagerCallback  │
│   (OS-level alarm)         (Smart targeted timer)       (every ~15 min)     │
│             │                         │                        │            │
│             └─────────────────────────┼────────────────────────┘            │
│                                       ▼                                      │
│                          ┌─────────────────────────┐                        │
│                          │   NotificationService   │                        │
│                          │      showNow() or       │                        │
│                          │      schedule()         │                        │
│                          └─────────────────────────┘                        │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

#### The Three Layers Explained

| Layer | Trigger | Precision | When It Works | When It Fails |
|-------|---------|-----------|---------------|---------------|
| **1. Exact Alarm** | `zonedSchedule()` | Exact time | App running OR device allows background alarms | Samsung/Xiaomi kill the alarm, or exact alarm permission denied |
| **2. Smart Timer** | `ReminderTimerService` | Exact second | App is open in foreground | App is closed or killed |
| **3. Workmanager** | Periodic ~15min job | ±15 minutes | App terminated, device allows background work | Device in Doze mode, battery saver extreme |

**Why three layers?**

- Layer 1 is the ideal path but unreliable on aggressive OEMs.
- Layer 2 guarantees 100% accuracy while the user is in the app.
- Layer 3 is a "safety net" that catches anything missed by Layers 1-2.

#### Key Files

| File | Purpose | Line Reference |
|------|---------|----------------|
| [`notification_service.dart`](lib/core/services/notifications/notification_service.dart) | Core wrapper for `flutter_local_notifications`. Handles init, permissions, scheduling, and showing immediate notifications. | [Class:L10](lib/core/services/notifications/notification_service.dart#L10) |
| [`reminder_notifications.dart`](lib/core/services/notifications/reminder_notifications.dart) | Abstract interface for reminder-specific notification operations (`schedule`, `cancel`, `showNow`). | [L1-17](lib/core/services/notifications/reminder_notifications.dart#L1) |
| [`workmanager_dispatcher.dart`](lib/core/services/notifications/workmanager_dispatcher.dart) | Top-level callback that Workmanager invokes in the background. Bootstraps Hive, checks due reminders, fires notifications. | [L13](lib/core/services/notifications/workmanager_dispatcher.dart#L13) |
| [`reminder_timer_service.dart`](lib/features/reminders/services/reminder_timer_service.dart) | In-app Smart Timer service. Finds next due reminder, sleeps exactly until that time, fires, repeats. | [Class:L10](lib/features/reminders/services/reminder_timer_service.dart#L10) |

#### NotificationService Methods

| Method | Purpose | When Called |
|--------|---------|-------------|
| [`initialize()`](lib/core/services/notifications/notification_service.dart#L20) | Sets up plugin, notification channel, and timezone. | App startup (in `completeInitialization`) |
| [`requestPermissionsIfNeeded()`](lib/core/services/notifications/notification_service.dart#L46) | Requests notification + exact alarm permissions on Android. | After initialization |
| [`schedule()`](lib/core/services/notifications/notification_service.dart#L142) | Schedules a notification for a future time using `zonedSchedule`. | When user creates/updates a reminder |
| [`showNow()`](lib/core/services/notifications/notification_service.dart#L111) | Shows an immediate notification. | Timer service fires, or Workmanager catches a due reminder |
| [`cancel()`](lib/core/services/notifications/notification_service.dart#L194) | Cancels a scheduled notification by ID. | When reminder is deleted or completed |

#### Smart Timer Strategy (ReminderTimerService)

The [`ReminderTimerService`](lib/features/reminders/services/reminder_timer_service.dart#L10) uses a **Smart Targeted Timer** approach instead of polling:

```dart
// Instead of polling every 30 seconds (wastes CPU)...
// We calculate exactly when the next reminder is due:

void scheduleNextCheck() {
  final activeReminders = _repo.getAll().where(...).toList();
  activeReminders.sort((a, b) => a.time.compareTo(b.time));
  
  final nextReminder = activeReminders.firstWhere((r) => r.time.isAfter(now));
  final waitDuration = nextReminder.time.difference(now);
  
  _smartTimer = Timer(waitDuration, () {
    _fireImmediate(nextReminder);
    scheduleNextCheck(); // Recursively schedule next
  });
}
```

**Benefits:**

- **0% CPU usage** while waiting (timer is dormant)
- **100% time precision** (fires on the exact second)
- Must be reset whenever reminders are created/updated/deleted

#### Workmanager Background Flow

When the OS kills the app, Workmanager runs periodically (~15 min minimum on Android) as a safety net:

```
workmanagerCallbackDispatcher() (top-level function)
    │
    ├─▶ 1. WidgetsFlutterBinding.ensureInitialized()
    │
    ├─▶ 2. NotificationService().initialize()
    │
    ├─▶ 3. Hive.init() + registerAdapter(ReminderAdapter)
    │
    ├─▶ 4. Hive.openBox<Reminder>(HiveBoxes.reminders)
    │
    └─▶ 5. handleBackgroundCheck()
            │
            ├─▶ Query: Incomplete reminders due within last 46 min
            │
            └─▶ For each: notifications.showNow()
```

**Spam Prevention:** We only fire notifications for reminders due within the last 46 minutes. This prevents Workmanager from nagging about very old missed reminders every 15 minutes.

#### Android Permission Considerations

| Permission | Required For | How to Request |
|------------|--------------|----------------|
| `POST_NOTIFICATIONS` | Showing any notification (Android 13+) | `requestNotificationsPermission()` |
| `SCHEDULE_EXACT_ALARM` | Using exact timing with `zonedSchedule` (Android 12+) | `requestExactAlarmsPermission()` or prompt user to Settings |

If exact alarm permission is denied, the service falls back to `AndroidScheduleMode.inexactAllowWhileIdle`, which may have slight timing variations but still works.

#### Initialization Sequence

```
main.dart
    │
    └─▶ AppInitializer.completeInitialization()
            │
            ├─▶ NotificationService().initialize()
            │       ├─▶ _plugin.initialize()
            │       ├─▶ tz.initializeTimeZones()
            │       └─▶ tz.setLocalLocation(userTimezone)
            │
            ├─▶ Workmanager().initialize(workmanagerCallbackDispatcher)
            │
            └─▶ Workmanager().registerPeriodicTask('reminder_check', ...)
```

### Storage & Google Drive

- **Local-first**:
  - All attachments are written to a deterministic local path (e.g. by feature and date).
  - Entities keep both a local path and optional Drive ID.
- **Drive sync**:
  - Uploads happen via a facade (`GoogleDriveService`) that hides Drive API details.
  - Authentication state is handled separately ([`lib/core/services/storage/drive_auth_store.dart`](lib/core/services/storage/drive_auth_store.dart) and [`lib/core/services/storage/google_drive_auth.dart`](lib/core/services/storage/google_drive_auth.dart)).
  - Failed uploads should never block core functionality; they only affect cloud availability.

## 12.2 Feature deep dives

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
  - The editor and supporting services (specifically `NoteEmbedService`) are responsible for:
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

## 12.3 How to implement common changes

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

## 12.4 Coding style & project conventions

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

## 12.5 Glossary (quick reference)

- **Hive**: Local key-value store used as the app’s primary source of truth.
- **SyncOperation**: A queued instruction describing what needs to be synchronized with Firestore.
- **Controller**: `ChangeNotifier`-based class that owns business logic and exposes state to the UI.
- **Repository**: Abstraction over data access (Hive, Firestore, Drive) for a given feature.
- **Service**: Cross-cutting infrastructure (notifications, connectivity, storage, debug logging, etc.).
- **Attachment**: Any non-text asset (image, audio, file) associated with a Task or Note.
- **Background service**: Long-lived object outside of widget tree that listens to system/app events and reacts (e.g. connectivity monitor).
