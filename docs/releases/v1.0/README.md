# v1.0 Release Plan

## Positioning

v1.0 finalizes LazyNote as a production-ready local-first productivity platform.

Theme:

- production reliability
- performance guarantees
- security hardening
- release and support readiness
- plugin sandbox and distribution governance

## User-Facing Outcomes

At the end of v1.0, users should get:

1. Stable IDE-grade notes workspace (recursive split + coherent buffers).
2. Reliable long-session behavior with robust recovery paths.
3. Predictable performance on large notes and multi-pane workflows.
4. Better diagnostics and supportability for issue resolution.

## Architecture Outcomes

At the end of v1.0, engineering should have:

1. Session recovery model for workspace state.
2. Hardened save/retry/recovery mechanisms.
3. Security/compliance baseline implementation closure.
4. Release-grade quality gates and documentation completeness.

## Scope

In scope:

- reliability hardening for multi-pane and long-session usage
- session restore and crash-safe workspace state
- security/privacy policy implementation closure
- full quality gates and release process hardening
- cross-platform parity and policy hardening for links/workspace launcher
- plugin sandbox runtime and capability enforcement closure
- iOS-ready plugin distribution policy (official repo/whitelist/signing)
- API compatibility CI gates with deprecation-first policy

Out of scope:

- multi-user collaborative editing runtime
- provider-agnostic distributed sync overhaul

## Candidate PR Breakdown

- `PR-1001-session-recovery-workspace-state`
- `PR-1002-save-pipeline-reliability-hardening`
- `PR-1003-security-and-privacy-closure`
- `PR-1004-performance-and-observability-gates`
- `PR-1005-release-readiness-and-doc-closure`
- `PR-1006-links-launcher-cross-platform-and-whitelist`
- `PR-1007-plugin-sandbox-runtime`
- `PR-1008-ios-plugin-distribution-policy`
- `PR-1009-api-compat-ci-gates`

## PR Specs

- `docs/releases/v1.0/prs/PR-1007-plugin-sandbox-runtime.md`
- `docs/releases/v1.0/prs/PR-1008-ios-plugin-distribution-policy.md`
- `docs/releases/v1.0/prs/PR-1009-api-compat-ci-gates.md`

## Quality Gates

- deterministic CI green for Rust + Flutter
- performance baseline checks documented and repeatable
- security checklist completion before final tag
- release checklist and changelog closure

## Acceptance Criteria (Release-Level)

v1.0 is complete when:

1. Workspace/session recovery is stable under crash/restart scenarios.
2. Save pipeline remains consistent under stress and failure injection.
3. Security/privacy requirements are implemented and documented.
4. Release process is reproducible with complete docs and support paths.
5. Links/workspace launcher behavior is policy-safe and cross-platform consistent.
6. Plugin execution is sandboxed with enforceable capability boundaries.
7. Plugin distribution policy is documented and operationally testable for iOS constraints.
8. API compatibility/deprecation CI gates prevent accidental breaking changes.
