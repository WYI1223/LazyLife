# PR-0216-ui-extension-slots

- Proposed title: `feat(ui-platform): block/view/panel/widget slot contracts`
- Status: Planned

## Goal

Define layered UI extension slots so features can be composed without tightly coupling view code.

## Scope (v0.2)

In scope:

- slot contracts for:
  - content block
  - view
  - side panel
  - home widget
- host lifecycle and rendering priority rules
- first-party slot registration baseline

Out of scope:

- visual redesign of all pages
- remote-loaded UI packages

## Step-by-Step

1. Define slot schemas and host interfaces.
2. Implement host adapters in Flutter shell.
3. Migrate a small first-party subset to slot registration.
4. Add widget tests for slot ordering and fallback behavior.

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/app/ui_slots/*`
- [edit] `apps/lazynote_flutter/lib/features/entry/entry_shell_page.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/*`
- [add] `apps/lazynote_flutter/test/ui_slots_host_test.dart`
- [add] `docs/architecture/ui-extension-slots.md`

## Dependencies

- `PR-0213-extension-kernel-contracts`

## Verification

- `flutter analyze`
- `flutter test`

## Acceptance Criteria

- [ ] Slot contracts are implemented for block/view/panel/widget layers.
- [ ] Slot rendering order and fallback rules are deterministic.
- [ ] First-party features can register into slots without direct host coupling.

