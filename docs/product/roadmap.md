# Roadmap

## Release Tracks

1. v0.1 (notes-first stabilization)
   - scope: close local notes loop + debug viewer readability baseline
   - focus PRs: `PR-0010C2`, `PR-0010C3`, `PR-0010C4`, `PR-0010D`, `PR-0017A`
   - plan: `docs/releases/v0.1/README.md`
1.5. v0.1.5 (Atom Time-Matrix bridge)
   - scope: time-matrix schema (Migration 6) + Inbox/Today/Upcoming task views
   - focus PRs: `PR-0011`
   - plan: `docs/releases/v0.1.5/README.md`
   - gate: v0.1 (PR-0017A) must close before v0.1.5 begins
2. v0.2 (workspace foundation, closure-ready)
   - scope: tree model, workspace provider, explorer recursion, split v1, extension kernel contracts (command/parser/provider/ui slot/capability), API lifecycle/deprecation policy baseline, CN/EN i18n, debug viewer phase-2 readability hardening, docs language policy
   - focus PRs: `PR-0202` to `PR-0221` (deferred from v0.2: `PR-0201`, `PR-0212`)
   - plan: `docs/releases/v0.2/README.md`
   - closure kit: `docs/releases/v0.2/CLOSURE_KIT.md`
2.5. v0.2.5 (debt paydown and semantic freeze bridge) — **completed 2026-02-27**
   - scope: semantics freeze, architecture/size baseline artifacts, frontend TL review docs, Dart god-object decomposition, decoupling, closure replay, v0.3 handoff re-baseline
   - focus PRs: `PR-0252` to `PR-0259`, `PR-0253` closure (PR-0251 superseded by PR-0256)
   - plan: `docs/releases/v0.2.5/README.md`
   - gate: v0.2 closure must be green before v0.2.5 closure handoff
3. v0.3 (IDE-grade recursive workspace) — **in progress**
   - scope: recursive split, drag-to-split, cross-pane coherence, perf gate, links/index/open foundation, workspace launcher experience, local task-calendar projection, Google Calendar provider pluginization, Windows global hotkey quick-entry
   - focus PRs: `PR-RB-00` to `PR-RB-11` (rebaselined from original `PR-030X` series, see `docs/releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md`)
   - plan: `docs/releases/v0.3/README.md`
4. v1.0 (production hardening)
   - scope: reliability, recovery, security, release readiness, cross-platform launcher policy parity, plugin sandbox/distribution/compatibility gates
   - candidate PRs: `PR-1001` to `PR-1009`
   - plan: `docs/releases/v1.0/README.md`

## Deferred Items Tracker

| Item | Original | Delivered In |
|------|----------|-------------|
| Tasks views | v0.1 `PR-0011` | v0.1.5 |
| Calendar minimal | v0.1 `PR-0012` | v0.2 |
| Reminders (Windows) | v0.1 `PR-0013` | v0.2 |
| Local task-calendar projection | v0.1 `PR-0014` | v0.3 `PR-RB-03`/`04` (partial, superseded from `PR-0308`) |
| Google Calendar provider | v0.1 `PR-0015` | v0.3 `PR-RB-12` (conditional, runtime deferred to v0.4+) |
| Export/import | v0.1 `PR-0016` | Deferred (v1.0+) |
| Notes delete lifecycle | v0.1 | Deferred (v1.0+) |
| Reminder cancel on `workspace_delete_folder(delete_all)` | v0.3 PR-RB-04 | Deferred (v0.4 `PR-0401`, post DI-12 single-root tree) |
