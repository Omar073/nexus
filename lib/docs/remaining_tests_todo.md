# Remaining Tests TODO

## Unit Tests — Controllers

### `task_controller_test.dart` (~8 tests)

- [ ] `tasksForStatus` returns filtered list by status
- [ ] `setQuery` filters by title/description substring
- [ ] `setOverdueOnly` excludes non-overdue tasks
- [ ] `setPriorityFilter` filters by priority enum
- [ ] `byId` returns correct task or null
- [ ] `highestPriorityActive` skips completed tasks
- [ ] `clearCategoryOnTasks` nullifies matching categoryId/subcategoryId
- [ ] `_purgeCompletedOlderThanRetention` deletes old completed tasks when setting enabled

> **Complexity:** Requires `TaskRepository` (Hive), `SyncService`, `GoogleDriveService`, `SettingsController` fakes. The `TaskCrudMixin` uses `SyncOperation` enqueue + Google Drive upload for attachments.

---

### `note_controller_test.dart` (~5 tests)

- [ ] `createEmpty` inserts note with default delta JSON
- [ ] `visibleNotes` filters by query (title + plain text)
- [ ] `setCategoryFilter` restricts to matching categoryId
- [ ] `delete` removes from repo and enqueues sync delete op
- [ ] `updateCategory` sets categoryId and marks dirty

> **Complexity:** Depends on `flutter_quill` for `saveEditor` and `_plainText`. `NoteRepository` (Hive), `SyncService`, `GoogleDriveService` fakes needed.

---

## Unit Tests — Platform Services

### `device_calendar_service_test.dart` (~3 tests)

- [ ] `requestPermissions` delegates to plugin and returns result
- [ ] `retrieveCalendars` returns plugin's calendar list
- [ ] `createEvent` passes event data to plugin

> **Complexity:** Requires `FakeDeviceCalendarPlugin` (already created). Straightforward delegation tests.

---

### `connectivity_monitor_service_test.dart` (~3 tests)

- [ ] Emits `true` when `connectivity_plus` reports wifi/mobile
- [ ] Emits `false` when `connectivity_plus` reports none
- [ ] `isOnline` getter reflects current state

> **Complexity:** Requires faking `Connectivity` from `connectivity_plus`. The stream-based API needs a `StreamController` to simulate connectivity changes.

---

## Unit Tests — Storage

### `attachment_storage_service_test.dart` (~3 tests)

- [ ] `copyIntoTaskDir` copies file into task-specific directory
- [ ] `newAudioPath` generates path under task dir with timestamp
- [ ] Task directory is created if it doesn't exist

> **Complexity:** Uses `dart:io` `Directory`/`File`. Can test with a temporary directory (`Directory.systemTemp`).

---

## Integration Tests

### `task_lifecycle_test.dart` (~3 tests)

- [ ] Create → update → toggle complete → verify state
- [ ] Recurring task creates next occurrence on completion
- [ ] Delete enqueues sync operation

> **Complexity:** Full `TaskController` with Hive + fakes for sync/drive.

---

### `note_lifecycle_test.dart` (~3 tests)

- [ ] Create empty → save with title → verify persistence
- [ ] Search filters notes by content
- [ ] Delete removes and enqueues sync op

> **Complexity:** Needs `flutter_quill` `QuillController` setup.

---

## E2E Tests

### `note_search_test.dart` (~2 tests)

- [ ] Create multiple notes → search by keyword → verify filtered results
- [ ] Category filter + query combine correctly

> **Complexity:** Same `flutter_quill` dependency as note controller tests.
