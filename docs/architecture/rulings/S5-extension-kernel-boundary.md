# S5: Extension Kernel Boundary

| Field | Value |
|------|------|
| Current Status | `active` |
| Rebuilt In | `PR-0403` |
| Historical Snapshot | [`../rulings-legacy/S5-extension-kernel-boundary.md`](../rulings-legacy/S5-extension-kernel-boundary.md) |
| Current ADR | [`../adr/ADR-0005-extension-kernel-boundary.md`](../adr/ADR-0005-extension-kernel-boundary.md) |

## Decision

First-party command execution stays outside Extension Kernel. Extension Kernel remains the guarded contract surface for future third-party extensions rather than a mandatory carrier for trusted product runtime.

## Normative Rules

1. First-party command paths may register and invoke directly in the product runtime without going through Extension Kernel manifest validation or capability guards.
2. Extension Kernel exists as the third-party extension contract boundary and must not be reinterpreted as the only valid runtime path for first-party features.
3. A declaration-only extension kernel remains a correct current state until real third-party runtime demand appears.
4. Changes required by other current rulings, including Atom and creation semantics, apply at the command and FFI layers rather than being routed through Extension Kernel by default.

## Current Interpretation

- Trusted first-party command runtime is direct product infrastructure, not an extension sandbox.
- Test adapters or placeholder extension hooks do not by themselves justify moving first-party runtime into Extension Kernel.

## Open Edges

- First real third-party plugin demand
- Sandboxed extension execution model
- Optional first-party capability manifest for documentation

## Traceability

- Historical source: [`../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md`](../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)
- Trigger source: [`../../reports/v0.2.5/frontend-review/08a-audit-findings.md`](../../reports/v0.2.5/frontend-review/08a-audit-findings.md)
- Journey record: [`../adr/ADR-0005-extension-kernel-boundary.md`](../adr/ADR-0005-extension-kernel-boundary.md)
