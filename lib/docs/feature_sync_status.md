## Feature sync status and TODOs

### Still local-only (not yet user-portable)

- **Habits**
  - Currently stored only in Hive.
  - No Firestore sync handler.
  - No usage of the sync queue (`SyncOperation` / `SyncService`).

- **Categories**
  - Category data is persisted in Hive and used to organize tasks.
  - No Firestore sync handler.
  - Not yet written to or read from Firestore.
  - **Impact:** Custom category names are lost on app reinstall or when the app package name is changed (new install = new data directory; Hive starts empty).

For **“log in on any device and see the same data”**, every feature that contributes to visible state (tasks, notes, reminders, habits, categories, etc.) needs the same offline‑first + sync pipeline as tasks/notes/reminders:

### Required pieces for each feature

- **Sync‑aware model**
  - Fields: `isDirty`, `lastSyncedAt`, `syncStatus`.
  - Serialization helpers: `toFirestoreJson()` / `fromFirestoreJson()`.

- **Repository support**
  - `getSyncPayload(String id)` that returns a Firestore‑ready map for the given entity.

- **Use cases**
  - Create/update/delete use cases must:
    - Write to the repository (Hive).
    - Enqueue a `SyncOperation` via `SyncService` (with correct `entityType` and `type`).

- **EntitySyncHandler implementation**
  - Implements `EntitySyncHandler<T>` for the feature’s model.
  - Handles:
    - `push(SyncOperation op)` – apply queue operations to Firestore.
    - `pull(DateTime? lastSyncAt)` – read remote changes since last sync, detect conflicts, update Hive.

- **Wiring into `SyncService`**
  - Handler must be registered in:
    - `AppInitializer.completeInitialization` (main `SyncService` instance).
    - Fallback `SyncService` instances in `provider_factory.dart` (for early/standalone controllers).

Once habits and categories have all of the above, their data will be user‑portable across devices in the same way as tasks, notes, and reminders.

