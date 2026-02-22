# PR-0311-windows-global-hotkey-quick-entry

- Proposed title: `feat(windows): global hotkey + quick entry runtime integration`
- Status: Planned

## Goal

Provide a global quick-entry entrypoint on Windows with stable focus/toggle behavior.

## Scope (v0.3)

In scope:

- register a global hotkey for quick entry window toggle
- show/hide/focus quick entry without disrupting current workspace session
- route quick entry command/search results to workspace active pane
- diagnostics output for hotkey registration lifecycle failures

Out of scope:

- platform parity for macOS/Linux
- full multi-window orchestration model

## Dependency

- source migration from deferred `PR-0201-global-hotkey-quick-entry`
- should run after tab/entry semantic stabilization in:
  - `PR-0304-tab-preview-pinned-model`
  - `PR-0310-first-party-command-parser-plugins`

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

