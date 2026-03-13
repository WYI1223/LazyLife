# DOC-008 / 02 Historical Semantic Freeze

## Purpose and Boundary

Freeze the semantic meaning of `DOC-008 / DI-0-dual-tab-manager.md` before any classification or carrier choice.

This stage must preserve that `DOC-008` is:

1. a historical DI clarification source;
2. a naming and layer-boundary clarification for the shell-ownership line;
3. not a fresh semantic freeze that replaces the already-published `TH-008` why-question.

## Trigger and Inputs

- source doc: [`../../../../../../reports/v0.3/design-discussions/DI-0-dual-tab-manager.md`](../../../../../../reports/v0.3/design-discussions/DI-0-dual-tab-manager.md)
- survey: [`../../../PR-0401/surveys/DOC-008-survey.md`](../../../PR-0401/surveys/DOC-008-survey.md)
- DN baseline: [`../../../PR-0401/dn-ledger.md`](../../../PR-0401/dn-ledger.md)

## Frozen Source Semantics

| DN Group | Source DN IDs | Frozen Meaning |
|------|------|------|
| Baseline clarification | `DN-146` | DI-0 clarified that the two `note_tab_manager` artifacts were different layers, not competing versions |
| Naming decision | `DN-147` | DI-0 fixed the name split `NoteTabStateManager -> EditorGroupModel` and `NoteTabManager -> NoteTabStrip` |
| Rename blast-radius trace | `DN-148` | DI-0 recorded the concrete widget-side rename surface across imports and test keys |
| PR-spec traceability | `DN-149` | DI-0 pushed the clarification back into `PR-0300D` and `PR-0301B` scope/spec wording |
| Implementation association | `DN-150` | DI-0 later recorded the landing implementation in `PR-RB-06` |

## Freeze Decision

1. `DOC-008` is a design-clarification append source for the shell-ownership line.
2. It tightens naming and layer-boundary understanding around the same stable why-question already published in `TH-008`.
3. It does not justify a new theme row.
4. PR-spec traceability should remain explicit even if it does not become a carrier by itself.

## References

- [`03-retrospective-override-review.md`](03-retrospective-override-review.md)
- [`../../../PR-0401/dn-ledger.md`](../../../PR-0401/dn-ledger.md)
