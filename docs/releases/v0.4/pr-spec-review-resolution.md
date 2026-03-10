# v0.4 PR Spec Review Resolution

- Date: 2026-03-10
- Reviewer: Claude (AI agent)
- Owner sign-off: Wyi

---

## Review Summary

| Round | Scope | BLOCKERs Found | BLOCKERs Fixed | Verdict |
|-------|-------|-----------------|-----------------|---------|
| R1 | 20 specs (PR-0400~0423) | 12 | 12 | BLOCKED → all fixed |
| R2 | 20 specs (incremental) | 0 | — | **PASS** |

**Final verdict: PASS** — all 20 specs are review-clean. No open BLOCKERs.

---

## R1 Findings & Resolutions

### Governance Specs (PR-0400~0406)

| ID | Severity | Finding | Resolution |
|----|----------|---------|------------|
| G-1 | ~~BLOCKER~~ → N/A | All 7 specs missing Theme Delta Contract sections per DI-20 Q2 | **Not a real blocker.** DI-20 Q2 mandates TDC as an execution entry gate, not a spec-stage requirement. PR-0404 itself defines the TDC model (bootstrapping dependency). Specs already declare theme coverage in header metadata. |
| G-2 | BLOCKER → Fixed | 28 broken markdown relative links across all 7 specs | **Fixed.** Three categories: (1) DI-20 paths corrected to `../../../reports/v0.3/design-discussions/` (14 instances); (2) prep-layer file paths corrected (10 instances); (3) non-existent files converted to plain text with "(planned, not yet created)" annotation (4 instances). |

**Remaining WARNINGs (non-blocking):**
- 6 "planned, not yet created" plain-text references — intentional; represent execution deliverables
- No time estimates — consistent stylistic choice across all governance specs

### Workspace Execution Specs (PR-0407~0413)

| ID | Severity | Finding | Resolution |
|----|----------|---------|------------|
| W-3 | BLOCKER → Fixed | PR-0408 Task Breakdown T5 references directory instead of file | Fixed: T4/T5 → `crates/lazynote_core/tests/migration_0012_test.rs` |
| W-7 | BLOCKER → Fixed | PR-0408 directory-level test file references | Fixed: same as W-3 |
| W-11 | BLOCKER → Fixed | PR-0409 AC references removed `TaskService.list_inbox` | Fixed: "委托到 ScopedAtomQuery" → "委托到 ScopedQueryRepository" |
| W-17 | BLOCKER → Fixed | PR-0411 directory-level Planned File Changes | Fixed: expanded to 8 specific files (1 guard module + 6 guarded services + 1 test) |
| W-18 | BLOCKER → Fixed | PR-0411 directory-level test file references | Fixed: T6 → `tests/ffi_new_functions_test.rs`, T7 → `tests/guard_test.rs`, T8 → 3 specific doc paths |
| W-21 | BLOCKER → Fixed | PR-0012 duplicate Planned File Changes entry | Fixed: removed duplicate `workspace_tree_types.dart` entry |
| W-24 | BLOCKER → Fixed | PR-0413 directory-level test references | Fixed: expanded to 8 specific test files matching spec descriptions |

**Remaining WARNINGs (non-blocking):**
- TBD time estimates in all Task Breakdowns — systemic; acceptable for pre-execution planning stage
- PR-0413 Design §4.2 says "4 test files" but Planned File Changes lists 5 — count discrepancy in summary text; file list is authoritative

### Feature + Fix Specs (PR-0414~0423)

| ID | Severity | Finding | Resolution |
|----|----------|---------|------------|
| F-1 | BLOCKER → Fixed | PR-0415 missing dependency on PR-0414 | Fixed: 前置条件 now includes "PR-0414（migration 13 已落地，本 PR migration 14 接续）" |
| F-2 | BLOCKER → Fixed | PR-0416 missing dependency on PR-0414/0415 | Fixed: 前置条件 now includes PR-0415 + PR-0414 + PR-0413 |
| F-3 | BLOCKER → Fixed | PR-0416 `ON DELETE CASCADE` contradicts Rule C | Fixed: added Rule C compliance justification — overlay is derived cache (not business entity), CASCADE only fires on hard-delete (maintenance path with Ruling), soft-delete (`is_deleted=1`) does not trigger |

**Remaining WARNINGs (non-blocking):**
- `Option<Option<String>>` FRB Dart generation uncertainty (PR-0414) — mitigated by `flutter analyze` + tests
- `pulldown-cmark` / `flutter_markdown` AST parity (PR-0416) — mitigated by skeleton-only block rendering
- `content_rev` auto-increment path coverage (PR-0416) — mitigated by grep scan + tests
- Other minor risks acknowledged in respective Risk tables

---

## R2 Verification

All 12 R1 fixes verified by incremental review:

1. **No new issues introduced** by any fix
2. **Cross-PR dependency chain verified**: PR-0407 → 0408 → 0409/0410 → 0411 → 0412 → 0413 → 0414 (m13) → 0415 (m14) → 0416 (m15)
3. **Migration numbering confirmed sequential**: 12 → 13 → 14 → 15 (PR-0419 m16 deferred to v0.5)
4. **PR-0407 and PR-0410** (untouched by R1) spot-checked — no missed issues
5. **All 24 R1 WARNINGs** remain at WARNING level — none promoted to BLOCKER

---

## Spec Inventory (20 specs)

| PR | Title | Group | Status |
|----|-------|-------|--------|
| PR-0400 | Legacy Rulings Archive | Governance | Review-clean |
| PR-0401 | Source Corpus & DN Extraction | Governance | Review-clean |
| PR-0402 | ADR Infrastructure & Metadata Contract | Governance | Review-clean |
| PR-0403 | Per-ADR Serial Execution | Governance | Review-clean |
| PR-0404 | Theme Delta Contract & Consistency Audit | Governance | Review-clean |
| PR-0405 | Closure Audit & Governance Activation | Governance | Review-clean |
| PR-0406 | Template Playbook & Lifecycle Backfill | Governance | Review-clean |
| PR-0407 | CI Architecture Check Enhancement | Workspace Execution | Review-clean |
| PR-0408 | Schema Migration (Single-Root Tree) | Workspace Execution | Review-clean |
| PR-0409 | ScopedAtomQuery + ScopedQueryRepository | Workspace Execution | Review-clean |
| PR-0410 | TreeService + CreationService | Workspace Execution | Review-clean |
| PR-0411 | Guard + FFI (Expand Phase) | Workspace Execution | Review-clean |
| PR-0412 | Flutter Core Adapter | Workspace Execution | Review-clean |
| PR-0413 | Flutter Features + Contract (Contract Phase) | Workspace Execution | Review-clean |
| PR-0414 | Icon + Cover Image | Feature | Review-clean |
| PR-0415 | Atom Comments | Feature | Review-clean |
| PR-0416 | Overlays + ViewMode | Feature | Review-clean |
| PR-0421 | Editor Fixes (#47-50) | Fix | Review-clean |
| PR-0422 | FFI Test Isolation (#46) | Fix | Review-clean |
| PR-0423 | Cross-Feature Refresh (#45) | Fix | Review-clean |
