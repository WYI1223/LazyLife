# DOC-009 / 03 Retrospective Override Review

## Purpose and Boundary

Check whether `DOC-009` introduces a real override, redirect, or new stable line over the already-published replay outputs.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- published topic-map rows in [`../../../../../../architecture/adr/topic-map.md`](../../../../../../architecture/adr/topic-map.md)
- published ADRs [`../../../../../../architecture/adr/ADR-0001-atom-projection-model.md`](../../../../../../architecture/adr/ADR-0001-atom-projection-model.md) and [`../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md`](../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md)
- current-effective ruling set in [`../../../../../../architecture/rulings/README.md`](../../../../../../architecture/rulings/README.md)
- legacy `S9` snapshot in [`../../../../../../architecture/rulings-legacy/S9-cross-feature-infrastructure-placement.md`](../../../../../../architecture/rulings-legacy/S9-cross-feature-infrastructure-placement.md)

## Override Review

| Source Surface | Override Result | Reason |
|------|------|------|
| `DN-154-DN-166`, `DN-170`, `DN-176` vs published `TH-008 / S2` | `append_only_with_ruling_refine` | DI-1 does not replace the shell-ownership why-question; it supplies the first full DI-level detail set that the current ruling can now absorb |
| `DN-169` vs published `TH-001 / S1` | `append_only_inherited_context` | DI-1 applies the already-published `title` truth rule to tab carriers; it does not create a new naming line |
| `DN-171-DN-174` vs legacy `S9` | `publish_missing_current_line` | The replay already has a legacy S9 snapshot and DI-1 decision-source-grade material, but no current-effective published row yet; this run can rebuild that line cleanly |
| `DN-151-DN-153`, `DN-158-DN-159`, `DN-167-DN-168`, `DN-175` | `no_override` | These clauses remain important trace or scope material, but they do not change any stable why-question or justify their own carrier |

## Decision

1. `DOC-009` must append into `TH-008` and may legitimately refine the current `S2` ruling text.
2. `DOC-009` must append inherited title-semantics evidence into `TH-001` without creating a title-only theme.
3. `DOC-009` must rebuild the missing current-effective `S9` line as a new published theme row.
4. Internal intake/problem/scope/synthesis clauses remain explicit non-carrier traces.

## References

- [`04-impact-cone-review.md`](04-impact-cone-review.md)
- [`../../../../../../architecture/adr/topic-map.md`](../../../../../../architecture/adr/topic-map.md)
