/// Domain enums for tasks (pure Dart, shared by domain and data layers).
enum TaskStatus { active, pending, completed }

enum TaskPriority { low, medium, high }

enum TaskDifficulty { low, medium, high }

enum TaskRecurrenceRule { none, daily, weekly }

enum SyncStatus { idle, syncing, synced, conflict, error }
