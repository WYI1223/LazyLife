# DOC-002 / 06 ADR Carrier Check

## Purpose and Boundary

Choose the carrier outcome for each classified line.

Allowed outputs:

1. `create_new_adr`
2. `append_existing_adr`
3. `redirect_to_existing_adr`
4. `park_later`
5. `escalate_to_governance`

## Trigger and Inputs

- `05-dn-classification-to-decision-line.md`
- `PR-0402` ADR metadata contract
- current mainline ADR registry state (`docs/architecture/adr/` was empty except for shell files)
- current ruling registry state (`docs/architecture/rulings/` was empty except for `README.md`)

## Carrier Decisions

| Theme ID | Decision | Reason |
|------|------|------|
| `TH-001` | `create_new_adr` | No published ADR exists, and the line is stable enough to publish with explicit open edges for deferred sub-rules |
| `TH-008` | `create_new_adr` | No earlier ADR carrier exists, and later DI phases expand the same line rather than blocking initial publication |
| `TH-002` | `create_new_adr` | Replay evidence supports a stable line with a current ruling target and no unresolved redirect |
| `TH-003` | `create_new_adr` | The line is distinct from `TH-001` and has a publishable current ruling target |
| `TH-009` | `create_new_adr` | Replay evidence supports a distinct carrier boundary line rather than an implementation appendix under another ADR |
| `TH-010` | `create_new_adr` | Replay evidence supports a distinct orchestration boundary line rather than an appendix under `TH-003` or `TH-001` |
| `TH-004` | `create_new_adr` | Publication is justified even though some later lifecycle hooks remain open |
| `TH-005` | `create_new_adr` | Split resolution is complete and there is no prior carrier to append into |

## Gate Result

All eight lines pass carrier check as `create_new_adr`.

No line is parked or escalated in this run.

## References

- [`../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md`](../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md)
- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
