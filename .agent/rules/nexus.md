---
trigger: always_on
---

# Nexus — Canonical AI rules (tool-agnostic)

This file is the **canonical, repo-local AI guidance** for Nexus that should be
usable by **any** AI tool (Cursor, Antigravity, etc.).

Cursor-specific rule wiring should live in `.cursor/rules/` and **point here**
instead of duplicating these rules.

## Sources of truth to refresh before feature work

Before **designing**, **scoping**, or **implementing** a feature (or materially
changing existing behavior), refresh these docs so work matches Nexus patterns:

| Doc | Use it for |
|-----|------------|
| `docs/nexus_knowledge_base.md` | Stack, repo layout, routing/shell, sync/storage overview, where things live. |
| `developer_README.md` | Deep flows, file-level maps, conventions, and how similar features are built. |
| `docs/CLEAN_ARCHITECTURE_MIGRATION.md` | Domain / Data / Presentation expectations per feature. |

## Architecture consistency expectations

- Prefer **feature-first** layout under `lib/features/<feature>/` with `domain/`,
  `data/`, `presentation/` where applicable.
- Reuse existing **Provider + ChangeNotifier** patterns; respect **shell vs root
  navigator** patterns (note editor / theme flows).
- Put cross-cutting logic in `lib/core/` **only** when it is truly shared;
  otherwise keep it inside the feature.
- Match routing patterns (`GoRouter`, `StatefulShellRoute`, imperative pushes)
  to patterns already documented in the knowledge base.

If you intentionally diverge from existing patterns, **update the docs in the
same work session** to explain the new approach.

## Documentation sync (required)

When a task changes **behavior, architecture, UX, routes, storage, tests, CI, or
dependencies**, update docs in the same session:

- `README.md` (user-facing, non-technical outcomes)
- `docs/nexus_knowledge_base.md` (high-level technical orientation)
- `developer_README.md` (deep technical walkthrough/reference)

Enforcement checklist:

1. Before finishing (or before commit if committing), review whether behavior or
   structure changed.
2. If changed, update all relevant sections across the three docs.
3. Keep boundary separation:
   - `README.md`: product language only.
   - `nexus_knowledge_base`: architecture/system map, not deep implementation internals.
   - `developer_README`: implementation details, workflows, troubleshooting.
4. Verify referenced file paths/links exist after edits.
5. After implementation is complete, run `scripts/run_ci_locally.ps1` and ensure
   the full local CI pipeline is green.

