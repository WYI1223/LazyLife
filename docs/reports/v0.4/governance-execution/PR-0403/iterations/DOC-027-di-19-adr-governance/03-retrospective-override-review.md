# DOC-027 / 03 Retrospective Override Review

## Purpose and Boundary

Review whether `DI-19` should override, append, or merely trace existing governance surfaces.

For this document, the central question is not theme split or merge. It is:

1. whether the already-landed governance docs still reflect the active `DI-19` rule set; and
2. whether any superseded proposal block in `DI-19` would incorrectly pull replay backward.

## Override Findings

| Source Layer | Finding | Replay Consequence |
|------|------|------|
| `### 2.1`, `### 2.3`, `## 10-15` | These sections are the active rule surface. | Treat as current-effective governance inputs. |
| `### 2.2`, `## 3-9` | These sections are explicitly superseded historical proposal blocks. | Keep as historical trace only; do not use them to rewrite current governance docs. |
| `docs/architecture/adr/README.md` | Already carries the journey-layer boundary, authority split, and retrospective/native ADR distinction. | Append / tighten only. |
| `docs/architecture/adr/topic-map.md` | Already carries mainline registry boundary, row admission rules, and explicit normative-source column. | Append / tighten only. |
| `PR-0402/adr-metadata-contract.md` | Already carries the retrospective ADR skeleton and metadata contract used by current replay. | Append the active ADR admission rule explicitly. |

## Replay Judgment

`DOC-027` is not a source that should create:

1. a new `TH-xxx` row;
2. a new governance ADR asset; or
3. a new governance ruling.

Instead, the replay outcome is:

1. tighten already-landed governance docs so they explicitly reflect the active `DI-19` rule surface;
2. mark the earlier `DOC-006 / PR-RB-00` carrier-migration seed as consumed by current governance sync;
3. leave execution-order, closure-audit, activation, and playbook extraction detail to `DOC-028`, `PR-0404`, `PR-0405`, and `PR-0406`.

## References

- [`02-historical-semantic-freeze.md`](02-historical-semantic-freeze.md)
- [`../../../../../../architecture/adr/README.md`](../../../../../../architecture/adr/README.md)
- [`../../../../../../architecture/adr/topic-map.md`](../../../../../../architecture/adr/topic-map.md)
- [`../../open-items.md`](../../open-items.md)
