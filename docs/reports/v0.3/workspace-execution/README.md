# Workspace Execution PR Drafts

> DI-18 执行方案的 PR spec 落地。每份 spec 遵循 `docs/development/pr-spec-template.md` 规范。

**PR-0a（文本治理）不在本目录维护**，由 [`governance-kickoff-prep/`](../governance-kickoff-prep/README.md) 承载（PR-GOV-01~06）。本目录只覆盖 PR-0b ~ PR-6。

---

## 依赖图

```
Phase 0                    Phase 1
PR-0a (文本治理) → governance-kickoff-prep/PR-GOV-*
                           Layer 1         Layer 2              Layer 3            Layer 4
PR-0b (CI 治理) ─────────→ PR-1 (Schema) → PR-2 (Query)   ─┐
                                            PR-3 (Mutation) ─┤→ PR-4 (Guard+FFI) → PR-5 (Flutter core) → PR-6 (Flutter features)
```

## PR 清单

| PR | 文件 | 来源 | 状态 |
|----|------|------|------|
| PR-0b | [PR-0b-ci-duplication-detection.md](PR-0b-ci-duplication-detection.md) | DI-21 | DRAFT |
| PR-1 | [PR-1-schema-migration.md](PR-1-schema-migration.md) | DI-15 | DRAFT |
| PR-2 | [PR-2-scoped-query-repository.md](PR-2-scoped-query-repository.md) | DI-16 Q1 | DRAFT |
| PR-3 | [PR-3-tree-service-creation-service.md](PR-3-tree-service-creation-service.md) | DI-16 Q2-Q4 | DRAFT |
| PR-4 | [PR-4-guard-ffi.md](PR-4-guard-ffi.md) | DI-16 Q5-Q6 | DRAFT |
| PR-5 | [PR-5-flutter-core.md](PR-5-flutter-core.md) | DI-17 Q1-Q4 | DRAFT |
| PR-6 | [PR-6-flutter-features.md](PR-6-flutter-features.md) | DI-17 Q5-Q6 + DI-16 Q6 cleanup | DRAFT |

## 设计依据

- 执行方案：[DI-18-execution-plan.md](../design-discussions/DI-18-execution-plan.md)
- CI 重复检测：[DI-21-ci-duplication-detection.md](../design-discussions/DI-21-ci-duplication-detection.md)
- Rust 数据模型：[DI-15-rust-data-model-single-root.md](../design-discussions/DI-15-rust-data-model-single-root.md)
- Rust Service/FFI：[DI-16-rust-service-ffi-contract.md](../design-discussions/DI-16-rust-service-ffi-contract.md)
- Flutter 薄客户端：[DI-17-flutter-thin-client.md](../design-discussions/DI-17-flutter-thin-client.md)
- PR spec 模板：[pr-spec-template.md](../../../development/pr-spec-template.md)
