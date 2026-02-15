# Nexus — Project Knowledge Base

> **Purpose:** Read this file at the start of any session to gain full project awareness without re-exploring the codebase.
> **Last updated:** 2026-02-15

---

## Quick Reference

| Key | Value |
|-----|-------|
| **Stack** | Flutter 3.10+, Dart, Firebase |
| **Architecture** | Feature-first MVC (Controllers + Provider) |
| **DI** | `Provider` (via `context.read`/`watch` and `AppProviderFactory`) |
| **Routing** | GoRouter (`lib/app/router/app_router.dart`) |
| **State** | `Provider` + `ChangeNotifier` (Controllers) |
| **Local Storage** | `Hive` (Entities) + `SharedPreferences` (Settings/Flags) |
| **Sync** | Offline-first via `SyncService` (Hive <-> Firestore) |
| **Entities** | `HiveType` annotated models (Task, Note, etc.) |
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

### Feature Structure

Every feature follows `features/<name>/`:

- **controllers/**: `XController` extends `ChangeNotifier`. Handles state & logic.
- **data/**: `XRepository` (abstracts data sources) and `XLocalDatasource`.
- **models/**: Data entities (often Hive annotated).
- **views/**: Screens and feature-specific widgets.

### State Management

- **Provider**: Used for Dependency Injection and State Propagation.
- **Controllers**: `TaskController`, `NoteController`, etc. manage state and call `notifyListeners()`.
- **Access**: `context.read<TaskController>()` or `context.watch<TaskController>()`.

### Dependency Injection

- **Setup**: `SplashWrapper` -> `AppProviderFactory` injects providers into `App`.
- **Services**: `SyncService`, `StorageService`, etc. are provided via `Provider` to Controllers.

### Sync Architecture

- **Offline-First**: Changes are written to Hive first.
- **SyncQueue**: Operations (Create/Update/Delete) are queued in `SyncOperation` Hive box.
- **SyncService**: Processes queue when online, pushing to Firebase/Google Drive.

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

- **Task**: Main entity. Has `title`, `status`, `recurrence`, `attachments`.
- **Note**: Rich text content (Quill Delta JSON).
- **Category**: Classification for tasks/notes.
- **SyncOperation**: Represents a pending sync action.
- **Settings**: User preferences (theme, sync enabled).

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
