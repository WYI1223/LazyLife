# PR-0209-ui-localization-cn-en

- Proposed title: `feat(ui): CN/EN localization baseline with runtime switch`
- Status: Planned

## Goal

Introduce a stable localization baseline so users can switch UI language between Chinese and English.

## Scope (v0.2)

In scope:

- localization resource structure (`en`, `zh-CN`)
- language selection UI in settings/workspace shell
- persistence of language preference in local settings
- migrate existing visible UI strings in active surfaces (Workbench, Notes, diagnostics)

Out of scope:

- full locale matrix beyond CN/EN
- localization for future modules not yet shipped

## Step-by-Step

1. Add localization scaffolding and resource files.
2. Add settings key for language preference.
3. Migrate existing hardcoded strings to localized resources.
4. Add fallback and startup language resolution logic.
5. Add tests for language switch and persistence.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/app/app.dart`
- [edit] `apps/lazynote_flutter/lib/core/settings/local_settings_store.dart`
- [add] `apps/lazynote_flutter/lib/l10n/*`
- [edit] `apps/lazynote_flutter/lib/features/entry/*`
- [edit] `apps/lazynote_flutter/lib/features/notes/*`
- [edit] `apps/lazynote_flutter/lib/features/diagnostics/*`
- [add] `apps/lazynote_flutter/test/localization_switch_test.dart`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test`

## Acceptance Criteria

- [ ] User can switch CN/EN in UI.
- [ ] Preference persists across app restarts.
- [ ] Missing translation gracefully falls back to canonical key/English path.

