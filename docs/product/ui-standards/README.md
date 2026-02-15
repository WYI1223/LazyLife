# UI Standards

This folder stores cross-feature UI standards and visual references for Flutter implementation.

## Scope

- Include: layout grammar, component structure, interaction patterns, visual references.
- Exclude: feature business logic, backend/API behavior, implementation tickets.

## Recommended for Flutter Developers

Use the following developer-spec documents as the primary implementation input:

| File | Target Surface | Platform | Last Updated | Owner | Notes |
| --- | --- | --- | --- | --- | --- |
| `note-ui-dev-spec.md` | Notes workspace / editor shell | Desktop first | 2026-02-15 | TBD | Includes optional floating capsule variant |
| `task-ui-dev-spec.md` | Tasks dashboard cards / drag-drop UI | Desktop first | 2026-02-15 | TBD | Includes 3-card structure and DnD visual behavior |
| `calendar-ui-dev-spec.md` | Calendar split-view weekly layout | Desktop first | 2026-02-15 | TBD | Unified card shell + inset divider + layered week grid |

## Source Notes (Original Collection)

The following files are kept as original reference material:

- `note-ui.md`
- `task-ui.md`
- `calendar-ui.md`

## Images

Store all source screenshots/renders in `images/`.

Current references:

- `images/SingleEntryCapsule.png`
- `images/TaskUIwithCapsule.png`
- `images/TaskUIwithCreateoperation.png`
- `images/TaskUIwithoutCapsule.png`
- `images/CalendarUI.png`
- `images/NoteUI.png`
- `images/NoteUIwithCapsule.png`

## Naming Convention

Use lowercase kebab-case for all docs and assets:

- Docs: `feature-name.md`
- Images: `FeatureNameVariant.png` or `feature-name-variant.png` (choose one style and keep it consistent)

## Maintenance Rules

- Update this index table whenever adding or renaming a UI standard document.
- Keep one topic per file to avoid mixed-spec drift.
- If a standard is release-specific, add a backlink from the corresponding `docs/releases/v*/` README or PR note.
