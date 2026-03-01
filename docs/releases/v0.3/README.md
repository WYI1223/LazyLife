# v0.3 Release Plan

> 2026-03-01 rebaseline: execution baseline has been superseded by
> `docs/releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md`.
> Keep this file as historical planning context.

## Positioning

v0.3 delivers the IDE-grade workspace interaction model on top of the v0.2.5 semantic and architecture baseline.

Theme:

- unified data model foundation (S1/S4/S8 rulings landed)
- recursive split architecture with EditorShellService (S2 Phase 2)
- drag-to-split interaction
- cross-pane editor coherence
- performance guardrails for long markdown documents
- links index/open foundation for launcher flows
- workspace launcher user flow on top of links index
- local task-calendar projection and Google Calendar provider
- Windows global hotkey quick-entry integration

> **Kickoff audit**: `docs/releases/v0.3/v0.3-kickoff.md` documents the full baseline delta
> analysis, PR spec audit, and rationale for the Phase 0/1/2 structure below.
> **Structural redesign**: kickoff §9 documents the top-down capability derivation
> that produced the current Phase structure (3-Track Phase 1, independent-Lane Phase 2).

## User-Facing Outcomes

At the end of v0.3, users should be able to:

1. Create notes/tasks/events with guaranteed workspace tree presence (no orphan atoms).
2. Split workspace recursively (not just limited preset split).
3. Drag tabs to edge zones to create new splits naturally.
4. Open the same note in different panes with coherent live content state.
5. Use preview/pinned tab semantics similar to IDE workflows.
6. Launch a workspace link set safely (`Open All` with confirmation/limits).
7. Use local task-calendar projection without requiring external provider login.
8. Connect Google Calendar via provider plugin flow (optional integration).
9. Toggle/focus quick entry from global hotkey on Windows.

## Architecture Outcomes

At the end of v0.3, engineering should have:

1. Unified `AtomListItem` DTO across all FFI list endpoints (S8 landed).
2. `view_hint`/`title`/`content_type` fields on Atom model (S1 landed).
3. All creation paths producing `Atom` + `atom_ref` (S4 landed).
4. `EditorShellService` as workbench-level tab/draft/save owner (S2 Phase 2).
5. Recursive layout tree model (`Internal` + `Leaf` nodes).
6. Geometry and safety rules (`>= 200px`) enforced in layout engine.
7. Buffer synchronization model designed for multi-pane editing.
8. Rendering strategy for long markdown with measurable performance targets.
9. Workspace launcher orchestration tied to links index and active pane rules.
10. Local task-calendar projection rules as core capability.
11. Google Calendar provider implemented against provider SPI with S6 three-layer model.
12. Links index/open pipeline available as launcher-ready foundation.
13. Global hotkey quick-entry route aligned with tab/entry semantics on Windows.

## Scope

In scope:

**Phase 0 — Foundation:**

- FFI type unification: NoteItem → AtomListItem (`PR-0300A`)
- Data model v2: view_hint/title/content_type fields (`PR-0300B`)
- Creation path unification: atom_ref forced pairing (`PR-0300C`)
- Coordinator thinning: typedef/invoker extraction (`PR-0300D`)

**Phase 1 — Infrastructure & Interaction (3 parallel Tracks):**

- Track A — Layout engine: recursive layout tree (`PR-0301`) + drag-to-split interaction (`PR-0302`)
- Track B — Editor state: EditorShellService extraction (`PR-0301B`) + cross-pane buffer sync (`PR-0303`) + preview/pinned tab model (`PR-0304`)
- Track C — Index pipeline: links index/open foundation (`PR-0306A`)

**Phase 2 — Features & Closure (independent Lanes):**

- Workspace launcher experience (`PR-0307`)
- Local task-calendar projection (`PR-0308`)
- Google Calendar provider plugin (`PR-0309`)
- Windows global hotkey quick-entry (`PR-0311`)
- Markdown segment rendering + perf gate (`PR-0305`)
- Reliability hardening and v0.3 closure (`PR-0306`)

Out of scope:

- collaborative multi-user editing
- CRDT merge runtime
- provider-sync conflict UI redesign
- first-party command/parser pluginization (S5 ruling: defer to v0.4+, see kickoff §2.2)

## Dependencies from v0.2 / v0.2.5

Required baseline (v0.2):

- tree schema + tree FFI
- workspace provider state hoisting
- explorer recursive lazy rendering + tab open-intent migration (`PR-0205B` M2 landed)
- split layout v1
- extension kernel + provider SPI + capability model

Required baseline (v0.2.5, completed 2026-02-27):

- Semantic rulings S1-S8 documented (`PR-0256`, see `docs/architecture/rulings/`)
- Dart god-object decomposition — NotesCoordinator + 6 managers (`PR-0252`)
- Pane-aware NoteTabStateManager with per-pane tab isolation (`PR-0257`)
- Notes-workspace decoupling — coordinator is sole state source,
  WorkspaceProvider is pane-layout-only at 166 lines (`PR-0258`)
- Rule E enforcement via CI `architecture_check.dart` (`PR-0259`)
- Closure replay and handoff evidence (`PR-0253`)

## Execution Order & Status Tracking

### Planning Phase — Design Investigation & Spec Readiness

> Goal: Resolve critical design blanks, then bring all PR specs to execution-ready state.
> Design readiness audit: `docs/reports/v0.3/01-design-readiness-audit.md`.
> Structural redesign: `docs/releases/v0.3/v0.3-kickoff.md` §9.

**Stage 1 — Design Investigation (can run in parallel with Phase 0 spec creation):**

| # | Task | Target | Blocks | Status |
|---|------|--------|--------|--------|
| DI-1 | EditorShellService interface design | D1-D4 decisions | PR-0301B, PR-0303, PR-0304, PR-0311 specs | Planned |
| DI-2 | Recursive layout tree data model | D5-D9 decisions | PR-0301, PR-0302 specs | Planned |
| DI-3 | Buffer synchronization architecture | D10-D13 decisions (depends on DI-1) | PR-0303, PR-0305 specs | Planned |

> DI deliverables: `docs/releases/v0.3/design/DI-{1,2,3}-*.md`

**Stage 2 — Spec Creation (after DI conclusions):**

| # | Task | Target Specs | Kickoff Reference | Status |
|---|------|-------------|-------------------|--------|
| P1 | Create Phase 0 specs | `PR-0300A`, `PR-0300B`, `PR-0300C`, `PR-0300D` | §3 | Planned |
| P2 | Create PR-0301B spec | `PR-0301B` | §9.5 + DI-1 | Planned |
| P3 | Rewrite 3 specs | `PR-0301`, `PR-0302`, `PR-0304` | §9.7.3 + DI-1/DI-2 | Planned |
| P4 | Update 5 affected specs | `PR-0303`, `PR-0307`, `PR-0308`, `PR-0309`, `PR-0311` | §2 + §9 + DI-1/DI-3 | Planned |
| P5 | Mark PR-0310 as dropped | `PR-0310` | §2 (DROP verdict, S5) | Planned |

**Planning Gate:**

- [ ] DI-1/DI-2/DI-3 design documents completed with decisions recorded
- [ ] 4 Phase 0 specs created and reviewed
- [ ] PR-0301B (EditorShellService) spec created with interface definition from DI-1
- [ ] PR-0301, PR-0302, PR-0304 rewritten per §9 restructuring + DI conclusions
- [ ] 5 updated specs aligned with S1-S8 rulings, coordinator pattern, and §9 dependency changes
- [ ] PR-0310 marked dropped with rationale
- [ ] All spec file paths listed in this README match actual files
- [ ] Each active risk (R1, R3, R6) has mitigation documented in the corresponding PR spec (see kickoff §6)
- [ ] Phase 1 Gate verification criteria are testable (not vague)

### Phase 0 — Foundation

> Goal: Clear architecture blockers. Establish unified data model and FFI contract
> for all subsequent phases.

| # | PR | Title | Ruling | Status |
|---|-----|-------|--------|--------|
| 1 | `PR-0300D` | Coordinator typedef/invoker extraction | 09 §7.1 | Planned |
| 2 | `PR-0300A` | FFI type unification (NoteItem → AtomListItem) | S8 | Planned |
| 3 | `PR-0300B` | Data model v2 (view_hint/title/content_type) | S1 | Planned |
| 4 | `PR-0300C` | Creation path unification (atom_ref forced pairing) | S4 | Planned |

**Phase 0 Gate:**

- [ ] `cargo test --all` PASS
- [ ] `flutter test` PASS (≥333, 0 fail)
- [ ] `architecture_check.dart` PASS (coordinator warning cleared)
- [ ] All creation paths produce Atom + atom_ref
- [ ] NoteItem not referenced by any Flutter code

### Phase 1 — Infrastructure & Interaction (3 Parallel Tracks)

> Goal: Build core infrastructure (layout engine, editor service, index pipeline) and
> interaction models (drag-to-split, buffer sync, tab preview/pinned).
> Three tracks run in parallel after Phase 0 Gate passes (see kickoff §9.5).

**Track A — Layout Engine (L1a → L2 drag):**

| # | PR | Title | Spec Status | Status |
|---|-----|-------|-------------|--------|
| 5 | `PR-0301` | Recursive layout tree engine | **Needs rewrite** | Planned |
| 6 | `PR-0302` | Drag-to-split interaction (layout-tree level) | **Needs rewrite** | Planned |

**Track B — Editor State (L1b → L2 buffer/tab):**

| # | PR | Title | Spec Status | Status |
|---|-----|-------|-------------|--------|
| 7 | `PR-0301B` | EditorShellService extraction (S2 Phase 2) | **New — needs create** | Planned |
| 8 | `PR-0303` | Cross-pane live buffer sync | Needs update | Planned |
| 9 | `PR-0304` | EditorGroupModel + preview/pinned tab | **Needs rewrite** | Planned |

> PR-0303 and PR-0304 both depend on PR-0301B, but have no dependency on each other — they can run in parallel.

**Track C — Index Pipeline (L1c):**

| # | PR | Title | Spec Status | Status |
|---|-----|-------|-------------|--------|
| 10 | `PR-0306A` | Links index/open foundation | Valid | Planned |

**Phase 1 Gate:**

- [ ] Recursive split stable, min-size constraint enforced
- [ ] Drag-to-split operates at layout-tree level (not NoteExplorer)
- [ ] EditorShellService owns tab/draft/save at workbench level
- [ ] Same-note multi-pane editing content-coherent
- [ ] Preview/pinned tab deterministic with test coverage
- [ ] Links index/open pipeline functional
- [ ] All v0.2.5 tests no regression

### Phase 2 — Features & Closure (Independent Lanes)

> Goal: Feature integration and quality closure.
> Each Lane starts when its specific dependency is met — no need to wait for all of Phase 1.
> Lane A and Lane B can start after Phase 0 completes (no Phase 1 dependency).

| Lane | # | PR | Title | Start Condition | Spec Status | Status |
|------|---|-----|-------|-----------------|-------------|--------|
| A | 11 | `PR-0307` | Workspace launcher experience | Track C (0306A) done | Needs update | Planned |
| B | 12 | `PR-0308` | Local task-calendar projection | Phase 0 done | Needs update | Planned |
| B | 13 | `PR-0309` | Google Calendar provider plugin | PR-0308 done | Needs update | Planned |
| C | 14 | `PR-0311` | Windows global hotkey quick-entry | Track B 0304 done | Needs update | Planned |
| D | 15 | `PR-0305` | Markdown segment rendering + perf gate | Track B 0303 done | Valid | Planned |
| — | 16 | `PR-0306` | Reliability hardening + v0.3 closure | All PRs done | Valid | Planned |

**Phase 2 / v0.3 Release Gate:**

- [ ] `cargo test --all` PASS
- [ ] `flutter test` PASS (0 fail)
- [ ] `architecture_check.dart` PASS (0 violations)
- [ ] Launcher flow has safety cap and confirmation
- [ ] Local calendar projection works without external provider
- [ ] Google Calendar runs through Provider SPI (S6 three-layer model)
- [ ] Global hotkey non-destructive, failures diagnosable
- [ ] Long markdown scenario ≥ 60 FPS
- [ ] Profile-mode performance check for long markdown in multi-pane view

## Dropped PRs

| Original PR | Reason | Alternative |
|-------------|--------|-------------|
| `PR-0310` (first-party command/parser pluginization) | S5 ruling: first-party does not go through Extension Kernel. Extension Kernel is a third-party security contract. | Defer to v0.4+ when first real third-party plugin need arises. |

## Dependency Graph

> Derived from capability layering in kickoff §9.3–§9.6.

```
Phase 0 (L0)               Phase 1 (L1+L2)                       Phase 2 (L3+L4)
─────────────               ─────────────────                     ─────────────────
0300D (slim)                Track A:          Track C:
                            0301 (layout)     0306A (links)──────► Lane A: 0307 (launcher)
0300A (FFI)                   ↓
  ↓                         0302 (drag)
0300B (model)
  ↓                         Track B:                              Lane B: 0308 (projection)
0300C (paths)════►          0301B (EditorShell)                       ↓
                              ↓       ↓                           0309 (Google Cal)
                            0303    0304
                           (buffer) (tab)────────────────────────► Lane C: 0311 (hotkey)
                              ↓
                            ·····························────────► Lane D: 0305 (perf)

                                                                  0306 (hardening + closure)
```

## Quality Gates (All Phases)

```bash
# Rust
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all

# Flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart

# Performance (Phase 1+)
# profile-mode benchmark with documented dataset
```

## Known Risks & Mitigations

> Full analysis with v0.3 resolution plans in `docs/releases/v0.3/v0.3-kickoff.md` §6.
> All risks must be resolved within v0.3 — no deferral to v0.4.
> §9 restructuring eliminated R2 and R5 by design (see §9.7.2).

| Risk | Description | Owner PR | v0.3 Resolution |
|------|-------------|----------|-----------------|
| R1 | `coordinator_impl.dart` at 1,514 lines — v0.3 additions may hit 2,000-line CI failure | `PR-0300D` + `PR-0301B` + `PR-0306` | PR-0300D thins to ~1,320 lines; PR-0301B extracts tab/draft/save (further reduction); PR-0306 performs second split if re-approaching 1,500 |
| R3 | PR-0300A FFI breaking change across many Flutter consumers | `PR-0300A` | Spec must include full consumer audit + mechanical replacement strategy; one-shot batch migration, no compat shim |
| R6 | PR-0309 is first runtime Provider SPI implementation — may expose SPI design flaws | `PR-0309` | Spec must include SPI verification step (mock provider integration test); SPI trait fixes within PR-0309, not deferred |

**Eliminated risks (§9 restructuring):**

- ~~R2~~ (`note_explorer.dart` bloat) — drag logic now operates at layout-tree level (PR-0302 rewrite), not added to NoteExplorer. Root cause eliminated.
- ~~R5~~ (EditorShellService bloating PR-0301) — EditorShellService is now a separate PR (PR-0301B). Single responsibility, root cause eliminated.

**Resolved risk:** R4 (PR-0205B M2 uncertainty) — verified landed at commit `f9d911a`. PR-0304 rewrite builds on existing baseline.

## Acceptance Criteria (Release-Level)

v0.3 is complete when:

1. All creation paths produce Atom + atom_ref (S4).
2. Unified AtomListItem DTO across all FFI list endpoints (S8).
3. Recursive split and drag-to-split are stable and constraint-safe.
4. EditorShellService owns tab/draft/save at workbench level (S2 Phase 2).
5. Multi-pane same-note editing remains coherent and recoverable.
6. Tab preview/pinned behavior is deterministic and test-covered.
7. Long markdown rendering meets agreed baseline performance target.
8. Workspace launcher flow is safe, constrained, and test-covered.
9. Local task-calendar projection is stable and independent from external provider.
10. Google Calendar integration runs through provider SPI with S6 three-layer model.
11. Windows global hotkey quick-entry flow is stable and non-destructive.

## Spec Status Summary

> Audit details in `docs/releases/v0.3/v0.3-kickoff.md` §2; structural redesign in §9.

| Spec | Audit Verdict | Action |
|------|---------------|--------|
| PR-0300A/B/C/D | — | **Create** (new Phase 0 specs) |
| PR-0301 | **REWRITE** | Narrow to pure layout tree engine; remove EditorShellService integration (§9.4 Problem 1) |
| **PR-0301B** | — | **Create** (new: EditorShellService extraction, S2 Phase 2; §9.5 Track B) |
| PR-0302 | **REWRITE** | Redesign as layout-tree-level interaction; drag logic not in NoteExplorer (§9.4 Problem 2) |
| PR-0303 | UPDATE | Dependency change: depends on PR-0301B (not PR-0302); buffer in EditorShellService |
| PR-0304 | **REWRITE** | Redesign on EditorGroupModel; depends on PR-0301B (not PR-0303); PR-0205B M2 baseline confirmed |
| PR-0305 | VALID | Moved to Phase 2 Lane D (depends on PR-0303 completion) |
| PR-0306 | VALID | Moved to Phase 2 closure (depends on all PRs) |
| PR-0306A | VALID | Moved to Phase 1 Track C (L1c infrastructure, not Phase 2 feature) |
| PR-0307 | UPDATE | Add S3 orthogonality AC (mandatory); add S4 creation path compliance |
| PR-0308 | UPDATE | Align with S1 view_hint, S7 trigger semantics |
| PR-0309 | UPDATE | Align with S6 three-layer model, fix stale deps |
| PR-0310 | **DROP** | S5 ruling contradiction |
| PR-0311 | UPDATE | Remove PR-0310 dep, add pane targeting spec; depends on PR-0304 |

## PR Specs

**Phase 0 (new):**

- `docs/releases/v0.3/prs/PR-0300A-ffi-type-unification.md`
- `docs/releases/v0.3/prs/PR-0300B-data-model-v2.md`
- `docs/releases/v0.3/prs/PR-0300C-creation-path-unification.md`
- `docs/releases/v0.3/prs/PR-0300D-coordinator-thinning.md`

**Phase 1 — Track A (Layout):**

- `docs/releases/v0.3/prs/PR-0301-recursive-layout-tree.md`
- `docs/releases/v0.3/prs/PR-0302-drag-to-split-edge-zones.md`

**Phase 1 — Track B (Editor State):**

- `docs/releases/v0.3/prs/PR-0301B-editor-shell-service.md`
- `docs/releases/v0.3/prs/PR-0303-cross-pane-live-buffer-sync.md`
- `docs/releases/v0.3/prs/PR-0304-tab-preview-pinned-model.md`

**Phase 1 — Track C (Index):**

- `docs/releases/v0.3/prs/PR-0306A-links-index-open-foundation.md`

**Phase 2 (Features & Closure):**

- `docs/releases/v0.3/prs/PR-0307-workspace-launcher-experience.md`
- `docs/releases/v0.3/prs/PR-0308-local-task-calendar-projection.md`
- `docs/releases/v0.3/prs/PR-0309-google-calendar-provider-plugin.md`
- `docs/releases/v0.3/prs/PR-0311-windows-global-hotkey-quick-entry.md`
- `docs/releases/v0.3/prs/PR-0305-markdown-segment-rendering-performance-gate.md`
- `docs/releases/v0.3/prs/PR-0306-recursive-workspace-reliability-hardening.md`

**Dropped:**

- ~~`docs/releases/v0.3/prs/PR-0310-first-party-command-parser-plugins.md`~~ (S5 ruling, see kickoff §2.2)
