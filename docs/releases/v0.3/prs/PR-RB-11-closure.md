# PR-RB-11: 收口与发布门

- Proposed title: `chore(release): PR-RB-11 v0.3 closure — cleanup, regression tests, doc sync, release evidence`
- Status: Draft

## Goal

v0.3 最终收口 PR。在所有 must-have PR（PR-RB-00 ~ PR-RB-10）完成后执行。四项职责：

1. **旧 manager 清理**：删除被 PR-RB-06+ 提取取代的旧代码残余
2. **回归测试补齐**：确保 v0.3 新增基础设施有充分测试覆盖
3. **架构与 API 文档同步**：所有 docs 反映 v0.3 实际代码状态
4. **Release evidence 收集**：执行 Release Gate，记录覆盖矩阵完成状态

前置条件：全部 must-have PR（PR-RB-00 ~ PR-RB-10）已合入

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| Rebaseline | `v0.3-pr-spec-rebaseline-2026-03-01.md` §4 PR-RB-11 + §5 Gates + §6 覆盖矩阵 | 收口范围 + 发布门标准 + 覆盖验证 |
| Ruling | S1~S9 全部 | 标注实施状态 |
| DI | DI-0~DI-5, DI-10 | 标注实施状态 |
| Engineering Standards | `engineering-standards.md` Rule A~F | 合规校验 |

## 设计方案

### Lane A: 旧 Manager 清理

PR-RB-06 将 NoteTabStateManager / NoteDraftManager / NoteSaveTracker 提取到 `lib/core/editor/`。PR-RB-05 将 WorkspaceTreeManager 提取到 `lib/core/workspace/`。PR-RB-11 清理残余：

| 检查项 | 动作 |
|--------|------|
| `notes_coordinator_impl.dart` 中对旧 manager 的残留引用 | 删除死代码、无用 import |
| 旧 manager 文件是否仍存在于 `features/notes/managers/` | 确认 PR-RB-06 已删除 `note_tab_manager.dart`（含类 NoteTabStateManager）/ `note_draft_manager.dart` / `note_save_tracker.dart`；若残留则删除 |
| `WorkspaceProvider` 中被 GroupLayout 取代的布局逻辑 | 确认 PR-RB-06 已迁移；清理残留 |
| 测试文件中对已删除 manager 的引用 | 更新或删除相关测试 |
| 旧 PR-030X spec 文件 | 已由 `_SUPERSEDED.md` 标注失效，不删除 |

**预期影响**：净删除 ~50-100 行残留代码（若前序 PR 清理彻底则可能为 0）。

### Lane B: 回归测试补齐

评估前序 PR 测试覆盖缺口，补齐关键路径测试。

| 测试领域 | 关键路径 | 预期由前 PR 覆盖 | PR-RB-11 补齐 |
|----------|---------|------------------|--------------|
| EditBuffer 状态机 | loading→ready→error→disposing 转换 | PR-RB-08 T7/T8 | 边界用例：concurrent edit、ref counting |
| GroupLayout 不变式 | I1-I7（max 8 pane、primary 不消失等） | PR-RB-06 T12/T13 | 压力测试：快速 split/close 序列 |
| Layout 持久化 | save→corrupt→recover 完整链路 | PR-RB-07 T4/T5 | 补充：schema 版本不匹配回退 |
| EditorResolver | register/resolve/unknown placeholder | PR-RB-09 T6/T7 | 覆盖已足够，PR-RB-11 不额外补 |
| Atom ref 语义 | 创建 → atom_ref 自动生成 | PR-RB-03 T12-T14 | 补充：多 entry point 一致性验证 |
| Tag results panel | 面板展开/收起/面包屑 | PR-RB-10 T7-T9 | 覆盖已足够，PR-RB-11 不额外补 |
| Cross-pane sync | 同一 Atom 两 pane 编辑 | PR-RB-08 T9/T10 | 补充：三 pane 同时编辑同一 Atom |
| Reminder lifecycle | 创建/修改/完成/删除触发 | PR-RB-04 T8-T12 | 补充：启动恢复在空数据库时 |

**预期新增**：5-8 个测试用例，~150-250 行测试代码。

### Lane C: 架构与 API 文档同步

| 文档 | 需要同步的内容 |
|------|---------------|
| `CLAUDE.md` | 更新 Project Snapshot 中 status 描述 + 新增 `lib/core/editor/` 和 `lib/core/workspace/` 模块描述 + 更新 Flutter State Management 章节反映 EditorShellService 架构 |
| `docs/architecture/overview.md` | 更新架构图和模块列表，反映 `core/editor/` + `core/workspace/` 新增 |
| `docs/architecture/data-model.md` | 确认 migration 10/11 的 `title`/`content_type`/`view_hint`/`atom_ref` 变更已记录 |
| `docs/api/ffi-contracts.md` | 确认 NoteItem→AtomListItem 迁移、新增 FFI 函数（`atoms_list_timed` 等）已记录 |
| `docs/architecture/engineering-standards.md` | 确认 Rule E `lib/core/` 豁免已明确 |
| Rulings `S1~S9` | 更新实施状态表 |
| DI `README.md` | 确认 DI-0~DI-5、DI-10 标注为 RESOLVED + implemented |

### Lane E: Gate 验证脚本提取（SSOT）

**动机**：Gate A 的 grep 模式在 PR-RB-04 和 PR-RB-11 中重复定义，Spec Review R2 时两处都需要修改（Issue 7）。遵循 SSOT（单一事实来源）原则，将 Gate 验证逻辑提取为可执行脚本，PR spec 只声明"运行 XX 脚本"。

**`tools/ci/gate_checks.dart`**（新文件，~80-100 行）：

```dart
/// Gate verification script for v0.3 release.
/// Usage: dart run ../../tools/ci/gate_checks.dart [--gate-a] [--gate-b] [--all]

// Gate A: 语义与契约验证
// - NoteItem 零引用（生成绑定除外）
// - 创建入口 atom_ref 可观察
// - tasks/calendar 零 reminder 直接引用（import 级静态检查）
// - entry 零 ExtensionRegistry 引用（S5 合规）

// Gate B: 编辑器基础设施验证
// - EditorShellService 测试存在且通过
// - EditBuffer cross-pane 测试存在且通过
// - GroupLayout 不变式测试存在且通过
// - Layout persistence round-trip 测试存在且通过
```

**好处**：
1. 验证逻辑活在代码里——可测试、可版本控制
2. CI 直接跑 `dart run ../../tools/ci/gate_checks.dart --all`
3. 改一处，PR-RB-04/PR-RB-11/DI-7 所有引用处自动生效
4. 未来 v0.4 可扩展 Gate C 等新门

**注意**：Gate A/B 的检查模式由 DI-7 和 rebaseline §5 定义，脚本是这些规则的可执行实现，不新增规则。

---

### Lane D: Release Evidence 收集

#### Gate A 验证（语义与契约，§5.1）

```bash
# 手写业务代码不再引用 NoteItem（生成绑定除外）
rg "NoteItem" apps/lazynote_flutter/lib/ --glob '!**/bindings/**' --glob '!**/frb_generated*'
# 期望：0 匹配

# 所有创建入口可观察 atom_ref
rg "create_note\|create_task\|entry_schedule\|entry_create" crates/lazynote_ffi/src/api.rs
# 验证每个返回 response 包含 node_uuid

# Tasks/Calendar 不承担提醒调度入口（import 级静态检查，与 DI-7 一致）
rg "ReminderScheduler\|scheduleReminder\|reminder_scheduler\|reminder_service" apps/lazynote_flutter/lib/features/tasks/
rg "ReminderScheduler\|scheduleReminder\|reminder_scheduler\|reminder_service" apps/lazynote_flutter/lib/features/calendar/
# 期望：0 匹配（调度已移至 core/reminders/reminder_lifecycle.dart 中间层，controller 通过注入回调间接调用）
```

#### Gate B 验证（编辑器基础设施，§5.2）

| 里程碑 | 验证方式 |
|--------|---------|
| M1（PR-RB-06）：多 pane split/close/resize | `flutter test` 中 EditorShellService 测试全通过 |
| M2（PR-RB-08）：跨 pane 同步编辑 | `flutter test` 中 EditBuffer cross-pane 测试全通过 |
| DI-0 命名冲突 | `NoteTabStrip` + `EditorGroupModel` 命名已落地，无歧义 |
| DI-1/2 group 生命周期 | GroupLayout 不变式测试 I1-I7 全通过 |
| DI-3 布局恢复 | layout persistence round-trip 测试全通过 |
| DI-4/5 跨 pane 一致性 | `_rev` 防陈旧 + 光标独立测试全通过 |

#### Release Gate 执行（§5 Release Gate）

```bash
# Rust
cd crates/
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all

# Flutter
cd apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

**记录内容**：
- Rust 测试数量（基线 189 → v0.3 预期 ≥200）
- Flutter 测试数量（基线 333 → v0.3 预期 ≥380）
- architecture_check 输出：0 violations, N allowlisted
- 逐条 Gate A / Gate B 验证截图或文本日志

#### 覆盖矩阵签核（§6）

逐条确认 rebaseline §6 覆盖矩阵每一行：

| 矩阵 | 内容 |
|------|------|
| §6.1 Rulings | S1~S9 → 标注 PR 已合入 + 实施状态 |
| §6.2 Modules | 8 个 module spec → 对应 PR 已合入 |
| §6.3 DI | DI-0~DI-5 → 对应 PR 已合入 |

### S5 合规校验

S5 裁决：Extension Kernel ≠ Flutter command system。PR-RB-11 验证：

- `CommandParser`/`CommandRegistry`/`CommandRouter` 未调用 `ExtensionRegistry` API
- `ExtensionRegistry` 仅在 settings/capability UI 中引用
- 不做 runtime 激活（保持 landed 边界）

```bash
# CommandRouter 不引用 ExtensionRegistry
rg "ExtensionRegistry" apps/lazynote_flutter/lib/features/entry/
# 期望：0 匹配
```

## Task Breakdown

| Task | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|
| **Lane A: 清理** | | | | |
| T1 | 审查 `notes_coordinator_impl.dart` 残留旧 manager 引用 | coordinator 文件 | 审查 + 编辑 | — |
| T2 | 确认/删除旧 manager 文件残留 | `features/notes/managers/` | 审查 + 可能删除 | — |
| T3 | 确认/清理 WorkspaceProvider 残留布局逻辑 | `features/workspace/` | 审查 + 可能编辑 | — |
| T4 | 清理测试文件中对已删除 manager 的引用 | `test/` | 审查 + 编辑 | T1, T2 |
| **Lane B: 测试补齐** | | | | |
| T5 | EditBuffer 边界测试：concurrent edit + ref counting | `test/edit_buffer_edge_test.dart` | 新文件 ~60 行 | — |
| T6 | GroupLayout 压力测试：快速 split/close 序列 | `test/group_layout_stress_test.dart` | 新文件 ~50 行 | — |
| T7 | Layout 持久化：schema 版本不匹配回退 | 现有 persistence 测试 | 编辑 ~+30 行 | — |
| T8 | Atom ref 多入口一致性验证 | `test/atom_ref_consistency_test.dart` | 新文件 ~40 行 | — |
| T9 | Cross-pane 三 pane 同时编辑 | 现有 buffer sync 测试 | 编辑 ~+40 行 | — |
| T10 | Reminder 启动恢复空数据库 | 现有 reminder 测试 | 编辑 ~+20 行 | — |
| **Lane C: 文档同步** | | | | |
| T11 | 更新 `CLAUDE.md`：Project Snapshot + 模块描述 + State Management | `CLAUDE.md` | 编辑 ~+30 行 ~-20 行 | — |
| T12 | 更新 `overview.md`：架构图 + 模块列表 | `docs/architecture/overview.md` | 编辑 | — |
| T13 | 更新 `data-model.md`：migration 10/11 | `docs/architecture/data-model.md` | 编辑 | — |
| T14 | 更新 `ffi-contracts.md`：新增/变更的 FFI 函数 | `docs/api/ffi-contracts.md` | 编辑 | — |
| T15 | 更新 Rulings 实施状态（S1~S9） | `docs/architecture/rulings/` | 编辑 9 个文件 | — |
| T16 | 更新 DI README 实施状态 | `docs/reports/v0.3/design-discussions/README.md` | 编辑 | — |
| **Lane E: Gate 验证脚本提取** | | | | |
| T17 | 创建 `tools/ci/gate_checks.dart`：Gate A + Gate B 验证逻辑 | `tools/ci/gate_checks.dart` | 新文件 ~100 行 | — |
| T18 | 更新 PR-RB-04 / PR-RB-11 Verification 章节：inline grep → 引用 gate_checks.dart | PR spec 文件 | 编辑 | T17 |
| **Lane D: Release Evidence** | | | | |
| T19 | 执行 Gate A 验证（`dart run gate_checks.dart --gate-a`），记录结果 | release-evidence 文件 | 新文件 | T1-T16, T17 |
| T20 | 执行 Gate B 验证（`dart run gate_checks.dart --gate-b`），记录里程碑通过状态 | release-evidence 文件 | 编辑 | T19 |
| T21 | 执行 Release Gate（full CI），记录测试数量与结果 | release-evidence 文件 | 编辑 | T19 |
| T22 | 签核覆盖矩阵 §6.1 / §6.2 / §6.3 | release-evidence 文件 | 编辑 | T19 |
| T23 | S5 合规校验 | release-evidence 文件 | 编辑 | T19 |
| T24 | 编写 `v0.3-release-evidence.md` 最终报告 | `docs/releases/v0.3/v0.3-release-evidence.md` | 新文件 ~100 行 | T19-T23 |

## Planned File Changes

**Lane A（清理）：**
- `[edit?]` coordinator / manager / workspace 文件（取决于残留量）

**Lane B（测试）：**
- `[add]` `apps/lazynote_flutter/test/edit_buffer_edge_test.dart` (~60 行)
- `[add]` `apps/lazynote_flutter/test/group_layout_stress_test.dart` (~50 行)
- `[add]` `apps/lazynote_flutter/test/atom_ref_consistency_test.dart` (~40 行)
- `[edit]` 现有 persistence / buffer sync / reminder 测试文件 (~+90 行)

**Lane C（文档）：**
- `[edit]` `CLAUDE.md`
- `[edit]` `docs/architecture/overview.md`
- `[edit]` `docs/architecture/data-model.md`
- `[edit]` `docs/api/ffi-contracts.md`
- `[edit]` `docs/architecture/rulings/S1-atom-projection.md` ~ `S9-cross-feature-infrastructure-placement.md`（9 个文件）
- `[edit]` `docs/reports/v0.3/design-discussions/README.md`

**Lane E（Gate 脚本）：**
- `[add]` `tools/ci/gate_checks.dart` (~100 行)

**Lane D（Evidence）：**
- `[add]` `docs/releases/v0.3/v0.3-release-evidence.md` (~100 行)

## Verification

```bash
# 全量 CI — 即 Release Gate 本身
cd crates/
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all

cd apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

```bash
# Gate A spot checks
rg "NoteItem" apps/lazynote_flutter/lib/ --glob '!**/bindings/**' --glob '!**/frb_generated*' | wc -l
# 期望：0

rg "ExtensionRegistry" apps/lazynote_flutter/lib/features/entry/ | wc -l
# 期望：0

# Release evidence 文件存在
test -f docs/releases/v0.3/v0.3-release-evidence.md
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 前序 PR 清理不彻底导致 T1-T4 工作量超预期 | LOW | 每个前序 PR 已有明确的 Acceptance Criteria 和删除清单 |
| 文档同步遗漏 | LOW | 覆盖矩阵提供系统化检查清单 |
| 回归测试发现 v0.3 bug | MEDIUM | 及时修复，PR-RB-11 允许包含小修复；重大问题回退到对应 PR |

## Acceptance Criteria

- [ ] 无旧 manager 残留代码（NoteTabStateManager / NoteDraftManager / NoteSaveTracker 在 `features/notes/` 中不存在）
- [ ] 回归测试补齐：新增 ≥5 个测试用例覆盖边界场景
- [ ] `CLAUDE.md` + `overview.md` + `data-model.md` + `ffi-contracts.md` 已更新反映 v0.3 状态
- [ ] Rulings S1~S9 实施状态已标注
- [ ] DI-0~DI-5, DI-10 实施状态已标注
- [ ] `tools/ci/gate_checks.dart` 已创建，Gate A/B 验证逻辑为单一事实来源
- [ ] Gate A 全部通过（`dart run gate_checks.dart --gate-a` 零 violation）
- [ ] Gate B 全部通过（`dart run gate_checks.dart --gate-b` 零 violation）
- [ ] Release Gate 全部通过（Rust + Flutter CI green + architecture check pass）
- [ ] S5 合规校验通过
- [ ] `v0.3-release-evidence.md` 已撰写
