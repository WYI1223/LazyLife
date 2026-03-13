# DOC-009 / 02 Historical Semantic Freeze

## Purpose and Boundary

Freeze the semantic meaning of `DOC-009 / DI-1-editor-shell-service.md` before any carrier choice.

This stage must preserve that `DOC-009` is:

1. the first large DI-level shell-detail source after the published `S2` baseline;
2. an application source for `S1` title semantics inside tab carriers rather than a replacement title theory;
3. the earliest replay source in the current corpus that can rebuild the legacy `S9` placement line as a current-effective carrier.

## Trigger and Inputs

- source doc: [`../../../../../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md`](../../../../../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md)
- survey: [`../../../PR-0401/surveys/DOC-009-survey.md`](../../../PR-0401/surveys/DOC-009-survey.md)
- DN baseline: [`../../../PR-0401/dn-ledger.md`](../../../PR-0401/dn-ledger.md)
- legacy normative snapshot: [`../../../../../../architecture/rulings-legacy/S9-cross-feature-infrastructure-placement.md`](../../../../../../architecture/rulings-legacy/S9-cross-feature-infrastructure-placement.md)

## Frozen Source Semantics

| DN Group | Source DN IDs | Frozen Meaning |
|------|------|------|
| Intake and inherited baseline | `DN-151-DN-153` | DI-1 opens from a design gap, converts audit D1-D3 into explicit questions, and treats legacy `S2` as the already-fixed ownership direction it must refine rather than re-litigate |
| Shell ownership detail | `DN-154-DN-166`, `DN-170`, `DN-176` | DI-1 refines the shell line into pane-vs-atom state partition, tab-driven group lifecycle, unified `EditBuffer`, coordinator boundary, explicit DI-4 handoff for multi-pane sync mechanics, post-extraction controller shape, and implementation landing in `PR-RB-06` |
| Title semantics application | `DN-169` | DI-1 applies `S1` title semantics to tabs by requiring `atom.title` rather than per-ref `display_name`, while introducing `TabEntry { atomId, title }` and `updateTabTitle` on the shell side |
| Cross-feature infrastructure placement | `DN-171-DN-174` | DI-1 resolves `WorkspaceTreeService` into `lib/core/workspace/` and the editor shell stack into `lib/core/editor/`, with an explicit core-vs-shared rationale and target module layout |
| Internal problem/scope/synthesis traces | `DN-158-DN-159`, `DN-167-DN-168`, `DN-175` | These clauses explain why DI-1 narrows and structures its local discussion, but they are not independent stable why-questions by themselves |

## Freeze Decision

1. `DOC-009` is a major append source for the already-published shell-ownership line.
2. `DOC-009` also contributes one inherited-context append to the published Atom-projection line around title semantics.
3. `DOC-009` is sufficient to rebuild the legacy `S9` placement line as a current published carrier.
4. Intake, problem-breakdown, internal scope, and architecture-synthesis clauses must stay explicit, but they should not all be promoted into separate theme rows.

## References

- [`03-retrospective-override-review.md`](03-retrospective-override-review.md)
- [`../../../PR-0401/dn-ledger.md`](../../../PR-0401/dn-ledger.md)
