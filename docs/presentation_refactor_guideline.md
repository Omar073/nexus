# Presentation Extraction Guideline

This guideline defines how presentation code should be split to keep screens/sheets short and maintainable.

## Target structure

- `presentation/pages` and `presentation/widgets`: composition and rendering only
- `presentation/state`: mutable UI/view state containers
- `presentation/logic`: interaction/orchestration helpers (callbacks, flow glue, mapper-like UI helpers)

## Extraction defaults

- Extract by default when a file:
  - exceeds ~220 lines, or
  - mixes rendering with more than 3 interaction helpers (`_onX`, `_startY`, `_commitZ`, etc)
- Keep helpers local only when file is small and clearly cohesive.

## Root route safety

For root sheets/dialogs/routes:

- read providers from caller context before opening route
- pass dependencies explicitly into sheet/dialog content
- avoid provider reads from root route contexts when feature-scoped providers are expected

## Practical checklist

1. Keep page/sheet widget focused on wiring.
2. Move mutable UI state to `presentation/state`.
3. Move interaction/orchestration helpers to `presentation/logic`.
4. Keep reusable UI components in `presentation/widgets`.
5. Validate after each batch:
   - `flutter analyze`
   - `scripts/run_ci_locally.ps1`
   - focused tests, then full `flutter test`
   - `flutter build apk --debug` at the end of phase
