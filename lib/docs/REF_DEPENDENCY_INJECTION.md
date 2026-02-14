# Dependency Injection in Nexus

This document explains how Dependency Injection (DI) is used in the Nexus app, with a focus on the Sync Service refactor as the primary example.

---

## What Problem Does DI Solve?

Before DI, `SyncService` created its own handlers internally:

```dart
// ❌ OLD — SyncService knows about every feature
class SyncService {
  SyncService({required this.firestore, required this.deviceId, ...}) {
    _handlers['task'] = TaskSyncHandler(firestore: firestore, ...);
    _handlers['note'] = NoteSyncHandler(firestore: firestore, ...);
  }
}
```

**Problems:**

| Issue | Consequence |
|-------|-------------|
| `core/` imports `features/` | Violates the dependency rule (Core should never depend on Features) |
| Adding a new entity requires editing `SyncService` | Breaks Open/Closed Principle |
| Hard to test | Can't swap handlers for mocks without modifying internals |

---

## The DI Solution

Instead of creating handlers internally, `SyncService` **receives** them:

```dart
// ✅ NEW — SyncService is agnostic
class SyncService {
  SyncService({
    required ConnectivityService connectivity,
    List<EntitySyncHandler> handlers = const [],
  }) : _connectivity = connectivity {
    for (final handler in handlers) {
      _handlers[handler.entityType] = handler;
    }
  }
}
```

Now `SyncService` lives in `core/` and has **zero knowledge** of Tasks or Notes.

---

## Where Injection Happens

Handlers are created and injected at app startup, in two places:

### 1. `AppInitializer` (Production startup)

**File:** [`app_initializer.dart`](../../features/splash/controllers/app_initializer.dart)

```dart
final taskHandler = TaskSyncHandler(
  firestore: FirebaseFirestore.instance,
  deviceId: critical.deviceId,
);
final noteHandler = NoteSyncHandler(
  firestore: FirebaseFirestore.instance,
  deviceId: critical.deviceId,
);

final syncService = SyncService(
  connectivity: critical.connectivityService,
  handlers: [taskHandler, noteHandler],
);
```

### 2. `AppProviderFactory` (Provider tree)

**File:** [`provider_factory.dart`](../../features/splash/controllers/provider_factory.dart)

Every `SyncService` instantiation in the provider tree follows the same pattern — handlers are created inline and passed to the constructor.

---

## Dependency Flow

```
features/splash/       (Composition Root)
  ├── Creates TaskSyncHandler    (from features/tasks/sync/)
  ├── Creates NoteSyncHandler    (from features/notes/sync/)
  └── Injects both into SyncService (from core/services/sync/)
```

**Key insight:** The "Composition Root" (`splash/`) is the only place that knows about all the pieces. Neither `core/` nor individual features need to know about each other.

---

## Adding a New Synced Entity

To add sync for a new entity (e.g., Habits):

1. **Create the handler** in the feature directory:
   - `lib/features/habits/sync/habit_sync_handler.dart`
   - Implement `EntitySyncHandler` (define `entityType`, `push`, `pull`)

2. **Register it** at the composition root:

   ```dart
   // In app_initializer.dart and provider_factory.dart
   final habitHandler = HabitSyncHandler(
     firestore: FirebaseFirestore.instance,
     deviceId: critical.deviceId,
   );

   final syncService = SyncService(
     connectivity: ...,
     handlers: [taskHandler, noteHandler, habitHandler], // ← Add here
   );
   ```

3. **Done.** No changes to `SyncService` itself are needed.

---

## Related Files

| File | Role |
|------|------|
| [`sync_service.dart`](../core/services/sync/sync_service.dart) | Core orchestrator (receives handlers) |
| [`entity_sync_handler.dart`](../core/services/sync/handlers/entity_sync_handler.dart) | Abstract interface for handlers |
| [`task_sync_handler.dart`](../../features/tasks/sync/task_sync_handler.dart) | Task-specific sync logic |
| [`note_sync_handler.dart`](../../features/notes/sync/note_sync_handler.dart) | Note-specific sync logic |
| [`provider_factory.dart`](../../features/splash/controllers/provider_factory.dart) | Composition root (where injection happens) |
| [`REF_SYNC_ARCHITECTURE.md`](REF_SYNC_ARCHITECTURE.md) | Full sync architecture overview |
