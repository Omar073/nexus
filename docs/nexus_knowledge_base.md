# Nexus — Project Knowledge Base

> **Purpose:** Read this at the start of a session to orient yourself in the codebase. This document is a **high-level technical traversal**: tech stack, dependencies, project structure, major subsystems, and how they connect. It is not the implementation-level walkthrough.
>
> **Last updated:** 2026-04-05

---

## Documentation boundaries

| Document | Audience | Depth | Purpose |
|----------|----------|-------|---------|
| `README.md` | End users / product readers | Low | User-facing overview of app idea and features. |
| `docs/nexus_knowledge_base.md` (this file) | Engineers and AI assistants | Medium | System orientation: architecture map, tooling, dependencies, routing/storage/sync overview. |
| `developer_README.md` | Engineers implementing changes | High | Deep technical walkthrough and reference for implementation details and contributor workflow. |

This file focuses on **what exists and how parts relate**. For detailed coding
guidance, feature implementation nuance, and operational procedures, use
`developer_README.md`.

---

## Quick reference

| Key | Value |
|-----|-------|
| **Stack** | Flutter (stable; pinned in `.github/workflows/ci.yml`), Dart 3.10+, Firebase (core + Firestore for sync) |
| **Architecture** | Feature-first layout with Clean Architecture **layers** inside each feature (`domain` / `data` / `presentation`) |
| **DI** | `provider`: `Provider` and `ChangeNotifierProvider`, composed at startup via `AppProviderFactory` |
| **Routing** | `go_router`: `lib/app/router/app_router.dart`, path constants in `lib/app/router/app_routes.dart` |
| **State in UI** | `ChangeNotifier` controllers under each feature’s `presentation/state_management/` plus feature-local presentation state in `presentation/state/` and interaction helpers in `presentation/logic/` |
| **Local persistence** | **Hive** typed boxes per domain area; **SharedPreferences** for user settings via `SettingsStore` |
| **Remote sync** | Firestore + offline-first queue (`HiveBoxes.syncOps`) processed by `SyncService` |
| **Domain vs data** | Domain **entities** are plain Dart; **Hive** models and mappers live in `data/` |
| **Localization** | `flutter_localizations` + **`FlutterQuillLocalizations`** (Quill toolbar requires the delegate; registered in **`lib/main.dart`** and **`lib/app/app.dart`**) |
| **CI** | GitHub Actions: `.github/workflows/ci.yml` (analyze, test; see file for exact steps) |

---

## Table of contents

- [Documentation boundaries](#documentation-boundaries)
- [Quick reference](#quick-reference)
- [1. How the app boots and where the shell lives](#1-how-the-app-boots-and-where-the-shell-lives)
  - [1.1 Entry: `lib/main.dart`](#11-entry-libmaindart)
  - [1.2 Splash: `lib/features/splash/`](#12-splash-libfeaturessplash)
  - [1.3 Main UI: `lib/app/app.dart`](#13-main-ui-libappappdart)
- [2. Repository layout: `lib/` at a glance](#2-repository-layout-lib-at-a-glance)
- [3. Clean Architecture within a feature](#3-clean-architecture-within-a-feature)
- [4. Services and backends (what talks to what)](#4-services-and-backends-what-talks-to-what)
- [5. Routes and navigation](#5-routes-and-navigation)
- [6. Domain entities (what “business objects” exist)](#6-domain-entities-what-business-objects-exist)
  - [6.3 Firestore entity layout (what exists in Firebase)](#63-firestore-entity-layout-what-exists-in-firebase)
- [7. Local storage: Hive boxes and settings](#7-local-storage-hive-boxes-and-settings)
- [8. CI/CD](#8-cicd)
- [9. Dependencies (families, not a full lockfile)](#9-dependencies-families-not-a-full-lockfile)
- [10. Tests (where to look)](#10-tests-where-to-look)
- [Related documentation](#related-documentation)

---

## 1. How the app boots and where the shell lives

### 1.1 Entry: `lib/main.dart`

The process starts with a **small** `MaterialApp` that does not use `GoRouter` yet. Its job is to show the splash immediately, apply base **`AppTheme`**, and—critically—register **localization delegates**, including **`FlutterQuillLocalizations.delegate`**. Anything later pushed on the **root** navigator (for example the full-screen note editor) still sits under this outer `MaterialApp` until popped, so Quill’s toolbar must find those delegates here.

### 1.2 Splash: `lib/features/splash/`

**`SplashWrapper`** (`presentation/pages/splash_wrapper.dart`) orchestrates **critical initialization** (Firebase, Hive, etc. via `AppInitializer` and related bootstrap code). When that work finishes, it builds a **`MultiProvider`** tree and mounts the real app shell as **`App`** (`lib/app/app.dart`).

**`AppProviderFactory`** (`presentation/bootstrap/provider_factory.dart`) is the composition root for **repository interfaces** and **controllers**. You add new app-wide services or repositories here when they must exist for the whole tree.

Splash also has **`presentation/models/`** for startup result types (e.g. `CriticalInitializationResult`, `AppInitializationResult`) that describe what got wired so the provider list can be built safely.

### 1.3 Main UI: `lib/app/app.dart`

**`App`** is a **`MaterialApp.router`** tied to a single **`GoRouter`** instance created in `AppRouter.create()`. Theme comes from **`SettingsController`** (light/dark/custom colors, nav bar style). The same **localization delegates** as `main.dart` appear again so the router subtree stays consistent.

**`App`** uses a **`builder`** to wrap the routed child with **`AnimatedTheme`** and **`wrapWithOverlays`** (`lib/app/services/app_services_composer.dart`), which currently layers things like the **global debug overlay** and can grow with more cross-cutting UI.

**Background hooks:** `initializeBackgroundServices` / `disposeBackgroundServices` in `app_services_composer.dart` start or tear down long-lived helpers (for example connectivity monitoring) after the widget tree can `read` services.

---

## 2. Repository layout: `lib/` at a glance

High-level **directory tree** of `lib/` (names only). Subsections **2.1–2.3** explain what each area is for. The repo also has top-level folders such as **`docs/`**, **`test/`**, **`scripts/`**, and **`assets/`** beside `lib/`.

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── app_globals.dart
│   ├── router/
│   ├── services/
│   └── theme/
├── app_secrets/
├── core/
│   ├── data/
│   ├── services/
│   │   ├── sync/
│   │   ├── note_embed_service.dart
│   │   ├── connectivity_monitor_service.dart
│   │   ├── platform/
│   │   ├── storage/
│   │   ├── notifications/
│   │   └── debug/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── analytics/
│   ├── calendar/
│   ├── categories/
│   ├── dashboard/
│   ├── habits/
│   ├── notes/
│   ├── reminders/
│   ├── settings/
│   ├── splash/
│   ├── sync/
│   ├── task_editor/
│   ├── tasks/
│   ├── theme_customization/
│   └── wrapper/
└── firebase_setup/
```

### 2.1 `lib/app/`

Application shell concerns that are **not** one feature: **routing**, **theme** (`theme/`), **global keys** (`app_globals.dart`), and **app-level composition** (`app.dart`, `services/`). This is the first place to look for “how does navigation work?” and “where is the theme decided?”.

### 2.2 `lib/core/`

Shared infrastructure **used by multiple features**:

- **`core/data/`** — Hive box names, type IDs, sync queue types and adapters, anything that is “the database shape” without belonging to a single feature.
- **`core/services/`** — Cross-cutting services: **`SyncService`** (queue processor), **storage** (Google Drive, paths), **notifications** (`NotificationService`, `battery_optimization_first_launch_prompt` for one-time Android exemption flow, `battery_optimization_dialog` for the explanation UI), **platform** (connectivity, health checks), **debug** logging, **`note_embed_service`** (voice attach/playback helpers for notes), **`connectivity_monitor_service`**, etc.
- **`core/utils/`** — Shared non-UI logic (conflict helpers, backoff, etc.).
- **`core/widgets/`** — Reusable UI such as **`NexusCard`**, debug overlays, shared snackbars, and shared pickers (for example `time_picker/nexus_time_picker.dart` used by reminders and task due-time flows).

Think of **`core/`** as “platform and plumbing”; think of **`features/`** as “product areas”.

### 2.3 `lib/features/` — product areas (one folder per area)

Each folder is a **vertical slice** of the product. Most slices follow **`domain/`**, **`data/`**, **`presentation/`** (see §3). Names map roughly to UI:

| Folder | Role in the product |
|--------|---------------------|
| **`wrapper/`** | **`AppWrapper`**: scaffold, **drawer**, **bottom navigation** (`NavBarBuilder`), keeps the tab **PageView** aligned with `StatefulNavigationShell`. |
| **`dashboard/`** | Home / overview hub. |
| **`tasks/`** | Task list, filters, task tiles, conflict UI for tasks. |
| **`task_editor/`** | Task create/edit experience (fields, categories, attachments). |
| **`reminders/`** | Reminder list and scheduling; ties to local notifications and timers. |
| **`notes/`** | Notes list, **note editor** (Quill + Markdown paths), attachments, voice sections, category selection in editor. |
| **`categories/`** | Hive **`Category`** model and **`CategoryController`** for hierarchical categories (tasks and note UI consume it). |
| **`habits/`** | Habit definitions, logs, charts. |
| **`calendar/`** | Calendar aggregation and device calendar hooks. |
| **`analytics/`** | Dashboard-style stats and charts. |
| **`settings/`** | Settings screens, **`SettingsController`**, repository for **`AppSettingsEntity`**, prefs via **`SettingsStore`**. Debug-only **Developer options** (`kDebugMode`) for local test hooks; root push re-wraps **`NotificationService`** only. |
| **`theme_customization/`** | Theme and nav bar customization screens (often pushed with provider re-wrap patterns similar to the note editor). |
| **`sync/`** | Sync status widgets and entry points into conflict flows (domain-specific dialogs often live on tasks/notes). |
| **`splash/`** | Startup, **`AppInitializer`**, **`AppProviderFactory`**. |

**`lib/firebase_setup/`** holds Firebase key templates. Repo-root **`docs/`** holds this file and other architecture notes.

---

## 3. Clean Architecture within a feature

Nexus does not use a single global `domain/` folder. Instead, **each feature** that follows the pattern owns its own three layers. That keeps tasks, notes, and reminders independent and avoids a monolithic domain package.

### 3.1 The three layers (what each is for)

**`domain/`** is the **innermost** layer: pure Dart, no Flutter widgets, no Hive, no Firestore types. It holds:

- **`entities/`** — Immutable (or clearly bounded) **business objects** such as `TaskEntity`, `NoteEntity`, `HabitEntity`, `ReminderEntity`, `AppSettingsEntity`.
- **`repositories/`** — **Interfaces only**, named `*RepositoryInterface`. They describe *what* the app can do with data, not *how* it is stored.
- **`use_cases/`** — One class per meaningful operation (`SaveNoteUseCase`, `CreateTaskUseCase`, …). Use cases depend on repository **interfaces** and entity types.
  - Include conflict/restore operations when they contain business orchestration (for example task/note conflict keep-local/keep-remote and restore flows).
- **Shared domain files** — Enums and value objects (`task_sort_option.dart`, `category_sort_option.dart`, …).

**`data/`** is the **middle** layer: how persistence and sync actually work.

- **`models/`** — Hive **`@HiveType`** models, JSON shapes, and non-Hive stores like **`SettingsStore`** / **`CustomColorsStore`** (backed by **SharedPreferences** for settings).
- **`mappers/`** — Translate **entity ↔ model** (`TaskMapper`, …).
- **`data_sources/`** — Low-level reads/writes to Hive boxes and similar stores.
- **`repositories/`** — **`SomethingRepositoryImpl`** classes that **implement** the domain interfaces. They orchestrate datasources and mappers. This is where **Hive box names** and **Firestore document shapes** are allowed to live.
- **`sync/`** — Feature-specific **sync handlers** (e.g. `TaskSyncHandler`, `NoteSyncHandler`) invoked by the central **`SyncService`**.
- **`services/`** — Feature infrastructure (e.g. reminder timers, Workmanager entrypoints for reminders).

**`presentation/`** is the **outer** layer: Flutter UI and **controller** state.

- **`state_management/`** — `ChangeNotifier` **controllers** (`TaskController`, `NoteController`, …). They subscribe to repositories (via interfaces), expose lists and filters to widgets, and call use cases. They should not embed raw Hive calls or sync-operation orchestration.
- **`pages/`** — Route-level screens (`TasksScreen`, `NotesListScreen`, …).
- **`widgets/`** — Everything from list tiles to dialogs to the **note editor** subtree (`presentation/widgets/editor/...`).
- **`utils/`** — Formatting and UI helpers.
- **`extensions/`** — `TaskEntity`-style extensions for display.

**Exception:** **`Category`** is often used as a **Hive model** with **`CategoryController`** without a separate `CategoryEntity` file; the categories feature still fits the same *idea* (model + controller + UI), but the domain folder may be thinner. Prefer reading that feature’s `data/` and `presentation/` when touching categories.

### 3.2 Why repository interfaces?

- **Domain** and **use cases** depend on **interfaces** → easy to **fake** in tests.
- **Data** supplies **implementations** → swapping storage means editing **`data/`** only.
- **Presentation** asks `Provider` for **`TaskRepositoryInterface`**, not `TaskRepositoryImpl`, so the UI stays decoupled from Hive/Firestore.

### 3.3 State management and accessing controllers

Widgets obtain controllers with **`context.watch<T>()`** (rebuild when state changes) or **`context.read<T>()`** (one-shot actions). Registration happens in **`AppProviderFactory`** for types that are global to the post-splash app.

### 3.4 Sync (high-level flow)

1. User actions persist **locally first** (Hive / prefs).
2. Outbound changes enqueue **`SyncOperation`** rows in **`HiveBoxes.syncOps`**.
3. **`SyncService`** (`lib/core/services/sync/sync_service.dart`) drains the queue when connectivity allows, delegating entity-specific work to **feature sync handlers**.
4. Conflicts surface in **feature UI** (task vs note dialogs) and from **sync status** widgets under **`lib/features/sync/`**.

### 3.5 Routing model

- **`StatefulShellRoute`** hosts the **bottom tabs** (dashboard, tasks, reminders, notes, settings). **`AppWrapper`** provides drawer + `PageView`-style tab body + **`NavBarBuilder`** (style from settings).
- **Drawer destinations** (habits, calendar, analytics) are **separate** `GoRoute`s on the same router.
- **`rootNavigatorKey`** (in `app_router.dart`) allows **full-screen** routes **above** the tab bar—used for the **note editor** and similar flows.

### 3.6 Note editor and provider scope

Opening a note uses **`NoteEditorScreen.push`**, which pushes on the **root** navigator. Root-navigator screens can sit outside the shell provider scope, so this flow uses **`NoteEditorScreen.wrapWithRequiredProviders`** to ensure required dependencies are available and the route keeps the app theme/localization context.

Editor UI lives under **`lib/features/notes/presentation/widgets/editor/`** (`NoteEditorView`, app bar, body, overflow menu, voice widgets, dialogs). Product behavior (Markdown vs rich text, voice section, category under title, toolbar position) is implemented there; this knowledge base does not duplicate every widget name.

For implementation-level details of sync internals and note-editor edge cases, use
`developer_README.md` feature deep dives.

---

## 4. Services and backends (what talks to what)

| Concern | Technology | Role in Nexus |
|---------|------------|----------------|
| **Google identity for APIs** | `google_sign_in` | Access to **Google Drive** and related APIs for attachments/backups—not a full first-party “Nexus account” system. |
| **Remote documents** | Cloud Firestore | **Sync** target for entities that have handlers; not the primary UI data source (Hive is). |
| **Local database** | Hive | **Source of truth** on device: tasks, notes, habits, reminders, categories, sync queue, metadata. |
| **User preferences** | SharedPreferences | Theme mode, nav bar style, retention, etc., via **`SettingsStore`**. |
| **Files / Drive** | `googleapis` + app storage paths | Upload/download for attachments where implemented. |
| **Reminders** | `flutter_local_notifications`, alarms, Workmanager | Schedule and fire notifications; feature code coordinates with **`ReminderController`**. Android manifest declares `ScheduledNotificationReceiver` (fires alarms when app is closed) and `ScheduledNotificationBootReceiver` (reschedules after reboot), and requests battery-optimization exemption (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`) to survive Doze. |

---

## 5. Routes and navigation

Paths are defined in **`AppRoute`** (`lib/app/router/app_routes.dart`) and registered in **`AppRouter.create()`**.

| Path | Screen | Placement |
|------|--------|-----------|
| `/dashboard` | `DashboardScreen` | Bottom shell |
| `/tasks` | `TasksScreen` | Bottom shell |
| `/reminders` | `RemindersScreen` | Bottom shell |
| `/notes` | `NotesListScreen` | Bottom shell |
| `/settings` | `SettingsScreen` | Bottom shell |
| `/habits` | `HabitsScreen` | Outside shell (drawer) |
| `/calendar` | `CalendarScreen` | Outside shell (drawer) |
| `/analytics` | `AnalyticsScreen` | Outside shell (drawer) |

The **note editor** has **no** dedicated GoRoute path: it is opened with **`Navigator.push`** via **`NoteEditorScreen.push`**, full-screen over the shell.

---

## 6. Domain entities (what “business objects” exist)

Core entities live under each feature’s **`domain/entities/`** (pure Dart; no Hive / Firestore imports). Data-layer persistence is implemented with **Hive models** under each feature’s `data/models/`, plus `toFirestoreJson()` / `fromFirestoreJson()` helpers for synced entities.

### 6.1 Layering: Entity vs Hive model vs Firestore JSON

- **Domain entity (`domain/entities/`)**
  - **Used by**: use cases + controllers (business logic and UI state).
  - **Shape**: plain Dart; keeps the app independent of storage.
- **Hive model (`data/models/`)**
  - **Used by**: repositories and datasources; stored in Hive boxes.
  - **Shape**: `@HiveType` + `@HiveField(...)`, plus sync metadata fields.
- **Firestore JSON (`toFirestoreJson` / `fromFirestoreJson`)**
  - **Used by**: sync handlers (`data/sync/*_sync_handler.dart`) invoked by `SyncService`.
  - **Shape**: `Map<String, dynamic>` with Firestore `Timestamp` values for date fields.

### 6.2 Common entity fields (sync-aware entities)

Most synced entities follow the same conventions in their Hive models:

- **`id`**: string UUID (also used as Firestore document id).
- **`createdAt` / `updatedAt`**: `DateTime` locally; `Timestamp` on Firestore. `updatedAt` is the incremental pull cursor (`where('updatedAt', isGreaterThan: lastSyncAt)`).
- **`isDirty`**: local-unsynced flag. Local writes set this to true and enqueue a `SyncOperation`.
- **`lastSyncedAt`**: last time the row was successfully synced.
- **`syncStatus`**: enum index (`idle` / `syncing` / `synced` / `conflict`).
- **`lastModifiedByDevice`** (tasks + notes): best-effort tracing/debugging aid; written to Firestore on push.

Feature-specific fields live alongside these (e.g. task due date, note content, reminder schedule).

### 6.3 Firestore entity layout (what exists in Firebase)

Firestore is used as the remote sync target (Hive remains the local source of truth). The app currently uses **top-level collections** (no per-user namespace), and document ids match entity ids:

| Entity type | Firestore collection | Local Hive model | Notes |
|------------|----------------------|------------------|-------|
| `task` | `tasks/{taskId}` | `Task` | Conflict detection supported via `TaskConflictDetector`. |
| `note` | `notes/{noteId}` | `Note` | Conflict detection supported via `NoteConflictDetector`. |
| `reminder` | `reminders/{reminderId}` | `Reminder` | Conflict detection supported via `ReminderConflictDetector`. Includes `notifiedAt` to prevent duplicate re-fires. |
| `habit` | `habits/{habitId}` | `Habit` | Currently “remote wins” on pull (no conflict UI surfaced yet). |

**Local-only entities (not on Firestore):**

- **`Category`**: stored in Hive (`HiveBoxes.categories`) and managed via `CategoryController`. There is no `categories/` Firestore collection today, so category structure is not restored on reinstall unless exported/imported.

---

## 7. Local storage: Hive boxes and settings

**Box names** are centralized in **`lib/core/data/hive/hive_boxes.dart`** and opened during bootstrap (**`lib/app/bootstrap/hive_bootstrap.dart`**):

- **`tasks`**, **`categories`**, **`reminders`**, **`notes`**, **`habits`**, **`habit_logs`**
- **`sync_ops`** — outbound sync queue
- **`sync_metadata`** — bookkeeping for sync state

**Settings** are **not** a Hive box named `settings`. They use **`SharedPreferences`** through **`SettingsStore`** (`lib/features/settings/data/models/settings_store.dart`) and map into domain settings via the settings repository.

---

## 8. CI/CD

**`.github/workflows/ci.yml`** runs on **`main`** pushes and PRs: Flutter setup (version pinned in the workflow), `flutter pub get`, placeholder secrets and assets, **`dart fix --apply`**, **`dart format`**, **`flutter analyze`**, **`flutter test`**, and optional coverage upload on PRs. For a local mirror, use **`scripts/run_ci_locally.ps1`** when present; **`scripts/run_ci_locally.ps1 -FormatFixAnalyze`** runs only **`dart fix`**, **`dart format`**, and **`flutter analyze`** (steps 5–7 of the full script).

---

## 9. Dependencies (families, not a full lockfile)

See **`pubspec.yaml`** for exact versions. Conceptual groupings:

- **State / DI:** `provider`
- **Navigation / shell:** `go_router`; bottom nav packages (`curved_labeled_navigation_bar`, `animated_notch_bottom_bar`, `google_nav_bar`, …)
- **Persistence / sync:** `hive`, `hive_flutter`, `cloud_firestore`, `shared_preferences`
- **Editor:** `flutter_quill`, `flutter_markdown`
- **Media:** `image_picker`, `record`, `audioplayers`
- **UI / charts / calendar:** `google_fonts`, `fl_chart`, `table_calendar`, `flutter_slidable`, `rive`
- **Platform:** `path_provider`, `permission_handler`, `workmanager`, `connectivity_plus`, …

---

## 10. Tests (where to look)

- **Unit** — e.g. `test/unit/sync/sync_service_test.dart` for queue behavior.
- **Widget** — e.g. `test/widget/notes/note_editor_screen_push_test.dart` for **root navigator + Provider** scope; `test/widget/screens/` for shell smoke tests.
- **Helpers** — `test/helpers/test_hive_all_boxes.dart` (and similar) to open multiple Hive boxes in tests.

---

## Related documentation

- **`README.md`** — Product-oriented overview for end users and readers.
- **`developer_README.md`** — Contributor guide, file-level maps, and deep dives.
- **`docs/CLEAN_ARCHITECTURE_MIGRATION.md`** — History and rationale for the domain/data/presentation split.
