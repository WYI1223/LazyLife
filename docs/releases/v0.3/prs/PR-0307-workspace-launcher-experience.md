# PR-0307-workspace-launcher-experience

- Proposed title: `feat(workspace): workspace launcher and open-all flow on links index`
- Status: Planned

## Goal

Build productivity launcher experience using indexed links and workspace-aware open behavior.

## Scope (v0.3)

In scope:

- workspace launcher view over grouped links
- `Open All` action with confirmation and safety caps
- launch ordering policy (folder first, then web, configurable baseline)
- Single Entry command bridge:
  - `> open <keyword>`
  - `> workspace <name>`

Out of scope:

- cross-platform parity beyond current baseline
- third-party custom scheme integrations

## Dependency

Requires `PR-0212-links-index-open-v1` from v0.2.

## Step-by-Step

1. Define workspace group model and mapping rules.
2. Build launcher UI entry and list/group rendering.
3. Implement `Open All` transaction with cap and confirmation.
4. Add Single Entry command adapters to launcher/open APIs.
5. Add tests for limit guard and launch ordering.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/entry/*`
- [add] `apps/lazynote_flutter/lib/features/workspace/workspace_launcher_page.dart`
- [add] `apps/lazynote_flutter/lib/features/links/workspace_grouping.dart`
- [edit] `crates/lazynote_ffi/src/api.rs` (if command/query envelopes expand)
- [add] `apps/lazynote_flutter/test/workspace_launcher_flow_test.dart`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/workspace_launcher_flow_test.dart`
- `cd apps/lazynote_flutter && flutter test`

## Acceptance Criteria

- [ ] Workspace launcher can open grouped resources with explicit confirmation.
- [ ] `Open All` respects configurable cap and ordering.
- [ ] Single Entry command routing to launcher/open is stable.

