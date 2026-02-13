## TODO: Documentation language policy (canonical = English)

### P0 — Decide & document the policy

* [ ] Define **English as the only canonical source** for docs (single source of truth).
* [ ] Add a short “Docs language policy” section to `CONTRIBUTING.md`:

  * English is canonical.
  * Translations are optional and may lag behind.
  * How to contribute translations (PR welcome).
* [ ] Decide naming conventions:

  * Canonical: `README.md`, `docs/**`
  * Chinese translation (later): `README.zh-CN.md`, `docs/zh-CN/**` (or `docs/i18n/zh-CN/**`)

### P0 — Entry points & navigation

* [ ] Add/ensure a single docs entry page: `docs/index.md`

  * Link to: architecture, product, compliance, governance, releases.
* [ ] Ensure `README.md` links to `docs/index.md` as the primary navigation.

### P1 — Canonical linking rules (avoid drift)

* [ ] Rule: internal doc links should point to **canonical paths** (`docs/...`), not translations.
* [ ] Rule: architecture decisions (ADR) are **canonical-only** (no full translation requirement).

### P1 — Translation mechanism (later, but plan now)

* [ ] Define a required translation header format (for future translated pages), e.g.:

  * “Translation of `<canonical_path>` @ `<source_commit>`”
  * “Translation may lag behind canonical.”
* [ ] Decide where translation lives:

  * Option A: `README.zh-CN.md` only (minimal)
  * Option B: `docs/zh-CN/**` full tree (later if needed)

### P2 — Automation/maintenance (optional later)

* [ ] Add a PR checklist item: “Docs updated? Translation impacted?”
* [ ] (Optional) Add a small script to detect translated docs missing `source_commit` header.
* [ ] (Optional) Add a docs lint job in CI (check broken links, etc.).
