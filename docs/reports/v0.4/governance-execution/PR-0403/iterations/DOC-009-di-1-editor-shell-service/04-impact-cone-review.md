# DOC-009 / 04 Impact Cone Review

## Purpose and Boundary

Record which published lines, current rulings, topic-map rows, and current architecture docs are touched by the `DOC-009` replay.

## Trigger and Inputs

- `03-retrospective-override-review.md`
- current published ADR and ruling sets
- current architecture docs that still carry live S9 backlinks

## Impact Cone

| Surface | Touched Items | Impact |
|------|------|------|
| Published ADR carriers | `ADR-0001`, `ADR-0002` | Append title-semantics consumption evidence into `ADR-0001` and shell-detail / DI-4-boundary evidence into `ADR-0002` |
| New ADR carrier | `ADR-0009` | Publish the rebuilt journey carrier for cross-feature infrastructure placement |
| Current rulings | `S2`, `S9` | Refine `S2` with DI-1 shell detail; publish rebuilt current-effective `S9` |
| Mainline topic-map rows | `TH-001`, `TH-008`, new `TH-011` | Sync one inherited-context note, one shell-detail note, and one new publish-complete row |
| Ruling / ADR registries | `docs/architecture/rulings/README.md`, `docs/architecture/adr/README.md` | Register the new `S9` / `ADR-0009` assets |
| Current architecture backlinks | `docs/architecture/overview.md`, `docs/architecture/modules/core-editor/editor-shell-service.md`, `docs/architecture/modules/core-workspace/workspace-tree-service.md` | Switch live `S9` backlinks from legacy snapshot to rebuilt current ruling |
| Non-carrier trace | `DN-151-DN-153`, `DN-158-DN-159`, `DN-167-DN-168`, `DN-175` | Keep explicit as replay trace, but do not sync them into mainline rows |

## Stable-Line Mapping

| Theme ID | `DOC-009` Contribution |
|------|------|
| `TH-001` | Applies `atom.title` naming semantics to tab carriers and keeps per-ref `display_name` out of the tab truth path |
| `TH-008` | Supplies the first full DI-level shell-detail contract: state partition, group lifecycle, unified `EditBuffer`, coordinator boundary, DI-4 handoff, and implementation landing |
| `TH-011` | Publishes the cross-feature infrastructure placement line for `lib/core/editor/` and `lib/core/workspace/` |

## References

- [`05-dn-classification-to-decision-line.md`](05-dn-classification-to-decision-line.md)
