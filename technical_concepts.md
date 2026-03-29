# Technical Concepts

This document explains general technical patterns and concepts used in the app. These are not specific to the app's business logic but are foundational programming patterns.

## Table of Contents

- [1. Singleton Pattern](#1-singleton-pattern)
- [2. Dependency Injection](#2-dependency-injection)
- [3. Async Fundamentals](#3-async-fundamentals-await-unawaited-async)
- [4. Async Generators](#4-async-generators-async-and-yield)
- [5. Streams and `await for`](#5-streams-and-await-for)
- [6. Repository Pattern](#6-repository-pattern)
- [7. Concepts: Mixin & CRUD Patterns](#7-concepts-mixin--crud-patterns-controller-architecture)
- [8. Hive Binary Serialization](#8-hive-binary-serialization)
- [9. Rich Text Editing (Quill and Delta Format)](#9-rich-text-editing-quill-and-delta-format)

## 1. Singleton Pattern

A **singleton** ensures only ONE instance of a class exists throughout the app's lifetime. This is useful for services that should have a single, shared state (e.g., connectivity monitoring, logging, caching).

### Implementation in Dart

```dart
class ConnectivityMonitorService {
  // 1. Factory constructor — the public entry point
  factory ConnectivityMonitorService() => _instance;
  
  // 2. Static final instance — THE singleton, stored forever
  static final ConnectivityMonitorService _instance =
      ConnectivityMonitorService._internal();
  
  // 3. Private named constructor — prevents external instantiation
  ConnectivityMonitorService._internal();
}
```

### How each piece works

| Component | Purpose |
|-----------|---------|
| `factory ConnectivityMonitorService()` | Public constructor that always returns `_instance` |
| `static final _instance` | The ONE instance, created once and stored at class level |
| `._internal()` | Private constructor — only this file can call it |

### Why each keyword matters

| Keyword | Role |
|---------|------|
| `static` | Belongs to the class itself, not any instance. Shared across all references. |
| `final` | Can only be assigned once. The instance is created once and never replaced. |
| `factory` | Special constructor that can return an existing object instead of creating new. |
| `_` prefix | Makes the member private to this file (Dart convention). |

### Lazy Initialization

**When does `_instance` get created?**

- ❌ NOT at compile time
- ❌ NOT immediately when the app starts
- ✅ **On first access** — when any code first touches `ConnectivityMonitorService`

```text
App starts
    ↓
... app runs ...
    ↓
First time ANY code calls ConnectivityMonitorService()
    ↓
Dart initializes static fields: _instance = ConnectivityMonitorService._internal()
    ↓
factory returns _instance
    ↓
All future calls return the same _instance
```

**Dart handles this automatically.** Unlike Java where you'd write:

```dart
// ❌ NOT needed in Dart
if (_instance == null) {
  _instance = ConnectivityMonitorService._internal();
}
return _instance;
```

With `static final`, Dart guarantees:

- **One-time initialization** — The constructor runs exactly once
- **Thread-safe** — No race conditions
- **Lazy** — Only happens when first accessed

### Proof: Add a print statement

```dart
ConnectivityMonitorService._internal() {
  print('>>> Instance created!');
}
```

You'll see `>>> Instance created!` printed **once**, and only when the class is first accessed. If you never call `ConnectivityMonitorService()` anywhere, you'll never see it.

### Call flow

```dart
// First call
final a = ConnectivityMonitorService();
// → Dart initializes _instance via _internal()
// → factory returns _instance

// Second call
final b = ConnectivityMonitorService();
// → _instance already exists
// → factory returns the SAME _instance

print(a == b);  // TRUE — same object!
```

### Summary

| Question | Answer |
|----------|--------|
| Created at compile time? | No |
| Created at app startup? | No |
| Created when first accessed? | **Yes** (lazy initialization) |
| Is there a null check? | No, Dart handles it automatically |
| How many times is `_internal()` called? | Exactly once, ever |
| Why private constructor? | Prevents external code from creating new instances |
| Why factory? | Returns existing instance instead of creating new |

---

## 2. Dependency Injection

**Dependency Injection (DI)** means passing dependencies into a class instead of creating them inside. This makes classes testable, swappable, and decoupled.

### 2.1 Why Use It?

| Approach | Testable? | Flexible? |
|----------|-----------|-----------|
| Create inside: `final _conn = Connectivity()` | ❌ Can't mock | ❌ Hardcoded |
| Inject via constructor: `MyClass({required Connectivity conn})` | ✅ Can mock | ✅ Swappable |

### 2.2 Pattern 1: Optional Parameter with Default

The simplest form. Good for services with a single dependency:

```dart
class ConnectivityService {
  // Optional parameter with default fallback
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
}
```

| Scenario | What happens |
|----------|--------------|
| Production: `ConnectivityService()` | Uses real `Connectivity()` |
| Testing: `ConnectivityService(connectivity: mock)` | Uses mock |

### 2.3 Pattern 2: Constructor Injection with List

When a class needs to work with **multiple implementations of the same interface**, inject them as a list. This is the **Strategy Pattern + DI** combination.

```dart
// The interface (defined in core/)
abstract class EntitySyncHandler {
  String get entityType;
  Future<void> push(SyncOperation op);
  Future<void> pull(DateTime? lastSyncAt);
}

// The orchestrator (defined in core/) — doesn't know about any specific handler
class SyncService {
  SyncService({
    required ConnectivityService connectivity,
    List<EntitySyncHandler> handlers = const [],  // ← DI via list
  }) : _connectivity = connectivity {
    for (final handler in handlers) {
      _handlers[handler.entityType] = handler;
    }
  }

  final Map<String, EntitySyncHandler> _handlers = {};
}
```

**Key benefit:** `SyncService` lives in `core/` and has **zero imports** from any feature. New features register themselves without touching `SyncService`.

### 2.4 The Composition Root

The **Composition Root** is the one place in your app where all dependencies are created and wired together. In Nexus, this is the `splash` feature:

```text
features/splash/
  ├── app_initializer.dart      ← Creates real services for production
  └── provider_factory.dart     ← Wires everything into the Provider tree
```

**Example from `app_initializer.dart`:**

```dart
// 1. Create feature-specific handlers (Workers)
final taskHandler = TaskSyncHandler(
  firestore: FirebaseFirestore.instance,
  deviceId: critical.deviceId,
);
final noteHandler = NoteSyncHandler(
  firestore: FirebaseFirestore.instance,
  deviceId: critical.deviceId,
);

// 2. Inject handlers into the core service (Manager)
final syncService = SyncService(
  connectivity: critical.connectivityService,
  handlers: [taskHandler, noteHandler],
);
```

### 2.5 Dependency Flow Visualization

```text
┌─────────────────────────────────────────────────┐
│       Composition Root (splash/)                │
│  Creates all dependencies and wires them        │
└────────────┬──────────────────┬─────────────────┘
             │                  │
    ┌────────▼────────┐  ┌─────▼──────────┐
    │  core/services/ │  │  features/     │
    │  SyncService    │  │  TaskSyncHandler│
    │  (Orchestrator) │  │  NoteSyncHandler│
    │  Knows NOTHING  │  │  (Workers)     │
    │  about features │  │                │
    └─────────────────┘  └────────────────┘
```

**The arrows flow inward:** Features depend on Core (for the interface). Core depends on nothing. The Composition Root depends on everything (but that's its job).

### 2.6 Adding a New Dependency

To add sync for a new entity (e.g., Habits):

1. Create `lib/features/habits/sync/habit_sync_handler.dart` implementing `EntitySyncHandler`.
2. Register it in `app_initializer.dart` and `provider_factory.dart`:

   ```dart
   handlers: [taskHandler, noteHandler, habitHandler] // ← Just add here
   ```

3. **No changes to `SyncService` needed.** This is the Open/Closed Principle in action.

### 2.7 DI in Tests

```dart
// Create a mock handler for testing
class MockSyncHandler extends EntitySyncHandler {
  @override String get entityType => 'test';
  @override Future<void> push(SyncOperation op) async { /* track calls */ }
  @override Future<void> pull(DateTime? lastSyncAt) async { /* return test data */ }
}

// Inject mock into SyncService
final service = SyncService(
  connectivity: MockConnectivity(),
  handlers: [MockSyncHandler()],
);
```

### 2.8 Summary

| Concept | In Nexus |
|---------|----------|
| **Interface** | `EntitySyncHandler` (abstract class in `core/`) |
| **Implementations** | `TaskSyncHandler`, `NoteSyncHandler` (in `features/`) |
| **Consumer** | `SyncService` (in `core/`, receives handlers via constructor) |
| **Composition Root** | `splash/` (creates and wires everything) |
| **Benefit** | Core never imports Features; new entities = zero core changes |

---

## 3. Async Fundamentals (`await`, `unawaited`, `async`)

Understanding the difference between synchronous and asynchronous execution is fundamental to Dart programming.

### Synchronous vs Asynchronous

| Type | Behavior | Example |
|------|----------|---------|
| **Synchronous** | Blocks until complete. Next line waits. | `final x = compute();` |
| **Asynchronous** | Returns immediately. Work continues in background. | `final future = fetchData();` |

### The `async` Keyword

Marking a function `async` allows you to use `await` inside it and makes it return a `Future`:

```dart
// Without async — returns synchronously
int add(int a, int b) {
  return a + b;
}

// With async — returns Future<int>
Future<int> addAsync(int a, int b) async {
  return a + b;  // Still instant, but wrapped in a Future
}
```

### `await` — Wait for Completion

`await` pauses execution until the `Future` completes, then returns its value:

```dart
Future<void> fetchUser() async {
  print('1. Starting fetch');
  final user = await api.getUser();  // ← Pauses here until complete
  print('2. Got user: $user');        // ← Runs after await completes
}
```

**Execution order:**

1. Print "Starting fetch"
2. Call `api.getUser()` — function pauses (but doesn't block the app)
3. When response arrives, print "Got user: ..."

### `unawaited()` — Fire and Forget

Sometimes you want to start an async operation but **not wait** for it. This is called "fire and forget":

```dart
// ❌ BAD — Dart analyzer warns about unhandled Future
syncOnce();  // Future is ignored

// ✅ GOOD — Explicitly mark as intentional
unawaited(syncOnce());  // "I know this returns a Future, I don't care"
```

**When to use `unawaited()`:**

| Scenario | Example |
|----------|---------|
| Background sync | `unawaited(syncOnce());` — sync runs, UI doesn't wait |
| Fire-and-forget logging | `unawaited(analytics.log('button_clicked'));` |
| Preloading data | `unawaited(prefetchImages());` |

**Real example from SyncService:**

```dart
Future<void> startAutoSync() async {
  _connectivity.onlineStream().listen((online) {
    if (online) {
      unawaited(syncOnce());  // Start sync, don't block the listener
    }
  });
}
```

Without `unawaited`, the analyzer would warn. With it, we're saying: "Yes, I intentionally want this to run in the background."

### Comparison Table

| Pattern | Blocks? | Returns | Use When |
|---------|---------|---------|----------|
| `await future` | Yes (pauses) | The resolved value | You need the result before continuing |
| `unawaited(future)` | No | void | Fire-and-forget, background work |
| `future.then(...)` | No | Future | Chaining without await (callback style) |
| No await or unawaited | No | Future (ignored) | ❌ Avoid — analyzer warning |

### `await` vs `unawaited` in UI flows (Nexus example)

In UI code, **`await`** is used when you must finish a task *before* continuing (e.g., block navigation until a save completes).

**`unawaited(...)`** is used when:

- you’re responding to an event callback that should return quickly, and
- you still want the async work to happen, but you don’t want to block the UI thread / gesture pipeline.

Example from the Notes editor:

```dart
unawaited(_autosave?.flush(syncRemote: true) ?? Future.value());
```

Meaning:

- The user is leaving the screen.
- We trigger a final “sync flush” in the background.
- We **do not** delay the pop animation / navigation by waiting for the network.

Here’s the surrounding context in `note_editor_view.dart` (simplified):

```dart
return PopScope(
  canPop: true,
  onPopInvokedWithResult: (didPop, result) {
    if (!didPop) return;
    _autosave?.cancelPending();
    unawaited(_autosave?.flush(syncRemote: true) ?? Future.value());
  },
  child: Scaffold(/* ... */),
);
```

### `async` vs `async*`

These keywords serve completely different purposes:

| Keyword | Returns | Emits | Use Case |
|---------|---------|-------|----------|
| `async` | `Future<T>` | One value (via `return`) | Standard async functions |
| `async*` | `Stream<T>` | Multiple values (via `yield`) | Generators that emit over time |

```dart
// async — returns ONE value wrapped in Future
Future<int> fetchCount() async {
  final response = await api.getCount();
  return response.count;  // Single return
}

// async* — yields MULTIPLE values as a Stream
Stream<int> countUp() async* {
  for (var i = 0; i < 5; i++) {
    await Future.delayed(Duration(seconds: 1));
    yield i;  // Emits: 0, 1, 2, 3, 4 (one per second)
  }
}
```

---

## 4. Async Generators (`async*` and `yield`)

An **async generator** is a function that returns a `Stream` and can emit multiple values over time.

### Generator Comparison

| Keyword | Returns | How to emit values |
|---------|---------|-------------------|
| `async` | `Future<T>` | `return` (once, then function ends) |
| `async*` | `Stream<T>` | `yield` (multiple times, keeps running) |

### Example

```dart
// Regular async — returns ONE value
Future<int> getOne() async {
  return 42;  // Done, function ends
}

// Async generator — returns MULTIPLE values
Stream<int> countUp() async* {
  yield 1;  // Emit 1, keep running
  yield 2;  // Emit 2, keep running
  yield 3;  // Emit 3, function ends
}
```

### What `yield` does

| Keyword | Behavior |
|---------|----------|
| `return` | Emits one value AND exits the function |
| `yield` | Emits one value AND continues running |

### `yield await` — wait then emit

```dart
yield await isOnline;  // Wait for Future, then emit its result
```

---

## 5. Streams and `await for`

A **Stream** is like a pipe that delivers values over time (vs a `Future` which delivers one value).

### Subscribing to a Stream

```dart
// Option 1: .listen() — callback-based
myStream.listen((value) {
  print(value);
});

// Option 2: await for — loop-based (inside async* function)
await for (final value in myStream) {
  print(value);
}
```

### `for` vs `await for`

| Syntax | Works with |
|--------|-----------|
| `for (... in list)` | Iterables — all values available now |
| `await for (... in stream)` | Streams — values arrive over time |

### Real example: Connectivity stream

```dart
Stream<bool> onlineStream() async* {
  yield await isOnline;  // Emit current state immediately
  
  await for (final result in onChanged) {  // Listen for changes
    yield result.isNotEmpty;  // Emit each change as it happens
  }
}
```

**Flow:**

```text
onlineStream() called
    ↓
yield await isOnline → emits true/false immediately
    ↓
await for... → subscribes to OS connectivity events
    ↓
WiFi disconnects → result arrives → yield false
    ↓
WiFi reconnects → result arrives → yield true
    ↓
(keeps listening forever until cancelled)
```

---

## 6. Repository Pattern

A **Repository** acts as a gateway (or abstraction layer) between your business logic (controllers) and your data sources. It encapsulates *how* data is stored and retrieved, so controllers don't need to know whether data comes from Hive, Firebase, or any other source.

### Why we need it in Nexus

Nexus has **two data sources**:

| Source | Purpose |
|--------|---------|
| **Hive** | Local offline storage (source of truth) |
| **Firestore** | Cloud sync for cross-device access |

Without a repository, controllers would need to:

```dart
// ❌ BAD — Controller knows too much about storage
class TaskController {
  Future<void> saveTask(Task task) async {
    // Talk to Hive directly
    final box = Hive.box<Task>('tasks');
    await box.put(task.id, task);
    
    // Also talk to Firestore
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(task.id)
        .set(task.toJson());
  }
}
```

### The Repository Solution

The repository provides a **common interface** that hides storage details:

```dart
// ✅ GOOD — Repository handles all storage logic
class TaskRepository {
  final TaskLocalDatasource _local;  // Hive operations
  
  Future<void> upsert(Task task) async {
    await _local.upsert(task);  // Write to Hive
    // Sync layer handles Firestore separately
  }
  
  List<Task> getAll() => _local.getAll();
  Task? getById(String id) => _local.getById(id);
  Future<void> delete(String id) => _local.delete(id);
}

// Controller stays clean
class TaskController {
  final TaskRepository _repo;
  
  Future<void> saveTask(Task task) async {
    await _repo.upsert(task);  // One line — doesn't know about Hive
  }
}
```

### Benefits

| Benefit | Explanation |
|---------|-------------|
| **Separation of concerns** | Controllers handle business logic; repositories handle data access |
| **Testability** | Mock the repository in tests — no real database needed |
| **Swappability** | Change storage backend without touching controllers |
| **Consistency** | All data access goes through one place |

### Repository as a Contract

Think of the repository as a **contract** that guarantees:

- "Give me a task ID, I'll return the task"
- "Give me a task object, I'll save it"
- "Call `getAll()`, I'll return all tasks"

The controller doesn't care *how* these promises are kept — just that they are.

### Real example in Nexus

```text
TaskController
    ↓ calls
TaskRepository.upsert(task)
    ↓ delegates to
TaskLocalDatasource.upsert(task)
    ↓ writes to
Hive box
```

Meanwhile, `SyncService` separately:

```text
SyncService
    ↓ reads from
Hive box (via repository)
    ↓ pushes to
Firestore
```

Both sides use the same Hive data, but neither knows about the other's implementation.

---

## 7. Concepts: Mixin & CRUD Patterns (Controller Architecture)

This section explains the **Mixin architectural pattern** used in Nexus to organize complex controllers. It combines Dart's `mixin` feature with the standard **CRUD** (Create, Read, Update, Delete) pattern.

### 7.1 What is a Mixin?

In Dart, a **mixin** is a way of reusing a class's code in multiple class hierarchies.

- **Unlike regular inheritance** (`extends`), a class can use *multiple* mixins (`with A, B, C`).
- **Unlike interfaces** (`implements`), mixins contain *concrete implementation code*.
- **Key feature**: A mixin can access members of the class it is mixed into, creating a powerful composition tool.

#### The `on` keyword (Constraint)

When defining a mixin, the `on` keyword restricts which classes can use it. This is **crucial** for our pattern:

```dart
mixin CrudMixin on BaseController {
  // Because of 'on', this mixin KNOWS that 'this' is a BaseController.
  // It can safely call methods/getters defined in BaseController.
  void save() {
    this.repository.save(); // ✅ Valid access to BaseController member
  }
}
```

### 7.2 Why use Mixins for Controllers?

We use mixins to slice a large controller **vertically by feature** (e.g., CRUD logic vs. Sync logic vs. filtering logic) while keeping it as a **single object at runtime**.

| Approach | Pros | Cons |
|----------|------|------|
| **Monolithic Class** | Simple, direct access to state | Becomes unmanageable (1000+ lines) |
| **Composition (Helper Classes)** | Separation of concerns | Helpers need rigorous dependency injection; `this` context is split |
| **Mixins (Our Choice)** | Separation of files; shared `this` context | Requires strict interface discipline (Base Class) |

### 7.3 The CRUD Pattern

**CRUD** stands for **Create, Read, Update, Delete**. These are the four basic functions of persistent storage.

In Nexus, CRUD operations are repetitive and standard:

1. **Create**: Generate ID, set defaults, save to Hive, queue sync.
2. **Read**: (Usually handled by the main controller via repository queries).
3. **Update**: Modify fields, mark dirty, save to Hive, queue sync.
4. **Delete**: Remove from Hive, queue sync delete operation.

Because these operations are boilerplate-heavy, we isolate them in a **CRUD Mixin**.

### 7.4 The Nexus Implementation: 3-Layer Split

We split complex controllers (like `TaskController`) into three files:

1. **Contract (Base Class)**
2. **Implementation (Mixin)**
3. **Assembly (Concrete Class)**

#### Layer 1: The Contract (`task_controller_base.dart`)

The **abstract base class** extends `ChangeNotifier`. It defines the *requirements* that the mixin needs but doesn't implement them.

```dart
abstract class TaskControllerBase extends ChangeNotifier {
  // ABSTRACT GETTERS: "The concrete class PROMISES to provide these"
  TaskRepository get repo;
  Uuid get uuid;
  String get deviceId;

  // ABSTRACT METHODS: "The concrete class must handle these"
  Future<void> enqueueSyncOp(Task task);
}
```

#### Layer 2: The Logic (`task_crud_mixin.dart`)

The **mixin** contains the CRUD logic. It uses the `on` constraint to access the Base Class's getters.

```dart
mixin TaskCrudMixin on TaskControllerBase {
  // Create Operation
  Future<void> createTask(String title) async {
    final task = Task(
      id: uuid.v4(),                  // Accessing Base getter
      title: title,
      lastModifiedBy: deviceId,       // Accessing Base getter
    );
    
    await repo.upsert(task);          // Accessing Base getter
    await enqueueSyncOp(task);        // Accessing Base method
    notifyListeners();                // Accessing ChangeNotifier method
  }

  // Update Operation
  Future<void> updateTask(Task task) async {
    task.isDirty = true;
    await repo.upsert(task);
    await enqueueSyncOp(task);
  }
}
```

#### Layer 3: The Assembly (`task_controller.dart`)

The **concrete class** ties everything together. It extends the Base, mixes in the Logic, and injects real dependencies.

```dart
class TaskController extends TaskControllerBase with TaskCrudMixin {
  // 1. Constructor injects real services
  TaskController({required this.repository, required this.uuid, ...});

  final TaskRepository repository;
  final Uuid uuid;

  // 2. Implements abstract getters (connects Mixin to Real Services)
  @override TaskRepository get repo => repository;
  @override Uuid get uuid => this.uuid;

  // 3. Implements abstract methods
  @override
  Future<void> enqueueSyncOp(Task task) async { ... }
}
```

### 7.5 Runtime Behavior & Integration

At runtime, Dart "flattens" this hierarchy.

- **One Object**: When you create `TaskController`, there is only **one instance** in memory.
- **One Context**: `this` in the mixin is the *exact same object* as `this` in the controller.
- **No Magic**: Calling `createTask()` on the controller simply executes the code in the mixin, which calls `repo` in the controller. It is as efficient as writing the code directly in the class.

### 7.6 Naming Conventions

If you decide to split a controller using this pattern, follow these naming rules to keep things consistent:

1. **Base Class**: `FeatureNameControllerBase` (e.g., `TaskControllerBase`)
    - **File**: `feature_name_controller_base.dart`
    - **Role**: Abstract class that extends `ChangeNotifier`. Defines logical requirements (getters for repos/services) and shared abstract methods.

2. **CRUD Mixin**: `FeatureNameCrudMixin` (e.g., `TaskCrudMixin`)
    - **File**: `feature_name_crud_mixin.dart`
    - **Role**: Mixin constrained to the base class (`mixin ... on FeatureNameControllerBase`). Implements core CRUD operations (create, update, delete) using the abstract getters. This is where you'll see classes named `XCrudMixin`.

3. **Concrete Class**: `FeatureNameController` (e.g., `TaskController`)
    - **File**: `feature_name_controller.dart`
    - **Role**: The main class consumed by the UI. Extends `Base` and mixes in `CrudMixin`. Injects real dependencies and handles other logic (filters, sorting, streams).

### 7.7 When to Use This Pattern

✅ **Use when:**

- Controller exceeds ~200 lines.
- Clear logical groupings exist (CRUD, sync, filters).

❌ **Don't use when:**

- Controller is small (e.g., `NoteController` is < 200 lines).
- Overkill adds complexity without benefit.

---

## 8. Hive Binary Serialization

Hive stores Dart objects as binary data. Understanding this format helps when writing custom adapters or debugging storage issues.

### The Binary Format

When Hive writes an object, it uses this structure:

```text
[fieldCount] [key0] [value0] [key1] [value1] ... [keyN] [valueN]
   1 byte    1 byte  varies  1 byte  varies
```

| Component | Size | Description |
|-----------|------|-------------|
| `fieldCount` | 1 byte | Total number of fields stored |
| `key` | 1 byte | Field index (0-255), matches `@HiveField(n)` |
| `value` | varies | Encoded value (Hive handles primitives, custom adapters handle objects) |

### Visual Example

Here's how a `SyncOperation` with `id="abc"`, `type=1`, `entityType="task"` actually looks in binary:

```text
┌───────────────────────────────────────────────────────────────────────────────┐
│ [9] [0] [3] ['a']['b']['c'] [1] [1] [2] [4] ['t']['a']['s']['k'] ...          │
│  │   │   └────────┬───────┘  │   │   │   └────────────┬──────────┘            │
│  │   │   String "abc"        │   │   │   String "task" (4 chars)              │
│  │   │   (length=3 + chars)  │   │   └── Field key 2 (entityType)             │
│  │   │                       │   └────── Value: 1 (int, 1 byte for small ints)│
│  │   └── Field key 0 (id)    └── Field key 1 (type)                           │
│  └────── 9 fields total                                                       │
└───────────────────────────────────────────────────────────────────────────────┘
```

**Reading this left to right:**

1. `[9]` — "This object has 9 fields"
2. `[0]` — "The next value is for field 0 (id)"
3. `[3]['a']['b']['c']` — String encoding: length byte + UTF-8 chars
4. `[1]` — "The next value is for field 1 (type)"
5. `[1]` — The integer value 1 (meaning "update")
6. `[2]` — "The next value is for field 2 (entityType)"
7. `[4]['t']['a']['s']['k']` — String "task"
8. ...and so on for remaining fields

### Model Class Example

```dart
@HiveType(typeId: HiveTypeIds.syncOperation)
class SyncOperation extends HiveObject {
  @HiveField(0) final String id;           // key = 0
  @HiveField(1) final int type;            // key = 1
  @HiveField(2) final String entityType;   // key = 2
  @HiveField(3) final String entityId;     // key = 3
  @HiveField(4) final Map<String, dynamic>? data;  // key = 4
  // ...
}
```

### Reading Data (Adapter)

```dart
@override
SyncOperation read(BinaryReader reader) {
  // First byte = number of fields stored
  final fieldCount = reader.readByte();

  // Build a map of field index → value
  // This allows handling missing fields gracefully (backwards compatibility)
  final fields = <int, dynamic>{};
  for (var i = 0; i < fieldCount; i++) {
    // Each field: [1-byte key][encoded value]
    final key = reader.readByte();    // e.g., 0 = id, 1 = type
    fields[key] = reader.read();      // Hive auto-decodes based on type
  }

  // Construct object with defaults for missing fields
  return SyncOperation(
    id: fields[0] as String,
    type: fields[1] as int,
    entityType: fields[2] as String,
    entityId: fields[3] as String,
    data: (fields[4] as Map?)?.cast<String, dynamic>(),
    retryCount: (fields[5] as int?) ?? 0,  // Default if field doesn't exist
    // ...
  );
}
```

### Writing Data (Adapter)

```dart
@override
void write(BinaryWriter writer, SyncOperation obj) {
  writer
    ..writeByte(9)           // fieldCount: 9 fields total
    ..writeByte(0)           // key for field 0
    ..write(obj.id)          // value for field 0
    ..writeByte(1)           // key for field 1
    ..write(obj.type)        // value for field 1
    ..writeByte(2)
    ..write(obj.entityType)
    // ... continue for all fields
}
```

### Why Field Keys (Not Order) Matter

Hive identifies fields by their numeric key, not their position. This enables:

| Scenario | What Happens |
|----------|--------------|
| **Add new field** `@HiveField(9)` | Old data still works — field 9 just returns null/default |
| **Remove field** | Old data has unused key — safely ignored |
| **Reorder fields in code** | No effect — keys stay the same |
| **Change key number** | ⚠️ **BREAKS DATA** — old data maps to wrong field |

### Key Rules

1. **Never reuse a type ID** — Each model needs a unique ID in `hive_type_ids.dart`
2. **Never change `@HiveField` numbers** — Existing data will map to wrong fields
3. **Add new fields at the end** — Use the next available number
4. **Handle nulls gracefully** — Use `?? defaultValue` for optional/new fields

### Handling Firestore Timestamps

Hive can't serialize Firestore `Timestamp` objects directly. Custom adapters must convert them:

```dart
/// Recursively converts Firestore Timestamps to DateTime
dynamic _convertTimestamps(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();  // Timestamp → DateTime
  } else if (value is Map) {
    return value.map((k, v) => MapEntry(k, _convertTimestamps(v)));
  } else if (value is List) {
    return value.map(_convertTimestamps).toList();
  }
  return value;
}

@override
void write(BinaryWriter writer, SyncOperation obj) {
  // Sanitize data before writing
  final sanitizedData = obj.data != null 
      ? _convertTimestamps(obj.data) 
      : null;
  // ... write sanitizedData instead of obj.data
}
```

---

## 9. Rich Text Editing (Quill and Delta Format)

The app uses `flutter_quill` for rich text editing in Notes. This section explains the underlying data structure and how we handle persistence.

### What is Quill?

**Quill** is a rich-text editor ecosystem.

- In our Flutter app we use the package **`flutter_quill`**.
- Quill stores content as a **Delta** (a list of operations) rather than HTML.

In Nexus, the note’s rich content is stored as a **Delta JSON string** in `Note.contentDeltaJson` / `NoteEntity.contentDeltaJson`.

### How Nexus uses Quill (Notes editor)

At a high level:

1. We load a `NoteEntity` from the repository (Hive is the local source of truth).
2. We create a `quill.QuillController` from `contentDeltaJson`.
3. We render the editor using `QuillEditor`.
4. On edits, we serialize the document back to Delta JSON and persist it locally.

Key places in the codebase:

```text
lib/features/notes/presentation/widgets/editor/note_editor_view.dart
  - owns the QuillController + title/markdown controllers
  - schedules autosave on edits

lib/features/notes/presentation/widgets/editor/helpers/note_editor_autosave_controller.dart
  - builds contentDeltaJson from Quill Document (or Markdown text)
  - calls NoteController.saveEditor(...)
```

### PopScope in the Notes editor (why it exists)

Flutter’s `PopScope` is the modern replacement for `WillPopScope` and supports Android predictive back.

In Nexus we use it in the note editor to trigger a “final sync save” **when the route has actually popped**.

- The callback is `onPopInvokedWithResult(didPop, result)`.
- When `didPop == true`, the note editor is closing, so we trigger:

```dart
unawaited(_autosave?.flush(syncRemote: true) ?? Future.value());
```

This does **not** block navigation; it just ensures we try to enqueue/sync the latest version on exit.

### What does `flush(syncRemote: true)` mean?

The note editor has two save “modes”:

- **Local autosave** (`syncRemote: false`)
  - debounced (after the user pauses typing)
  - writes to local storage immediately
  - does *not* enqueue a remote sync operation

- **Sync flush on exit/background** (`syncRemote: true`)
  - runs when the user leaves the editor or the app is backgrounded
  - persists locally and **also enqueues sync** so the remote version can be updated

This matches the “maximize reliability” strategy:

- local is always updated quickly (crash-safe)
- remote is updated at safe moments (exit/background) without blocking the UI

The actual autosave helper in Nexus is `NoteEditorAutosaveController`. Two key methods are:

```dart
void scheduleLocalSave() {
  _debounce?.cancel();
  _debounce = Timer(debounceDuration, () {
    unawaited(flush(syncRemote: false));
  });
}

Future<void> flush({required bool syncRemote}) async {
  await _notes.saveEditor(
    noteId: _noteId,
    title: _titleController.text,
    contentDeltaJson: _currentDeltaJson(),
    isMarkdown: _isMarkdown(),
    enqueueSync: syncRemote,
  );
}
```

And `_currentDeltaJson()` is the bridge between the editor state and persistence:

```dart
return jsonEncode(_quillController.document.toDelta().toJson());
```

### Inline attachment markers (voice/image)

When the user attaches a voice note or an image, we insert an inline marker in the text at the current cursor position so the content clearly indicates “attachment was added here”.

We centralize insertion logic in `NoteEditorMarkerInserter`:

```dart
void insert({
  required bool isMarkdown,
  required TextEditingController markdownController,
  required quill.QuillController quillController,
  required String marker,
}) {
  if (isMarkdown) {
    // Inserts into markdownController at selection start.
  } else {
    // Inserts into Quill document at cursor.
    quillController.document.insert(safeOffset, '$marker ');
  }
}
```

### Why not HTML or Markdown?

We use **Quill Delta** format instead of HTML or Markdown because:

1. **Source of Truth**: It is the native format of the editor. Converting to/from HTML/Markdown can cause data loss (e.g., specific attributes, nested lists).
2. **Operational Transform**: Delta is designed for real-time collaboration and granular change tracking (useful for future sync improvements).
3. **JSON Structure**: Easy to parse, validate, and manipulate programmatically.

### The Delta Format

A Delta is a JSON array of operations. It describes *how to create* the document.

```json
[
  {"insert": "Hello "},
  {"insert": "World", "attributes": {"bold": true}},
  {"insert": "\n"}
]
```

| Operation    | Action                                                          |
|--------------|-----------------------------------------------------------------|
| `insert`     | Adds text or embeds (images, line breaks)                       |
| `attributes` | (Optional) Strings or maps defining style (bold, header, color) |

### Persistence Strategy

1. **Saving**: We serialize the Delta to a JSON string before saving to Hive/Firestore.

   ```dart
   note.contentDeltaJson = jsonEncode(controller.document.toDelta().toJson());
   ```

2. **Loading**: We parse the JSON string back into a Delta to initialize the controller.

   ```dart
   final json = jsonDecode(note.contentDeltaJson);
   final doc = Document.fromJson(json);
   _controller = QuillController(document: doc, ...);
   ```

3. **Handling Empty/Corrupt Data**:
   - Always wrap parsing in a `try/catch` block.
   - Fallback to an empty document (must contain at least one newline `\n` to be valid).

### Read-Only Previews (Lightweight)

To avoid instantiating a heavy `QuillController` just to show a list preview, we extract plain text directly from the Document model:

```dart
String getPreviewText(Note note) {
  try {
    final doc = Document.fromJson(jsonDecode(note.contentDeltaJson));
    return doc.toPlainText();  // ← Fast, no UI widgets needed
  } catch (e) {
    return "";
  }
}
```

### Read-Only Editor (Visual)

For the **Conflict Resolution Dialog**, we need to show the *formatted* note but prevent editing. We use a standard `QuillEditor` with specific flags:

```dart
QuillEditor.basic(
  controller: controller,
  config: const QuillEditorConfig(
    readOnly: true,        // ← Disables keyboard & editing
    enableInteractiveSelection: false, // ← Optional: disable selection
    showCursor: false,
  ),
)
```

---
