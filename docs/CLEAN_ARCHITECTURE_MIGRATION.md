# Nexus Clean Architecture Migration — Complete Walkthrough

> This document covers every decision, step, and structural convention applied during the migration of Nexus from a flat feature-first MVC layout to feature-first **Clean Architecture**.

---

## Table of Contents

1. [Why We Migrated](#1-why-we-migrated)
2. [The Three Layers Explained](#2-the-three-layers-explained)
   - 2.1 Domain
   - 2.2 Data
   - 2.3 Presentation
3. [Subfolder Reference](#3-subfolder-reference)
4. [Domain Entities vs Data Models](#4-domain-entities-vs-data-models)
5. [Mappers — Bridging Domain and Data](#5-mappers--bridging-domain-and-data)
6. [Repositories — Interface and Implementation](#6-repositories--interface-and-implementation)
7. [Use Cases — Encapsulating Business Logic](#7-use-cases--encapsulating-business-logic)
8. [Presentation — State Management, Pages, Widgets](#8-presentation--state-management-pages-widgets)
9. [Special Cases and Edge Decisions](#9-special-cases-and-edge-decisions)
   - 9.1 Splash Bootstrap
   - 9.2 Sort Option Enums
   - 9.3 Presentation-Only Features
   - 9.4 Data Services (Reminders)
   - 9.5 Sync Handlers
10. [Migration Execution — Step by Step](#10-migration-execution--step-by-step)
11. [Before-and-After Structure Comparison](#11-before-and-after-structure-comparison)
12. [Import Updates and Verification](#12-import-updates-and-verification)
13. [Layer Dependency Rules](#13-layer-dependency-rules)
14. [Final Feature Structure Map](#14-final-feature-structure-map)
15. [Quality Gates](#15-quality-gates)

---

## 1. Why We Migrated

The original codebase used a flat feature-first MVC layout:

```
lib/features/<feature>/
  controllers/       ← business logic + UI state mixed together
  views/             ← screens, widgets
  models/            ← Hive models, DTOs, enums, and domain types all in one folder
  sync/              ← sync handlers
  utils/             ← helpers
```

**Problems with this layout:**

- **No separation of concerns**: Controllers contained business rules, sync logic, filtering, sorting, and UI state all tangled together.
- **Models were overloaded**: A single `models/` folder held Hive-annotated persistence classes, Firestore serialization logic, UI result types, enums, repositories, and local data sources — all mixed together.
- **Testing was difficult**: You couldn't test business logic in isolation because it was embedded in controllers that imported Flutter, Hive, and Firebase.
- **Dependency direction was unclear**: Any file could import any other file. There was no enforced layering.

**What Clean Architecture gives us:**

- **Testable domain logic**: Pure Dart entities and use cases with no framework dependencies.
- **Swappable infrastructure**: Repository interfaces in domain, implementations in data — swap Hive for SQLite without touching business rules.
- **Clear dependency direction**: domain ← data ← presentation. Inner layers never know about outer layers.
- **Feature-level encapsulation**: Each feature is a self-contained unit with well-defined internal structure.

---

## 2. The Three Layers Explained

Every feature in Nexus now contains up to three top-level folders, and **only** these folders may exist at the feature root:

### 2.1 Domain Layer (`domain/`)

The **innermost layer**. Contains the business rules and contracts of the application. Everything here is **pure Dart** — no Flutter, no Hive, no Firebase, no third-party framework dependencies.

**What lives here:**
- **Entities**: The core business objects (e.g., `TaskEntity`, `NoteEntity`). Immutable, plain Dart classes.
- **Repository interfaces**: Abstract classes defining what persistence operations exist (e.g., `TaskRepository`).
- **Use cases**: Single-responsibility classes that encapsulate one business operation (e.g., `CreateTaskUseCase`).
- **Domain enums and value objects**: Business-level enums like `TaskPriority`, `TaskStatus`, `TaskSortOption`.

**What does NOT live here:**
- Anything with `@HiveType`, `@HiveField`, `extends HiveObject`.
- Anything that imports `package:flutter/*`.
- Anything that imports `package:cloud_firestore/*`.
- Controllers, widgets, or UI-related code.

### 2.2 Data Layer (`data/`)

The **middle layer**. Implements the contracts defined in domain and handles all persistence, serialization, and external service integration.

**What lives here:**
- **Models (DTOs)**: Persistence-aware versions of domain entities. These have `@HiveType` annotations, `HiveAdapter` classes, `toFirestoreJson()` / `fromFirestoreJson()` methods. Example: `Task` (the Hive model) vs `TaskEntity` (the domain entity).
- **Mappers**: Pure functions that convert between domain entities and data models (e.g., `TaskMapper.toEntity(Task t)` and `TaskMapper.toModel(TaskEntity e)`).
- **Repository implementations**: Concrete classes that implement the abstract repository from domain (e.g., `TaskRepositoryImpl implements TaskRepository`).
- **Data sources**: Classes that directly interact with storage (Hive boxes, local file system). Example: `TaskLocalDatasource`.
- **Sync handlers**: Feature-specific sync logic (e.g., `TaskSyncHandler`) that knows how to push/pull entities to/from Firestore.
- **Data services**: Infrastructure services like `ReminderTimerService` (timers + Workmanager callbacks) that are purely about scheduling infrastructure, not UI.

**What does NOT live here:**
- Widgets, screens, or any Flutter UI code.
- Controllers or state management classes.

### 2.3 Presentation Layer (`presentation/`)

The **outermost layer**. Contains everything the user sees and interacts with, plus the state management that drives it.

**What lives here:**
- **State management**: `ChangeNotifier`-based controllers that hold UI state (loading, error, filtered lists) and delegate business operations to use cases. Example: `TaskController`.
- **Pages**: Full-screen widgets (e.g., `TasksScreen`, `HabitsScreen`).
- **Widgets**: Reusable UI components (tiles, dialogs, sections, navigation drawers).
- **Utils**: View-only utilities like date formatters, attachment picker helpers, sorting display helpers.
- **Bootstrap** (splash only): Composition root classes (`AppInitializer`, `AppProviderFactory`) that wire everything together at startup.
- **Presentation models** (splash only): Result types that aggregate controllers and services for the startup flow.

---

## 3. Subfolder Reference

Here is every subfolder we use and which layer it belongs to:

| Layer | Subfolder | Purpose | Example |
|-------|-----------|---------|---------|
| `domain/` | `entities/` | Pure Dart business objects | `TaskEntity`, etc. (categories uses data model directly) |
| `domain/` | `repositories/` | Abstract persistence contracts | `abstract class TaskRepositoryInterface` |
| `domain/` | `use_cases/` | Single-responsibility business operations | `CreateTaskUseCase`, `DeleteTaskUseCase` |
| `domain/` | *(root)* | Domain enums and value objects | `task_enums.dart`, `task_sort_option.dart` |
| `data/` | `models/` | Hive/Firestore-annotated DTOs | `Task extends HiveObject`, `Category` |
| `data/` | `mappers/` | Entity ↔ Model converters | `TaskMapper.toEntity()`, `TaskMapper.toModel()` |
| `data/` | `repositories/` | Concrete repository implementations | `TaskRepositoryImpl implements TaskRepositoryInterface` |
| `data/` | `data_sources/` | Direct storage access (Hive boxes) | `TaskLocalDatasource` |
| `data/` | `sync/` | Feature-specific Firestore sync logic | `TaskSyncHandler`, `NoteSyncHandler` |
| `data/` | `services/` | Infrastructure services (timers, background) | `ReminderTimerService` |
| `presentation/` | `state_management/` | `ChangeNotifier` controllers | `TaskController`, `CategoryController` |
| `presentation/` | `pages/` | Full-screen widgets | `TasksScreen`, `HabitsScreen` |
| `presentation/` | `widgets/` | Reusable UI components | `TaskItem`, `CategoryDrawer` |
| `presentation/` | `utils/` | View-only helpers | `TaskDateFormatter`, `AttachmentPickerUtils` |
| `presentation/` | `extensions/` | Dart extensions for UI display | `TaskEntityExtensions` |
| `presentation/` | `bootstrap/` | Composition root (splash only) | `AppInitializer`, `AppProviderFactory` |
| `presentation/` | `models/` | Startup result types (splash only) | `AppInitializationResult` |

---

## 4. Domain Entities vs Data Models

This is one of the most important distinctions in the architecture. They represent the **same concept** (a Task, a Note, a Habit) but serve fundamentally different purposes.

### Domain Entity (`TaskEntity`)

```dart
/// Domain entity for a task (pure Dart, no Hive).
class TaskEntity {
  const TaskEntity({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.lastModifiedByDevice,
    this.description,
    this.categoryId,
    // ...
  });

  final String id;
  final String title;
  final int status;
  final DateTime createdAt;
  // All fields are final (immutable)
}
```

**Characteristics:**
- **Immutable** (`final` fields, `const` constructor).
- **Pure Dart** — no imports from Hive, Firebase, Flutter, or any external package.
- **No serialization logic** — no `toJson()`, no `fromFirestoreJson()`, no `@HiveField`.
- **No persistence awareness** — doesn't know it's stored in Hive or synced to Firestore.
- **Lives in**: `domain/entities/`.

### Data Model (`Task`)

```dart
@HiveType(typeId: HiveTypeIds.task)
class Task extends HiveObject implements ConflictDetectable {
  Task({
    required this.id,
    required this.title,
    required this.status,
    // ...
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;  // mutable (Hive requirement)

  // Hive adapter, Firestore serialization, etc.

  Map<String, dynamic> toFirestoreJson() => { /* ... */ };
  static Task fromFirestoreJson(Map<String, dynamic> json) { /* ... */ }
}
```

**Characteristics:**
- **Mutable** where Hive requires it (fields without `final`).
- **Persistence-annotated** — `@HiveType`, `@HiveField`, `extends HiveObject`.
- **Serialization-aware** — contains `toFirestoreJson()`, `fromFirestoreJson()`, and a `TypeAdapter`.
- **Implements infrastructure interfaces** — like `ConflictDetectable` for sync.
- **Lives in**: `data/models/`.

### Why two classes for the same thing?

- **Testability**: Domain logic (use cases) can be tested with plain `TaskEntity` objects without setting up Hive boxes.
- **Framework independence**: If you replace Hive with SQLite, you only change the data model and mapper — domain stays untouched.
- **Immutability safety**: The domain entity guarantees immutability. The data model can be mutable as required by the persistence framework.

---

## 5. Mappers — Bridging Domain and Data

Mappers are **stateless utility classes** that convert between domain entities and data models. They live in `data/mappers/` because they know about both layers (they import both the entity and the model).

```dart
class TaskMapper {
  /// Convert a Hive data model to a domain entity.
  static TaskEntity toEntity(Task t) {
    return TaskEntity(
      id: t.id,
      title: t.title,
      description: t.description,
      // ... field-by-field mapping
    );
  }

  /// Convert a domain entity to a Hive data model.
  static Task toModel(TaskEntity e) {
    return Task(
      id: e.id,
      title: e.title,
      description: e.description,
      // ... field-by-field mapping
    );
  }
}
```

**Where they're used:**
- `TaskRepositoryImpl.getAll()` calls `TaskMapper.toEntity()` to convert Hive models before returning them.
- `TaskRepositoryImpl.upsert()` calls `TaskMapper.toModel()` to convert the domain entity before persisting it.

This ensures the **repository implementation is the only place** that deals with the conversion, and everything above it (use cases, controllers, UI) only ever touches domain entities.

---

## 6. Repositories — Interface and Implementation

### Abstract Repository (Domain)

```dart
/// Contract for task persistence (pure Dart).
abstract class TaskRepositoryInterface {
  List<TaskEntity> getAll();
  TaskEntity? getById(String id);
  Future<void> upsert(TaskEntity task);
  Future<void> delete(String id);
  Stream<void> get changes;
  Map<String, dynamic>? getSyncPayload(String id);
}
```

- Lives in `domain/repositories/`.
- References **only domain types** (`TaskEntity`).
- Has no knowledge of Hive, Firestore, or any storage mechanism.
- Use cases and controllers depend on this interface, not the implementation.
- Other features follow the same pattern (e.g. `NoteRepositoryInterface`, `HabitRepositoryInterface`, `ReminderRepositoryInterface`, `SettingsRepositoryInterface`).

### Concrete Repository (Data)

```dart
class TaskRepositoryImpl implements TaskRepositoryInterface {
  TaskRepositoryImpl({TaskLocalDatasource? local})
    : _local = local ?? TaskLocalDatasource() {
    _local.listenable().addListener(_onBoxChanged);
  }

  final TaskLocalDatasource _local;

  @override
  List<TaskEntity> getAll() =>
      _local.getAll().map(TaskMapper.toEntity).toList();

  @override
  Future<void> upsert(TaskEntity task) async {
    final model = TaskMapper.toModel(task);
    await _local.put(model);
  }
  // ...
}
```

- Lives in `data/repositories/`.
- Implements the domain interface (`TaskRepositoryInterface`).
- Uses a `data_sources/` class (`TaskLocalDatasource`) for direct Hive access.
- Uses a `mappers/` class (`TaskMapper`) to convert between `Task` (data model) and `TaskEntity` (domain entity).
- Is the **only** place that knows about the concrete storage mechanism (Hive boxes, Firestore payloads).

### Why interface + implementation?

This split between `TaskRepositoryInterface` (domain) and `TaskRepositoryImpl` (data) gives us:

- **Inversion of dependencies**: use cases depend on the *interface*, not on Hive or any concrete storage. The data layer points inward to domain, never the other way around.
- **Swap-friendly infrastructure**: if we ever move away from Hive (e.g. to SQLite), we only change `TaskRepositoryImpl` and `TaskLocalDatasource` (plus any models/mappers). All use cases, controllers, and UI remain untouched.
- **Testability**: unit tests for use cases can inject in-memory fake implementations of `TaskRepositoryInterface` without touching Hive or Firestore.
- **Consistent pattern across features**: notes, habits, reminders, and settings all follow the same `XRepositoryInterface` + `XRepositoryImpl` pattern, each wired to their own `data_sources/` and `mappers/`.

### Dependency Injection

The abstract `TaskRepositoryInterface` is what gets injected everywhere:

```dart
// In the composition root (AppInitializer):
final taskRepo = TaskRepositoryImpl();  // concrete implementation
final createTask = CreateTaskUseCase(taskRepo, syncService, deviceId: deviceId);
```

Use cases receive `TaskRepositoryInterface` (the interface), not `TaskRepositoryImpl` (the class).

---

## 7. Use Cases — Encapsulating Business Logic

Each use case is a **single-purpose class** with a `call()` method. It encapsulates one business operation and its side effects (like enqueueing a sync operation).

```dart
class CreateTaskUseCase {
  CreateTaskUseCase(this._repo, this._syncService, {required String deviceId})
    : _deviceId = deviceId;

  final TaskRepositoryInterface _repo;
  final SyncService _syncService;
  final String _deviceId;

  Future<TaskEntity> call({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    // ...
  }) async {
    final entity = TaskEntity(
      id: Uuid().v4(),
      title: title.trim(),
      status: TaskStatus.active.index,
      createdAt: DateTime.now(),
      // ...
    );
    await _repo.upsert(entity);
    await _enqueueSync(entity);
    return entity;
  }
}
```

**Key points:**
- Depends on **repository interfaces** (`TaskRepository`), not implementations.
- Lives in `domain/use_cases/`.
- Contains the **business rules** (validation, entity creation, sync enqueueing).
- Controllers call use cases; use cases call repositories.

---

## 8. Presentation — State Management, Pages, Widgets

### State Management (Controllers)

Controllers are **thin** `ChangeNotifier` classes. They:
- Hold UI state (loading flags, filter values, cached lists).
- Delegate all business operations to use cases.
- Call `notifyListeners()` to trigger UI rebuilds.

```dart
class TaskController extends ChangeNotifier {
  TaskController({
    required TaskRepository repo,
    required CreateTaskUseCase createTaskUseCase,
    required UpdateTaskUseCase updateTaskUseCase,
    // ...
  }) : _repo = repo,
       _createTask = createTaskUseCase,
       _updateTask = updateTaskUseCase;

  Future<void> addTask({required String title, ...}) async {
    await _createTask(title: title, ...);  // delegate to use case
    _refreshTasks();
    notifyListeners();
  }
}
```

### Pages

Full-screen `StatelessWidget` or `StatefulWidget` classes. They consume controllers via `Provider` and render the UI.

### Widgets

Reusable UI components: tiles, dialogs, sections, headers, navigation drawers. They receive data and callbacks; they don't contain business logic.

### Utils

View-only helpers that format dates for display, pick attachments from the device, or provide sorting display names. They never modify domain state.

---

## 9. Special Cases and Edge Decisions

### 9.1 Splash Bootstrap

`splash` is the **composition root** — the place where all dependencies are wired together at startup. It has a unique structure:

```
splash/presentation/
  bootstrap/          ← AppInitializer, AppProviderFactory
  models/             ← AppInitializationResult, CriticalInitializationResult
  pages/              ← SplashScreen, SplashWrapper
```

- `AppInitializer` and `AppProviderFactory` create concrete repositories, sync handlers, and controllers, then inject them into the Provider tree.
- `AppInitializationResult` and `CriticalInitializationResult` hold references to **controllers and services** (presentation-layer types), so they **must live in presentation**, not domain or data. Putting them in domain would create a domain → presentation dependency; putting them in data would create a data → presentation dependency. Both would violate the dependency rule.
- We named the folder `bootstrap/` instead of `state_management/` because these files are composition/wiring services, not `ChangeNotifier` controllers.

### 9.2 Sort Option Enums

`TaskSortOption` and `CategorySortOption` define **how domain entities are sorted** (newest first, alphabetical, by priority). They are domain-level enums, just like `TaskPriority` and `TaskStatus`, so they live in `domain/`:

```
tasks/domain/
  task_enums.dart            ← TaskPriority, TaskStatus, TaskDifficulty, etc.
  task_sort_option.dart      ← TaskSortOption enum
  category_sort_option.dart  ← CategorySortOption enum
```

They were initially placed in `presentation/models/` by mistake and later corrected.

### 9.3 Presentation-Only Features

Some features don't have domain or data layers because they aggregate data from other features rather than owning their own entities:

| Feature | Layers | Reason |
|---------|--------|--------|
| `analytics` | `presentation/` only | Reads from `TaskController`, `HabitController` — no own entities |
| `calendar` | `presentation/` only | Reads from `TaskController`, `ReminderController` |
| `dashboard` | `presentation/` only | Displays summaries from multiple features |
| `wrapper` | `presentation/` only | App shell, navigation bar, drawer |
| `task_editor` | `presentation/` only | UI-only editor that calls `TaskController` |
| `sync` | `presentation/` only | UI for sync status and conflict resolution |
| `theme_customization` | `presentation/` only | UI for customizing theme via `SettingsController` |

### 9.4 Data Services (Reminders)

`ReminderTimerService` and `ReminderWorkmanagerCallback` are **infrastructure services** that manage timers and background task scheduling. They live under `data/services/` because:
- They directly interact with platform APIs (Workmanager, timers).
- They access data sources (Hive boxes for reminders).
- They are not UI code and not domain logic.

### 9.5 Sync Handlers

`TaskSyncHandler` and `NoteSyncHandler` live under `data/sync/` within their respective features because:
- They contain Firestore-specific push/pull logic.
- They use data models (not domain entities) for serialization.
- They are registered at the composition root (`splash/presentation/bootstrap/`) and injected into `SyncService`.

---

## 10. Migration Execution — Step by Step

The migration was executed feature-by-feature in this order:

### Step 1: Audit existing structure
We compared every feature's current top-level folders against the target structure (`domain/`, `data/`, `presentation/` only). A compliance report was generated identifying all violations.

### Step 2: Create target directories
For each feature, we created the new directories:
```
mkdir domain/entities domain/repositories domain/use_cases
mkdir data/models data/mappers data/repositories data/data_sources
mkdir presentation/state_management presentation/pages presentation/widgets
```

### Step 3: Move files with `git mv`
Every file was moved using `git mv` to preserve Git history:

| Old Location | New Location |
|-------------|-------------|
| `controllers/*.dart` | `presentation/state_management/` |
| `views/*_screen.dart` | `presentation/pages/` |
| `views/widgets/` | `presentation/widgets/` |
| `views/utils/` | `presentation/utils/` |
| `models/<entity>.dart` | `data/models/` |
| `models/<entity>_local_datasource.dart` | `data/data_sources/` |
| `models/<entity>_repository.dart` | `data/repositories/` |
| `sync/*.dart` | `data/sync/` |
| `services/*.dart` | `data/services/` |
| `utils/<view_helper>.dart` | `presentation/utils/` |

### Step 4: Update all imports across the codebase
After moving files, every `.dart` file in `lib/` and `test/` that referenced an old import path was updated. We used PowerShell scripts to perform bulk string replacements:

```powershell
$replacements = @{
    "package:nexus/features/tasks/controllers/task_controller.dart" =
        "package:nexus/features/tasks/presentation/state_management/task_controller.dart"
    "package:nexus/features/tasks/models/task.dart" =
        "package:nexus/features/tasks/data/models/task.dart"
    # ... all old → new path mappings
}
```

### Step 5: Remove empty old directories
After all files were moved, the now-empty old directories (`controllers/`, `views/`, `models/`, `sync/`, `utils/`, `services/`) were deleted.

### Step 6: Verify
After each feature:
1. `flutter analyze` — zero issues.
2. `flutter test` — all tests pass.
3. Final full run of `.\scripts\run_ci_locally.ps1` — all 8 CI steps pass.

### Step 7: Update documentation
`REF_SYNC_ARCHITECTURE.md` and `REF_DEPENDENCY_INJECTION.md` were updated to reference the new file paths.

---

## 11. Before-and-After Structure Comparison

### Before (Tasks — flat MVC)

```
lib/features/tasks/
  controllers/
    task_controller.dart
    category_controller.dart
  views/
    tasks_screen.dart
    widgets/
      task_item.dart
      category_drawer.dart
      ...
    utils/
      ...
  models/
    task.dart
    category.dart
    task_attachment.dart
    task_local_datasource.dart
    task_repository.dart
    task_editor_result.dart
    task_sort_option.dart
    category_sort_option.dart
  sync/
    task_sync_handler.dart
  utils/
    task_date_formatter.dart
  domain/     ← partially migrated
  data/       ← partially migrated
```

### After (Tasks — Clean Architecture)

```
lib/features/tasks/
  domain/
    entities/
      task_entity.dart
      task_attachment_entity.dart
    repositories/
      task_repository.dart         ← abstract interface
    use_cases/
      create_task_use_case.dart
      update_task_use_case.dart
      delete_task_use_case.dart
      toggle_task_completed_use_case.dart
      add_task_attachment_use_case.dart
      clear_category_on_tasks_use_case.dart
    task_enums.dart
    task_sort_option.dart
  data/
    models/
      task.dart                    ← @HiveType DTO
      task_attachment.dart
    mappers/
      task_mapper.dart
    repositories/
      task_repository_impl.dart    ← implements TaskRepository
      task_repository_legacy.dart
      task_repository_new.dart
    data_sources/
      task_local_datasource.dart
      task_local_datasource_new.dart
    sync/
      task_sync_handler.dart
  presentation/
    state_management/
      task_controller.dart
      category_controller.dart
    pages/
      tasks_screen.dart
    widgets/
      tiles/task_item.dart, task_item_content.dart
      sections/category_section.dart, subcategory_section.dart, ...
      navigation/category_drawer.dart, jump_to_category_button.dart
      dialogs/category_dialogs.dart
      (task_editor_dialog.dart moved to task_editor feature)
      sort_bottom_sheet.dart
      ...
    utils/
      task_sorting_helper.dart
      task_date_formatter.dart
    extensions/
      task_entity_extensions.dart
```

---

## 12. Import Updates and Verification

After each feature's files were moved, we ran a comprehensive check:

1. **Grep for old import paths**: Searched the entire `lib/` and `test/` trees for any import still referencing the old location (e.g., `features/tasks/controllers/`).
2. **Bulk replace**: Applied the old → new path mappings across all `.dart` files.
3. **Layer violation scan**:
   - `domain/**/*.dart` must not import from `data/` or `presentation/`.
   - `data/**/*.dart` must not import from `presentation/`.
4. **Legacy path scan**: No file in `lib/` should import `legacy_mvc/`.
5. **`flutter analyze`**: Must report zero issues.

All five checks passed for the final codebase.

---

## 13. Layer Dependency Rules

```
┌──────────────────────┐
│    Presentation      │  Depends on: domain, data (models only), core
│  (state_management,  │
│   pages, widgets)    │
├──────────────────────┤
│       Data           │  Depends on: domain, core
│  (models, mappers,   │
│   repos, datasources)│
├──────────────────────┤
│      Domain          │  Depends on: core (abstractions only)
│  (entities, repos,   │  NEVER imports data/ or presentation/
│   use_cases)         │
└──────────────────────┘
```

**Allowed:**
- `presentation/` → imports `domain/` (entities, repo interfaces, use cases, enums).
- `presentation/` → imports `data/models/` (for types used across layers like `NavBarStyle`, `Category`).
- `data/` → imports `domain/` (entities, repo interfaces).
- `data/` → imports other `data/` within the same feature.
- Composition root (`splash/presentation/bootstrap/`) → imports **everything** (concrete repos, sync handlers, controllers) — this is the one place where all layers meet.

**Forbidden:**
- `domain/` → NEVER imports `data/` or `presentation/`.
- `data/` → NEVER imports `presentation/`.
- No feature's `domain/` or `data/` imports another feature's `presentation/`.

---

## 14. Final Feature Structure Map

| Feature | `domain/` | `data/` | `presentation/` | Notes |
|---------|:---------:|:-------:|:----------------:|-------|
| **tasks** | entities, repos, use_cases, enums | models, mappers, repos, data_sources, sync | state_management, pages, widgets, utils, extensions | Most complete feature |
| **notes** | entities, repos, use_cases | models, mappers, repos, data_sources, sync | state_management, pages, widgets | Includes sync handler |
| **reminders** | entities, repos, use_cases | models, mappers, repos, data_sources, services | state_management, pages, widgets | Has `data/services/` for timers |
| **habits** | entities, repos, use_cases | models, mappers, repos, data_sources | state_management, pages, widgets | |
| **settings** | entities, repos, use_cases | models, repos | state_management, pages, widgets | 13 use cases |
| **splash** | — | — | bootstrap, models, pages | Composition root |
| **analytics** | — | — | state_management, pages, widgets, utils | Aggregator |
| **calendar** | — | — | state_management, pages, widgets | Aggregator |
| **dashboard** | — | — | pages, widgets | Aggregator |
| **sync** | — | — | state_management, widgets | UI for sync status |
| **task_editor** | — | — | pages, widgets | UI-only |
| **wrapper** | — | — | pages, widgets | App shell |
| **theme_customization** | — | — | pages, widgets | UI-only |

---

## 15. Quality Gates

The following checks all pass on the final migrated codebase:

| Check | Result |
|-------|--------|
| `flutter analyze` | No issues found |
| `flutter test` | All 140 tests pass |
| `.\scripts\run_ci_locally.ps1` (full CI) | All 8 steps pass |
| `flutter build apk --debug` | Builds successfully |
| Domain → Data/Presentation imports | None found |
| Data → Presentation imports | None found |
| Old-path imports (`controllers/`, `views/`, `models/`, `sync/`) | None found in code (only in this doc) |
| `legacy_mvc/` imports | None found |

---

*Document generated after completing the full clean architecture migration of the Nexus codebase.*
