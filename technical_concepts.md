# Technical Concepts

This document explains general technical patterns and concepts used in the app. These are not specific to the app's business logic but are foundational programming patterns.

---

## Singleton Pattern

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

## Dependency Injection

**Dependency Injection (DI)** means passing dependencies into a class instead of creating them inside.

### Why use it?

| Approach | Testable? | Flexible? |
|----------|-----------|-----------|
| Create inside: `final _conn = Connectivity()` | ❌ Can't mock | ❌ Hardcoded |
| Inject via constructor: `MyClass({Connectivity? conn})` | ✅ Can mock | ✅ Swappable |

### Pattern with optional parameter

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

### Do you need it?

- **If writing unit tests**: Yes, inject mocks
- **If not testing this class**: Optional, but costs nothing to keep

---

## Async Generators (`async*` and `yield`)

An **async generator** is a function that returns a `Stream` and can emit multiple values over time.

### `async` vs `async*`

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

## Streams and `await for`

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

*Add more technical concepts below as needed.*
