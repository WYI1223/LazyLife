# PR-3: TreeService 增强 + CreationService

- Proposed title: `feat(core): tree service protection rules and unified creation service`
- Status: Draft

## Goal

增强 TreeService（签名修复、保护规则、move 硬约束），引入 CreationService 统一 atom 创建路由（`resolve_creation_role` + `origin_workspace_id` 事务写入），实现 `reassign_designated` repo/service 层。

前置条件：PR-1（需要 Migration 0012 的 schema 和系统节点）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-16-rust-service-ffi-contract.md` Q2-Q4 | TreeService 增强、CreationService 设计、保护规则 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-15-rust-data-model-single-root.md` Q9、Q12 | 系统节点保护规则、designated folder 语义 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` Q1（PR-3 行）、Q4（Service 测试） | PR 定位、测试要求 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-12-workspace-tree-single-root.md` Q6 | 创建路由优先级 |

## Scope

In scope:
- `get_ancestor_path` 签名修复（DI-16 Q2）
- `list_atom_refs_for_atom` 新方法
- TreeService 保护规则：系统节点不可删除/移出
- move 硬约束：不可移入非本 workspace
- CreationService：`resolve_creation_role` 优先级（指定 folder > designated > root）+ `origin_workspace_id` 事务写入（DI-16 Q3）
- `reassign_designated` repo 方法 + service 层实现（DI-16 Q4）
- 跨 workspace 保护
- Service 层测试

Out of scope:
- ScopedQueryRepository（PR-2）
- Guard / FFI（PR-4）
- Flutter 层变更（PR-5/6）

## Design

TBD — kickoff 阶段细化。参考 DI-16 Q2-Q4 和 DI-12 Q6。

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Rust | `get_ancestor_path` 签名修复 + `list_atom_refs_for_atom` | `crates/lazynote_core/src/repo/tree_repo.rs` | TBD | — |
| T2 | Rust | TreeService 保护规则 + move 硬约束 | `crates/lazynote_core/src/service/tree_service.rs` | TBD | T1 |
| T3 | Rust | CreationService（`resolve_creation_role` + `origin_workspace_id` 写入） | `crates/lazynote_core/src/service/creation_service.rs` | TBD | — |
| T4 | Rust | `reassign_designated` repo + service | `crates/lazynote_core/src/repo/`, `crates/lazynote_core/src/service/` | TBD | — |
| T5 | Rust | 保护规则测试 + 创建路由优先级测试 + reassign 测试 | `crates/lazynote_core/tests/` | TBD | T2-T4 |

## Planned File Changes

- `[edit]` crates/lazynote_core/src/repo/tree_repo.rs (签名修复 + 新方法)
- `[edit]` crates/lazynote_core/src/repo/workspace_meta_repo.rs (`reassign_designated` repo 实现，DI-16 Q2)
- `[edit]` crates/lazynote_core/src/service/tree_service.rs (保护规则 + move 硬约束)
- `[edit]` crates/lazynote_core/src/service/creation_service.rs (resolve_creation_role 优先级 + origin_workspace_id 写入)
- `[edit]` crates/lazynote_core/src/service/mod.rs (导出)
- `[add]` crates/lazynote_core/tests/tree_service_protection_test.rs (或合入现有测试文件)

## Verification

### CI gates

```bash
cd crates/
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all
```

### Structural verification

```bash
# 验证 CreationService 存在
grep -rn "resolve_creation_role" crates/lazynote_core/src/ --include="*.rs"
# 预期：函数定义 + 至少一处调用

# 验证保护规则
grep -rn "system_node\|designated" crates/lazynote_core/src/service/tree_service.rs
# 预期：保护逻辑相关匹配
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 创建路由优先级边界情况（无 designated folder 时 fallback） | LOW | `resolve_creation_role` 优先级链有明确 fallback 到 root |
| move 硬约束与现有 move 测试冲突 | LOW | 新约束仅限跨 workspace，当前只有单 workspace |

## Acceptance Criteria

- [ ] `get_ancestor_path` 签名修复完成
- [ ] `list_atom_refs_for_atom` 方法可查询 atom 在树中的所有引用
- [ ] 系统节点不可通过 TreeService 删除
- [ ] 系统节点不可通过 TreeService 移出 workspace
- [ ] move 操作拒绝跨 workspace 移动
- [ ] `resolve_creation_role` 优先级：指定 folder > designated > root
- [ ] CreationService 事务内写入 `origin_workspace_id`
- [ ] `reassign_designated` repo/service 实现可重新指定 designated folder
- [ ] CreationService 拒绝跨 workspace 创建
- [ ] 现有 TreeService 测试全绿（语义不变回归）
- [ ] `cargo test --all` 全绿
- [ ] `cargo clippy --all -- -D warnings` 零 warning
- [ ] PR spec Status updated to Merged
