# Release Lifecycle Template

> Codified from v0.3 kickoff experience. Use this template to plan and execute each version release.

---

## Phase 1: Kickoff

### 1.1 Kickoff Audit

- Compare previous version's PR specs against the current codebase
- Identify completed, partially completed, and deferred items
- Document gaps and carry-forward items

### 1.2 Design Readiness Audit

- Scan all planned PRs for unresolved design questions
- Classify gaps as: blocked (needs DI), deferred (future version), or resolved
- Output: design readiness report listing all DI candidates

### 1.3 Design Discussions (DI)

- One DI resolves one design question, producing one ruling
- Each DI declares dependencies: prerequisite DIs and downstream DIs
- **Cross-DI consistency checkpoint**: after completing a batch of 3+ DIs, verify rulings don't conflict

### 1.4 Rulings / Modules Backfill

- After new rulings are produced, scan all existing PR specs
- Update Execution Contract tables and Verification commands to reference new rulings
- Ensure module boundary definitions are current

### 1.5 PR Spec Rebaseline (if applicable)

- When previous-version specs exist, rebaseline them to current state
- Assign new PR numbers (e.g., PR-RB-XX series)
- Document mapping from old to new PR numbers

### 1.6 PR Spec Writing

- Write specs following `pr-spec-template.md`
- Each spec must pass the 5 filling rules (see template)
- Cross-reference rulings and module boundaries

### 1.7 Spec Review (R1/R2)

- **R1**: Full review of all specs — identify issues, missing references, scope gaps
- **Fix round**: Address all R1 findings
- **R2**: Incremental review — verify R1 fixes don't introduce new problems
- **Sign-off**: All specs approved for execution

---

## Phase 2: Execution

### 2.1 Branch Strategy

- Trunk-based development: short-lived feature branches, squash merge to main
- Branch naming: `docs/pr-rb-XX-*` or `feat/pr-rb-XX-*`

### 2.2 PR-00: Doc Fixes + Infrastructure

- Every version starts with a doc-fix PR (PR-RB-00 equivalent)
- Fixes stale references, adds CI guardrails, cleans orphan files

### 2.3 PR Execution

- Execute PRs in dependency order
- Each PR must pass CI before merge
- Update PR spec status from Draft → In Progress → Merged

### 2.4 Mid-Point Checkpoint (optional)

- Recommended when version has >6 PRs
- Review progress, adjust scope if needed, verify no drift from specs

---

## Phase 3: Closure

### 3.1 Dead Code Cleanup

- Remove unused imports, functions, and files introduced during execution
- Verify no orphaned test helpers or mock files

### 3.2 Regression Test Gap Fill

- Review test coverage for all new/modified code
- Add missing integration tests for cross-feature interactions

### 3.3 Doc Sync

- Update: `CLAUDE.md`, `overview.md`, `data-model.md`, `ffi-contracts.md`, `rulings/`
- Ensure all paths, descriptions, and references match post-execution state

### 3.4 Gate Verification (scripted)

- Run architecture checks: `dart run ../../tools/ci/architecture_check.dart`
- Run full test suite: `flutter test`
- Run format + lint: `dart format` + `flutter analyze`

### 3.5 Release Evidence Collection

- Compile CI results, test counts, architecture check output
- Document any known issues or deferred items

### 3.6 Coverage Matrix Sign-Off

- Map each PR spec's acceptance criteria to evidence
- Confirm all criteria are met or explicitly deferred with rationale

### 3.7 Lifecycle Template Retrospective

- Review this template against actual execution experience
- Backfill improvements for the next version's kickoff

---

## Key Process Protocols

| Protocol | Description |
|----------|-------------|
| **DI splitting** | One DI solves one design question. If a second independent question emerges during discussion, split it into a new DI |
| **Cross-DI consistency** | After completing a batch of 3+ DIs, run a dependency matrix cross-check to verify no hidden conflicts between rulings |
| **Ruling/Module backfill** | After new rulings are produced, scan all written PR specs and update Execution Contract references and Verification commands |
| **Spec Review rounds** | R1 full review → fix → R2 incremental review (only verify fixes don't introduce new problems) → sign-off |

---

## Deliverables Checklist

Every version release must produce the following artifacts:

```
docs/releases/vN.M/
├── README.md                              — Version overview
├── vN.M-kickoff.md                        — Kickoff audit
├── vN.M-pr-spec-rebaseline-DATE.md        — Rebaseline (if applicable)
├── prs/PR-RB-XX-*.md                      — PR Specs
├── vN.M-release-evidence.md               — Release evidence

docs/reports/vN.M/
├── NN-design-readiness-audit.md           — Design readiness audit
├── design-discussions/DI-*.md             — DI series
├── design-discussions/README.md           — DI index
└── pr-spec-review-resolution.md           — Spec review report
```
