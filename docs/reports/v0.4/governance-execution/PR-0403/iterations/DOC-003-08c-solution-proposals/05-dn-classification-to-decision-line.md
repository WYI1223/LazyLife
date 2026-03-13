# DOC-003 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-003` clause nodes into append candidates, parked governance-seed bundles, and explicit non-carrier outcomes.

This stage must not:

1. invent a new theme row just because `08c` contains implementation detail;
2. flatten governance-seed material into already-published semantic lines;
3. silently hide negative-evidence or backlog clauses as if they were new ADR carriers.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-003`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| `S2` phase-1 shell execution bridge | `TH-008` | `DN-083`, `DN-085` | Append to the existing shell-ownership line. `3.1.1` and `3.1.3` deepen the execution path for workbench-level ownership, but they do not replace the stable why-question already published in `ADR-0002`. |
| `S7` infrastructure migration bridge | `TH-004` | `DN-086` | Append to the existing reminders-infrastructure line. `3.1.4` gives concrete execution evidence for the already-published shared/core placement and lifecycle-trigger model. |
| Rule E local decoupling tactic | `none` | `DN-084` | Keep as `context_only`. Breaking the notes-tags cycle is a local implementation tactic, not a stable decision line distinct enough to justify its own theme row. |
| Low-priority defer note | `none` | `DN-087` | Keep as `context_only`. This clause records what was intentionally not prioritized in the immediate execution path. |
| Early CI / guardrail proposal bundle | `pending_governance_seed` | `DN-088-DN-091` | `park_later`. These clauses are valuable governance-seed material, but later governance sources formalize the guardrail contract more cleanly than `08c` does. |
| Documentation backlog and negative evidence | `none` | `DN-092`, `DN-093` | Keep as `context_only`. These clauses explain sync backlog and no-action validations, but they do not justify ADR or ruling carrier creation. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-003 / 08c-solution-proposals.md` |
| Covered Themes | `TH-008`, `TH-004` |
| Theme Operations | `append_adr`, `confirm_no_new_theme`, `park_later`, `sync_mainline_notes`, `record_open_items` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `DOC-001`, `DOC-002`, `DOC-004`, `DOC-005`, later governance DI sources |
| Out of Scope | creating a new theme from local decoupling tactics, publishing CI-policy ADRs from `08c` alone, rewriting `PR-0401` extraction baseline |
| Must Preserve | `DOC-002` stable why-questions, explicit governance-seed parking, explicit context-only clauses, no silent theme-row creation |
| Allowed Simplifications | local implementation estimates and file-count details may stay summarized as execution evidence rather than being copied into current rulings |
| Escalation Required If Violated | any attempt to split `TH-008` or `TH-004`, or to publish a new guardrail theme from `DOC-003` alone |
| Accepted Debt | `OI-002`, `OI-006`, `OI-007` |
| Output Docs | `ADR-0002`, `ADR-0007`, working-copy classification artifacts, `open-items.md`, `doc-run-queue.md` |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-003` from `awaiting_signoff` to `completed` |

### Theme Delta Rows

| Theme ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `TH-008` | `append_existing_adr + sync_mainline_notes` | `active` | `active` | `ADR-0002`, working-copy + mainline `topic-map.md` | shell ownership remains one line; `08c` stays execution evidence rather than a fork | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-004` | `append_existing_adr + sync_mainline_notes` | `active` | `active` | `ADR-0007`, working-copy + mainline `topic-map.md` | shared/core reminder ownership remains one line; bulk-delete stays an explicit later edge | `06`, `07`, `08`, `architecture_check.dart` |

## Gate Result

`DOC-003` yields:

1. two append candidates for already-published theme rows (`TH-008`, `TH-004`);
2. one parked governance-seed bundle (`DN-088-DN-091`);
3. four explicit context-only clauses (`DN-084`, `DN-087`, `DN-092`, `DN-093`);
4. zero new theme rows.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
- [`../../open-items.md`](../../open-items.md)
