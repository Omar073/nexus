## Firebase user data model for Nexus

> Goal: allow a user to sign into Nexus on **any device** and see **their own tasks, notes, reminders, habits, categories, etc.**, isolated from other users.

This document outlines options for structuring **user‑scoped data** in Firestore and recommends a pattern for Nexus.

---

### 1. Requirements and constraints

- **Per‑user isolation**
  - Each user should see **only** their own data.
  - Security rules should enforce that users cannot access each other’s data.

- **Feature‑specific collections**
  - Nexus has separate features: `tasks`, `notes`, `reminders`, `habits`, `categories`, etc.
  - We want to keep features **modular** in the codebase and in the database.

- **Offline‑first & sync**
  - Local Hive models + `SyncService` + Firestore.
  - Clean mapping between local entities and remote documents.

- **Query patterns**
  - Common queries:
    - “All tasks for current user, filtered/sorted in various ways.”
    - “All notes for current user.”
    - “All reminders for current user.”
  - Less common: cross‑user admin views (e.g. analytics) — can be supported later.

- **Scalability**
  - Even though Nexus is a side project and will likely have **relatively few users**, any one user can still accumulate **a lot** of tasks/notes/reminders over time.
  - The model should therefore:
    - Scale cleanly with **high per‑user volume** (thousands of docs per collection for a single user).
    - Still behave well if usage grows beyond the initial “few users” assumption.
  - Stick to Firestore best practices (flat‑ish collections, avoid giant documents).

- **Per‑user storage limits (quotas)**
  - You may want to cap how much data a single user can create to keep Firebase costs and storage under control.
  - Practical knobs you can introduce later:
    - Hard limits on counts (e.g. max N tasks, M notes, K reminders per user).
    - Soft limits via UX (warning banners, upgrade prompts) even before hard enforcement.
  - Enforcement options:
    - **Client‑side checks** before creating new documents (fast feedback, but not secure on their own).
    - **Server‑side / Cloud Functions** that validate counts before allowing writes.
    - **Security rules with `get()` / `count()`** for simple caps, if performance and complexity stay acceptable for your expected scale.

---

### 2. Option A – User document encapsulates all data

**Shape (conceptual):**

```text
users/{userId}
  - profile fields...
  - tasks: [ { ...task fields... }, ... ]
  - notes: [ { ...note fields... }, ... ]
  - reminders: [ ... ]
  - habits: [ ... ]
  - categories: [ ... ]
```

Variants:

- Arrays of embedded objects (`tasks: [ {...}, {...} ]`)
- Nested maps (`tasksById: { taskId1: {...}, taskId2: {...} }`)
- Or subcollections under a single user doc:
  - `users/{userId}/tasks/{taskId}`, `users/{userId}/notes/{noteId}`, etc.

**Pros:**

- Everything for a user lives “under” their user doc.
- Security rules sometimes feel simpler (`request.auth.uid == resource.id` or parent).

**Cons (for Nexus):**

- **Big documents**:
  - Embedding tasks/notes directly into the user document can easily hit Firestore document size limits (~1 MB).
  - High write amplification (updating one task updates the entire user doc).

- **Versioning & conflicts**:
  - Our sync architecture currently maps **one entity per document** (`tasks/{taskId}`, `notes/{noteId}`).
  - Embedding everything in one doc breaks that mapping and complicates conflict detection.

- **Query flexibility**:
  - Harder to query tasks/notes through standard Firestore queries when they’re nested arrays/maps.
  - You end up fetching the whole user doc and filtering client‑side.

- **Migration complexity**:
  - Nexus already uses flat collections (`tasks`, `notes`) with per‑document sync. Moving to a monolithic user doc is a big refactor.

**Use case where Option A makes sense:**

- Very small per‑user datasets (e.g. user preferences, a handful of items).
- You rarely query sub‑collections independently.

For Nexus (with hundreds/thousands of tasks/notes per user), this option is **not ideal**.

---

### 3. Option B – Feature collections with `userId` field

**Shape (conceptual):**

```text
users/{userId}
  - profile fields, settings, metadata

tasks/{taskId}
  - userId: <uid>
  - ...task fields...

notes/{noteId}
  - userId: <uid>
  - ...note fields...

reminders/{reminderId}
  - userId: <uid>
  - ...reminder fields...

habits/{habitId}
  - userId: <uid>
  - ...habit fields...

categories/{categoryId}
  - userId: <uid>
  - ...category fields...
```

**Key idea:**  
Each feature keeps its own top‑level collection, but **every document has a `userId` field** linking it back to the Firebase Auth user.

**Pros:**

- **Aligns with current Nexus sync architecture:**
  - Each entity (task/note/reminder/…) is a **separate Firestore document**.
  - Existing `TaskSyncHandler` / `NoteSyncHandler` / `ReminderSyncHandler` concepts extend naturally:
    - Add `userId` field in `toFirestoreJson()`.
    - Query with `.where('userId', isEqualTo: currentUser.uid)` in `pull`.

- **Scalable:**
  - Each collection can grow independently (millions of documents).
  - Firestore indexing and querying are straightforward.

- **Query flexibility:**
  - Simple, efficient queries for “current user’s tasks/notes/reminders”:
    ```dart
    firestore.collection('tasks')
      .where('userId', isEqualTo: uid)
      .orderBy('updatedAt', descending: true);
    ```

- **Security rules are clear:**
  - At the document level:
    ```js
    match /tasks/{taskId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    ```

  - Similar for notes, reminders, habits, categories.

- **Feature modularity:**
  - Tasks/notes/reminders/habits/categories stay separate in code and in Firestore.
  - You can evolve one feature’s schema without touching the others.

**Cons:**

- You can’t fetch *all* of a user’s data with a single `users/{userId}` lookup; you must query each collection.
  - This is acceptable for Nexus, since UI is already organized by feature (Tasks screen, Notes screen, etc.).
- Cross‑user admin or global analytics queries require careful indexing and consideration of `userId` filters (but this is generally fine).

---

### 4. Recommended approach for Nexus

**Use Option B** (feature collections with a `userId` field) for all user‑scoped features.

#### 4.1. Data model changes (per feature)

For each sync‑enabled feature (tasks, notes, reminders now; habits/categories later):

- **Model:**
  - Add a `String userId;` field.
  - Include `userId` in `toFirestoreJson()` / `fromFirestoreJson()`.

- **Repository:**
  - Ensure `getSyncPayload(id)` includes `userId`.

- **Use cases:**
  - When creating an entity, pass `userId` (often from a `UserSession` or `AuthController`) and persist it.

Example (task model `toFirestoreJson`):

```dart
Map<String, dynamic> toFirestoreJson() => {
  'id': id,
  'userId': userId,
  'title': title,
  'description': description,
  'createdAt': Timestamp.fromDate(createdAt),
  'updatedAt': Timestamp.fromDate(updatedAt),
  // ...
};
```

#### 4.2. Sync handlers

In each `EntitySyncHandler` (`TaskSyncHandler`, `NoteSyncHandler`, `ReminderSyncHandler`, future `HabitSyncHandler`, `CategorySyncHandler`):

- **Push**: no change beyond propagating `userId` already in the payload.
- **Pull**:
  - Filter by `userId`:
    ```dart
    Query<Map<String, dynamic>> q = _collection.where(
      'userId',
      isEqualTo: currentUserId,
    );
    if (lastSyncAt != null) {
      q = q.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncAt));
    }
    ```
  - `currentUserId` typically comes from:
    - A `UserSession`/`AuthController` injected into the handler, or
    - A small `UserContext` service that exposes `uid`.

#### 4.3. Security rules (high‑level)

In `firestore.rules` (conceptual sketch):

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Tasks
    match /tasks/{taskId} {
      allow read, write: if isOwner();
    }

    // Notes
    match /notes/{noteId} {
      allow read, write: if isOwner();
    }

    // Reminders
    match /reminders/{reminderId} {
      allow read, write: if isOwner();
    }

    // Habits
    match /habits/{habitId} {
      allow read, write: if isOwner();
    }

    // Categories
    match /categories/{categoryId} {
      allow read, write: if isOwner();
    }

    function isOwner() {
      return request.auth != null
        && request.auth.uid == resource.data.userId;
    }
  }
}
```

You may also want to enforce that creates must write `userId = request.auth.uid`.

#### 4.4. Login flow and user ID propagation

With this model:

- Login gives you a Firebase `uid`.
- On each device:
  - You initialize `SyncService` and handlers with a way to get `uid`.
  - Use cases include `userId` when constructing new entities.
  - Sync handlers read/write only documents where `userId == uid`.

Result:

- Any device signed into the **same Firebase user** sees the **same tasks, notes, reminders, habits, categories**, etc.
- A different user has a different `uid`, thus a completely separate slice of each collection.

---

### 5. Categories, habits, and other data types

#### 5.1. Categories: own collection vs. embedded in tasks/notes

**Recommendation: categories should be their own collection.**

| Approach | Pros | Cons |
|----------|------|------|
| **Own collection** `categories/{categoryId}` | Single source of truth; shared across tasks and notes; independent lifecycle (rename, delete); tasks/notes reference by `categoryId` | One extra collection and sync handler |
| **Embedded in tasks/notes** | Fewer collections | Duplication; rename category = update every task/note; no shared category list; harder to manage subcategories |

**Why own collection:**

- Categories are **shared** — many tasks and notes use the same category.
- They have their **own lifecycle** — create, rename, delete, add subcategories.
- Tasks and notes only need a **reference** (`categoryId`, `subcategoryId`), not the full category data.
- Matches Nexus’s current design: `Category` model, `CategoryController`, tasks/notes store `categoryId`.

**Firestore shape:**

```text
categories/{categoryId}
  - userId: <uid>
  - id: string
  - name: string
  - parentId: string?   // null = root category

tasks/{taskId}
  - userId: <uid>
  - categoryId: string?   // references categories/{categoryId}
  - subcategoryId: string?
  - ...

notes/{noteId}
  - userId: <uid>
  - categoryId: string?
  - ...
```

When syncing: categories sync first (or in parallel). Tasks and notes sync with `categoryId`; if a category is missing (e.g. deleted), the client treats the task/note as uncategorized.

#### 5.2. Habits

**Own collection** `habits/{habitId}` with `userId`, same pattern as tasks/notes. Habit logs can be:

- A separate collection `habit_logs/{logId}` with `habitId` and `userId`, or
- Embedded in the habit document if the number of logs per habit is small (e.g. last N days).

For Nexus, habit logs are numerous over time, so a **separate `habit_logs` collection** is preferable.

#### 5.3. Other data types (summary)

| Data type | Collection | Notes |
|-----------|------------|-------|
| Tasks | `tasks` | `userId`, `categoryId`, `subcategoryId` |
| Notes | `notes` | `userId`, `categoryId` |
| Reminders | `reminders` | `userId` |
| Categories | `categories` | `userId`, `parentId` for hierarchy |
| Habits | `habits` | `userId` |
| Habit logs | `habit_logs` | `userId`, `habitId` |
| Sync metadata | `sync_metadata` | Per-user last sync timestamps |

All user-scoped collections include a `userId` field and use the same security-rule pattern (`request.auth.uid == resource.data.userId`).

---

### 6. Migration considerations

For existing data (pre‑user model):

- Current documents in `tasks`, `notes`, `reminders` do **not** have `userId` yet.
- Once Auth is introduced, you can:
  - Run a one‑time migration script that:
    - Assumes all current data belongs to a single user (your account).
    - Writes `userId: '<your uid>'` into each document.
  - Or, if you already have per‑device/anonymous data, decide how to map those to real users.

Your existing `tool/migrate_firestore.dart` can be adapted to also set `userId` for migrated docs.

---

### 7. Summary

- **Don’t embed all feature data inside the user document.**
- **Do** use **separate collections per feature** (`tasks`, `notes`, `reminders`, `habits`, `categories`), each with a `userId` field.
- Update:
  - Models → add `userId` and sync fields.
  - Repositories → `getSyncPayload(id)` includes `userId`.
  - Use cases → enqueue `SyncOperation`s with `entityType` and Firestore payload.
  - Handlers → filter Firestore queries by `userId` and `updatedAt`.
  - `SyncService` wiring → register handlers in `AppInitializer` and `provider_factory`.

This structure matches Nexus’s existing clean architecture and sync design, and gives you the behavior you want: **log in anywhere, see the same per‑user data**.

