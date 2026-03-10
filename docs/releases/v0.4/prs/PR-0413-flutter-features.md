# PR-0413: Flutter Features 适配 + 旧 FFI 移除（Contract 阶段）

- Proposed title: `feat(features): tasks calendar migration and legacy FFI removal`
- Status: Draft

## Goal

全部 Flutter 消费方迁移到新接口（Tasks/Calendar/Notes/Tag Panel/Entry Search/Editor），Explorer 内部分层重构（DI-17 Q3），移除 synthetic uncategorized 逻辑，删除 `workspace_tree_children_loader.dart`，移除全部 15 个旧 FFI 函数（expand-contract 的 contract 阶段）。代码库净减。

前置条件：PR-0412（需要 WorkspaceTreeService B+ 已就位）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-17-flutter-thin-client.md` Q3/Q5-Q6 | 全部消费方适配、Explorer 内部分层、synthetic 移除 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-16-rust-service-ffi-contract.md` Q6 | 旧 FFI 清理清单 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` Q1（PR-0413 行）、Q2（A+ R2/R4 contract 规则）、Q4（清理验证 gate） | PR 定位、迁移策略、清理验证要求 |
| 附录 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` 附录 A | 15 个旧 FFI 函数完整清单 + 验证命令 |
| 规范源 | `docs/api/ffi-contracts.md` | 需更新：移除旧函数契约 |

## Scope

In scope:
- TasksController 迁移：mock WorkspaceTreeService + QueryAtomsInvoker
- CalendarController 迁移：query helper 适配
- **QueryAtomsInvoker** 封装 + **query helper**（`query_atoms` FFI 的 Dart 消费层入口，供全部 feature controller 使用）
- Notes/Tag Panel invoker 迁移（`notes_list` → `query_atoms` via QueryAtomsInvoker）（DI-16 Q6.1）
- Entry Search 迁移（`entry_search` → `query_atoms` via QueryAtomsInvoker）（DI-16 Q6.1）
- Editor/Resolver 迁移（`note_get` → `atom_get`）（DI-16 Q6.3）
- Explorer 内部分层：基础层/特化层拆分，禁止反向耦合（DI-17 Q3）
- synthetic uncategorized 全量删除（8 文件 48 处引用）
- 删除 `workspace_tree_children_loader.dart`
- 移除 15 个旧 FFI 函数（附录 A 完整清单）
- FRB 绑定重生成
- 旧 FFI 引用的测试代码同步迁移或删除
- 更新 `docs/api/ffi-contracts.md`（移除旧函数）
- 清理验证 gate（grep 零匹配、文件删除断言、uncategorized 清零）

Out of scope:
- Rust Core 层变更（PR-0408~0410 已完成）
- Guard/FFI 新增（PR-0411 已完成）
- WorkspaceTreeService 基础设施（PR-0412 已完成）

## Design

TBD — kickoff 阶段细化。

**Contract 阶段**：本 PR 是 expand-contract 的 contract 阶段。PR-0411 expand 阶段保留的旧 FFI 薄 wrapper，在本 PR 中全部移除。Flutter 消费方完成迁移后，旧接口不再有调用方。

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Dart | TasksController 迁移到新 invoker | `apps/lazynote_flutter/lib/features/tasks/` | TBD | — |
| T2 | Dart | CalendarController 迁移到新 invoker | `apps/lazynote_flutter/lib/features/calendar/` | TBD | — |
| T3 | Dart | Notes/Tag Panel invoker 迁移 | `apps/lazynote_flutter/lib/features/notes/` | TBD | — |
| T4 | Dart | Entry Search invoker 迁移 | `apps/lazynote_flutter/lib/features/entry/` | TBD | — |
| T5 | Dart | Editor/Resolver invoker 迁移 | `apps/lazynote_flutter/lib/core/editor/` | TBD | — |
| T6 | Dart | Explorer 内部分层（基础层/特化层） | `apps/lazynote_flutter/lib/features/notes/` | TBD | — |
| T7 | Dart | synthetic uncategorized 全量删除 | 8 文件 | TBD | — |
| T8 | Dart | 删除 workspace_tree_children_loader.dart | `apps/lazynote_flutter/lib/core/workspace/` | TBD | — |
| T9 | FFI | 移除 15 个旧 FFI 函数 | `crates/lazynote_ffi/src/api.rs` | TBD | T1-T5 |
| T10 | FFI | FRB 绑定重生成 | `scripts/gen_bindings.ps1` | TBD | T9 |
| T11 | Dart | 测试更新（controller mock + 负向测试） | `apps/lazynote_flutter/test/` | TBD | T1-T8 |
| T12 | Dart | 清理验证 gate 执行 | — | TBD | T1-T10 |
| T13 | Docs | 更新 ffi-contracts.md（移除旧函数） | `docs/api/ffi-contracts.md` | TBD | T9 |

## Planned File Changes

- `[edit]` apps/lazynote_flutter/lib/features/tasks/ (controller 迁移)
- `[edit]` apps/lazynote_flutter/lib/features/calendar/ (controller 迁移)
- `[edit]` apps/lazynote_flutter/lib/features/notes/ (Tag Panel invoker 迁移 + Explorer 内部分层)
- `[edit]` apps/lazynote_flutter/lib/features/entry/ (Entry Search invoker 迁移)
- `[edit]` apps/lazynote_flutter/lib/core/editor/ (Editor/Resolver invoker 迁移)
- `[edit]` 8 files (synthetic uncategorized 引用清除)
- `[delete]` apps/lazynote_flutter/lib/core/workspace/workspace_tree_children_loader.dart
- `[edit]` crates/lazynote_ffi/src/api.rs (移除 15 个旧函数)
- `[regen]` crates/lazynote_ffi/src/frb_generated.rs (FRB 自动生成)
- `[regen]` apps/lazynote_flutter/lib/core/bindings/ (FRB 自动生成)
- `[edit]` docs/api/ffi-contracts.md (移除旧函数契约)
- `[edit]` apps/lazynote_flutter/test/ (测试迁移/更新)

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

### Structural verification（清理验证 gate）

```bash
# 旧 FFI 函数名零匹配（附录 A 完整清单）
grep -rn "tasks_list_inbox\|tasks_list_today\|tasks_list_upcoming\|calendar_list_by_range\|notes_list\|entry_search\|atoms_list_timed\|entry_create_note\|entry_create_task\|entry_schedule\|note_create\|note_update\|note_set_tags\|calendar_update_event\|note_get" crates/ apps/ --include="*.rs" --include="*.dart"
# 预期：零匹配

# 删除文件验证
test ! -f apps/lazynote_flutter/lib/core/workspace/workspace_tree_children_loader.dart
# 预期：文件不存在

# uncategorized 清零
grep -rn "uncategorized\|synthetic" apps/ --include="*.dart" | grep -v "test" | grep -v "//"
# 预期：零匹配（排除测试文件和注释）
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 遗漏旧 FFI 引用导致编译失败 | MEDIUM | 清理验证 gate grep 零匹配 + `flutter analyze` |
| synthetic uncategorized 引用散布在非预期位置 | LOW | grep 全量扫描 + 48 处已在 DI-17 中识别 |
| FRB 重生成后类型不匹配 | MEDIUM | `flutter analyze` + `flutter test` 全覆盖 |

## Acceptance Criteria

- [ ] QueryAtomsInvoker 封装完成，作为 `query_atoms` FFI 的统一 Dart 消费入口
- [ ] TasksController 使用 WorkspaceTreeService + QueryAtomsInvoker 加载 section 数据
- [ ] CalendarController 使用新 query 接口
- [ ] Notes/Tag Panel 已迁移到 `query_atoms`（不再调用 `notes_list`）
- [ ] Entry Search 已迁移到 `query_atoms`（不再调用 `entry_search`）
- [ ] Editor/Resolver 已迁移到 `atom_get`（不再调用 `note_get`）
- [ ] Explorer 已拆分为基础层/特化层，无反向耦合（DI-17 Q3）
- [ ] synthetic uncategorized 逻辑不存在（负向测试：确认无 BFS 合成）
- [ ] `workspace_tree_children_loader.dart` 已删除
- [ ] 15 个旧 FFI 函数已从 `api.rs` 移除
- [ ] 清理验证：旧 FFI 函数名在代码文件（`.rs` + `.dart`）中零匹配
- [ ] 清理验证：uncategorized/synthetic 标识符在代码文件中零匹配
- [ ] FRB 绑定重生成后 `flutter analyze` 零 warning
- [ ] `docs/api/ffi-contracts.md` 已移除旧函数契约
- [ ] `cargo test --all` 全绿
- [ ] `flutter test` 全绿
- [ ] `cargo clippy --all -- -D warnings` 零 warning
- [ ] PR spec Status updated to Merged
