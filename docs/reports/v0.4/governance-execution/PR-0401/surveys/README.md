# PR-0401 Survey Index

This directory stores per-document structure surveys for PR-0401.

## Coverage

- `DOC-001` through `DOC-029` now each have a survey file.
- `DOC-017` is a missing-slot survey: it records the `DI-9` absence from the design-discussions index rather than a real source document.
- The current survey pass is intentionally source-anchor-first: each file is split at the smallest stable heading or list-item anchor that exists in the source text.

## Current Boundary

- Survey completion does not mean DN extraction is complete.
- `DOC-002`, `DOC-006`, `DOC-027`, and `DOC-028` still remain the only DN-seeded rows in `dn-ledger.md`.
- The next pass should continue per-anchor DN extraction without re-collapsing survey granularity.
