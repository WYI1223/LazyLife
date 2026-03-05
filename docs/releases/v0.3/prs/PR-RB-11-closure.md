# PR-RB-11: 收口与发布门

- Proposed title: `chore(release): PR-RB-11 v0.3 closure — regression tests, doc sync, release evidence`
- Status: Ready for Implementation

## Goal

v0.3 最终收口 PR。在所有 must-have PR（PR-RB-00 ~ PR-RB-10）完成后执行。三项职责：

1. **回归测试补齐**：填补 v0.3 新增基础设施的测试覆盖缺口
2. **架构与 API 文档同步**：所有 docs 反映 v0.3 实际代码状态
3. **Release evidence 收集**：执行 Release Gate，记录覆盖矩阵完成状态

前置条件：全部 must-have PR（PR-RB-00 ~ PR-RB-10）已合入 ✓（2026-03-04 确认）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| Rebaseline | `v0.3-pr-spec-rebaseline-2026-03-01.md` §4 PR-RB-11 + §5 Gates + §6 覆盖矩阵 | 收口范围 + 发布门标准 + 覆盖验证 |
| Ruling | S1~S9 全部 | 标注实施状态 |
| DI | DI-0~DI-5, DI-10~DI-12 | 标注实施状态；DI-11/DI-12 以 v0.4 planning addendum 口径回填。DI-13 保持 PENDING（Q1-Q3 未裁决），DI-14 保持 PENDING（v0.4 概念母题，Q0-Q2 已裁决但整体未完结） |
| Temporary Checklist | `docs/releases/v0.3/v0.3-rulings-modules-checklist-temp-2026-03-01.md` | DI-11/DI-12 相关守则同步的 SSOT 检查清单 |
| Engineering Standards | `engineering-standards.md` Rule A~F | 合规校验 |

---

## Pre-Implementation Audit（2026-03-04）

在 PR-RB-00~PR-RB-10 全部合入后，对代码库和文档进行了系统性审计。审计结果直接影响本 PR 的设计方案和任务分解。

### Audit A: 旧 Manager 残留 → **CLEAN**

| 检查项 | 结果 |
|--------|------|
| `NoteTabStateManager` / `NoteDraftManager` / `NoteSaveTracker` 文件 | PR-RB-06 已全部删除 |
| `WorkspaceProvider` 文件 | PR-RB-06 已删除 |
| 旧类名在 `lib/` 和 `test/` 中的引用 | **0 处活跃引用**（仅 3 处历史设计注释，保留得当） |
| `notes_coordinator_impl.dart` 死代码/无用 import | 0 处 |
| `features/notes/managers/` 目录 | 仅存 `note_list_manager.dart`、`note_tag_manager.dart`（活跃模块） |

**结论**：Lane A（旧 Manager 清理）工作量为 0。前序 PR 清理彻底，无需代码变更。Lane A 降级为 verification-only 任务，不产出代码 diff。

### Audit B: 测试覆盖缺口

| 测试领域 | 现有测试 | 现状 | PR-RB-11 动作 |
|----------|---------|------|--------------|
| **GroupLayout 不变式** | **0 个专门测试** | **关键缺口**。GroupLayout 仅在 `layout_persistence_test.dart` 和 `editor_shell_service_test.dart` 中被间接使用，无 split/close/nesting/traversal 专项测试 | **新建 `group_layout_test.dart`**，覆盖 split、close、allGroupIds、深层嵌套、快速 split/close 序列 |
| EditBuffer 状态机 | 14 个测试（`edit_buffer_test.dart`） | 覆盖 phase 转换、跨 pane 同步、save 语义、性能守卫。缺少：多 pane 并发 edit（同帧） | 追加 concurrent edit 边界用例 |
| Layout 持久化 | 20 个测试（`layout_persistence_test.dart`） | 已覆盖 schema 版本不匹配（scenario 3: version > current → skipOverwrite）、损坏恢复、atomic write。**原 spec T7 已被前序 PR 覆盖** | ~~T7 移除~~；可选补充 I/O 故障场景 |
| EditorResolver | 5 个测试（`editor_resolver_test.dart`） | 基础覆盖充分（register/override/unknown placeholder） | 不补齐 |
| Atom ref 语义 | 通过 workspace 集成测试间接覆盖 | 缺少多 entry point（note_create / entry_create_note / entry_create_task）创建后 atom_ref 一致性的直接验证 | 新建 `atom_ref_consistency_test.dart` |
| Cross-pane sync | 13 个测试（edit_buffer + editor_shell_service + workspace_split） | 2-pane 场景充分。**缺少 3-pane 同时编辑同一 Atom** | 追加三 pane 测试 |
| Tag results panel | 10 个测试（widget + integration） | 覆盖充分 | 不补齐 |
| Reminder lifecycle | 28 个测试（lifecycle + scheduler） | **空数据库启动恢复已有测试**（`handles empty timed atom list gracefully`）。**原 spec T10 已被前序 PR 覆盖** | ~~T10 移除~~ |

**结论**：GroupLayout 零测试是最大缺口。EditBuffer concurrent + 三 pane cross-pane + atom ref 一致性是次要缺口。Layout persistence schema mismatch 和 reminder empty DB 已由前序 PR 覆盖，从 spec 移除。

### Audit C: 文档同步差距

| 文档 | 现状 | PR-RB-11 动作 |
|------|------|--------------|
| `CLAUDE.md` | **已更新**。Project Snapshot、Flutter State Management、core/editor/、core/workspace/ 均已反映 v0.3 | verification-only（确认无遗漏） |
| `docs/architecture/overview.md` | 基本完整。**小缺口**：migration 计数仍为 "9" 应为 "11" | 修正 migration 计数 |
| `docs/architecture/data-model.md` | **已完整**。migration 10/11、title/content_type/view_hint/atom_ref 均已记录 | verification-only |
| `docs/api/ffi-contracts.md` | **缺失 `workspace_ancestor_path`**（函数存在于 api.rs:1101，PR-RB-10 新增，未同步到文档） | 补充 `workspace_ancestor_path` 条目 |
| `docs/architecture/engineering-standards.md` | Rule E `lib/core/` 豁免已明确 | verification-only |
| Rulings S1~S9 | 各文件均有状态字段。S1/S4 已包含 v0.4 addendum。需确认所有 v0.3 实施状态标记一致 | 实施状态扫描 + 标注 |
| DI README | DI-0~DI-7, DI-10~DI-12, DI-15, DI-19 已标 RESOLVED。DI-8/DI-9 DEFERRED。DI-13 PENDING（Q1-Q3 未裁决，正确）。DI-14 PENDING（v0.4 概念母题，正确）。DI-16 IN PROGRESS。DI-17/DI-18 PENDING（v0.4 规划，正确） | verification-only（状态正确，无需变更） |
| Temp Checklist | RC-06、RC-07、MC-03 未勾选。§6（PR-RB-11 挂接）全部未勾选 | 逐项执行并闭合 |

### Audit D: 跨 PR 延期项

审计 PR-RB-00~PR-RB-10 全部 spec，共识别 15 项显式延期至 v0.4 的内容。所有延期均有明确文档记录，无遗漏或隐性延期。关键项：

| 延期项 | 来源 | 文档状态 |
|--------|------|---------|
| S1 R9-R14（icon/cover/canvas/conversation） | PR-RB-02 Out of Scope | S1 ruling 明确标注 |
| S4 指定文件夹 UI / 多引用 UI / /Pending/ pool | PR-RB-03 Out of Scope | S4 ruling 明确标注 |
| S7 soft-delete 触发提醒取消 | PR-RB-04 Q2 | PR spec 明确延期到 v0.4 PR-0401 |
| DI-9 entry_search 参数重设计 | PR-RB-02 Out of Scope | DI-9 DEFERRED |
| S6 Google Calendar OAuth + 真实 runtime | Rebaseline §3.3 | PR-RB-12 Conditional Lane |
| S2 Phase 4+ EditOp types | PR-RB-06 code comment | v0.4+ 标注 |
| EditBuffer cursor persistence | PR-RB-07 Out of Scope | 文档标注 |
| Unknown content_type 页面集成测试 | PR-RB-09 | 延期到非 markdown 类型引入时 |
| DI-12/14/15/16/17/18 workspace 拓扑演进 | v0.4 planning DIs | 已产出执行计划 |

**结论**：v0.3/v0.4 边界清晰，PR-RB-11 仅需在 release evidence 中汇总延期清单，无需额外处理。

---

## 设计方案

### Lane A: 旧 Manager 清理 → 降级为 Verification-Only

**审计结果**：前序 PR 清理彻底。NoteTabStateManager / NoteDraftManager / NoteSaveTracker / WorkspaceProvider 在 `lib/` 和 `test/` 中零活跃引用，无死代码、无无用 import。

**动作**：仅执行确认性审查（`rg` 搜索 + 结果记录），不产出代码 diff。结果记入 release evidence。

### Lane B: 回归测试补齐

基于 Audit B 的精确缺口分析，PR-RB-11 补齐以下测试：

| 测试领域 | 文件 | 新增测试数 | 覆盖内容 |
|----------|------|-----------|---------|
| **GroupLayout 不变式**（关键缺口） | `test/group_layout_test.dart`（新建） | ~10 个 | split 正确性（axis、fraction、ID 生成）、close 级联、allGroupIds 遍历、深层嵌套（4+ pane）、快速 split/close 序列、边界：关闭不存在的 groupId、最后一个 pane 不消失（I1） |
| EditBuffer concurrent edit | `test/edit_buffer_test.dart`（追加） | 1-2 个 | 同帧多 pane 并发 edit()、Future.wait 竞态 |
| Cross-pane 三 pane | `test/editor_shell_service_test.dart`（追加） | 1-2 个 | 3 pane 同时编辑同一 Atom、监听器通知确认 |
| Atom ref 多入口一致性 | `test/atom_ref_consistency_test.dart`（新建） | 2-3 个 | note_create / entry_create_note / entry_create_task 创建后 atom_ref 存在性验证 |

**预期新增**：15-17 个测试用例，~200-250 行测试代码。

**已从原 spec 移除的测试**（审计确认前序 PR 已覆盖）：
- ~~Layout persistence schema 版本不匹配~~（`layout_persistence_test.dart` scenario 3 已覆盖）
- ~~Reminder 启动恢复空数据库~~（`reminder_lifecycle_test.dart:417` `handles empty timed atom list gracefully` 已覆盖）

### Lane C: 架构与 API 文档同步

基于 Audit C 的精确差距分析，分为"需变更"和"仅验证"两类：

**需变更：**

| 文档 | 变更内容 |
|------|---------|
| `docs/architecture/overview.md` | migration 计数 "9" → "11" |
| `docs/api/ffi-contracts.md` | 补充 `workspace_ancestor_path(atom_id)` → `WorkspaceAncestorPathResponse` 条目（PR-RB-10 新增函数） |
| Rulings S1~S9 | v0.3 实施状态标注扫描。重点：S2（Phase 2/3 落地）、S3（Phase A 落地）、S9（core/editor/ + core/workspace/ 抽取落地） |
| Temp Checklist | 执行 RC-06（S3 与 DI-12 无冲突确认）、RC-07（S9 workspace 描述一致性确认）、MC-03（reminder scheduler 一致性确认）。完成 §6 PR-RB-11 挂接项 |

**仅验证（审计已确认完整，无需变更）：**

| 文档 | 验证结论 |
|------|---------|
| `CLAUDE.md` | Project Snapshot + State Management + core/editor/ + core/workspace/ 均已反映 v0.3 ✓ |
| `docs/architecture/data-model.md` | migration 10/11、title/content_type/view_hint/atom_ref 已记录 ✓ |
| `docs/architecture/engineering-standards.md` | Rule E `lib/core/` 豁免已明确 ✓ |
| DI README | DI-0~DI-12 状态正确。DI-13 保持 PENDING（Q1-Q3 未裁决），DI-14 保持 PENDING（v0.4 概念母题）✓ |

### Lane E: Gate 验证脚本提取（SSOT）

**动机**：Gate A 的 grep 模式在 PR-RB-04 和 PR-RB-11 中重复定义。遵循 SSOT 原则，将 Gate 验证逻辑提取为可执行脚本。

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

### Lane D: Release Evidence 收集

#### Gate A 验证（语义与契约，Rebaseline §5.1）

```bash
# 手写业务代码不再引用 NoteItem（生成绑定除外）
rg "NoteItem" apps/lazynote_flutter/lib/ --glob '!**/bindings/**' --glob '!**/frb_generated*'
# 期望：0 匹配

# 所有创建入口可观察 atom_ref — 多层断言
# Rust 集成测试（note_create 路径）：
# - note_create_with_parent_places_atom_ref_under_folder (api.rs:2281)
# - note_create_without_parent_places_atom_ref_at_root (api.rs:2326)
# Flutter 测试（entry_create_note / entry_create_task / entry_schedule 路径）：
# - atom_ref_consistency_test.dart (T5 新建，覆盖全部 entry 入口)
# gate_checks.dart --gate-a 自动检查上述测试存在性

# Tasks/Calendar 不承担提醒调度入口（import 级静态检查）
rg "ReminderScheduler|scheduleReminder|reminder_scheduler|reminder_service" apps/lazynote_flutter/lib/features/tasks/
rg "ReminderScheduler|scheduleReminder|reminder_scheduler|reminder_service" apps/lazynote_flutter/lib/features/calendar/
# 期望：0 匹配

# S5：CommandRouter 不引用 ExtensionRegistry
rg "ExtensionRegistry" apps/lazynote_flutter/lib/features/entry/
# 期望：0 匹配
```

#### Gate B 验证（编辑器基础设施，Rebaseline §5.2）

| 里程碑 | 验证方式 |
|--------|---------|
| M1（PR-RB-06）：多 pane split/close/resize | `flutter test` 中 EditorShellService 测试全通过 |
| M2（PR-RB-08）：跨 pane 同步编辑 | `flutter test` 中 EditBuffer cross-pane 测试全通过 |
| DI-0 命名冲突 | `NoteTabStrip` + `EditorGroupModel` 命名已落地，无歧义 |
| DI-1/2 group 生命周期 | GroupLayout 不变式测试全通过 |
| DI-3 布局恢复 | layout persistence round-trip 测试全通过 |
| DI-4/5 跨 pane 一致性 | `_rev` 防陈旧 + 光标独立测试全通过 |

#### Release Gate 执行（Rebaseline §5 Release Gate）

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
- Rust 测试数量（基线 189；v0.3 实际值由执行时记录，需无回退）
- Flutter 测试数量（基线 333；v0.3 实际值由执行时记录，需无回退）
- architecture_check 输出
- `gate_checks.dart --all` 输出
- 逐条 Gate A / Gate B 验证结果

#### 覆盖矩阵签核（Rebaseline §6）

| 矩阵 | 内容 |
|------|------|
| §6.1 Rulings | S1~S9 → 标注 PR 已合入 + 实施状态 |
| §6.2 Modules | 8 个 module spec → 对应 PR 已合入 |
| §6.3 DI | DI-0~DI-5 → 对应 PR 已合入 |

#### v0.4 延期项汇总

将 Audit D 识别的 15 项显式延期清单纳入 release evidence，建立 v0.3→v0.4 交接记录。

---

## Task Breakdown

| Task | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|
| **Lane A: 验证（无代码变更）** | | | | |
| T1 | 执行旧 manager 残留搜索，记录零结果 | `rg` 输出 → release evidence | 审查 only | — |
| **Lane B: 测试补齐** | | | | |
| T2 | GroupLayout 不变式测试（关键缺口） | `test/group_layout_test.dart`（新建） | 新文件 ~120 行，~10 个测试 | — |
| T3 | EditBuffer concurrent edit 边界 | `test/edit_buffer_test.dart`（追加） | ~+30 行，1-2 个测试 | — |
| T4 | Cross-pane 三 pane 同时编辑 | `test/editor_shell_service_test.dart`（追加） | ~+40 行，1-2 个测试 | — |
| T5 | Atom ref 多入口一致性验证 | `test/atom_ref_consistency_test.dart`（新建） | 新文件 ~60 行，2-3 个测试 | — |
| **Lane C: 文档同步** | | | | |
| T6 | `overview.md`：migration 计数修正 | `docs/architecture/overview.md` | 1 行编辑 | — |
| T7 | `ffi-contracts.md`：补充 `workspace_ancestor_path` | `docs/api/ffi-contracts.md` | ~+15 行 | — |
| T8 | Rulings S1~S9 实施状态扫描与标注 | `docs/architecture/rulings/`（9 个文件） | 审查 + 编辑 | — |
| T9 | DI README：验证 DI-0~DI-12 状态正确（DI-13/DI-14 保持 PENDING，无需变更） | `docs/reports/v0.3/design-discussions/README.md` | 审查 only | — |
| T10 | 临时守则清单：执行 RC-06/RC-07/MC-03 + §6 挂接 | `v0.3-rulings-modules-checklist-temp-2026-03-01.md` | 审查 + 勾检 | T8, T9 |
| T11 | 验证 `CLAUDE.md` / `data-model.md` / `engineering-standards.md` 无遗漏 | 各文件 | 审查 only | — |
| **Lane E: Gate 验证脚本** | | | | |
| T12 | 创建 `tools/ci/gate_checks.dart` 并集成到 CI workflow | `tools/ci/gate_checks.dart`（新建）+ `.github/workflows/` CI 配置确认 | 新文件 ~100 行 + CI 验证 | — |
| **Lane D: Release Evidence** | | | | |
| T13 | 执行 Gate A + 记录结果 | release-evidence 文件 | 执行 + 记录 | T1, T12 |
| T14 | 执行 Gate B + 记录里程碑通过状态 | release-evidence 文件 | 执行 + 记录 | T2-T5, T12 |
| T15 | 执行 Release Gate（full CI）+ 记录测试数量 | release-evidence 文件 | 执行 + 记录 | T2-T5 |
| T16 | 签核覆盖矩阵 §6.1/§6.2/§6.3 | release-evidence 文件 | 审查 + 记录 | T8, T9 |
| T17 | v0.4 延期项汇总 | release-evidence 文件 | 编写 | — |
| T18 | 编写 `v0.3-release-evidence.md` 最终报告 | `docs/releases/v0.3/v0.3-release-evidence.md`（新建） | 新文件 ~120 行 | T13-T17 |

## Planned File Changes

**Lane B（测试）：**
- `[add]` `apps/lazynote_flutter/test/group_layout_test.dart` (~120 行)
- `[add]` `apps/lazynote_flutter/test/atom_ref_consistency_test.dart` (~60 行)
- `[edit]` `apps/lazynote_flutter/test/edit_buffer_test.dart` (~+30 行)
- `[edit]` `apps/lazynote_flutter/test/editor_shell_service_test.dart` (~+40 行)

**Lane C（文档）：**
- `[edit]` `docs/architecture/overview.md`（migration 计数修正）
- `[edit]` `docs/api/ffi-contracts.md`（补充 workspace_ancestor_path）
- `[edit]` `docs/architecture/rulings/S1-atom-projection.md` ~ `S9-cross-feature-infrastructure-placement.md`（实施状态标注，9 个文件）
- `[verify]` `docs/reports/v0.3/design-discussions/README.md`（DI-0~DI-12 状态验证，DI-13/DI-14 保持 PENDING 无需变更）
- `[edit]` `docs/releases/v0.3/v0.3-rulings-modules-checklist-temp-2026-03-01.md`（闭合检查项）

**Lane E（Gate 脚本）：**
- `[add]` `tools/ci/gate_checks.dart` (~100 行)

**Lane D（Evidence）：**
- `[add]` `docs/releases/v0.3/v0.3-release-evidence.md` (~120 行)

**不变（审计确认无需变更）：**
- `CLAUDE.md` — 已由前序 PR 更新至最新
- `docs/architecture/data-model.md` — migration 10/11 已记录
- `docs/architecture/engineering-standards.md` — Rule E 豁免已明确
- `apps/lazynote_flutter/lib/` — Lane A 零残留，无代码清理

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
# Gate checks script（SSOT，跨平台）
cd apps/lazynote_flutter/
dart run ../../tools/ci/gate_checks.dart --all
# 期望：Gate A PASS, Gate B PASS
# gate_checks.dart 内部执行 NoteItem 零引用、atom_ref 可观察、S5 合规等验证

# Release evidence 文件存在（路径相对于 apps/lazynote_flutter/）
# Windows: if exist ..\..\docs\releases\v0.3\v0.3-release-evidence.md echo OK
# POSIX:   test -f ../../docs/releases/v0.3/v0.3-release-evidence.md
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| GroupLayout 测试补齐时发现不变式 bug | MEDIUM | GroupLayout 已在生产路径使用（PR-RB-06~RB-09），若发现 bug 属于隐性回归，及时修复 |
| 文档同步遗漏 | LOW | 覆盖矩阵 + 临时守则清单提供系统化检查 |
| 回归测试发现 v0.3 bug | MEDIUM | 及时修复，PR-RB-11 允许包含小修复；重大问题回退到对应 PR |

## Acceptance Criteria

- [ ] 旧 manager 零残留已验证并记录（Lane A verification pass）
- [ ] 回归测试补齐：新增 ≥15 个测试用例（其中 GroupLayout ≥10 个）
- [ ] `overview.md` migration 计数修正 + `ffi-contracts.md` 补充 `workspace_ancestor_path`
- [ ] Rulings S1~S9 实施状态已标注
- [ ] DI-0~DI-5, DI-10~DI-12 实施状态已标注（DI-11/DI-12 以 v0.4 addendum 口径）；DI-13/DI-14 保持 PENDING 已确认
- [ ] `v0.3-rulings-modules-checklist-temp-2026-03-01.md` 相关项全部闭合（RC-06/RC-07/MC-03 + §6 挂接）
- [ ] `tools/ci/gate_checks.dart` 已创建，Gate A/B 验证逻辑为单一事实来源，CI workflow 可执行
- [ ] Gate A 全部通过（`dart run ../../tools/ci/gate_checks.dart --gate-a` 零 violation）
- [ ] Gate B 全部通过（`dart run ../../tools/ci/gate_checks.dart --gate-b` 零 violation）
- [ ] §Verification CI gates 全部通过（测试数量无回退，release evidence 记录实际值）
- [ ] S5 合规校验通过
- [ ] v0.4 延期项汇总已纳入 release evidence
- [ ] `v0.3-release-evidence.md` 已撰写
