# PR-0209-ui-localization-cn-en

- Proposed title: `feat(ui): CN/EN localization baseline with runtime switch`
- Status: Completed

## Goal

Introduce a stable localization baseline so users can switch UI language between Chinese and English.

## Scope (v0.2)

In scope:

- localization resource structure (`en`, `zh-CN`)
- language selection UI in settings/workspace shell
- persistence of language preference in local settings
- migrate existing visible UI strings in active surfaces (Workbench, Notes, diagnostics)
- startup locale resolution and fallback behavior

Out of scope:

- full locale matrix beyond CN/EN
- localization for future modules not yet shipped
- Rust/Core-side localization (Flutter-only for v0.2)

## Contract Freeze (M1)

This section is the M1 source of truth for implementation.

1. Locale set
   - supported locales: `en`, `zh-CN`
   - no additional locale introduced in v0.2
2. Settings contract
   - persist language preference in `settings.json` as `ui.language`
   - allowed values: `system | en | zh-CN`
   - invalid value fallback: `system`
3. Startup resolution order
   - explicit `ui.language` (`en`/`zh-CN`) takes priority
   - `system` maps platform locale to nearest supported locale
   - if system locale is unsupported, fallback to `en`
4. First-frame policy
   - locale is a first-frame-affecting setting
   - `main.dart` must apply layered loading for locale resolution:
     - critical locale read before `runApp`
     - non-critical settings remain in background bootstrap
5. Contract boundary
   - no Rust FFI API shape changes
   - no stable error-code catalog change (`docs/api/error-codes.md`)
   - no API lifecycle/deprecation surface change

## Milestones

### M1 - Contract and Plan Freeze (completed)

1. Freeze scope and startup strategy.
2. Freeze settings key and value grammar.
3. Freeze fallback rules and out-of-scope boundaries.
4. Sync release plan status.

M1 progress:

- [x] CN/EN locale set and settings value grammar frozen.
- [x] startup resolution order and first-frame policy frozen.
- [x] FFI/error-code boundary frozen (Flutter-only delivery).
- [x] release plan status synchronized.

### M2 - Localization Implementation

1. Add Flutter localization scaffolding (`l10n` resources and generated accessors).
2. Add `ui.language` read/backfill/write in `LocalSettingsStore`.
3. Wire app-level locale configuration in `MaterialApp`.
4. Add runtime language switch UI in settings shell.
5. Migrate visible strings in active surfaces:
   - Workbench navigation labels
   - Notes shell/explorer key actions
   - diagnostics panel/core controls

M2 progress:

- [x] Added `l10n` resource scaffold (`app_en.arb`, `app_zh.arb`, `app_zh_CN.arb`) and generated localizations.
- [x] Added `ui.language` contract parse/backfill/persist path in `LocalSettingsStore`.
- [x] Added app-level locale runtime controller and `MaterialApp` locale/delegates wiring.
- [x] Added settings language selector (runtime switch with persistence and failure fallback).
- [x] Migrated Workbench shell, settings capability page, and diagnostics panel/core baseline strings.
- [x] Complete Notes active-surface string migration sweep.
- [x] Add dedicated startup-resolution + runtime-switch regression bundle.

### M3 - Regression and Closure

1. Add tests for startup locale resolution and persistence.
2. Add widget coverage for runtime language switching.
3. Re-run `flutter analyze` and full `flutter test`.
4. Sync docs/contracts and mark PR as completed.

M3 progress:

- [x] Re-ran `flutter analyze` and full `flutter test` after Notes migration.
- [x] Synced docs/contracts to reflect M2 completion.
- [x] Add dedicated startup locale resolution regression test (`test/localization_startup_resolution_test.dart`).
- [x] Add runtime language switch regression test (`test/localization_switch_test.dart`).

## Step-by-Step (M2/M3 Execution)

1. Add localization scaffolding and resource files.
2. Add `ui.language` settings key persistence path.
3. Add locale fallback and startup resolution path.
4. Migrate hardcoded strings in active surfaces.
5. Add tests for switch + persistence + fallback.
6. Update docs and closure checklist.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/app/app.dart`
- [edit] `apps/lazynote_flutter/lib/main.dart`
- [edit] `apps/lazynote_flutter/lib/core/settings/local_settings_store.dart`
- [add] `apps/lazynote_flutter/lib/l10n/*`
- [edit] `apps/lazynote_flutter/lib/features/settings/*`
- [edit] `apps/lazynote_flutter/lib/features/entry/*`
- [edit] `apps/lazynote_flutter/lib/features/notes/*`
- [edit] `apps/lazynote_flutter/lib/features/diagnostics/*`
- [add] `apps/lazynote_flutter/test/localization_switch_test.dart`
- [add] `apps/lazynote_flutter/test/localization_startup_resolution_test.dart`
- [edit] `docs/releases/v0.2/README.md`
- [edit] `docs/releases/v0.2/prs/PR-0209-ui-localization-cn-en.md`

## Verification

- `cd apps/lazynote_flutter && flutter gen-l10n`
- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test`

## Acceptance Criteria

- [x] User can switch CN/EN in UI.
- [x] Preference persists across app restarts.
- [x] Startup locale resolution follows `ui.language -> system -> en` contract.
- [x] Missing translation gracefully falls back to English path.
- [x] No FFI/API contract drift introduced by localization PR.
