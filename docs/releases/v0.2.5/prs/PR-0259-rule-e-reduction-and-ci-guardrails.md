# PR-0259-rule-e-reduction-and-ci-guardrails

- Proposed title: `refactor(frontend): PR-0259 Rule E violation reduction and CI guardrails`
- Status: Planned

## Goal

Eliminate 4 Rule E violations (notes↔tags cycle + reminders cross-feature
import) and establish automated CI guardrails to prevent new architecture
violations during v0.3 development.

Prerequisite:

- `PR-0258` completed (import state must be stable before establishing CI checks).

## Execution Contract (Canonical Inputs)

- PR plan: `docs/reports/v0.2.5/frontend-review/08d-pr-replanning.md` Section 4.7
- Solution proposals: `docs/reports/v0.2.5/frontend-review/08c-solution-proposals.md` Sections 3.1.2, 3.1.4, 3.2
- Rule E definition: `docs/architecture/engineering-standards.md`

## Scope

In scope:

- 08c 3.1.2 (notes↔tags cycle break)
- 08c 3.1.4 (reminders migration to `core/`)
- 08c 3.2 (CI architecture check script + workflow)

Out of scope:

- entry→search decoupling (v0.3, LOW)
- entry→diagnostics decoupling (v0.3, LOW)
- notes→workspace pane layout import (v0.3 Phase 2)

## Task Breakdown

### Tags Cycle Break (08c 3.1.2)

| Task | Content | File | Est. Change | Dep |
|------|---------|------|-------------|-----|
| T1 | Create `lib/shared/ui_tokens.dart`, extract 4 shared color constants | `[add]` `lib/shared/ui_tokens.dart` | new file ~15 lines | — |
| T2 | `notes_style.dart` re-export shared constants (`export` statement), notes internal consumers need no import change | `[edit]` `lib/features/notes/notes_style.dart` | edit ~8 lines | T1 |
| T3 | `tag_filter.dart` import from `notes_style.dart` changed to `shared/ui_tokens.dart` | `[edit]` `lib/features/tags/tag_filter.dart` | edit 1 line | T1 |

### Reminders Migration (08c 3.1.4)

| Task | Content | File | Est. Change | Dep |
|------|---------|------|-------------|-----|
| T4 | Create `lib/core/reminders/` directory, move `reminder_scheduler.dart` | `[move]` `features/reminders/` → `core/reminders/` | 0 net lines | — |
| T5 | Move `reminder_service.dart` | `[move]` `features/reminders/` → `core/reminders/` | 0 net lines | T4 |
| T6 | Update 4 consumer imports: `main.dart`, `tasks_controller.dart`, `calendar_controller.dart`, `reminder_scheduler.dart` (internal import) | 4 files edit 1 line each | edit 4 lines | T4, T5 |
| T7 | Update test imports: `mock_reminder_service.dart`, `reminder_scheduler_test.dart` | 2 test files | edit 2-3 lines | T4, T5 |
| T8 | Delete empty `lib/features/reminders/` directory | `[delete]` directory | — | T6 |

### CI Guardrails (08c 3.2)

| Task | Content | File | Est. Change | Dep |
|------|---------|------|-------------|-----|
| T9 | Create `architecture_check.dart` unified analysis script (Rule E + file size + structural layer checks) | `[add]` `tools/ci/architecture_check.dart` | new file ~250 lines | — |
| T10 | Create `rule_e_allowlist.yaml` (3 exemptions: notes→workspace, entry→search, entry→diagnostics) | `[add]` `tools/ci/rule_e_allowlist.yaml` | new file ~20 lines | T9 |
| T11 | Create `file_size_exemptions.yaml` (1 exemption: note_explorer.dart 1,720 lines HOLD) | `[add]` `tools/ci/file_size_exemptions.yaml` | new file ~10 lines | T9 |
| T12 | Update CI workflow: add architecture check step in `flutter_windows` job | `[edit]` `.github/workflows/ci.yml` | add ~15 lines | T9 |

### Parallel Lanes (allowed)

- Tags (T1-T3) and Reminders (T4-T8) are independent and can run in parallel.
- CI scripts (T9-T12) can run in parallel with T1-T8.

## Branching Convention

- Branch: `feat/pr-0259-rule-e-reduction-and-ci`
- PR title: `refactor(frontend): PR-0259 Rule E violation reduction and CI guardrails`

## Planned File Changes

- `[add]` `apps/lazynote_flutter/lib/shared/ui_tokens.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_style.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/tags/tag_filter.dart`
- `[move]` `apps/lazynote_flutter/lib/features/reminders/reminder_scheduler.dart` → `apps/lazynote_flutter/lib/core/reminders/`
- `[move]` `apps/lazynote_flutter/lib/features/reminders/reminder_service.dart` → `apps/lazynote_flutter/lib/core/reminders/`
- `[edit]` `apps/lazynote_flutter/lib/main.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/tasks/tasks_controller.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/calendar/calendar_controller.dart`
- `[edit]` `apps/lazynote_flutter/test/helpers/mock_reminder_service.dart`
- `[edit]` `apps/lazynote_flutter/test/reminder_scheduler_test.dart`
- `[delete]` `apps/lazynote_flutter/lib/features/reminders/` (empty directory)
- `[add]` `tools/ci/architecture_check.dart`
- `[add]` `tools/ci/rule_e_allowlist.yaml`
- `[add]` `tools/ci/file_size_exemptions.yaml`
- `[edit]` `.github/workflows/ci.yml`

## Rule E Violation Impact

| State | Non-allowlisted violations | Allowlisted exemptions |
|-------|---------------------------|------------------------|
| Before PR-0259 | ~7 | 0 |
| After PR-0259 | **0** | 3 (notes→workspace, entry→search, entry→diagnostics) |

## Test Baseline

Entry: ~322 pass / 0 fail (PR-0258 exit)
Exit: **~322 pass / 0 fail** (no test additions or deletions in this PR)

## Task Checklist

- [ ] `T1` create `shared/ui_tokens.dart`
- [ ] `T2` re-export from `notes_style.dart`
- [ ] `T3` update `tag_filter.dart` import
- [ ] `T4` move `reminder_scheduler.dart` to `core/reminders/`
- [ ] `T5` move `reminder_service.dart` to `core/reminders/`
- [ ] `T6` update consumer imports
- [ ] `T7` update test imports
- [ ] `T8` delete empty `features/reminders/`
- [ ] `T9` create `architecture_check.dart`
- [ ] `T10` create `rule_e_allowlist.yaml`
- [ ] `T11` create `file_size_exemptions.yaml`
- [ ] `T12` update CI workflow

## Verification

### CI gates (cwd: `apps/lazynote_flutter/`)

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build windows --debug
dart run ../../tools/ci/architecture_check.dart
```

### Structural verification (cwd: repo root)

```bash
# Verify tags→notes import eliminated
rg -n "features/notes" apps/lazynote_flutter/lib/features/tags/
# Expected: zero matches

# Verify features/reminders deleted
test ! -d apps/lazynote_flutter/lib/features/reminders

# Verify core/reminders exists
test -f apps/lazynote_flutter/lib/core/reminders/reminder_scheduler.dart
test -f apps/lazynote_flutter/lib/core/reminders/reminder_service.dart

# Architecture check passes
cd apps/lazynote_flutter && dart run ../../tools/ci/architecture_check.dart
# Expected: 0 violations, 3 allowlisted
```

## Risk

| Risk | Severity | Mitigation |
|------|----------|------------|
| `architecture_check.dart` false positives | MEDIUM | Validate on post-PR-0258 code first, then integrate into CI |
| `notes_style.dart` re-export affects downstream | LOW | Dart `export` preserves API surface |
| Reminders migration impact | LOW | Pure file move + import update, no behavior change |

## Rollback

Tags fix (T1-T3) and reminders migration (T4-T8) are independent and can be
reverted separately. CI scripts (T9-T12) are additive — reverting only removes
the check.

## Acceptance Criteria

- [ ] `tag_filter.dart` no longer imports `features/notes/`.
- [ ] `lib/shared/ui_tokens.dart` exists with 4 shared color constants.
- [ ] `features/reminders/` directory no longer exists.
- [ ] `lib/core/reminders/` contains `reminder_scheduler.dart` and `reminder_service.dart`.
- [ ] All consumer and test imports updated.
- [ ] `architecture_check.dart` runs successfully: 0 non-allowlisted violations.
- [ ] File size check: no file exceeds 2,200 lines; `note_explorer.dart` (1,720) triggers warning only.
- [ ] CI workflow includes architecture check step.
- [ ] CI green (format + analyze + test + build + architecture check).
