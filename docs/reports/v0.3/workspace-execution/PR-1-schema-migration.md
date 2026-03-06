# PR-1: Schema Migration 0012 — 单根树 + Workspace 元数据 + Designated Folders

- Proposed title: `feat(core): migration 0012 single-root workspace tree with designated folders`
- Status: Draft

## Goal

新增 Migration 0012，建立单根 workspace 树结构：`workspaces` 表、designated folders 映射、`atoms.origin_workspace_id` 字段、系统节点回填、DB 触发器保护。为后续 PR-2~6 提供 schema 基础。

前置条件：PR-0b（CI 增强应先就位）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-15-rust-data-model-single-root.md` | Schema 设计、系统节点定义、触发器定义、回填逻辑的完整依据 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` Q1（PR-1 行）、Q4（Migration 测试） | PR 定位、测试要求 |
| 现有 schema | `crates/lazynote_core/src/db/migrations/` | 当前 11 个 migration，本 PR 新增第 12 个 |

## Scope

In scope:
- 新增 `0012_workspace_single_root.sql`
- `workspaces` 表（workspace 元数据：workspace_id、display_name、is_default 等，DI-15 Q9）
- `atoms` 表新增 `origin_workspace_id` 字段（DI-15 Q10：来源 workspace 标记，nullable 以兼容回填）
- `designated_folders` 表（系统节点映射）
- 系统节点创建（workspace root + 3 个 designated folders）
- 现有数据回填（已有 atom 的 atom_ref 归入正确 designated folder）
- DB 触发器：`protect_designated_folder_soft_delete`、`protect_designated_folder_hard_delete`、`validate_designated_folder_workspace`、`protect_workspace_root_reparent`、`protect_workspace_root_kind`
- WorkspaceMetaRepository（Rust：`resolve_designated`、workspace 元数据查询）
- Migration 注册到 `mod.rs` MIGRATIONS 数组
- Migration 测试（全新安装 + 版本升级 + 触发器负测）

Out of scope:
- ScopedQueryRepository（PR-2）
- TreeService 增强 / CreationService（PR-3）
- FFI 函数变更（PR-4）

## Design

TBD — kickoff 阶段细化。参考 DI-15 的 schema 设计。

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Rust | Migration SQL 编写 | `crates/lazynote_core/src/db/migrations/0012_workspace_single_root.sql` | TBD | — |
| T2 | Rust | Migration 注册 | `crates/lazynote_core/src/db/migrations/mod.rs` | TBD | T1 |
| T3 | Rust | WorkspaceMetaRepository | `crates/lazynote_core/src/repo/` | TBD | T1 |
| T4 | Rust | 全新安装测试 + 版本升级测试 | `crates/lazynote_core/tests/` | TBD | T1-T3 |
| T5 | Rust | 触发器负测（5 项） | `crates/lazynote_core/tests/` | TBD | T1 |

## Planned File Changes

- `[add]` crates/lazynote_core/src/db/migrations/0012_workspace_single_root.sql
- `[edit]` crates/lazynote_core/src/db/migrations/mod.rs (注册 migration 12)
- `[add]` crates/lazynote_core/src/repo/workspace_meta_repo.rs (WorkspaceMetaRepository)
- `[edit]` crates/lazynote_core/src/repo/mod.rs (导出新 repo)
- `[add]` crates/lazynote_core/tests/migration_0012_test.rs (或合入现有测试文件)

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
# 验证 migration 注册
grep -c "0012" crates/lazynote_core/src/db/migrations/mod.rs
# 预期：至少 1 匹配

# 验证触发器存在于 SQL
grep -c "protect_designated_folder" crates/lazynote_core/src/db/migrations/0012_workspace_single_root.sql
# 预期：至少 2 匹配（soft-delete + hard-delete）

grep -c "protect_workspace_root" crates/lazynote_core/src/db/migrations/0012_workspace_single_root.sql
# 预期：至少 2 匹配（reparent + kind）
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 回填逻辑处理边界情况（orphan atoms、已删除 atoms） | MEDIUM | 充分的版本升级测试覆盖 |
| 触发器阻止合法操作 | LOW | 触发器负测覆盖全部 5 个保护场景 |

## Acceptance Criteria

- [ ] Migration 0012 从空 DB 运行成功，`workspaces` 表存在
- [ ] Migration 0012 从空 DB 运行成功，系统节点（workspace root + 3 designated folders）存在
- [ ] Migration 0012 从空 DB 运行成功，`atoms.origin_workspace_id` 字段存在
- [ ] Migration 0012 从 v11 升级成功，旧 atom 回填到正确 designated folder
- [ ] Migration 0012 从 v11 升级成功，`atoms.origin_workspace_id` 回填正确
- [ ] 触发器负测：designated folder soft-delete 被拒绝
- [ ] 触发器负测：designated folder hard-delete 被拒绝
- [ ] 触发器负测：跨 workspace designated 写入被拒绝
- [ ] 触发器负测：workspace root re-parent 被拒绝
- [ ] 触发器负测：workspace root kind 篡改被拒绝
- [ ] WorkspaceMetaRepository 可查询 workspace 元数据
- [ ] WorkspaceMetaRepository 可查询 designated folder 映射（`resolve_designated`）
- [ ] `cargo test --all` 全绿
- [ ] `cargo clippy --all -- -D warnings` 零 warning
- [ ] PR spec Status updated to Merged
