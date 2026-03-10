# PR-0401 Document Inventory

> Mainline source corpus inventory for PR-0401.
> Ordering rule: `08a-09` chain -> `PR-RB-00` -> `v0.3-release-evidence` -> `DI-0` through `DI-21` in numeric order.

| Doc ID | Path | Doc Class | Corpus Role | Time Position | Normative Status | Extracted DN IDs | Notes |
|------|------|------|------|------|------|------|------|
| `DOC-001` | `docs/reports/v0.2.5/frontend-review/08a-audit-findings.md` | Audit report | Trigger source | `2026-02-26 / 08a` | `historical` | `pending` | Facts baseline for D1-D10 and semantic ambiguity list |
| `DOC-002` | `docs/reports/v0.2.5/frontend-review/08b-semantic-decisions.md` | Semantic decision log | Decision source | `2026-02-26 / 08b` | `historical` | `DN-003, DN-004, DN-005, DN-006, DN-007` | Current semantic ruling journey anchor; current normative anchors now live in `rulings-legacy/` |
| `DOC-003` | `docs/reports/v0.2.5/frontend-review/08c-solution-proposals.md` | Solution proposal | Execution source | `2026-02-27 / 08c` | `historical` | `pending` | Structural/execution bridge from semantic decisions to PR lanes |
| `DOC-004` | `docs/reports/v0.2.5/frontend-review/08d-pr-replanning.md` | PR replanning report | Execution source | `2026-02-27 / 08d` | `historical` | `pending` | Replanning and mapping from 08-series decisions into executable PRs |
| `DOC-005` | `docs/reports/v0.2.5/frontend-review/09-acceptance-report.md` | Acceptance report | Closure source | `2026-02-27 / 09` | `historical` | `pending` | Closure evidence and v0.3 handoff boundary |
| `DOC-006` | `docs/releases/v0.3/prs/PR-RB-00-doc-fixes.md` | PR spec / doc governance | Governance source | `2026-03-01 / PR-RB-00` | `historical` | `DN-001, DN-002` | ADR deprecation and E1 migration fact source |
| `DOC-007` | `docs/releases/v0.3/v0.3-release-evidence.md` | Release evidence | Closure source | `2026-03-01 / v0.3 release evidence` | `historical` | `pending` | Confirms v0.3 closure and deferred boundary into v0.4 |
| `DOC-008` | `docs/reports/v0.3/design-discussions/DI-0-dual-tab-manager.md` | Design discussion | Design discussion source | `2026-03 / DI-0` | `historical` | `pending` | Entry point of DI chain |
| `DOC-009` | `docs/reports/v0.3/design-discussions/DI-1-editor-shell-service.md` | Design discussion | Design discussion source | `2026-03 / DI-1` | `historical` | `pending` | Editor shell ownership and interface baseline |
| `DOC-010` | `docs/reports/v0.3/design-discussions/DI-2-layout-tree-structure.md` | Design discussion | Design discussion source | `2026-03 / DI-2` | `historical` | `pending` | Layout tree structure and propagation rules |
| `DOC-011` | `docs/reports/v0.3/design-discussions/DI-3-layout-persistence.md` | Design discussion | Design discussion source | `2026-03 / DI-3` | `historical` | `pending` | Layout persistence and migration decisions |
| `DOC-012` | `docs/reports/v0.3/design-discussions/DI-4-buffer-sync-model.md` | Design discussion | Design discussion source | `2026-03 / DI-4` | `historical` | `pending` | Buffer sync model and granularity |
| `DOC-013` | `docs/reports/v0.3/design-discussions/DI-5-cursor-and-conflict.md` | Design discussion | Design discussion source | `2026-03 / DI-5` | `historical` | `pending` | Cursor independence and conflict handling |
| `DOC-014` | `docs/reports/v0.3/design-discussions/DI-6-cross-track-dependencies.md` | Design discussion | Design discussion source | `2026-03 / DI-6` | `historical` | `pending` | Cross-track dependency restructuring |
| `DOC-015` | `docs/reports/v0.3/design-discussions/DI-7-gates-perf-testing.md` | Design discussion | Design discussion source | `2026-03 / DI-7` | `historical` | `pending` | Gates, perf baselines, testing strategy |
| `DOC-016` | `docs/reports/v0.3/design-discussions/DI-8-spi-verification.md` | Design discussion | Design discussion source | `2026-03 / DI-8` | `deferred` | `pending` | Explicitly deferred to v0.4 in DI index |
| `DOC-017` | `—` | Missing slot | Missing source slot | `2026-03 / DI-9` | `deferred` | `n/a` | `DI-9` is referenced in the DI index but no file exists; keep slot explicit |
| `DOC-018` | `docs/reports/v0.3/design-discussions/DI-10-editor-resolver-shell.md` | Design discussion | Design discussion source | `2026-03 / DI-10` | `historical` | `pending` | Editor resolver shell design |
| `DOC-019` | `docs/reports/v0.3/design-discussions/DI-11-atomtype-rename-impact.md` | Design discussion | Design discussion source | `2026-03 / DI-11` | `historical` | `pending` | AtomType -> ViewHint rename impact |
| `DOC-020` | `docs/reports/v0.3/design-discussions/DI-12-workspace-tree-single-root.md` | Design discussion | Design discussion source | `2026-03 / DI-12` | `historical` | `pending` | Single-root workspace semantics anchor |
| `DOC-021` | `docs/reports/v0.3/design-discussions/DI-13-calendar-range-limit-policy.md` | Design discussion | Design discussion source | `2026-03 / DI-13` | `pending` | `pending` | DI index marks this item pending |
| `DOC-022` | `docs/reports/v0.3/design-discussions/DI-14-workspace-tree-core-promotion.md` | Design discussion | Design discussion source | `2026-03 / DI-14` | `pending` | `pending` | DI index marks this item pending |
| `DOC-023` | `docs/reports/v0.3/design-discussions/DI-15-rust-data-model-single-root.md` | Design discussion | Design discussion source | `2026-03 / DI-15` | `historical` | `pending` | Rust data-model single-root decisions |
| `DOC-024` | `docs/reports/v0.3/design-discussions/DI-16-rust-service-ffi-contract.md` | Design discussion | Design discussion source | `2026-03 / DI-16` | `pending` | `pending` | In-progress contract discussion |
| `DOC-025` | `docs/reports/v0.3/design-discussions/DI-17-flutter-thin-client.md` | Design discussion | Design discussion source | `2026-03 / DI-17` | `pending` | `pending` | DI index says pending; file header should be reconciled later if inconsistent |
| `DOC-026` | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` | Design discussion | Design discussion source | `2026-03 / DI-18` | `historical` | `pending` | Execution planning and migration/testing strategy |
| `DOC-027` | `docs/reports/v0.3/design-discussions/DI-19-adr-governance.md` | Governance decision discussion | Governance decision source | `2026-03-06 / DI-19` | `current_effective` | `DN-008, DN-009, DN-010` | Active governance design source for ADR layering and trigger rules |
| `DOC-028` | `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md` | Governance decision discussion | Governance execution source | `2026-03-06 / DI-20` | `current_effective` | `DN-011, DN-012, DN-013` | Active execution-plan source; defines T4 extraction rules and PR sequence |
| `DOC-029` | `docs/reports/v0.3/design-discussions/DI-21-ci-duplication-detection.md` | Design discussion | Design discussion source | `2026-03 / DI-21` | `historical` | `pending` | CI duplication detection discussion |
