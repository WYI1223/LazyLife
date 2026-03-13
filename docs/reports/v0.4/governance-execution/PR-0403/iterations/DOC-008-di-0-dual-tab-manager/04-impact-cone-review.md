# DOC-008 / 04 Impact Cone Review

## Purpose and Boundary

Record which published lines, ADRs, topic-map rows, and non-carrier traces are touched by the `DOC-008` replay.

## Trigger and Inputs

- `03-retrospective-override-review.md`
- current published ADR set
- current topic-map mainline and working copy

## Impact Cone

| Surface | Touched Items | Impact |
|------|------|------|
| Published ADR carriers | `ADR-0002` | Append DI-0 naming clarification, blast-radius note, and implementation association |
| Mainline topic-map rows | `TH-008` | Sync notes to reflect the DI-0 naming split and layer clarification |
| Current rulings | none | `DOC-008` clarifies naming and implementation linkage, but does not rewrite current ruling text |
| Non-carrier trace | `DN-149` | Keep PR-spec traceability explicit as `context_only` |

## Stable-Line Mapping

| Theme ID | `DOC-008` Contribution |
|------|------|
| `TH-008` | S2 baseline clarification, naming split, widget rename blast radius, and implementation linkage into `PR-RB-06` |

## References

- [`05-dn-classification-to-decision-line.md`](05-dn-classification-to-decision-line.md)
