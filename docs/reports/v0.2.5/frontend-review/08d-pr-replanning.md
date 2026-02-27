# 08d — PR 再规划

> 基于 08b 语义裁决和 08c 解决方案推导的 PR 执行计划。
> 本文为 [08-reassessment-and-replanning.md](08-reassessment-and-replanning.md) 的第四部分。

| 字段 | 值 |
|------|-----|
| 日期 | 2026-02-27 |
| 前提 | [08b-semantic-decisions.md](08b-semantic-decisions.md) S1-S8 完成 + [08c-solution-proposals.md](08c-solution-proposals.md) 完成 |
| 状态 | **完成（规划定稿，尚未执行）** |

---

## 4.1 原 PR 状态与处置

| 原 PR | 原定范围 | 处置 |
|-------|---------|------|
| PR-0251（语义冻结） | 5 个语义歧义区域的冻结 + v0.3 依赖措辞更新 | **废弃，由 PR-0256 取代** — S1-S8 覆盖全部 5 个原始领域并扩展至 8 个 |
| PR-0252（模块化重构） | 22 任务（P0-1 ~ P3-5），god-object 拆分 | **已完成** — 全部任务已合并，333 pass / 0 fail |
| PR-0253（收尾交接） | 6 维闭合检查 + 全质量门禁回放 + v0.3 交接 | **保留，更新依赖** — 在 PR-0256/0257/0258/0259 完成后执行 |

---

## 4.2 新 PR 结构

| PR | 名称 | 类型 | 风险 | 08c 来源 | 依赖 |
|----|------|------|------|---------|------|
| **PR-0256** | 语义裁决与文档对齐 | 纯文档 | LOW | 3.3（7 项文档同步） | 08b/08c/08d 完成 |
| **PR-0257** | NoteTabManager pane-aware 升级 | 代码 | MEDIUM | 3.1.1 前置条件 | PR-0256 |
| **PR-0258** | notes↔workspace 结构性解耦 | 代码 | **HIGH** | 3.1.1 + 3.1.3 | PR-0257 |
| **PR-0259** | Rule E 消减与 CI 防线 | 代码 + CI | MEDIUM | 3.1.2 + 3.1.4 + 3.2 | PR-0258 |
| **PR-0253** | v0.2.5 收尾与 v0.3 交接 | 验证 + 文档 | LOW | — | PR-0256/0257/0258/0259 |

### S1-S8 裁决落地映射

v0.2.5 执行的 PR 仅覆盖 S1-S8 的部分裁决（S2 Phase 1、S7 Rule E 豁免等）。其余裁决在 v0.3 中按以下映射落地：

| 裁决 | v0.2.5 执行项 | v0.3 可执行落点 | v0.3 落地位置 |
|------|-------------|---------------|-------------|
| S1（Atom projection） | 无代码变更 | Atom 添加 `view_hint` / `title` 字段 + `atom_ref` 强制配对 | **v0.3 待规划**：需新增 data-model-v2 PR 或集成到 PR-0301 |
| S2（Tab/draft/save 架构） | Phase 1: PR-0257 + PR-0258 | Phase 2: 提取 `EditorShellService` 到 `core/` | PR-0303（cross-pane live buffer sync 的前置重构） |
| **S3（tag×workspace 正交）** | 当前行为已符合语义（PR-0256 文档化） | **验证正交不变式：tag 查询面板实现时确保 workspace tree 不受 tag 筛选影响** | **v0.3 待规划**：需新增 tag-query-panel PR 或集成到 PR-0307 |
| **S4（创建路径统一）** | Path A 缺陷已记录（PR-0256 文档化） | **Path A 修复：所有创建路径生成 Atom + atom_ref；Smart Folder 依赖此修复** | **v0.3 待规划**：需新增 creation-unification PR，为 PR-0301 前置条件 |
| S5（Extension Kernel 边界） | 文档化 first-party/third-party 边界（PR-0256） | Extension Kernel runtime 激活 + 命令注册迁移 | PR-0310（first-party command/parser plugins） |
| S6（Provider SPI 三层分离） | 文档化三层职责（PR-0256） | Sync Provider 首个实现 | PR-0309（Google Calendar provider plugin） |
| S7（Reminders 定位） | Rule E 豁免文档化（PR-0256）+ 迁移到 `core/`（PR-0259） | 触发语义重构：Atom 生命周期触发 | PR-0308（local task-calendar projection） |
| S8（NoteItem→AtomListItem） | 时间线修正为 v0.3（PR-0256） | FFI 类型统一：废弃 NoteItem DTO | **v0.3 待规划**：需新增 ffi-type-unification PR |

> **注**：标记"v0.3 待规划"的 4 项（S1、S3、S4、S8）需在 PR-0253 v0.3 交接文档中明确列为 v0.3 re-baseline 输入，确保 v0.3 规划阶段为其分配 PR 编号。参考 `docs/releases/v0.3/README.md` 现有 PR-0301~PR-0311。

---

## 4.3 执行顺序

```
PR-0252（已完成）
    │
    ▼
08a → 08b → 08c → 08d（已完成）
    │
    ▼
PR-0256（语义裁决 + 文档对齐）
    │
    ▼
PR-0257（NoteTabManager pane-aware 升级）← micro-PR
    │
    ▼
PR-0258（notes↔workspace 解耦）← 主力 PR，HIGH 风险
    │
    ▼
PR-0259（Rule E 消减 + CI 防线）
    │
    ▼
PR-0253（v0.2.5 收尾 + v0.3 交接）
    │
    ▼
v0.2.5 正式关闭 → v0.3 启动
```

---

## 4.4 PR-0256 — 语义裁决与文档对齐

| 字段 | 值 |
|------|-----|
| 标题 | `docs(architecture): PR-0256 semantic rulings and documentation alignment` |
| 类型 | 纯文档，不修改任何 `lib/` 或 `test/` 文件 |
| 风险 | LOW |
| 分支 | `docs/pr-0256-semantic-rulings-and-doc-alignment` |
| 依赖 | 08b/08c/08d 已完成 |
| 阻塞 | PR-0257, PR-0258, PR-0259 |

**目标**：将 S1-S8 语义裁决和 08c 解决方案正式写入架构/治理文档，消除文档漂移，为后续代码 PR 提供文档基础。

**范围**：

| In scope | Out of scope |
|----------|-------------|
| 08c 3.3 全部 7 项文档更新 | 任何运行时代码变更 |
| CLAUDE.md 架构表更新 | CI workflow 变更 |
| v0.2.5 Release README 更新 | Schema/数据变更 |
| PR-0251 标记为废弃 | |

**任务分解**：

| Task | 内容 | 目标文件 | 估算变更量 | 依赖 |
|------|------|---------|-----------|------|
| T1 | **重写** `architecture/overview.md` 至 v0.2.5 实际状态 | `docs/architecture/overview.md` | ~200 行（当前 116 行，全文重写） | — |
| T2 | 更新 `ffi-contracts.md`：标注 NoteItem → AtomListItem 统一方向（S8） | `docs/api/ffi-contracts.md` | 改 ~30 行 | — |
| T3 | 更新 `extension-kernel.md`：添加 first-party / third-party 边界定义章节（S5） | `docs/architecture/extension-kernel.md` | 加 ~30 行 | — |
| T4 | 更新 `provider-spi.md`：添加三层职责分离章节 Provider / Orchestrator / Mapping（S6） | `docs/architecture/provider-spi.md` | 加 ~30 行 | — |
| T5 | 更新 `engineering-standards.md`：Rule E 补充 `lib/core/` 基础设施豁免说明（S7） | `docs/architecture/engineering-standards.md` | 加 ~5 行 | — |
| T6 | 更新 `API_COMPATIBILITY.md`：NoteItem/AtomListItem 统一时间线从 v0.2 修正为 v0.3（S8） | `docs/governance/API_COMPATIBILITY.md` | 改 ~5 行 | — |
| T7 | 更新 `CLAUDE.md`：coordinator 架构描述、monorepo 布局表（post-PR-0252 状态） | `CLAUDE.md` | 改 ~20 行 | — |
| T8 | 更新 v0.2.5 Release README：新执行顺序、PR-0251 废弃标记、新增 PR-0256/0257/0258/0259 | `docs/releases/v0.2.5/README.md` | 改 ~30 行 | — |
| T9 | PR-0251 spec 标记为废弃 | `docs/releases/v0.2.5/prs/PR-0251-semantics-freeze-and-v0.3-rebaseline-docs.md` | 改 ~3 行（Status → Superseded） | — |
| T10 | 08 系列状态最终更新 | `docs/reports/v0.2.5/frontend-review/08-reassessment-and-replanning.md` | 改 ~5 行 | T1-T9 |

**计划文件变更**：

- `[edit]` `docs/architecture/overview.md`（全文重写）
- `[edit]` `docs/api/ffi-contracts.md`
- `[edit]` `docs/architecture/extension-kernel.md`
- `[edit]` `docs/architecture/provider-spi.md`
- `[edit]` `docs/architecture/engineering-standards.md`
- `[edit]` `docs/governance/API_COMPATIBILITY.md`
- `[edit]` `CLAUDE.md`
- `[edit]` `docs/releases/v0.2.5/README.md`
- `[edit]` `docs/releases/v0.2.5/prs/PR-0251-semantics-freeze-and-v0.3-rebaseline-docs.md`
- `[edit]` `docs/reports/v0.2.5/frontend-review/08-reassessment-and-replanning.md`

**验收标准**：

- [ ] `architecture/overview.md` 反映 v0.2.5 实际状态（workspace tree、coordinator 架构、extension kernel、provider SPI）
- [ ] S5 first-party/third-party 边界写入 `extension-kernel.md`
- [ ] S6 三层职责分离写入 `provider-spi.md`
- [ ] S7 Rule E `core/` 豁免写入 `engineering-standards.md`
- [ ] S8 NoteItem→AtomListItem 时间线修正为 v0.3
- [ ] CLAUDE.md 布局表和控制器表与代码对齐
- [ ] Release README 执行顺序更新，PR-0251 标记为废弃
- [ ] 无代码文件变更（`git diff --name-only | grep -E '^(apps|crates|tools|\.github)/'` 为空）

**CI gates**：无代码变更，仅需确认文档格式正确。

---

## 4.5 PR-0257 — NoteTabManager Pane-Aware 升级

| 字段 | 值 |
|------|-----|
| 标题 | `refactor(frontend): PR-0257 extend NoteTabManager with pane-scoped tab tracking` |
| 类型 | 代码 |
| 风险 | MEDIUM |
| 分支 | `feat/pr-0257-pane-aware-tab-manager` |
| 依赖 | PR-0256（S2 裁决已文档化） |
| 阻塞 | PR-0258 |

**目标**：将 NoteTabManager 从 flat `_openNoteIds` 列表升级为 pane-scoped `_openNoteIdsByPane` 映射，使 coordinator 可从 NoteTabManager（而非 WorkspaceProvider）读取 pane 级 tab 状态。这是 PR-0258 解耦的前置条件。

**背景**：coordinator 的 `openNoteIds` getter（`notes_coordinator_impl.dart:269-279`）当前在多窗格模式下 **独占读取** WP 的 `openTabsByPane`：

```dart
List<String> get openNoteIds {
    final workspaceTabs = _workspaceProvider.openTabsByPane[_workspaceProvider.activePaneId];
    if (_workspaceProvider.layoutState.paneOrder.length > 1) {
      return List.unmodifiable(workspaceTabs);  // 多窗格：只读 WP
    }
    return workspaceTabs.isEmpty
        ? _noteTabManager.openNoteIds  // 单窗格回退：flat list
        : List.unmodifiable(workspaceTabs);
}
```

NoteTabManager 当前仅有 flat `_openNoteIds: List<String>`（`managers/note_tab_manager.dart:56`），不支持 per-pane 跟踪。PR-0258 删除 WP 的 tab 状态后，如果 NoteTabManager 不升级，多窗格 tab 路由将丢失。

**范围**：

| In scope | Out of scope |
|----------|-------------|
| NoteTabManager pane-scoped 数据结构 | WP Bridge 删除（PR-0258） |
| coordinator openNoteIds getter 切换到 NoteTabManager | WP tab/save 状态删除（PR-0258） |
| coordinator open/close/activate 方法路由更新 | 测试文件删除（PR-0258） |
| 新增 pane-scoped tab 测试 | |

**任务分解**：

| Task | 内容 | 文件 | 估算变更量 | 依赖 |
|------|------|------|-----------|------|
| T1 | NoteTabManager 添加 `_openNoteIdsByPane: Map<String, List<String>>` 和 `_activePaneId` 字段 | `managers/note_tab_manager.dart` | 加 ~20 行 | — |
| T2 | 添加 pane-scoped 方法：`openNoteIdsForPane(paneId)`, `addNoteToPane(paneId, atomId)`, `removeNoteFromPane(paneId, atomId)`, `switchPane(paneId)`, `addPane(paneId)`, `removePane(paneId, mergeToPaneId)` | `managers/note_tab_manager.dart` | 加 ~80 行 | T1 |
| T3 | 重构 NoteTabManager 内部方法（`openNote`, `closeNote`, `activateNote` 等）从操作 `_openNoteIds` 改为操作 `_openNoteIdsByPane[activePaneId]`，保持单窗格行为不变 | `managers/note_tab_manager.dart` | 改 ~60 行 | T2 |
| T4 | 更新 coordinator 的 `openNoteIds` getter：从读 `_workspaceProvider.openTabsByPane` 改为读 `_noteTabManager.openNoteIdsForPane(activePaneId)` | `notes_coordinator_impl.dart:269-279` | 改 ~10 行 | T3 |
| T5 | 更新 coordinator 的 `_openNote`、`_closeNote`、`_activateNote` 等方法：通过 NoteTabManager 的 pane-scoped 方法操作 tab 状态 | `notes_coordinator_impl.dart` | 改 ~30 行 | T4 |
| T6 | 新增 pane-scoped tab 管理测试 | `test/note_tab_manager_pane_test.dart` 或扩展 `test/note_tab_manager_test.dart` | 加 ~100 行（~5 test cases） | T3 |

**计划文件变更**：

- `[edit]` `apps/lazynote_flutter/lib/features/notes/managers/note_tab_manager.dart`（~160 行变更）
- `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart`（~40 行变更）
- `[add]` 或 `[edit]` pane-scoped tab 测试文件

**行数影响**：
- `note_tab_manager.dart`：343 → ~440（+100 行 pane-scoped 逻辑）
- `notes_coordinator_impl.dart`：1,782 → 1,782（改内部实现，行数持平）

**测试基线**：333 + ~5 新 pane 测试 = **~338 pass / 0 fail**

**验收标准**：

- [ ] NoteTabManager 支持 `openNoteIdsForPane(paneId)` 方法
- [ ] coordinator `openNoteIds` 在单窗格和多窗格模式下均从 NoteTabManager 读取
- [ ] 现有单窗格行为完全保持（所有 333 个现有测试通过）
- [ ] 新增 pane-scoped 测试覆盖：添加/删除/切换 pane、pane 内 tab 开关
- [ ] CI green（format + analyze + test + build）

**CI gates**（cwd: `apps/lazynote_flutter/`）：

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build windows --debug
```

**风险**：

| 风险 | 严重度 | 缓解措施 |
|------|--------|---------|
| 单窗格回归 | MEDIUM | T3 必须保持 flat list 语义兼容：当只有一个 pane 时，行为与原 flat list 一致 |
| NoteTabManager 与 WP split/close 不同步 | MEDIUM | coordinator 的 `splitActivePane`/`closeActivePane` 调用链需同步通知 NoteTabManager 添加/移除 pane |

**回滚**：独立分支，可安全回退。不影响其他 PR。

---

## 4.6 PR-0258 — notes↔workspace 结构性解耦

| 字段 | 值 |
|------|-----|
| 标题 | `refactor(frontend): PR-0258 eliminate notes-workspace dual state system` |
| 类型 | 代码 |
| 风险 | **HIGH** |
| 分支 | `feat/pr-0258-notes-workspace-decoupling` |
| 依赖 | PR-0257（NoteTabManager pane-aware 升级完成） |
| 阻塞 | PR-0259 |

**目标**：消除双状态系统。PR 完成后，coordinator 是 tab/draft/save 状态的唯一来源；WorkspaceProvider 缩减为仅管理 pane 布局。

**范围**：

| In scope | Out of scope |
|----------|-------------|
| 08c 3.1.1 步骤 1-6（WP 解耦） | Phase 2 EditorShellService 提取（v0.3） |
| 08c 3.1.3 步骤 2-3（coordinator 瘦身） | notes→workspace pane 布局 import 消除（v0.3） |
| 受影响测试迁移/删除 | notes↔tags 循环打破（PR-0259） |
| | Reminders 迁移（PR-0259） |

**WP tab/save 状态全部消费者**（08c 3.1.1 验证结果）：

| 消费者 | 文件:行 | 读取的 WP 字段 | 迁移方案 |
|---|---|---|---|
| app shell 标题 | `app.dart:71-77` | `openTabsByPane`, `activePaneId` | 改为读 coordinator 的 `openNoteIds.length` |
| notes page 覆盖层 | `notes_page.dart:440-451` | `openTabsByPane`, `saveStateByNoteId` | 改为读 coordinator/managers |
| workspace port snapshot | `workspace_port.dart:4` | `openTabsByPane`（typedef 字段） | 删除 typedef（随 WP Bridge 删除） |

**任务分解**（严格顺序执行）：

| Task | 内容 | 文件 | 估算变更量 | 依赖 |
|------|------|------|-----------|------|
| T1 | 迁移 `notes_page.dart` 消费者：`openTabsByPane` → coordinator/managers | `notes_page.dart:438-454` | 改 ~30 行 | — |
| T2 | 迁移 `app.dart` titleBuilder：`workspace.openTabsByPane` → `coordinator.openNoteIds` | `app.dart:71-77` | 改 ~5 行 | — |
| T3 | 删除 `_syncWorkspaceActiveSnapshot()` 方法 | `notes_coordinator_impl.dart` | 删 ~12 行 | T1, T2 |
| T4 | 删除 `_syncWorkspaceFromControllerState()` 方法 | `notes_coordinator_impl.dart` | 删 ~68 行 | T3 |
| T5 | 移除 coordinator 中所有 sync 调用点（`_openNote`、`_closeNote` 等中的 sync 调用） | `notes_coordinator_impl.dart` | 改 ~15 行 | T3, T4 |
| T6 | 删除 `_WorkspaceProviderPort` adapter class（1608-1692 行区域） | `notes_coordinator_impl.dart` | 删 ~85 行 | T5 |
| T7 | 删除 `workspace_port.dart` | `workspace_port.dart` | 删 28 行（整文件） | T6 |
| T8 | 删除辅助映射方法（`_mapSaveStateToWorkspace`, `_workspaceSaveStateForNote` 等） | `notes_coordinator_impl.dart` | 删 ~70 行 | T6 |
| T9 | 缩减 WorkspaceProvider：删除 tab/save/buffer 状态字段和所有同步方法 | `workspace_provider.dart` | 删 ~464 行（664 → ~200） | T5 |
| T10 | 更新 coordinator 构造函数：移除 bridge 初始化 | `notes_coordinator_impl.dart` | 改 ~15 行 | T9 |
| T11 | 移除 `notes_coordinator.dart` 中 workspace_port.dart import | `notes_coordinator.dart` | 删 1 行 | T7 |
| T12 | 提取 typedef 声明和 default invoker 到 `notes_coordinator_types.dart`（3.1.3 步骤 2） | `notes_coordinator_impl.dart` → `notes_coordinator_types.dart` | 新文件 ~150 行，原文件删 ~150 行 | T10 |
| T13 | 评估 getter 代理层简化（3.1.3 步骤 3） | `notes_coordinator_impl.dart` | 改/删 ~50 行（估算） | T12 |
| T14 | 删除 `notes_controller_workspace_bridge_test.dart`（整文件） | `test/notes_controller_workspace_bridge_test.dart` | 删 ~380 行 | T9 |
| T15 | 裁剪 `workspace_provider_test.dart`：删除 tab/save 状态测试，保留 pane 布局测试 | `test/workspace_provider_test.dart` | 删 ~140 行 | T9 |

**计划文件变更**：

- `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
- `[edit]` `apps/lazynote_flutter/lib/app/app.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart`（主要：~260 行删除 + ~150 行提取）
- `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_coordinator.dart`
- `[delete]` `apps/lazynote_flutter/lib/features/notes/workspace_port.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/workspace/workspace_provider.dart`（主要：~464 行删除）
- `[add]` `apps/lazynote_flutter/lib/features/notes/notes_coordinator_types.dart`
- `[delete]` `apps/lazynote_flutter/test/notes_controller_workspace_bridge_test.dart`
- `[edit]` `apps/lazynote_flutter/test/workspace_provider_test.dart`

**行数影响**：

| 文件 | 当前 | PR 后 | 变化 |
|------|------|-------|------|
| `notes_coordinator_impl.dart` | 1,782 | ~1,400 | -382（删 sync/bridge ~260 + 提取 types ~150 + 简化 ~50，加回 import ~78） |
| `workspace_provider.dart` | 664 | ~200 | -464 |
| `workspace_port.dart` | 28 | 0 | -28（删除） |
| `notes_coordinator_types.dart` | 0 | ~150 | +150（新建） |
| 生产代码净变化 | | | **约 -724 行** |

**WP 删除的状态**（08c 3.1.1 步骤 5 表）：

| 删除 | Phase 1 后归属 |
|------|---------------|
| `_openTabsByPane` | coordinator → NoteTabManager（PR-0257 已升级） |
| `_activeTabByPane` | coordinator → NoteTabManager |
| `_buffersByNoteId` | coordinator → NoteDraftManager |
| `_saveStateByNoteId` | coordinator → NoteSaveTracker |
| `_saveDebounceByNoteId` | coordinator → NoteSaveTracker |
| `_saveInFlightByNoteId` | coordinator → NoteSaveTracker |
| **保留** | `_layoutState`, `_activePaneId`, `splitActivePane`, `closeActivePane` |

**测试基线**：~338（PR-0257 出口） - 16 删除 = **~322 pass / 0 fail**

> 计数方法：按文件内 `test(` 调用计数（与 08c 3.1.1 受影响测试表一致）。

测试减少的明细：
1. Bridge 测试（9 cases，整文件删除）：`notes_controller_workspace_bridge_test.dart` 测试的是一个不再存在的 WP Bridge 系统
2. WP tab/save 测试（7 cases，从 `workspace_provider_test.dart` 15 cases 中选择性删除）：tab/draft/save 状态已迁移到 coordinator managers，已有 manager 测试覆盖；保留 8 个 pane 布局测试

**验收标准**：

- [ ] `notes_page.dart` 从 coordinator 读取 tab/save 状态，不再读 WP
- [ ] `app.dart` titleBuilder 从 coordinator 读取，不再读 WP
- [ ] `_syncWorkspaceActiveSnapshot` 和 `_syncWorkspaceFromControllerState` 已从 coordinator_impl 删除
- [ ] `_WorkspaceProviderPort` 类已删除
- [ ] `workspace_port.dart` 已删除
- [ ] 辅助映射方法已删除
- [ ] WorkspaceProvider 缩减为 pane-layout-only（无 tab/save/buffer 状态）
- [ ] Typedef 和 default invoker 提取到 `notes_coordinator_types.dart`
- [ ] `notes_controller_workspace_bridge_test.dart` 已删除
- [ ] `workspace_provider_test.dart` 仅保留 pane 布局测试
- [ ] `notes_coordinator_impl.dart` < 1,500 行
- [ ] `workspace_provider.dart` < 250 行
- [ ] CI green（format + analyze + test + build）

**CI gates**（cwd: `apps/lazynote_flutter/`）：

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build windows --debug
```

**结构验证**（cwd: 仓库根）：

```bash
# 验证无 bridge 代码残留
rg -n "syncExternalNote|beginBatchSync|endBatchSync|resetAll|syncSaveState" \
  apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart
# 预期：零匹配

# 验证 WP 无 tab/save 状态
rg -n "openTabsByPane|buffersByNoteId|saveStateByNoteId|_activeTabByPane" \
  apps/lazynote_flutter/lib/features/workspace/workspace_provider.dart
# 预期：零匹配

# 验证 workspace_port.dart 已删除
test ! -f apps/lazynote_flutter/lib/features/notes/workspace_port.dart

# 行数检查
wc -l apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart  # < 1,500
wc -l apps/lazynote_flutter/lib/features/workspace/workspace_provider.dart  # < 250
```

**风险**：

| 风险 | 严重度 | 缓解措施 |
|------|--------|---------|
| 消费者迁移遗漏 | HIGH | T1/T2 完成后运行 `rg "workspaceProvider\." notes_page.dart`，仅保留 pane 布局调用 |
| 测试减少导致覆盖缺口 | MEDIUM | 逐条映射删除的测试断言到现有 coordinator/manager 测试 |
| pane 布局操作与 NoteTabManager 不同步 | MEDIUM | coordinator 的 `splitActivePane`/`closeActivePane` 调用链需同步操作 NoteTabManager（PR-0257 已处理） |

**回滚**：单分支，可整体回退。无耦合回滚单元。

---

## 4.7 PR-0259 — Rule E 消减与 CI 防线

| 字段 | 值 |
|------|-----|
| 标题 | `refactor(frontend): PR-0259 Rule E violation reduction and CI guardrails` |
| 类型 | 代码 + CI |
| 风险 | MEDIUM |
| 分支 | `feat/pr-0259-rule-e-reduction-and-ci` |
| 依赖 | PR-0258（import 状态必须稳定后才能建立 CI 检查） |
| 阻塞 | PR-0253 |

**目标**：消除 4 处 Rule E 违规（notes↔tags 循环 + reminders 跨 feature import），建立自动化 CI 防线防止 v0.3 开发中引入新的架构违规。

**范围**：

| In scope | Out of scope |
|----------|-------------|
| 08c 3.1.2（notes↔tags 循环打破） | entry→search 解耦（v0.3，LOW） |
| 08c 3.1.4（reminders 迁移到 `core/`） | entry→diagnostics 解耦（v0.3，LOW） |
| 08c 3.2（CI 架构检查脚本 + workflow） | notes→workspace pane 布局 import（v0.3 Phase 2） |

**任务分解**：

### Tags 循环打破（3.1.2）

| Task | 内容 | 文件 | 估算变更量 | 依赖 |
|------|------|------|-----------|------|
| T1 | 创建 `lib/shared/ui_tokens.dart`，提取 4 个共享颜色常量 | `[add]` `lib/shared/ui_tokens.dart` | 新文件 ~15 行 | — |
| T2 | `notes_style.dart` 重新导出 shared 常量（`export` 语句），notes 内部消费者无需改 import | `[edit]` `lib/features/notes/notes_style.dart` | 改 ~8 行 | T1 |
| T3 | `tag_filter.dart` import 从 `notes_style.dart` 改为 `shared/ui_tokens.dart` | `[edit]` `lib/features/tags/tag_filter.dart` | 改 1 行 | T1 |

### Reminders 迁移（3.1.4）

| Task | 内容 | 文件 | 估算变更量 | 依赖 |
|------|------|------|-----------|------|
| T4 | 创建 `lib/core/reminders/` 目录，移动 `reminder_scheduler.dart` | `[move]` `features/reminders/` → `core/reminders/` | 0 行净变更 | — |
| T5 | 移动 `reminder_service.dart` | `[move]` `features/reminders/` → `core/reminders/` | 0 行净变更 | T4 |
| T6 | 更新 4 个消费者 import：`main.dart`, `tasks_controller.dart`, `calendar_controller.dart`, `reminder_scheduler.dart`（内部 import） | 4 个文件各改 1 行 | 改 4 行 | T4, T5 |
| T7 | 更新测试 import：`mock_reminder_service.dart`, `reminder_scheduler_test.dart` | 2 个测试文件 | 改 2-3 行 | T4, T5 |
| T8 | 删除空的 `lib/features/reminders/` 目录 | `[delete]` 目录 | — | T6 |

### CI 防线（3.2）

| Task | 内容 | 文件 | 估算变更量 | 依赖 |
|------|------|------|-----------|------|
| T9 | 创建 `architecture_check.dart` 统一分析脚本（Rule E + 文件大小 + 结构层次检查） | `[add]` `tools/ci/architecture_check.dart` | 新文件 ~250 行 | — |
| T10 | 创建 `rule_e_allowlist.yaml`（3 条豁免：notes→workspace, entry→search, entry→diagnostics） | `[add]` `tools/ci/rule_e_allowlist.yaml` | 新文件 ~20 行 | T9 |
| T11 | 创建 `file_size_exemptions.yaml`（1 条豁免：note_explorer.dart 1,720 行 HOLD） | `[add]` `tools/ci/file_size_exemptions.yaml` | 新文件 ~10 行 | T9 |
| T12 | 更新 CI workflow：在 `flutter_windows` job 中添加 architecture check step | `[edit]` `.github/workflows/ci.yml` | 加 ~15 行 | T9 |

**计划文件变更**：

- `[add]` `apps/lazynote_flutter/lib/shared/ui_tokens.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_style.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/tags/tag_filter.dart`
- `[move]` `apps/lazynote_flutter/lib/features/reminders/reminder_scheduler.dart` → `apps/lazynote_flutter/lib/core/reminders/`
- `[move]` `apps/lazynote_flutter/lib/features/reminders/reminder_service.dart` → `apps/lazynote_flutter/lib/core/reminders/`
- `[edit]` `apps/lazynote_flutter/lib/main.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/tasks/tasks_controller.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/calendar/calendar_controller.dart`
- `[edit]` `apps/lazynote_flutter/test/helpers/mock_reminder_service.dart`
- `[edit]` `apps/lazynote_flutter/test/reminder_scheduler_test.dart`
- `[delete]` `apps/lazynote_flutter/lib/features/reminders/`（空目录）
- `[add]` `tools/ci/architecture_check.dart`
- `[add]` `tools/ci/rule_e_allowlist.yaml`
- `[add]` `tools/ci/file_size_exemptions.yaml`
- `[edit]` `.github/workflows/ci.yml`

**Rule E 违规变化**：

| 状态 | 非白名单违规 | 白名单豁免 |
|------|-------------|-----------|
| PR-0259 前 | ~7 | 0 |
| PR-0259 后 | **0** | 3（notes→workspace, entry→search, entry→diagnostics） |

**测试基线**：继承 PR-0258 出口基线（~322 pass / 0 fail），本 PR 无测试增删。

**验收标准**：

- [ ] `tag_filter.dart` 不再 import `features/notes/`
- [ ] `lib/shared/ui_tokens.dart` 存在，包含 4 个共享颜色常量
- [ ] `features/reminders/` 目录不再存在
- [ ] `lib/core/reminders/` 包含 `reminder_scheduler.dart` 和 `reminder_service.dart`
- [ ] 全部消费者和测试 import 已更新
- [ ] `architecture_check.dart` 运行成功：0 非白名单违规
- [ ] 文件大小检查：无文件超过 2,200 行；`note_explorer.dart`（1,720）仅触发警告
- [ ] CI workflow 包含 architecture check step
- [ ] CI green（format + analyze + test + build + architecture check）

**CI gates**（cwd: `apps/lazynote_flutter/`）：

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build windows --debug
dart run ../../tools/ci/architecture_check.dart
```

**结构验证**（cwd: 仓库根）：

```bash
# 验证 tags→notes import 消除
rg -n "features/notes" apps/lazynote_flutter/lib/features/tags/
# 预期：零匹配

# 验证 features/reminders 已删除
test ! -d apps/lazynote_flutter/lib/features/reminders

# 验证 core/reminders 存在
test -f apps/lazynote_flutter/lib/core/reminders/reminder_scheduler.dart
test -f apps/lazynote_flutter/lib/core/reminders/reminder_service.dart

# Architecture check 通过（需在 apps/lazynote_flutter/ 下运行，或从仓库根用相对路径）
cd apps/lazynote_flutter && dart run ../../tools/ci/architecture_check.dart
# 预期：0 violations, 3 allowlisted
```

**风险**：

| 风险 | 严重度 | 缓解措施 |
|------|--------|---------|
| `architecture_check.dart` 误报 | MEDIUM | 先在 post-PR-0258 代码上验证后再集成 CI |
| `notes_style.dart` re-export 影响下游 | LOW | Dart `export` 保持 API 表面不变 |
| Reminders 迁移影响 | LOW | 纯文件移动 + import 更新，无行为变更 |

**回滚**：Tags 修复（T1-T3）和 reminders 迁移（T4-T8）相互独立，可分别回退。CI 脚本（T9-T12）为新增，回退仅移除检查。

---

## 4.8 PR-0253 更新 — v0.2.5 收尾与 v0.3 交接

| 字段 | 值 |
|------|-----|
| 标题 | `chore(release): PR-0253 v0.2.5 closure with replay evidence and v0.3 handoff` |
| 类型 | 验证 + 文档 |
| 风险 | LOW |
| 分支 | `chore/pr-0253-v0.2.5-closure` |
| 依赖 | PR-0256, PR-0257, PR-0258, PR-0259 全部完成 |

**目标**：以可复现的质量证据关闭 v0.2.5，移交 re-baselined 的 v0.3 计划。

**更新后的闭合检查清单**（从 6 维扩展到 7 维）：

| 维度 | 检查内容 | 依赖 PR |
|------|---------|--------|
| 1. 合约闭合 | S1-S8 裁决文档化，架构文档同步 | PR-0256 |
| 2. 重构闭合 | PR-0252（22 任务完成）+ PR-0258（解耦完成） | PR-0252, PR-0258 |
| 3. 基线闭合 | PR-0254A/B/C 产物可复现 | PR-0254A/B/C |
| 4. 前端审查闭合 | PR-0255A/B/C 已接受，08a-08d 已完成 | PR-0255A/B/C |
| 5. 架构门禁闭合 | `architecture_check.dart` CI 绿色，0 非白名单违规 | PR-0259 |
| 6. 发布闭合 | format/lint/test/build + architecture check 重放 | 全部 |
| 7. 交接闭合 | v0.3 README/roadmap 与 v0.2.5 产出同步，S1-S8 裁决交接 | PR-0256 |

**更新后的验收标准**：

- [ ] 全部 7 个闭合维度通过
- [ ] CI 重放证据记录（含 architecture check 输出）
- [ ] 测试基线记录（预期 ~322 pass / 0 fail）
- [ ] v0.3 README 引用 S1-S8 裁决文档
- [ ] v0.3 依赖章节反映 PR-0258 解耦（coordinator 为唯一状态源）
- [ ] v0.3 re-baseline 输入包含 4 项"v0.3 待规划"裁决（S1/S3/S4/S8），各附具体 DoD 描述
- [ ] CHANGELOG.md 更新 v0.2.5 条目
- [ ] Release README 状态设为 "Completed"

**计划文件变更**：

- `[edit]` `docs/releases/v0.2.5/README.md`（状态 → Completed）
- `[edit]` `docs/releases/v0.2.5/prs/PR-0253-v0.2.5-closure-and-v0.3-handoff.md`（更新闭合清单）
- `[edit]` `docs/releases/v0.3/README.md`（同步 v0.2.5 产出）
- `[edit]` `docs/product/roadmap.md`（v0.2.5 标记完成）
- `[edit]` `CHANGELOG.md`（v0.2.5 条目）

---

## 4.9 v0.3 就绪度检查清单

v0.2.5 关闭前必须满足的全部条件（修正版）：

| # | 条件 | 负责 PR | 备注 |
|---|------|---------|------|
| 1 | S1-S8 全部裁决完成且文档化 | PR-0256 | |
| 2 | WP Bridge 删除，coordinator 成为唯一状态源 | PR-0258 | |
| 3 | notes→workspace import 仅保留 pane 布局 API，记入 allowlist | PR-0258 | ~~降至 0~~（Phase 2 v0.3 消除） |
| 4 | NoteTabManager 支持 pane-scoped tab 跟踪 | PR-0257 | Phase 2 提升到 EditorShellService 的基础 |
| 5 | notes↔tags 循环依赖消除 | PR-0259 | |
| 6 | Coordinator impl < 1,500 行 | PR-0258 | 预期 ~1,400 行 |
| 7 | WorkspaceProvider < 250 行（仅 pane 布局） | PR-0258 | 预期 ~200 行 |
| 8 | CI `architecture_check.dart` 上线 | PR-0259 | |
| 9 | Rule E 非白名单违规降至 0 | PR-0259 | 3 条白名单豁免 |
| 10 | `architecture/overview.md` 更新至 v0.2.5 | PR-0256 | |
| 11 | `ffi-contracts.md` 标注 NoteItem→AtomListItem 方向 | PR-0256 | |
| 12 | CLAUDE.md 与实际代码对齐 | PR-0256 | |
| 13 | 测试基线 ~322 pass / 0 fail | PR-0258 后 | PR-0257 +~5, PR-0258 -16（9 bridge + 7 WP tab/save） |
| 14 | 全质量门禁回放通过 | PR-0253 | |
| 15 | S1/S3/S4/S8 的 v0.3 落地 PR 已明确分配或计划 | PR-0253 | 4 项"v0.3 待规划"裁决的交接 DoD 写入 v0.3 README |

---

## 4.10 v0.2.5 Release README 更新计划

`docs/releases/v0.2.5/README.md` 需在 PR-0256 T8 中执行以下变更：

**1. Release Status 更新**：

```
- Current active item: `PR-0256-semantic-rulings-and-doc-alignment`
```

**2. Lane Strategy 更新**：

```
v0.2.5 主线：
1. contract/docs freeze (PR-0251) ← 已废弃，由 PR-0256 取代
2. behavior-parity refactor (PR-0252) ← 已完成
3. 08 系列重新审视 (08a-08d) ← 新增
4. semantic rulings + docs (PR-0256) ← 新增，取代 PR-0251
5. pane-aware upgrade (PR-0257) ← 新增
6. structural decoupling (PR-0258) ← 新增
7. Rule E + CI (PR-0259) ← 新增
8. closure replay + v0.3 handoff (PR-0253)
```

**3. Execution Order 更新**：

```
1.  ~~PR-0251-semantics-freeze-and-v0.3-rebaseline-docs~~ (superseded by PR-0256)
2.  PR-0254A-architecture-baseline-contract
3.  PR-0254B-architecture-baseline-tooling-implementation
4.  PR-0254C-architecture-baseline-report-closure
5.  PR-0255A-frontend-code-health-report
6.  PR-0255B-frontend-module-split-blueprint
7.  PR-0255C-frontend-phased-refactor-plan
8.  PR-0252-dart-modular-refactor-and-decoupling
9.  PR-0256-semantic-rulings-and-doc-alignment
10. PR-0257-pane-aware-tab-manager-upgrade
11. PR-0258-notes-workspace-structural-decoupling
12. PR-0259-rule-e-reduction-and-ci-guardrails
13. PR-0253-v0.2.5-closure-and-v0.3-handoff
```

**4. PR Specs 列表**：新增 PR-0256/0257/0258/0259 条目。
