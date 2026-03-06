# PR-4: AccessGuard 体系 + FFI 新增（Expand 阶段）

- Proposed title: `feat(ffi): access guard architecture and new guarded FFI functions`
- Status: Draft

## Goal

引入 CallerContext + AccessGuard 体系，包装全套 Guarded*Service，新增 FFI 函数（`query_atoms`、`atom_create`、`workspace_resolve_designated` 等）。旧 FFI 保留为薄 wrapper（expand-contract 的 expand 阶段），保证 Flutter 侧编译通过。

前置条件：PR-2 + PR-3（需要 ScopedQueryRepository + CreationService + TreeService 增强）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-16-rust-service-ffi-contract.md` Q5-Q6 | Guard 设计、FFI 函数清单、expand-contract 策略 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` Q1（PR-4 行）、Q2（expand-contract）、Q4（FFI 测试 + DenyGuard） | PR 定位、迁移策略、测试要求 |
| 规范源 | `docs/api/ffi-contracts.md` | 需更新：新增 FFI 函数契约 |
| 规范源 | `docs/governance/API_COMPATIBILITY.md` | 需更新：breaking change 记录 |
| 现有实现 | `crates/lazynote_ffi/src/api.rs` | 需修改的目标文件 |

## Scope

In scope:
- CallerContext struct
- AccessGuard trait + NoopGuard 默认实现
- Guarded*Service 全套包装
- FFI 新函数：`query_atoms`、`atom_create`、`workspace_resolve_designated`、`workspace_reassign_designated` 等
- 旧 FFI 函数改为薄 wrapper（内部委托到 Guarded*Service）
- FRB 绑定重生成
- DenyGuard 测试专用实现
- 更新 `docs/api/ffi-contracts.md`（新函数）
- 更新 `docs/governance/API_COMPATIBILITY.md`（breaking change 记录）
- 更新 `docs/api/error-codes.md`（新增 Guard 相关错误码，DI-16 要求）

Out of scope:
- 旧 FFI 函数移除（PR-6 contract 阶段）
- Flutter 消费方变更（PR-5/6）

## Design

TBD — kickoff 阶段细化。参考 DI-16 Q5-Q6。

**Expand-Contract 机制**：本 PR 是 expand 阶段——新增新接口，旧接口函数体替换为薄 wrapper（一次委托调用到 Guarded*Service），函数签名保留。PR-6 执行 contract（移除旧接口）。

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Rust | CallerContext + AccessGuard trait + NoopGuard | `crates/lazynote_core/src/` | TBD | — |
| T2 | Rust | Guarded*Service 全套包装 | `crates/lazynote_core/src/service/` | TBD | T1 |
| T3 | FFI | FFI 新函数导出 | `crates/lazynote_ffi/src/api.rs` | TBD | T2 |
| T4 | FFI | 旧 FFI 改为薄 wrapper | `crates/lazynote_ffi/src/api.rs` | TBD | T2 |
| T5 | FFI | FRB 绑定重生成 | `scripts/gen_bindings.ps1` | TBD | T3-T4 |
| T6 | Rust | 新函数测试 + 旧函数回归测试 | `crates/lazynote_core/tests/` | TBD | T3 |
| T7 | Rust | DenyGuard 边界测试 | `crates/lazynote_core/tests/` | TBD | T2-T3 |
| T8 | Docs | 更新 ffi-contracts.md + API_COMPATIBILITY.md + error-codes.md | `docs/api/`, `docs/governance/` | TBD | T3 |

## Planned File Changes

- `[add]` crates/lazynote_core/src/guard/ (CallerContext, AccessGuard trait, NoopGuard)
- `[add]` crates/lazynote_core/src/service/guarded_*.rs (Guarded*Service 包装)
- `[edit]` crates/lazynote_ffi/src/api.rs (新 FFI 函数 + 旧 FFI 改 wrapper)
- `[regen]` crates/lazynote_ffi/src/frb_generated.rs (FRB 自动生成)
- `[regen]` apps/lazynote_flutter/lib/core/bindings/ (FRB 自动生成)
- `[edit]` docs/api/ffi-contracts.md (新函数契约)
- `[edit]` docs/governance/API_COMPATIBILITY.md (breaking change 记录)
- `[edit]` docs/api/error-codes.md (新增 Guard 相关错误码)
- `[add]` crates/lazynote_core/tests/guard_test.rs (DenyGuard 测试)

## Verification

### CI gates

```bash
cd crates/
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all

cd ../apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

### Structural verification

```bash
# 验证旧 FFI 函数已改为薄 wrapper（只有一次委托调用）
# Review checklist：每个旧函数内部只有一次 Guarded*Service 委托调用

# 验证新 FFI 函数存在
grep -rn "query_atoms\|atom_create\|workspace_resolve_designated" crates/lazynote_ffi/src/api.rs
# 预期：至少 3 匹配

# 验证 DenyGuard 测试存在
grep -rn "DenyGuard\|deny_guard" crates/lazynote_core/tests/ --include="*.rs"
# 预期：至少 1 匹配
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| FRB 重生成后 Flutter 编译失败 | MEDIUM | 旧 FFI 签名保留，Flutter 不需要立即适配 |
| Guard 架构引入过多 boilerplate | LOW | NoopGuard 为默认实现，Guarded*Service 是机械包装 |
| 旧函数 wrapper 内部逻辑遗留 | LOW | Review checklist + A+ R1 规则验证 |

## Acceptance Criteria

- [ ] CallerContext struct 定义完成
- [ ] AccessGuard trait 定义完成
- [ ] NoopGuard 默认实现
- [ ] Guarded*Service 全套包装正确委托到底层 Service
- [ ] FFI 新函数（`query_atoms`、`atom_create`、`workspace_resolve_designated`、`workspace_reassign_designated` 等）可调用
- [ ] 旧 FFI 函数改为薄 wrapper（内部仅一次 Guarded*Service 委托）
- [ ] DenyGuard 测试通过：拒绝路径返回预期错误
- [ ] DenyGuard 测试通过：错误码映射正确（如 `access_denied`）
- [ ] 旧 FFI 函数行为不变（现有测试全绿）
- [ ] FRB 绑定重生成后 `flutter analyze` 零 warning
- [ ] `docs/api/ffi-contracts.md` 已更新新函数契约
- [ ] `docs/governance/API_COMPATIBILITY.md` 已记录 breaking change
- [ ] `docs/api/error-codes.md` 已注册新增错误码（如 `access_denied`、`invalid_query_descriptor`）
- [ ] `cargo test --all` 全绿
- [ ] `cargo clippy --all -- -D warnings` 零 warning
- [ ] PR spec Status updated to Merged
