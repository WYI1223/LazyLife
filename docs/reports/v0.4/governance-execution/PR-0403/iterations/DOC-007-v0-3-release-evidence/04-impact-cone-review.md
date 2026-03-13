# DOC-007 / 04 Impact Cone Review

## Purpose and Boundary

Record which published lines, ADRs, topic-map rows, and parked bundles are touched by the `DOC-007` replay.

## Trigger and Inputs

- `03-retrospective-override-review.md`
- current published ADR set
- current topic-map mainline and working copy

## Impact Cone

| Surface | Touched Items | Impact |
|------|------|------|
| Published ADR carriers | `ADR-0001` through `ADR-0008` | Append release-evidence confirmation, sign-off, deferred-boundary, and post-review verification where relevant |
| Mainline topic-map rows | `TH-001`, `TH-008`, `TH-002`, `TH-003`, `TH-009`, `TH-010`, `TH-004`, `TH-005` | Sync notes to reflect `DOC-007` release-evidence confirmation |
| Current rulings | none | `DOC-007` is closure evidence only and does not rewrite current ruling text |
| Parked carry-forward bundles | release verification, release governance, v0.4 boundary remainder, release review-fix provenance | Remain explicit in `open-items.md` and classification output |

## Stable-Line Mapping

| Theme ID | `DOC-007` Contribution |
|------|------|
| `TH-001` | Gate A, release gate, ruling-layer sign-off, deferred-boundary, and post-review re-verification confirmation |
| `TH-008` | Gate B, release gate, ruling-layer sign-off, DI-chain sign-off, and post-review re-verification confirmation |
| `TH-002` | Release gate, ruling-layer sign-off, and post-review re-verification confirmation |
| `TH-003` | Atom-ref / Gate A confirmation, release gate, ruling-layer sign-off, deferred-boundary, and post-review re-verification confirmation |
| `TH-009` | Gate A, release gate, ruling-layer sign-off, and post-review re-verification confirmation |
| `TH-010` | Release gate, ruling-layer sign-off, deferred-boundary, and post-review re-verification confirmation |
| `TH-004` | Gate A, release gate, ruling-layer sign-off, deferred-boundary, and post-review re-verification confirmation |
| `TH-005` | Gate A, release gate, ruling-layer sign-off, and post-review re-verification confirmation |

## Non-Line Impact

1. `DN-133-DN-134` stays a release-verification bundle.
2. `DN-139-DN-141` stays a release/governance closure bundle.
3. `DN-142` keeps a non-line v0.4-boundary remainder.
4. `DN-143-DN-144` stays release-evidence provenance.
5. `DN-138` keeps an `S9` legacy-only sign-off remainder that does not create a published row.

## References

- [`05-dn-classification-to-decision-line.md`](05-dn-classification-to-decision-line.md)
- [`../../open-items.md`](../../open-items.md)
