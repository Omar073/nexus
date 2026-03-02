# Nexus — Project Knowledge Base

> **Purpose:** Read this file at the start of any session to gain full project awareness without re-exploring the codebase.
> **Last updated:** 2026-02-15

---

## Quick Reference

| Key | Value |
|-----|-------|
| **Stack** | Flutter 3.10+, Dart, Firebase |
| **Architecture** | Feature-first Clean Architecture (Domain / Data / Presentation) |
| **DI** | `Provider` (via `context.read`/`watch` and `AppProviderFactory`) |
| **Routing** | GoRouter (`lib/app/router/app_router.dart`) |
| **State** | `Provider` + `ChangeNotifier` (Controllers) |
| **Local Storage** | `Hive` (Data models/DTOs) + `SharedPreferences` (Settings/Flags) |
| **Sync** | Offline-first via `SyncService` (Hive <-> Firestore) |
| **Entities** | Pure Dart domain entities (no Hive) + `@HiveType` data models mapped via mappers |
| **Localization** | `flutter_localizations` + `FlutterQuillLocalizations` |
| **CI/CD** | GitHub Actions (`.github/workflows/ci.yml`) |

---

## 1. Directory Structure

```
lib/
├── main.dart                          # Entry point
├── app/
│   ├── app.dart                       # MaterialApp setup, Theme
│   ├── app_globals.dart               # Global keys
│   ├── router/                        # GoRouter config & Routes
│   ├── services/                      # App-level service composition
│   └── theme/                         # AppTheme & Colors
│
├── core/
│   ├── data/                          # Shared data components
│   │   ├── hive/                      # HiveBoxes, TypeIds
│   │   ├── device_id_store.dart       # Device ID persistence
│   │   ├── sync_metadata.dart         # Sync metadata
│   │   ├── sync_queue.dart            # Operation queue
│   │   └── sync_operation_adapter.dart
│   ├── services/                      # Core Services
│   │   ├── debug/                     # Logger
│   │   ├── notifications/             # Local Notifications
│   │   ├── platform/                  # Connectivity
│   │   ├── storage/                   # Drive, Hive, File
│   │   ├── sync/                      # SyncService
│   │   ├── connectivity_monitor_service.dart
│   │   └── note_embed_service.dart
│   ├── utils/                         # Helpers & Logic
│   │   ├── note_conflict_detector.dart
│   │   ├── sync_backoff.dart
│   │   ├── task_conflict_detector.dart
│   │   └── ...
│   └── widgets/                       # Shared UI
│       ├── debug/                     # GlobalDebugOverlay
│       ├── common_snackbar.dart
│       ├── nexus_card.dart
│       ├── habit_pill.dart
│       └── ...
│
├── features/                          # Feature modules
│   ├── analytics/
│   ├── calendar/
│   ├── dashboard/
│   ├── habits/
│   ├── notes/
│   ├── reminders/
│   ├── settings/
│   ├── splash/                        # Initialization
│   ├── sync/                          # Sync UI & Logic
│   ├── task_editor/                   # Task Creation/Editing
│   ├── tasks/
│   ├── theme_customization/           # Theme UI
│   └── wrapper/                       # App Shell
│
├── docs/                              # Project Documentation
└── firebase_setup/                    # Firebase Config
```

---

## 2. Key Patterns & Conventions

### Clean Architecture Layers

Every feature now follows a strict **Domain / Data / Presentation** structure under `lib/features/<name>/`:

- **`domain/`** (pure Dart, innermost layer)
  - `entities/`: Pure business objects, immutable, no Hive/Firestore/Flutter.  
    - Example: `TaskEntity`, `NoteEntity`, `HabitEntity`, `ReminderEntity`, `AppSettingsEntity`.
  - `repositories/`: **Interfaces only**, named `*RepositoryInterface`.  
    - Example: `TaskRepositoryInterface`, `NoteRepositoryInterface`, `HabitRepositoryInterface`, `ReminderRepositoryInterface`, `SettingsRepositoryInterface`.
  - `use_cases/`: One class per business operation (`CreateTaskUseCase`, `SaveNoteUseCase`, `ToggleHabitTodayUseCase`, `UpdateThemeModeUseCase`, etc.).
  - Root files: Domain enums and value objects (`task_enums.dart`, `task_sort_option.dart`, `category_sort_option.dart`).

- **`data/`** (infrastructure + persistence, middle layer)
  - `models/`: Persistence-aware DTOs (`@HiveType`, `@HiveField`, Hive adapters, Firestore JSON helpers).  
    - Examples: `Task`, `Note`, `Habit`, `Reminder`, `SettingsStore`, `CustomColorsStore`.
  - `mappers/`: Convert between domain entities and data models (e.g. `TaskMapper.toEntity()` / `TaskMapper.toModel()`).
  - `data_sources/`: Direct storage access (Hive boxes, local stores).  
    - Examples: `TaskLocalDatasource`, `NoteLocalDatasource`, `HabitLocalDatasource`, `ReminderLocalDatasource`.
  - `repositories/`: **Implementations** of domain interfaces, named `*RepositoryImpl`.  
    - Examples: `TaskRepositoryImpl implements TaskRepositoryInterface`, `NoteRepositoryImpl`, `HabitRepositoryImpl`, `ReminderRepositoryImpl`, `SettingsRepositoryImpl`.
    - These are the **only** classes that know about both domain and the underlying storage.
  - `sync/`: Feature-specific sync handlers (e.g. `TaskSyncHandler`, `NoteSyncHandler`).
  - `services/`: Infrastructure services like `ReminderTimerService`, `ReminderWorkmanagerCallback`.

- **`presentation/`** (UI + state, outermost layer)
  - `state_management/`: `ChangeNotifier`-based controllers (e.g. `TaskController`, `NoteController`, `HabitController`, `ReminderController`, `SettingsController`, `SyncController`, `AnalyticsController`, `CalendarController`).
    - Controllers hold **UI state only** and call domain use cases; they do not contain persistence logic.
  - `pages/`: Screens (e.g. `TasksScreen`, `NotesListScreen`, `RemindersScreen`, `HabitsScreen`, `SettingsScreen`, `DashboardScreen`, `CalendarScreen`, `AnalyticsScreen`).
  - `widgets/`: Feature-specific widgets (tiles, dialogs, sections, navigation drawers, detail sheets, etc.).
  - `utils/`: View-only helpers, such as date formatters and attachment picker helpers.
  - `extensions/`: Dart extensions to make entities easier to render (e.g. `TaskEntityExtensions`).
  - `bootstrap/` (splash only): Composition root that wires together repositories, use cases, controllers, and services (`AppInitializer`, `AppProviderFactory`).
  - `models/` (splash only): Startup result types (`AppInitializationResult`, `CriticalInitializationResult`) that aggregate controllers and services for the UI layer.

### Why interfaces and implementations for repositories?

- **Domain layer** declares interfaces like `TaskRepositoryInterface`, `NoteRepositoryInterface`, etc.  
  - These are pure contracts that talk in terms of domain entities (`TaskEntity`, `NoteEntity`, etc.).
  - Use cases depend on these interfaces only.
- **Data layer** provides concrete classes like `TaskRepositoryImpl`, `NoteRepositoryImpl`, etc.  
  - They implement the corresponding `*RepositoryInterface` and are wired to:
    - `data_sources/` (Hive/local storage) and
    - `mappers/` (entity ↔ model conversions).
  - They are the **only** place that knows about Hive, Firestore payloads, or any other storage detail.
- **Presentation layer** (controllers) receives the interface types via DI, never the `Impl` types directly.

This pattern lets us:

- Swap out storage (e.g. replace Hive with another DB) by changing only `data/` code.
- Unit-test use cases and controllers with simple in-memory fakes that implement `*RepositoryInterface`.
- Keep domain logic independent of frameworks and persistence details.

### State Management

- **Provider**: Used for Dependency Injection and State Propagation.
- **Controllers (Presentation layer)**:  
  - `TaskController`, `NoteController`, `HabitController`, `ReminderController`, `SettingsController`, etc. live under `presentation/state_management/`.  
  - They hold UI state (filters, loading flags, view models) and delegate business logic to **domain use cases**, which in turn depend on `*RepositoryInterface`.
- **Access**: `context.read<TaskController>()` or `context.watch<TaskController>()`.

### Dependency Injection

- **Setup**: `SplashWrapper` → `AppInitializer` (bootstrap) → `AppProviderFactory` registers:
  - `Provider<*RepositoryInterface>` for each feature repository.
  - `ChangeNotifierProvider` for each controller.
- **Services**: `SyncService`, `ConnectivityService`, `GoogleDriveService`, etc. are constructed in the splash bootstrap layer and injected where needed (usually into use cases or controllers).

### Sync Architecture

- **Offline-First**: Changes are written to Hive first.
- **SyncQueue**: Operations (Create/Update/Delete) are queued in `SyncOperation` Hive box.
- **SyncService**: Processes queue when online, pushing to Firebase/Google Drive.
- **Conflict resolution UI**: Conflict dialogs are feature-specific: `TaskConflictResolutionDialog` (`lib/features/tasks/presentation/widgets/task_conflict_resolution_dialog.dart`) for tasks, `NoteConflictResolutionDialog` (`lib/features/notes/presentation/widgets/note_conflict_resolution_dialog.dart`) for notes. Both are wired to the **Sync section** in Settings. When conflicts exist, a "Resolve conflicts" button appears that opens the appropriate dialog. Users can choose "Keep Local" (re-enqueues local as update) or "Keep Remote" (overwrites local with remote version). `SyncStatusWidget` (`lib/features/sync/presentation/widgets/sync_status_widget.dart`) is also available as a standalone widget for showing sync status and opening conflict dialogs.

### Routing

- **GoRouter**: Defined in `lib/app/router/app_router.dart`.
- **ShellRoute**: `AppWrapper` provides the persistent bottom navigation shell.

---

## 3. Services & Backend

| Service | Technology | Role |
|---------|------------|------|
| **Auth** | Google Sign-In (`google_sign_in`) | Drive Access Only (No User Auth) |
| **Database** | Firestore | Remote persistence for Sync |
| **Local DB** | Hive | Offline interactions & caching |
| **Drive** | Google Drive API (`googleapis`) | Backup/Sync for specific user data |
| **Notifications** | flutter_local_notifications | Local scheduled reminders |
| **Background** | Workmanager | Background sync & tasks |

> **Note:** The app currently does not have a user authentication layer (sign-up/sign-in). Google Sign-In is strictly used to authenticate with Google APIs for Drive storage (backups & attachments).

---

## 4. Routes

Defined in `AppRoute` enum (`lib/app/router/app_routes.dart`):

| Path | Screen | Feature |
|------|--------|---------|
| `/dashboard` | `DashboardScreen` | Dashboard |
| `/tasks` | `TasksScreen` | Tasks |
| `/reminders` | `RemindersScreen` | Reminders |
| `/notes` | `NotesListScreen` | Notes |
| `/settings` | `SettingsScreen` | Settings |
| `/habits` | `HabitsScreen` | Habits (Drawer) |
| `/calendar` | `CalendarScreen` | Calendar (Drawer) |
| `/analytics` | `AnalyticsScreen` | Analytics (Drawer) |

---

## 5. Key Domain Entities

> In the new architecture, **domain entities are pure Dart**, while persistence-specific details live in data models.

- **TaskEntity**: Main domain entity for tasks. Immutable; holds business fields like `title`, `status`, `recurringRule`, `attachments`, `createdAt`, `updatedAt`, `lastModifiedByDevice`. Mapped to the Hive `Task` model in `data/models/task.dart`.
- **NoteEntity**: Domain representation of notes (Quill Delta JSON, metadata). Mapped to `Note` in `data/models/note.dart`.
- **Category** (data model): Classification for tasks; categories feature uses the Hive model directly (no separate domain entity).
- **HabitEntity** / **HabitLogEntity**: Domain entities for habit tracking and individual logs.
- **ReminderEntity**: Domain entity for reminders with scheduling info.
- **AppSettingsEntity** / **ColorPresetEntity**: Domain entities for user settings and color presets.
- **SyncOperation** (in `core/data`): Represents queued sync actions (unchanged conceptually, but now consumed via repository/use case layers).

---

## 6. Local Storage (Hive Boxes)

- `tasks`
- `notes`
- `categories`
- `sync_ops` (Sync Queue)
- `settings` (or SharedPrefs)

---

## 7. CI/CD

### GitHub Actions (`.github/workflows/ci.yml`)

- Triggers on push/pull_request to `main`.
- **Jobs**:
  - **Setup**: Flutter environment.
  - **Secrets**: Generates placeholder `app_secrets.dart` & `apiKeys.dart`.
  - **Assets**: Generates placeholder icons.
  - **Formatting**: Runs `dart format` and pushes changes if needed.
  - **Analysis**: `flutter analyze`.
  - **Tests**: `flutter test`.
  - **Coverage**: Uploads to Codecov.

---

## 8. Dependencies (Key Packages)

- **State/DI**: `provider`.
- **Navigation**: `go_router`, `curved_labeled_navigation_bar`, `animated_notch_bottom_bar`.
- **Data**: `hive`, `hive_flutter`, `cloud_firestore`, `shared_preferences`.
- **Sync/Network**: `connectivity_plus`, `googleapis`, `http`.
- **UI/Content**: `flutter_quill`, `table_calendar`, `flutter_slidable`, `google_fonts`.
- **Platform**: `path_provider`, `device_calendar`, `permission_handler`, `workmanager`.
