# DOC-002 / 03 Retrospective Override Review

## Purpose and Boundary

Review how later source material treated each `08b` decision line.

This stage decides whether a line was:

1. continued and formalized;
2. redirected or superseded;
3. still blocked from publication.

## Trigger and Inputs

- `DOC-003 / 08c` execution proposals
- `DOC-004 / 08d` PR mapping and v0.3 handoff
- `DOC-005 / 09` closure and orphan ledger
- `rulings-legacy/S1-S8`

## Override Review

| Line | Later Sources Consumed | Result |
|------|------------------------|--------|
| `S1` | `08c 3.2.4`, `08d 4.2/4.4/4.8/4.9`, `09 4.1-4.4/7.3`, legacy `S1` | Continued and formalized. No later source replaced the stable why-question; later material only split implementation timing and preserved deferred sub-lines `R11-R14`. |
| `S2` | `08c 3.1.1`, `08d 4.2/4.5/4.6`, `09 4.1-4.3/7.3`, legacy `S2` | Continued with phase detail. The line was not redirected into a different topic; later DI work expands the same shell-ownership line. |
| `S3` | `08c 3.2.4`, `08d 4.2/4.8/4.9`, `09 4.1-4.2/7.3`, legacy `S3` | Validated rather than overturned. Later material confirms the orthogonality invariant instead of replacing it. |
| `S4` | `08c 3.2.4`, `08d 4.2/4.8/4.9`, `09 4.1-4.2/7.3`, legacy `S4` | Continued and landed. Later material turns the semantic rule into a v0.3 implementation path but does not redirect the line elsewhere. |
| `S5` | `08c 3.2.4/3.3`, `08d 4.2/4.4/4.7/4.8`, `09 4.1-4.2/5.2`, legacy `S5` | Continued and landed. Later material documents and preserves the first-party / third-party split rather than rewriting it. |
| `S6` | `08c 3.2.4/3.3`, `08d 4.2/4.4/4.7/4.8`, `09 4.1-4.2/5.2`, legacy `S6` | Continued with runtime deferred. The line stays stable even though orchestrator/runtime pieces remain later work. |
| `S7` | `08c 3.1.4/3.2.4`, `08d 4.2/4.7/4.8`, `09 4.1-4.2/5.2`, legacy `S7` | Continued and landed. The module move and lifecycle-trigger semantics were later implemented rather than superseded. |
| `S8` | `08c 3.2.4/3.3`, `08d 4.2/4.4/4.8`, `09 4.1-4.3/7.3`, legacy `S8` | Continued and landed. Replay evidence does not support merging the DTO boundary back into `S1`; `S8` remains a distinct line. |

## Gate Result

No `DOC-002` line requires `redirect_to_existing_adr` or `escalate_to_governance` at this stage.

## References

- [`../../../../../../reports/v0.2.5/frontend-review/08c-solution-proposals.md`](../../../../../../reports/v0.2.5/frontend-review/08c-solution-proposals.md)
- [`../../../../../../reports/v0.2.5/frontend-review/08d-pr-replanning.md`](../../../../../../reports/v0.2.5/frontend-review/08d-pr-replanning.md)
- [`../../../../../../reports/v0.2.5/frontend-review/09-acceptance-report.md`](../../../../../../reports/v0.2.5/frontend-review/09-acceptance-report.md)
