# Clean Architecture Compliance Report

**Expected structure:**
```
lib/features/<feature_name>/
  ├── domain/          (PURE DART - no Flutter, no external libs)
  │   ├── entities/
  │   ├── repositories/ (abstract interfaces)
  │   └── use_cases/
  ├── data/            (implementation details)
  │   ├── models/      (DTOs, Hive adapters; extend domain entities)
  │   ├── repositories/ (implementations of domain repositories)
  │   └── data_sources/
  └── presentation/
      ├── state_management/ (Providers / ChangeNotifiers)
      ├── pages/            (Scaffolds)
      └── widgets/          (Components)
```

---

## 1. `lib/features/wrapper`

**Current structure:**
- `views/` — app_wrapper.dart, app_drawer.dart, nav_bar_wrappers/*, views/widgets/*

**Compliance:** ❌ **Does not follow**

| Issue | Current | Expected |
|-------|---------|----------|
| No `presentation/` | Uses `views/` at root | `presentation/pages/` and `presentation/widgets/` |
| No domain/data | None | OK if feature is UI-only (no business logic) |
| Naming | `views/` | `presentation/pages/` for screens, `presentation/widgets/` for components |

**Recommendation:** Rename `views/` → `presentation/`, then move screens into `presentation/pages/` and reusable pieces into `presentation/widgets/`. No domain or data layer needed if this stays UI-only.

---

## 2. `lib/features/theme_customization`

**Current structure:**
- `presentation/widgets/` (nav_bar_styles, colors, presets, preview)
- `presentation/pages/` (theme_customization_screen.dart)

**Compliance:** ✅ **Mostly compliant**

| Item | Status |
|------|--------|
| presentation/pages/ | ✅ |
| presentation/widgets/ | ✅ |
| presentation/state_management/ | Missing (only if this feature has its own state) |
| domain/ | Not present — acceptable for pure UI/theming |
| data/ | Not present — acceptable |

**Recommendation:** No structural change required. Add `presentation/state_management/` only if you introduce a dedicated controller/notifier for this feature.

---

## 3. `lib/features/tasks` (and `controllers/`)

**Current structure (summary):**
- `domain/` — entities/, repositories/, use_cases/, task_enums.dart ✅
- `data/` — mappers/, repositories/task_repository_impl.dart, plus **root-level** `task_repository.dart`, `task_local_datasource.dart`
- `controllers/` — task_controller, category_controller, helpers
- `views/` — tasks_screen, widgets/*, utils/*
- `models/` — task.dart, category.dart, task_attachment.dart, task_editor_result.dart, task_sort_option.dart, category_sort_option.dart, task_repository.dart, task_local_datasource.dart
- `sync/` — task_sync_handler.dart
- `utils/` — task_date_formatter.dart
- `presentation/` — only extensions/

**Compliance:** ❌ **Partially compliant — several violations**

| Issue | Current | Expected |
|-------|---------|----------|
| Controllers location | `controllers/` at feature root | `presentation/state_management/` |
| Views location | `views/` at root | `presentation/pages/` + `presentation/widgets/` |
| Data models | `models/` at root (Task, Category, task_attachment — Hive DTOs) | `data/models/` |
| Data repositories | `data/task_repository.dart` (concrete) + `models/task_repository.dart` (duplicate?) | `data/repositories/` only; one impl implementing domain contract |
| Data sources | `data/task_local_datasource.dart` + `models/task_local_datasource.dart` | `data/data_sources/` (single place) |
| Sync handler | `sync/task_sync_handler.dart` | Prefer `data/` (e.g. `data/sync/` or under repositories if it’s sync impl detail) |
| Presentation layer | `views/` + `presentation/extensions/` | `presentation/pages/`, `presentation/widgets/`, `presentation/state_management/` |

**Recommendation:**
- Move `controllers/` → `presentation/state_management/`.
- Move `views/*` into `presentation/`: e.g. tasks_screen → `presentation/pages/`, rest → `presentation/widgets/` (with subfolders as needed).
- Move Hive/JSON DTOs from `models/` (task.dart, category.dart, task_attachment.dart, task_local_datasource if it’s a class) into `data/models/`; keep or move presentation-only models (task_editor_result, task_sort_option, category_sort_option) under `presentation/` or a clear subfolder.
- Consolidate repository/datasource: single implementation in `data/repositories/`, single local datasource in `data/data_sources/`; remove duplicate `task_repository.dart` / `task_local_datasource.dart` from `models/` and from `data/` root.
- Put `task_sync_handler` under `data/` (e.g. `data/sync/` or next to repositories).

---

## 4. `lib/features/task_editor`

**Current structure:**
- `task_editor_sheet.dart` (root)
- `widgets/` — task_attribute_selectors, task_quick_options, task_priority_button, task_category_selector, task_editor_inputs, task_option_chip, task_editor_header

**Compliance:** ❌ **Does not follow**

| Issue | Current | Expected |
|-------|---------|----------|
| No `presentation/` | Root + `widgets/` | `presentation/pages/` (or screens) and `presentation/widgets/` |
| Main screen at root | task_editor_sheet.dart | e.g. `presentation/pages/task_editor_sheet.dart` or `presentation/widgets/` if it’s a component |
| No domain/data | None | OK if task_editor only uses tasks domain and has no own entities/repos |

**Recommendation:** Introduce `presentation/`: e.g. move `task_editor_sheet.dart` to `presentation/widgets/` (or `presentation/pages/` if you treat it as a page), and keep the rest under `presentation/widgets/`. No domain/data required if this feature only consumes tasks domain.

---

## 5. `lib/features/sync`

**Current structure:**
- `presentation/state_management/sync_controller.dart`
- `presentation/widgets/sync_status_widget.dart` (task conflict dialog moved to `lib/features/tasks/presentation/widgets/task_conflict_resolution_dialog.dart`)

**Compliance:** ❌ **Does not follow**

| Issue | Current | Expected |
|-------|---------|----------|
| Controllers | `controllers/` at root | `presentation/state_management/` |
| Views | `views/` at root | `presentation/widgets/` (or pages if you have a full screen) |

**Recommendation:** Move `controllers/` → `presentation/state_management/`, and `views/` → `presentation/widgets/` (and `presentation/pages/` if you add a dedicated sync page). If sync has its own domain (e.g. conflict resolution rules), add `domain/` later.

---

## 6. `lib/features/splash`

**Current structure:**
- `models/` — app_initialization_result.dart, critical_initialization_result.dart
- `controllers/` — provider_factory.dart, app_initializer.dart
- `views/` — splash_screen.dart, splash_wrapper.dart

**Compliance:** ❌ **Does not follow**

| Issue | Current | Expected |
|-------|---------|----------|
| Controllers | `controllers/` at root | `presentation/state_management/` |
| Views | `views/` at root | `presentation/pages/` and `presentation/widgets/` |
| Models | `models/` at root (result DTOs / bootstrap objects) | If they are not domain entities: keep as presentation or a small “bootstrap” namespace; if they are DTOs, `data/models/` |

**Recommendation:** Move `controllers/` → `presentation/state_management/`. Move `views/` into `presentation/`: e.g. splash_screen → `presentation/pages/`, splash_wrapper → `presentation/widgets/`. Treat `app_initialization_result` and `critical_initialization_result` as presentation/bootstrap types (e.g. under `presentation/` or a dedicated `bootstrap/` folder) unless they become real DTOs for a data layer. Splash may not need domain/ or data/ if it only orchestrates app startup.

---

## Summary

| Feature | Compliant | Main changes needed |
|---------|-----------|----------------------|
| **wrapper** | ❌ | Use `presentation/` with pages + widgets instead of `views/`. |
| **theme_customization** | ✅ | None. |
| **tasks** | ❌ | Move controllers → presentation/state_management; views → presentation; DTOs → data/models; repos/datasources into data/repositories and data/data_sources; remove duplicates. |
| **task_editor** | ❌ | Introduce `presentation/` and put sheet + widgets under pages/widgets. |
| **sync** | ❌ | Move controllers → presentation/state_management; views → presentation/widgets (and pages if needed). |
| **splash** | ❌ | Move controllers → presentation/state_management; views → presentation/pages and presentation/widgets. |

If you want, the next step can be a concrete migration plan (file moves and import updates) for one feature (e.g. tasks or splash) so you can repeat the pattern for the rest.
