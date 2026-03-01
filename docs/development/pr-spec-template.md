# PR Spec Template

> Standard structure for PR specification documents. Codified from v0.3 kickoff experience.

---

## Template

```markdown
# PR-RB-XX: Title

- Proposed title: `type(scope): description`
- Status: Draft | In Progress | Merged

## Goal

[1-2 sentences: what problem does this PR solve?]

前置条件：[list dependent PRs that must be merged first]

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| [type] | [exact file path in repo] | [how this input drives this PR] |

## Scope

In scope:
- [explicit list of what this PR will do]

Out of scope:
- [explicit list of what this PR will NOT do, with rationale]

## Design

[Technical design, code examples, open decisions table]

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | [lane] | [description] | [file path] | [estimate] | [dependencies] |

## Planned File Changes

- `[add]` path/to/new/file.ext (description)
- `[edit]` path/to/existing/file.ext (description)
- `[delete]` path/to/removed/file.ext
- `[move]` old/path → new/path

## Verification

### CI gates

\`\`\`bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
\`\`\`

### Structural verification

\`\`\`bash
# [paste-to-terminal commands with expected output comments]
\`\`\`

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| [risk description] | LOW/MEDIUM/HIGH | [mitigation strategy] |

## Acceptance Criteria

- [ ] [binary criterion — pass/fail, no ambiguity]
- [ ] [binary criterion]
- [ ] PR spec Status updated to Merged
```

---

## Filling Rules

1. **Execution Contract file names must exactly match repository file names** — no semantic aliases. (Lesson from v0.3 Spec Review Issue 4)

2. **Verification commands must be executable** — paste into terminal and run directly, no human interpretation required.

3. **Acceptance Criteria must be binary** — each criterion can only be judged "pass" or "fail". No fuzzy language like "mostly complete" or "generally follows".

4. **Planned File Changes paths must be specific to file level** — no "related files" or vague descriptions.

5. **Each Task in Task Breakdown corresponds to one git commit granularity** — tasks may be combined but not further split.
