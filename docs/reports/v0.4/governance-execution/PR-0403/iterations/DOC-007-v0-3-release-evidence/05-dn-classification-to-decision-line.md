# DOC-007 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-007` clause nodes into append candidates for already-published theme rows and explicit parked release/governance bundles.

This stage must not:

1. create a new semantic carrier from release evidence alone;
2. turn release sign-off tables into current-ruling rewrites;
3. hide the v0.4 deferred boundary or the release-evidence review-fix lineage.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-007`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| S1 release verification, ruling-layer sign-off, and deferred-boundary confirmation | `TH-001` | `DN-135`, `DN-137`, `DN-138`, `DN-142`, `DN-145` | Append to the existing Atom-projection line. `DOC-007` confirms v0.3 release verification and preserves the S1 deferred boundary without changing the stable why-question. |
| S2 release verification, DI-chain sign-off, and handoff confirmation | `TH-008` | `DN-136`, `DN-137`, `DN-138`, `DN-140`, `DN-145` | Append to the existing shell-ownership line. `DOC-007` confirms Gate B, DI-0 through DI-5 release closure, and post-review stability without creating a new shell carrier. |
| S3 release sign-off and post-review re-verification | `TH-002` | `DN-137`, `DN-138`, `DN-145` | Append to the existing tag-workspace line. `DOC-007` confirms release closure without reopening the orthogonality line. |
| S4 atom_ref verification, release sign-off, and deferred-boundary confirmation | `TH-003` | `DN-135`, `DN-137`, `DN-138`, `DN-142`, `DN-145` | Append to the existing creation-path line. `DOC-007` confirms release closure and preserves later deferred work without changing the invariant. |
| S5 release verification and ruling-layer sign-off | `TH-009` | `DN-135`, `DN-137`, `DN-138`, `DN-145` | Append to the existing extension-kernel line. `DOC-007` confirms declaration-only closure as acceptable v0.3 release state without creating a new runtime line. |
| S6 release sign-off and deferred-boundary confirmation | `TH-010` | `DN-137`, `DN-138`, `DN-142`, `DN-145` | Append to the existing Provider-SPI line. `DOC-007` confirms release closure and keeps runtime and mapping follow-up explicit as later work. |
| S7 release verification, ruling-layer sign-off, and deferred-boundary confirmation | `TH-004` | `DN-135`, `DN-137`, `DN-138`, `DN-142`, `DN-145` | Append to the existing reminders line. `DOC-007` confirms release closure and preserves the bulk-delete follow-up boundary. |
| S8 release verification and ruling-layer sign-off | `TH-005` | `DN-135`, `DN-137`, `DN-138`, `DN-145` | Append to the existing DTO-unification line. `DOC-007` confirms release closure without collapsing the DTO boundary into `TH-001`. |
| Residual-cleanup verification and release test-delta accounting | `pending_release_verification_bundle` | `DN-133-DN-134` | `park_later`. These clauses are important release evidence, but they do not answer an ADR-worthy why-question. |
| Module-layer sign-off, DI-chain sign-off, and doc-sync closure | `pending_release_governance_bundle` | `DN-139-DN-141` | `park_later`. These clauses remain explicit release/governance carry-forward material rather than semantic carriers. |
| v0.3 to v0.4 boundary remainder | `pending_v0_4_boundary_bundle` | `DN-142 (non-line remainder: DI-9 + workspace-topology deferrals)` | `park_later`. The cross-line deferred-boundary remainder stays explicit intake lineage for later replay and audit. |
| Release-evidence review-fix provenance | `pending_release_review_fix_bundle` | `DN-143-DN-144` | `park_later`. The review-fix batches remain explicit provenance for the release-evidence artifact itself. |
| S9 release sign-off remainder | `pending_legacy_only_s9_trace` | `DN-138 (S9 remainder only)` | `context_only`. `DOC-007` confirms S9 release sign-off, but this run does not create a current published row from release evidence alone. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-007 / v0.3-release-evidence.md` |
| Covered Themes | `TH-001`, `TH-008`, `TH-002`, `TH-003`, `TH-009`, `TH-010`, `TH-004`, `TH-005` |
| Theme Operations | `append_adr`, `confirm_release_signoff`, `sync_mainline_notes`, `park_later`, `record_open_items` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `DOC-002`, `DOC-003`, `DOC-004`, `DOC-005`, later DI chain, and later governance/release audit sources |
| Out of Scope | creating a new theme from release evidence alone, publishing a release-governance ADR from closure tables, rewriting current rulings from v0.3 release evidence |
| Must Preserve | existing stable why-questions, explicit deferred-boundary intake, explicit release/governance parked bundles, legacy-only S9 trace, and review-fix provenance |
| Allowed Simplifications | release transcript detail may stay summarized in ADR revision records rather than being copied into current rulings |
| Escalation Required If Violated | any attempt to publish a new row from release sign-off alone or to silently drop the v0.4 boundary / review-fix lineage |
| Accepted Debt | `OI-001`, `OI-002`, `OI-003`, `OI-010`, `OI-011`, `OI-016`, `OI-017`, `OI-018`, `OI-019` |
| Output Docs | `ADR-0001..0008`, working-copy + mainline `topic-map.md`, `dn-ledger-classification.md`, `open-items.md`, `doc-run-queue.md` |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-007` from `awaiting_signoff` to `completed` |

### Theme Delta Rows

| Theme ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `TH-001` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0001`, working-copy + mainline `topic-map.md` | release-gate and deferred-boundary confirmation append without dropping open S1 future edges | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-008` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0002`, working-copy + mainline `topic-map.md` | Gate B and DI-chain closure append to the same shell line rather than spawning a release-only shell carrier | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-002` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0003`, working-copy + mainline `topic-map.md` | release sign-off confirms the published line without reopening the orthogonality boundary | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-003` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0004`, working-copy + mainline `topic-map.md` | atom_ref and deferred-boundary closure append without changing the invariant | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-009` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0005`, working-copy + mainline `topic-map.md` | declaration-only release closure stays valid without forcing runtime publication | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-010` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0006`, working-copy + mainline `topic-map.md` | release closure and runtime-deferral confirmation append without changing the carrier boundary | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-004` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0007`, working-copy + mainline `topic-map.md` | release closure and bulk-delete defer boundary append without redefining module ownership | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-005` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0008`, working-copy + mainline `topic-map.md` | release closure confirms the DTO boundary without collapsing it into `TH-001` | `06`, `07`, `08`, `architecture_check.dart` |

## Gate Result

`DOC-007` yields:

1. eight append candidates for already-published theme rows;
2. four parked release/governance bundles;
3. one legacy-only `S9` context trace;
4. zero new theme rows and zero current-ruling rewrites.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
- [`../../open-items.md`](../../open-items.md)
