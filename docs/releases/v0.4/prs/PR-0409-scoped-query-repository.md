# PR-0409: ScopedAtomQuery + ScopedQueryRepository

- Proposed title: `feat(core): scoped atom query engine with CTE pipeline`
- Status: Draft

## Goal

引入统一查询引擎 ScopedQueryRepository，支持按 workspace 子树范围查询 atoms。替代 TaskService/CalendarService 的直查 atoms 路径，为 PR-0411 FFI 层的 `query_atoms` 提供后端。

前置条件：PR-0408（需要 Migration 0012 的 schema）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-16-rust-service-ffi-contract.md` Q1 | ScopedAtomQuery 结构、枚举、CTE 管线设计 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` Q1（PR-0409 行）、Q4（Service 测试） | PR 定位、测试要求（契约真值表） |
| 现有实现 | `crates/lazynote_core/src/service/task_service.rs` | 查询路径改造目标 |
| 现有实现 | `crates/lazynote_core/src/service/atom_service.rs` | 查询路径改造目标 |

## Scope

In scope:
- ScopedAtomQuery struct + 全套枚举（ProjectionMode、TimeFilter、SortOrder 等）
- ScopedQueryRepository：CTE 管线实现（子树展开 → 时间过滤 → 排序 → 分页）
- TaskService 查询路径改造：`list_inbox`/`list_today`/`list_upcoming` 委托到 ScopedAtomQuery（DI-16 Q1.4）
- CalendarService 查询路径改造：`list_by_range` 委托到 ScopedAtomQuery
- 契约真值表测试：descriptor 合法/非法组合覆盖
- overdue T1 补偿逻辑

Out of scope:
- TreeService 增强 / CreationService（PR-0410）
- FFI 层变更（PR-0411）
- Flutter 消费方变更（PR-0412/6）

## Design

TBD — kickoff 阶段细化。参考 DI-16 Q1 的 ScopedAtomQuery 设计。

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Rust | ScopedAtomQuery struct + 枚举定义 | `crates/lazynote_core/src/repo/` | TBD | — |
| T2 | Rust | ScopedQueryRepository CTE 管线 | `crates/lazynote_core/src/repo/` | TBD | T1 |
| T3 | Rust | TaskService 查询路径委托改造 | `crates/lazynote_core/src/service/task_service.rs` | TBD | T2 |
| T4 | Rust | CalendarService 查询路径委托改造 | `crates/lazynote_core/src/service/atom_service.rs` | TBD | T2 |
| T5 | Rust | 契约真值表测试 + time-matrix 四象限测试 | `crates/lazynote_core/tests/` | TBD | T2 |

## Planned File Changes

- `[add]` crates/lazynote_core/src/repo/scoped_query_repo.rs (ScopedQueryRepository)
- `[add]` crates/lazynote_core/src/model/scoped_atom_query.rs (ScopedAtomQuery + 枚举)
- `[edit]` crates/lazynote_core/src/service/task_service.rs (委托到 ScopedAtomQuery)
- `[edit]` crates/lazynote_core/src/service/atom_service.rs (calendar 查询委托)
- `[edit]` crates/lazynote_core/src/repo/mod.rs (导出新 repo)
- `[edit]` crates/lazynote_core/src/model/mod.rs (导出新 model)
- `[add]` crates/lazynote_core/tests/scoped_query_test.rs

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
# 验证 ScopedAtomQuery 类型存在
grep -rn "ScopedAtomQuery" crates/lazynote_core/src/ --include="*.rs"
# 预期：struct 定义 + 至少一处使用

# 验证 TaskService 委托到新查询
grep -rn "ScopedAtomQuery\|ScopedQueryRepository" crates/lazynote_core/src/service/task_service.rs
# 预期：至少 1 匹配
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| CTE 管线 SQL 复杂度高 | MEDIUM | 充分的四象限测试 + overdue 补偿测试 |
| 旧 TaskService/CalendarService 测试因路径改造失败 | LOW | 委托改造保持语义不变，旧测试全绿即回归通过 |

## Acceptance Criteria

- [ ] ScopedAtomQuery struct 和全套枚举定义完成
- [ ] ScopedQueryRepository CTE 管线可按子树范围查询 atoms
- [ ] time-matrix 四象限（T0/T1/T2/T3）正确过滤
- [ ] overdue T1 补偿逻辑正确
- [ ] scope 限定：只返回指定子树内的 atom
- [ ] 分页正确：limit/offset 参数按预期截断结果集
- [ ] 去重正确：同一 atom 在子树中有多个 atom_ref 时查询结果不重复
- [ ] 契约真值表：`ProjectionMode x include_path` 非法组合返回 `invalid_query_descriptor` 错误
- [ ] 契约真值表：`include_overdue_deadlines x time_filter` 非法组合返回 `invalid_query_descriptor` 错误
- [ ] TaskService `list_inbox`/`list_today`/`list_upcoming` 委托到 ScopedAtomQuery
- [ ] 现有 TaskService/CalendarService 测试全绿（语义不变回归）
- [ ] `cargo test --all` 全绿
- [ ] `cargo clippy --all -- -D warnings` 零 warning
- [ ] PR spec Status updated to Merged
