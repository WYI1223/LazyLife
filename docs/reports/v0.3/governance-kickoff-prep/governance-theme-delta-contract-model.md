# Governance Theme Delta Contract Model

> Prep-layer execution model for future governance PR specs.
> This document is not a stable template yet; it captures the minimum contract shape that
> later mainline execution must preserve.

---

## Purpose

This model defines how a governance PR declares:

1. which governance themes it changes;
2. what kind of change it performs on each theme;
3. which semantics must not be downgraded during execution;
4. how review and closure should verify the declared delta.

It is a prep-layer reference for future kickoff organization, not a final reusable template.

---

## Global Contract Fields

Each governance PR should declare a top-level `Theme Delta Contract` with at least:

| Field | Meaning |
|------|---------|
| `Covered Themes` | Which `T1-T8` themes are affected |
| `Theme Operations` | Theme-level operations performed by this PR |
| `Primary Theme Owner` | The owner responsible for semantic correctness |
| `PR Executor` | The person implementing the PR |
| `Secondary Coverage` | Incidental but real coverage of adjacent themes |
| `Out of Scope` | What this PR explicitly does not do |
| `Must Preserve` | Semantic constraints that must not be weakened |
| `Allowed Simplifications` | Temporary simplifications that do not change the target semantics |
| `Escalation Required If Violated` | Conditions that require governance escalation |
| `Accepted Debt` | Explicit debt, owner, and exit condition |
| `Output Docs` | Documents created or changed by the PR |
| `Verification` | How the PR proves its delta is real |
| `Required Sign-off` | Required owner / governance approval |

---

## Theme Delta Row Fields

For each covered theme, one row is required:

| Field | Meaning |
|------|---------|
| `Theme ID` | Stable governance theme identifier |
| `Theme Operation` | Operation applied to the theme |
| `Before Status` | Theme state before this PR |
| `After Status` | Theme state after this PR |
| `Docs Touched` | Concrete documents where the delta lands |
| `Must Preserve` | Theme-specific invariant |
| `Verification` | Theme-specific verification signal |

No theme may be listed without a concrete row-level delta.

---

## Operation Catalog

Recommended `Theme Operation` values:

| Operation | Use When |
|------|---------|
| `inventory` | Source corpus / theme inventory is being established |
| `confirm` | Existing rule or structure is being made explicit |
| `split` | One theme is being split into multiple decision lines |
| `merge` | Multiple theme candidates are being unified |
| `supersede` | A previous theme path is explicitly overridden |
| `redirect` | Theme continuation is redirected to a new line |
| `prepare_adr_draft` | Prep-layer ADR manuscript is being created |
| `publish_adr` | Mainline ADR is being published |
| `backlink_sync` | Traceability / backlink rules are being synchronized |
| `closure_audit` | Closure evidence is being produced |
| `template_sync` | Stable template / playbook / lifecycle material is being backfilled |

Prep-layer specs should prefer `prepare_adr_draft` over `publish_adr` unless the action truly
belongs to future mainline execution.

---

## Anti-Downgrade Hooks

The contract must make semantic downgrade explicit rather than implicit.

1. `Must Preserve` records the target semantics that cannot be weakened.
2. `Allowed Simplifications` records staging-only simplifications.
3. `Accepted Debt` must never be used to hide semantic downgrade.
4. If the real implementation weakens target semantics, it must escalate back into governance
   rather than being silently absorbed by the PR spec.

---

## Minimal Example

```md
## Theme Delta Contract

| Field | Content |
|------|---------|
| Covered Themes | `T5`, `T6` |
| Theme Operations | `T5=confirm+template_sync`, `T6=confirm+backlink_sync` |
| Primary Theme Owner | `PR-GOV-04` |
| PR Executor | `TBD (during v0.4 kickoff)` |
| Must Preserve | `Semantic Review` stays manual; traceability graph stays explicit |

### Theme Delta Rows

| Theme ID | Theme Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------------|---------------|--------------|--------------|---------------|--------------|
| `T5` | `confirm`, `template_sync` | only defined in DI | prep contract model exists | `...` | no hidden downgrade | `...` |
```

---

## Current Prep Conclusion

1. This model is now available as a prep-layer reference.
2. It still requires real future kickoff use before it can become a stable template.
3. Mainline template finalization remains a `PR-GOV-06` concern.
