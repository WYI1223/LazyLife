# DOC-018 / 07 ADR Create Or Append

## Purpose and Boundary

Execute the carrier decisions from `06`.

For `DOC-018`, this stage must:

1. append resolver-shell detail into the published shell-ownership ADR;
2. append editor-resolver placement detail into the published placement ADR;
3. avoid creating any new ADR asset.

## Trigger and Inputs

- `06-adr-carrier-check.md`
- published ADRs [`../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md`](../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md) and [`../../../../../../architecture/adr/ADR-0009-cross-feature-infrastructure-placement.md`](../../../../../../architecture/adr/ADR-0009-cross-feature-infrastructure-placement.md)
- source doc [`../../../../../../reports/v0.3/design-discussions/DI-10-editor-resolver-shell.md`](../../../../../../reports/v0.3/design-discussions/DI-10-editor-resolver-shell.md)

## ADR Append Actions

| ADR | Action | Result |
|------|------|------|
| `ADR-0002` | append | Added `DOC-018` evidence covering the resolver middle layer, `EditorPaneBuilder` interface boundary, explicit `register()` protocol, no-fallback safety rule, and the preserved future `View Mode` edge plus DI-4 bridge handoff note |
| `ADR-0009` | append | Added `DOC-018` evidence covering `lib/core/editor/editor_resolver.dart` placement, `NoteEditor -> MarkdownEditorPane` extraction boundary, and the rule that feature chrome remains feature-local rather than moving into core infrastructure |

## ADR Asset Result

1. zero new ADR filenames were created;
2. `ADR-0002` and `ADR-0009` are the only touched carriers;
3. `DOC-018` is now reflected in both journey lineages.

## References

- [`08-ruling-update-and-sync.md`](08-ruling-update-and-sync.md)
