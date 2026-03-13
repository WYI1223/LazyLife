# DOC-005 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-005` clause nodes into append candidates for already-published theme rows and explicit parked closure/governance bundles.

This stage must not:

1. create a new semantic carrier from release acceptance language alone;
2. flatten CI, doc-audit, debt-register, or release-verdict bundles into existing semantic rows;
3. hide `08b` deferred placeholders or `08d` parked closure material.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-005`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| S1 closure, v0.3 handoff, and deferred-placeholder preservation | `TH-001` | `DN-111`, `DN-112`, `DN-113`, `DN-122` | Append to the existing Atom-projection line. `09` confirms closure and handoff without replacing the stable why-question, and it explicitly preserves the deferred S1 placeholder ledger. |
| S2 closure, v0.3 handoff, and later-shell follow-up preservation | `TH-008` | `DN-111`, `DN-112`, `DN-113`, `DN-122` | Append to the existing shell-ownership line. `09` accepts the line as ready for handoff while preserving later shell detail as append-only work. |
| S3 closure and v0.3 handoff | `TH-002` | `DN-111`, `DN-112`, `DN-122` | Append to the existing tag-workspace line. `09` validates that the orthogonality line stays stable through closure and handoff. |
| S4 closure and v0.3 handoff | `TH-003` | `DN-111`, `DN-112`, `DN-122` | Append to the existing creation-path line. `09` confirms handoff readiness without changing the invariant. |
| S5 closure, v0.3 handoff, and preserved first-party manifest question | `TH-009` | `DN-111`, `DN-112`, `DN-113`, `DN-122` | Append to the existing extension-kernel boundary line. `09` keeps the manifest-style description question explicit as later debt instead of forcing a new carrier. |
| S6 closure and v0.3 handoff | `TH-010` | `DN-111`, `DN-112`, `DN-122` | Append to the existing Provider-SPI line. `09` confirms declaration-only handoff as acceptable current state. |
| S7 closure and v0.3 handoff | `TH-004` | `DN-111`, `DN-112`, `DN-122` | Append to the existing reminders line. `09` confirms the shared/core placement as handoff-ready while leaving bulk-delete follow-up explicit. |
| S8 closure and v0.3 handoff | `TH-005` | `DN-111`, `DN-112`, `DN-122` | Append to the existing DTO-unification line. `09` confirms release-closure readiness without collapsing the line back into `TH-001`. |
| Risk, debt, plan, regression, and 08a-coverage closure bundle | `pending_release_closure_bundle` | `DN-104-DN-110`, `DN-114` | `park_later`. These clauses are vital release-closure evidence, but they do not justify a semantic carrier in this run. |
| Doc-audit, CI, allowlist, readiness, release-judgment, and series-closure bundle | `pending_governance_closure_bundle` | `DN-115-DN-121`, `DN-123-DN-125` | `park_later`. These clauses remain explicit carry-forward material for later governance, release-audit, and playbook-backfill work. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-005 / 09-acceptance-report.md` |
| Covered Themes | `TH-001`, `TH-008`, `TH-002`, `TH-003`, `TH-009`, `TH-010`, `TH-004`, `TH-005` |
| Theme Operations | `append_adr`, `confirm_no_new_theme`, `park_later`, `sync_mainline_notes`, `record_open_items` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `DOC-001`, `DOC-002`, `DOC-003`, `DOC-004`, later governance and release-audit sources |
| Out of Scope | creating a new semantic row from release acceptance language, publishing a release-governance ADR from `09` alone, rewriting current ruling text from closure tables |
| Must Preserve | published why-questions, explicit deferred placeholders, explicit release/governance carry-forward bundles, no silent flattening of acceptance-report bundles into semantic carriers |
| Allowed Simplifications | release metrics and table detail may remain summarized in ADR revision records instead of being copied into current rulings |
| Escalation Required If Violated | any attempt to create a new theme row from release closure tables or to rewrite current rulings from `09` |
| Accepted Debt | `OI-001`, `OI-002`, `OI-003`, `OI-006`, `OI-010`, `OI-011` |
| Output Docs | `ADR-0001..0008`, working-copy + mainline `topic-map.md` notes, `dn-ledger-classification.md`, `open-items.md`, `doc-run-queue.md` |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-005` from `awaiting_signoff` to `completed` |

### Theme Delta Rows

| Theme ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `TH-001` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0001`, working-copy + mainline `topic-map.md` | deferred S1 placeholders stay explicit rather than disappearing from replay | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-008` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0002`, working-copy + mainline `topic-map.md` | shell ownership remains one line; later shell detail stays append-only work | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-002` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0003`, working-copy + mainline `topic-map.md` | orthogonality line stays stable through closure and handoff | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-003` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0004`, working-copy + mainline `topic-map.md` | creation-path invariant stays explicit and unmerged | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-009` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0005`, working-copy + mainline `topic-map.md` | declaration-only extension handoff stays valid and manifest debt stays explicit | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-010` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0006`, working-copy + mainline `topic-map.md` | provider/mapping split stays stable through closure and handoff | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-004` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0007`, working-copy + mainline `topic-map.md` | shared/core placement stays stable and bulk-delete remains an explicit later edge | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-005` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0008`, working-copy + mainline `topic-map.md` | DTO boundary remains distinct from `TH-001` through release closure | `06`, `07`, `08`, `architecture_check.dart` |

## Gate Result

`DOC-005` yields:

1. eight append candidates for already-published theme rows;
2. one parked release-closure bundle (`DN-104-DN-110`, `DN-114`);
3. one parked governance-closure bundle (`DN-115-DN-121`, `DN-123-DN-125`);
4. zero new theme rows and zero current-ruling rewrites.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
- [`../../open-items.md`](../../open-items.md)
