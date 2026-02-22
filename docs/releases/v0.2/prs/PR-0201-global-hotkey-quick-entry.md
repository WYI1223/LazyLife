# PR-0201-global-hotkey-quick-entry

- Proposed title: `feat(windows): global hotkey + quick entry window`
- Status: Deferred to v0.3 (`PR-0311-windows-global-hotkey-quick-entry`)

## Goal

Provide a global quick-entry entrypoint on Windows for capture-first flow.

## Deferral Decision (2026-02-22)

- deferred from v0.2 to v0.3 to avoid introducing runner/lifecycle instability
  during v0.2 closure
- execution owner moved to `docs/releases/v0.3/prs/PR-0311-windows-global-hotkey-quick-entry.md`

## Scope (target: v0.3)

In scope:

- register a global hotkey for quick entry window toggle
- show/hide/focus quick entry without disrupting current workspace session
- route quick entry command/search results to main workspace active pane

Out of scope:

- platform parity for macOS/Linux
- full multi-window orchestration model

## Why Deferred from v0.1

- v0.1 prioritized Rust core/data/notes baseline closure.
- global window/hotkey behavior introduces additional platform and lifecycle risk.

## Step-by-Step

1. Define hotkey config contract (default + override path).
2. Implement Windows registration/unregistration lifecycle.
3. Add quick entry host window with focus/restore behavior.
4. Bridge quick entry actions to existing entry router and workspace state.
5. Add diagnostics output for hotkey registration failures.

## Planned File Changes

- [edit] `apps/lazynote_flutter/windows/runner/*` (hotkey/window host glue)
- [edit] `apps/lazynote_flutter/lib/features/entry/*` (quick entry routing integration)
- [edit] `apps/lazynote_flutter/lib/features/entry/entry_shell_page.dart`
- [edit] `docs/architecture/settings-config.md` (hotkey config keys if added)

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test`
- manual Windows validation:
  - hotkey opens quick entry while app is backgrounded
  - hotkey toggles visibility/focus reliably
  - selected note opens in current active pane

## Acceptance Criteria

- [ ] Global hotkey can open/focus quick entry window on Windows.
- [ ] Quick entry result can open note in workspace active pane.
- [ ] Failure paths are non-fatal and diagnosable.
