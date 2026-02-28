# v0.3 设计就绪度审计报告

---

## 0. 文档信息

| 项目 | 值 |
|------|-----|
| **项目名称** | LazyNote — v0.3 设计就绪度审计 |
| **审计负责人** | AI Agent（Claude） |
| **审核人** | 前端 TL（WYI1223） |
| **审计日期** | 2026-02-28 |
| **报告版本** | M1（初始审计） |
| **审计范围** | v0.3 全部 16 个 PR 的设计就绪状态 + 关键代码基线验证 |
| **代码基线** | branch: `main`, commit: `5d833fbb` |
| **运行环境基线** | Flutter 3.41.0 · Dart 3.11.0 · FRB 2.11.1 · Windows 11 Pro 10.0.26100 |
| **前置文档** | kickoff `docs/releases/v0.3/v0.3-kickoff.md`（含 §9 结构重审）|
| **前置报告** | v0.2.5 `docs/reports/v0.2.5/frontend-review/01-code-health-report.md` |

### 审计输入

| 输入 | 路径 | 状态 |
|------|------|------|
| v0.3 Release Plan | `docs/releases/v0.3/README.md` | §9 结构重审后已更新 |
| v0.3 Kickoff | `docs/releases/v0.3/v0.3-kickoff.md` | §1-§9 完成 |
| 现有 PR spec（12 个） | `docs/releases/v0.3/prs/` | 12 个文件存在 |
| v0.2.5 代码体检 | `docs/reports/v0.2.5/frontend-review/01-code-health-report.md` | M4 完成 |
| v0.2.5 语义裁决 | `docs/architecture/rulings/` | S1-S8 完成 |

### 审计范围

本报告回答一个核心问题：**v0.3 的 16 个 PR 是否都具备了足够的设计确定性来编写可执行的 spec？**

具体审计维度：

1. 每个 PR 的实现方案是否明确？
2. 关键数据结构和接口是否已定义？
3. 是否存在需要前置研讨才能解决的设计空白？
4. PR 间的依赖链是否有隐藏缺口？
5. 验证标准是否可测试？

### 不纳入范围

| 排除项 | 原因 |
|--------|------|
| Rust Core 代码审计 | Phase 0 的 Core 变更由 S1/S4/S8 裁决充分定义 |
| 性能基准建立 | 属 Phase 2 PR-0305 执行阶段，本报告仅审计 spec 就绪度 |
| 测试代码质量 | 不影响设计就绪度判定 |

---

## 1. 执行摘要

### 设计就绪度：🟡 黄色（局部设计空白，整体架构方向正确）

**核心发现：**

kickoff §9 的能力分层（L0-L4）和 PR 边界重划是正确的。但从能力分层到可执行 spec 之间，存在一个未覆盖的环节：**关键 PR 的设计方案尚未确定**。

三个设计空白构成 spec 编写的前置阻塞：

1. **EditorShellService 接口未定义**（阻塞 PR-0301B/0303/0304 spec）— 从 coordinator 提取 tab/draft/save 的接口形态、状态归属、迁移路径均未确定。`EditorGroupModel` 在当前代码中完全不存在。
2. **递归布局树数据模型未确定**（阻塞 PR-0301/0302 spec）— 当前 `WorkspaceLayoutState` 是有意设计的扁平模型（最多 4 pane），递归二叉树的节点结构、约束传播、序列化格式需从零设计。
3. **Buffer 同步架构未决定**（阻塞 PR-0303/0305 spec）— 当前 `NoteEditor` 使用 per-instance `TextEditingController`，无跨实例同步。同步模型的选型（共享 buffer / 事件驱动 / 集中式 store）直接决定 spec 内容。

**影响评估：**

| 阻塞范围 | 被阻塞 PR | 占 v0.3 总 PR 数 |
|----------|----------|-----------------|
| DI-1 EditorShellService | PR-0301B, PR-0303, PR-0304, PR-0311 | 4/16（25%） |
| DI-2 布局树模型 | PR-0301, PR-0302 | 2/16（12.5%） |
| DI-3 Buffer 同步 | PR-0303, PR-0305 | 2/16（12.5%） |
| **合计（去重）** | **PR-0301/0301B/0302/0303/0304/0305/0311** | **7/16（44%）** |

**结论：** 在解决三个设计空白之前，v0.3 的 44% PR 无法编写有意义的 spec。建议在 Planning Phase 中增设 **设计研讨阶段（Design Investigation）**，将三个设计空白的结论作为 spec 编写的前置交付物。

---

## 2. 代码基线现状

审计时的关键文件度量（截至 commit `5d833fbb`）：

### 2.1 Flutter 前端概况

| 指标 | 值 |
|------|-----|
| 手写 Dart 文件数 | 75 |
| 手写代码行数 | 19,231 |
| 测试文件数 | 54 |
| 测试用例数 | 333 pass / 0 fail |

### 2.2 PR-0301B 目标文件（EditorShellService 提取源）

| 文件 | 行数 | 角色 | v0.3 影响 |
|------|------|------|----------|
| `notes_coordinator_impl.dart` | 1,514 | 协调器主实现 | PR-0300D 瘦身 → PR-0301B 提取 tab/draft/save |
| `managers/note_tab_manager.dart` | 440 | Per-pane tab 状态管理 | PR-0301B 提升到 workbench 级 |
| `note_tab_manager.dart`（根级） | 422 | Tab 管理器（v0.2 遗留） | 与 managers/ 版本关系待确认 |
| `managers/note_draft_manager.dart` | 258 | Per-note draft buffer | PR-0301B 提升 |
| `managers/note_save_tracker.dart` | 95 | 保存状态机 | PR-0301B 提升 |
| `note_editor.dart` | 110 | 编辑器 widget | PR-0303 buffer sync 改造点 |

**发现**：`note_tab_manager.dart` 存在两个版本 — `managers/note_tab_manager.dart`（440 行）和根级 `note_tab_manager.dart`（422 行）。PR-0301B spec 需要首先澄清哪个是规范版本，或者两者的关系。

### 2.3 PR-0301 目标文件（布局树改造）

| 文件 | 行数 | 角色 | v0.3 影响 |
|------|------|------|----------|
| `workspace_provider.dart` | 166 | Pane 布局状态（扁平模型） | PR-0301 替换为递归树 |
| `workspace_models.dart` | 66 | WorkspaceLayoutState 等模型 | PR-0301 重写为树节点模型 |

**当前布局模型分析**（`workspace_models.dart` L19-66）：

```
WorkspaceLayoutState（不可变）
├── paneOrder: List<String>        — 有序 pane ID 列表
├── paneFractions: List<double>    — 每个 pane 的相对尺寸
└── splitDirection: horizontal/vertical — 仅支持根级方向
```

关键约束：
- 硬编码最多 4 pane
- 最小 200px
- **非递归** — 有意设计为 v0.2 基线验证用

### 2.4 PR-0302 目标文件（Drag 交互）

| 文件 | 行数 | 角色 | v0.3 影响 |
|------|------|------|----------|
| `note_explorer.dart` | 1,720 | Explorer 树 widget | §9 决定 drag 逻辑不进入此文件 |
| `explorer_drag_controller.dart` | 103 | Explorer 树内拖拽 | 仅 explorer 内部移动，非 split |
| `notes_page.dart` | 802 | Notes 页面容器 | PR-0302 可能影响 |

**当前 Drag 功能分析**（`explorer_drag_controller.dart`）：

现有 drag 功能仅用于 **explorer 树内移动**（文件夹/笔记引用拖拽重排），与 drag-to-split 完全无关。PR-0302 需要在布局树层面新建 overlay 交互系统，而非扩展现有 explorer drag。

### 2.5 EditorGroupModel 搜索结果

在整个代码库中搜索 `EditorGroupModel`、`EditorGroup`、`PaneModel`：**零匹配**。

这确认了 `EditorGroupModel` 是 v0.3 全新概念，必须在 PR-0301B 中从零定义。

---

## 3. 逐 PR 设计就绪度评估

### 评估维度

| 维度 | 含义 | 评分 |
|------|------|------|
| **方案确定性** | 实现方案是否明确到可以写 spec？ | ✅ 明确 / ⚠️ 部分 / ❌ 未确定 |
| **接口定义** | 关键数据结构/API 是否已定义？ | ✅ 已定义 / ⚠️ 需设计 / ❌ 不存在 |
| **依赖清晰度** | 上下游依赖是否无歧义？ | ✅ 清晰 / ⚠️ 有隐藏依赖 / ❌ 阻塞 |
| **验证可测试性** | AC 是否可自动化验证？ | ✅ 可测 / ⚠️ 需定义 / ❌ 模糊 |

### 3.1 Phase 0 — 基础设施前置

| PR | 方案确定性 | 接口定义 | 依赖清晰度 | 验证可测试性 | 就绪度 |
|----|-----------|---------|-----------|------------|--------|
| PR-0300D | ✅ 机械提取 | ✅ typedef/invoker 列表可由代码审计确定 | ✅ 无外部依赖 | ✅ 行数验证 + CI | **就绪** |
| PR-0300A | ✅ 机械替换 | ⚠️ 需完整消费者审计 | ✅ 无外部依赖 | ✅ 编译通过 + grep 验证 | **就绪**（需审计） |
| PR-0300B | ✅ S1 裁决已定义字段 | ✅ Atom model 扩展 | ✅ 依赖 0300A | ✅ schema 验证 | **就绪** |
| PR-0300C | ✅ S4 裁决已定义路径 | ⚠️ 需创建路径清单审计 | ✅ 依赖 0300B | ✅ 路径覆盖验证 | **就绪**（需审计） |

**Phase 0 评估：全部就绪。** 4 个 PR 均为机械性变更，实现方案由 S1/S4/S8 裁决充分定义。PR-0300A 和 PR-0300C 需要代码审计来确定完整的变更清单，但这属于 spec 编写的一部分，不需要前置设计研讨。

### 3.2 Phase 1 Track A — 布局引擎

| PR | 方案确定性 | 接口定义 | 依赖清晰度 | 验证可测试性 | 就绪度 |
|----|-----------|---------|-----------|------------|--------|
| PR-0301 | ❌ 树模型未确定 | ❌ LayoutTreeEngine 接口不存在 | ✅ 依赖 Phase 0 | ⚠️ "递归稳定" 需定义 | **阻塞** |
| PR-0302 | ❌ 交互模型未确定 | ❌ SplitDropOverlay 不存在 | ⚠️ 对 0301B 是否有隐藏依赖？ | ⚠️ "drag 稳定" 需定义 | **阻塞** |

**Track A 阻塞分析：**

PR-0301 需要回答的核心设计问题：

1. **树节点数据结构**：采用 `sealed class LayoutNode { case Internal(left, right, splitAxis, fraction); case Leaf(paneId); }` 还是其他模型？
2. **约束传播**：min 200px 如何在嵌套树上传播？父节点 fraction 变化时子节点如何响应？
3. **序列化格式**：树状态是否持久化？JSON schema 是什么？
4. **从扁平模型迁移**：现有 `WorkspaceLayoutState`（`paneOrder` + `paneFractions`）如何迁移到树模型？向后兼容还是一次性替换？
5. **最大深度限制**：是否需要？pane 数上限从 4 改为多少？

PR-0302 需要在 PR-0301 树模型确定后才能设计交互：

1. **Drop zone 定义**：Leaf 节点的上下左右边缘区域如何定义？占 Leaf 面积的比例？
2. **Overlay 系统**：SplitDropOverlay 是全局单例还是 per-Leaf？
3. **反馈视觉**：拖拽过程中用户看到什么？（高亮区域？预览分割线？）
4. **隐藏依赖**：新建的 split 中，新 pane 需要在 EditorShellService 注册。PR-0302 是否依赖 PR-0301B？

### 3.3 Phase 1 Track B — 编辑器状态

| PR | 方案确定性 | 接口定义 | 依赖清晰度 | 验证可测试性 | 就绪度 |
|----|-----------|---------|-----------|------------|--------|
| PR-0301B | ❌ 接口形态未确定 | ❌ EditorGroupModel 不存在 | ✅ 依赖 Phase 0 | ⚠️ "接口冻结" 标准未定义 | **阻塞** |
| PR-0303 | ❌ 同步模型未确定 | ❌ BufferStore/SharedBuffer 不存在 | ❌ 依赖 0301B 接口 | ⚠️ "内容一致" 需定义验证场景 | **阻塞** |
| PR-0304 | ⚠️ 基线存在(PR-0205B M2) | ❌ EditorGroupModel 不存在 | ❌ 依赖 0301B 接口 | ✅ 状态机可测 | **阻塞** |

**Track B 阻塞分析：**

PR-0301B 是 Track B 的起点，也是整个 v0.3 的 **架构枢纽**。需要回答的核心设计问题：

1. **Service 接口形态**：
   - 选项 A：直接暴露 3 个 manager（NoteTabManager + NoteDraftManager + NoteSaveTracker）作为 service 的组成部分
   - 选项 B：定义新的 `EditorGroupModel`（per-pane 状态聚合），3 个 manager 重构为 model 的内部实现
   - 选项 C：保持 manager 在 coordinator 内部，EditorShellService 仅定义读取接口（facade 模式）

2. **状态归属迁移**：
   - `_openNoteIdsByPane`（NoteTabManager 内部状态）→ 移到 EditorShellService？还是 EditorGroupModel？
   - `_draftContentByAtomId`（NoteDraftManager 内部状态）→ per-pane 还是全局？
   - `_previewTabId`（NoteTabManager 内部状态）→ per-pane preview 还是全局唯一？

3. **Coordinator 关系**：coordinator 委托给 service？还是 service 取代 coordinator 的部分职责？剩余的 coordinator 还管什么？

4. **双版本 NoteTabManager 问题**：
   - `managers/note_tab_manager.dart`（440 行）
   - `note_tab_manager.dart`（422 行，根级）
   - 两者是什么关系？PR-0301B 提取哪一个？

PR-0303 在 0301B 接口确定前无法设计：

1. **同步模型选型**：
   - 选项 A：共享 TextEditingController — 同一个 controller 绑定到多个 pane 的 editor
   - 选项 B：事件驱动同步 — 每个 editor 独立 controller，变更事件通过 EditorShellService 广播
   - 选项 C：集中式 BufferStore — 在 EditorShellService 中维护 per-note canonical buffer，editor 订阅

2. **光标处理**：多窗格编辑同一笔记时，光标位置是否同步？各自独立？
3. **冲突场景**：两个 pane 同时编辑同一行如何处理？
4. **性能影响**：同步频率（每次击键？debounce？）对长文档的影响

PR-0304 在 0301B 接口确定前无法完成 EditorGroupModel 设计，但 preview/pinned 的 **状态机逻辑** 可以基于 PR-0205B M2 基线提前推导。

### 3.4 Phase 1 Track C — 索引管道

| PR | 方案确定性 | 接口定义 | 依赖清晰度 | 验证可测试性 | 就绪度 |
|----|-----------|---------|-----------|------------|--------|
| PR-0306A | ⚠️ 高层明确，细节不足 | ⚠️ FFI 接口 spec 存在但链接语法未定义 | ✅ 无 Phase 1 内部依赖 | ✅ 可测 | **基本就绪** |

**Track C 评估：**

PR-0306A 的现有 spec 定义了 5 步实施路径和 3 条 AC，但缺少以下细节：

1. **链接提取语法**：仅处理 Markdown `[text](url)` 还是也处理 bare URL、wiki link？
2. **增量更新策略**：每次 note save 全量重建索引？还是增量 diff？
3. **重复链接处理**：同一 URL 在同一 note 中出现多次，索引条目是一条还是多条？

这些细节可在 spec 编写过程中内定，不构成前置阻塞。

### 3.5 Phase 2 — 功能与收尾

| PR | 方案确定性 | 接口定义 | 依赖清晰度 | 验证可测试性 | 就绪度 |
|----|-----------|---------|-----------|------------|--------|
| PR-0307 | ✅ 依赖 0306A 设计 | ⚠️ S3 正交性 AC 待追加 | ✅ 依赖 Track C | ✅ 可测 | **就绪**（需 UPDATE） |
| PR-0308 | ✅ S1/S7 裁决定义 | ⚠️ 投影规则待精确化 | ✅ 依赖 Phase 0 | ✅ 可测 | **就绪**（需 UPDATE） |
| PR-0309 | ⚠️ SPI 首次实现 | ⚠️ SPI trait 可能需修改 | ✅ 依赖 0308 | ⚠️ R6 风险 | **有风险但可启动** |
| PR-0311 | ✅ 平台集成明确 | ⚠️ pane targeting 待定义 | ⚠️ 依赖 0304 接口 | ✅ 可测 | **就绪**（需 UPDATE） |
| PR-0305 | ⚠️ 策略未量化 | ⚠️ 性能目标待定义 | ⚠️ 依赖 0303 buffer | ⚠️ 基准待建立 | **需设计** |
| PR-0306 | ✅ 收尾性质 | ✅ 明确 | ✅ 依赖所有 PR | ✅ 可测 | **就绪** |

---

## 4. 三个关键设计空白详析

### 4.1 DI-1：EditorShellService 接口设计

**严重度**：🔴 Critical — 阻塞 Track B 全部 3 个 PR + Phase 2 Lane C

**现状**：

EditorShellService 是 §9 结构重审的核心新增（PR-0301B），是 S2 Phase 2 裁决的落地载体。但目前：

- `EditorGroupModel` 在代码库中 **完全不存在**（grep 零匹配）
- 目标提取源是 coordinator 内部的 3 个 manager，其接口从未设计为 "可对外暴露"
- NoteTabManager 有两个版本文件（`managers/` 下 440 行 + 根级 422 行），职责关系不明确

**需要确定的设计决策**：

| # | 决策点 | 选项 | 影响范围 |
|---|--------|------|---------|
| D1 | Service 形态 | A: 组合现有 manager / B: 新建 EditorGroupModel / C: Facade 读取接口 | 全部 Track B PR |
| D2 | 状态归属 | Tab 状态、draft buffer、save tracker 的归属点 | PR-0303 buffer sync |
| D3 | Coordinator 残留职责 | 提取后 coordinator 还管什么？ | R1 风险缓解效果 |
| D4 | 双版本 TabManager | 规范版本是哪个？另一个的去留？ | PR-0301B 实施范围 |

**建议输出**：接口定义文档（方法签名 + 状态归属图 + 迁移路径），作为 PR-0301B spec 的前置附件。

### 4.2 DI-2：递归布局树数据模型

**严重度**：🟠 High — 阻塞 Track A 全部 2 个 PR

**现状**：

当前 `WorkspaceLayoutState` 是 **有意设计的扁平基线**：

```dart
// workspace_models.dart L19-66（当前实现）
class WorkspaceLayoutState {
  final List<String> paneOrder;       // 有序 pane ID
  final List<double> paneFractions;   // 相对尺寸
  final SplitDirection splitDirection; // 单一方向
  // 硬编码最多 4 pane
}
```

PR-0301 要替换为递归二叉树（kickoff §9.3 L1a），但树的具体设计未定义。

**需要确定的设计决策**：

| # | 决策点 | 选项 | 影响范围 |
|---|--------|------|---------|
| D5 | 树节点结构 | A: Dart sealed class (Internal/Leaf) / B: 可变树 + ChangeNotifier / C: 不可变 + rebuild | PR-0301 核心实现 |
| D6 | 约束传播 | A: 自顶向下尺寸分配 / B: 自底向上约束求解 / C: Flutter LayoutDelegate | PR-0301 + PR-0302 |
| D7 | 持久化 | A: JSON 序列化 / B: 不持久化（每次启动恢复默认） / C: 按 session 保存 | PR-0301 scope |
| D8 | 迁移策略 | A: 向后兼容（旧模型 → 新模型转换器） / B: 一次性替换 | PR-0301 风险 |
| D9 | 最大深度/pane数 | 无限制？深度上限？pane 数上限？ | PR-0301 + PR-0302 AC |

**建议输出**：数据模型定义文档（节点类型 + 约束规则 + 序列化 schema + 迁移方案），作为 PR-0301 spec 的前置附件。

### 4.3 DI-3：Buffer 同步架构

**严重度**：🟠 High — 阻塞 PR-0303 + 影响 PR-0305

**现状**：

```dart
// note_editor.dart L1-110（当前实现）
class NoteEditor extends StatefulWidget {
  final String content;
  final ValueChanged<String> onChanged;
  // per-instance TextEditingController — 无跨实例同步
}
```

每个 editor widget 实例拥有独立的 `TextEditingController`。对于同一笔记在多个 pane 中打开的场景，当前代码 **无任何同步机制**。

**需要确定的设计决策**：

| # | 决策点 | 选项 | 影响范围 |
|---|--------|------|---------|
| D10 | 同步模型 | A: 共享 Controller / B: 事件广播 / C: 集中式 BufferStore | PR-0303 核心实现 |
| D11 | 同步粒度 | A: 全量替换 / B: 差分 patch / C: 按段（段落级） | PR-0303 + PR-0305 性能 |
| D12 | 光标独立性 | A: 各 pane 光标独立 / B: 光标也同步 | PR-0303 UX |
| D13 | 冲突处理 | A: Last-write-wins / B: 不允许同时编辑 / C: Operational Transform | PR-0303 复杂度 |

**建议输出**：同步架构方案文档（模型选型 + 数据流图 + 边界情况处理），作为 PR-0303 spec 的前置附件。

---

## 5. 其他未完善项

### 5.1 Phase 1 Gate 验证标准不够精确

当前 Phase 1 Gate 包含模糊条件：

| 当前表述 | 问题 | 建议精确化 |
|---------|------|-----------|
| "Same-note multi-pane editing content-coherent" | "content-coherent" 不是可自动化验证的条件 | 定义具体测试场景：在 pane A 编辑 → pane B 在 N ms 内反映变更 |
| "Recursive split stable" | "stable" 含义不明确 | 定义：N 次 split/close 循环后状态一致，无内存泄漏 |
| "Preview/pinned tab deterministic" | "deterministic" 需操作序列定义 | 定义：给定操作序列 → 预期 tab 状态映射表 |

### 5.2 性能目标未量化

PR-0305 的 "≥ 60 FPS" 目标缺少：

| 缺失维度 | 需要定义 |
|---------|---------|
| 数据集 | 多长的 Markdown？（1K 行？10K 行？100K 行？） |
| 窗格数 | 1 pane？2 pane 同笔记？4 pane？ |
| 硬件基线 | 哪种 CPU/GPU？最低配置？ |
| 测量方法 | Flutter DevTools Timeline？profile mode 自动化？ |
| 基线对比 | 与 v0.2 相比改善还是不退化？ |

### 5.3 PR-0302 对 PR-0301B 的隐藏依赖

§9 的依赖图中，PR-0302（Track A）只依赖 PR-0301（Track A）。但 drag-to-split 创建新 pane 后：

- 新 pane 需要在 EditorShellService 中注册（获取 EditorGroupModel）
- 新 pane 的 tab strip 需要初始化

如果 PR-0302 在 PR-0301B 之前完成，新 split 的 pane 只有布局容器但没有编辑器状态管理。

**评估**：这不一定构成硬依赖 — PR-0302 可以创建空 pane，编辑器注册由后续 PR 补全。但 spec 必须明确这个边界：PR-0302 的 scope 是 "布局分割" 还是 "可用的编辑器窗格"？

### 5.4 增量交付价值未考虑

当前 Phase 1 的三条 Track 完成后分别提供什么用户价值？

| Track | 单独完成后的用户价值 | 是否有意义？ |
|-------|-------------------|------------|
| Track A | 递归分屏 + drag — 但新 pane 可能没有编辑器状态管理 | ⚠️ 部分价值 |
| Track B | EditorShellService + buffer sync + tab preview — 但只能在扁平布局上工作 | ⚠️ 部分价值 |
| Track C | 链接索引可用 — 但 Launcher (PR-0307) 在 Phase 2 | ⚠️ 基础设施，无直接用户价值 |

**结论**：三条 Track 必须全部完成（或至少 Track A + Track B）才能交付完整的 "IDE 级工作区" 体验。这意味着 Phase 1 Gate 是一个 **整体交付门禁**，不是三个独立的交付点。

### 5.5 测试策略缺失

v0.3 引入多个全新交互模型（多窗格编辑、drag-to-split、buffer 同步、递归布局树），但当前规划中 **没有任何地方定义测试方法论**。

需要回答的问题：

| 新能力 | 测试问题 | 现有测试能力 |
|--------|---------|------------|
| 多窗格编辑 | Widget test 能模拟多 pane 场景吗？需要自定义 test harness？ | 当前 widget test 均为单 pane |
| Drag-to-split | 如何模拟 drag gesture 在 layout tree 上的交互？ | Flutter `WidgetTester` 支持 `drag()`，但 overlay 交互可能需要额外 setup |
| Buffer 同步 | 同步一致性如何在测试中验证？需要时序控制？ | 无现有参考 |
| 递归布局树 | 树操作（split/close/resize）的状态正确性如何验证？ | 当前布局测试基于扁平模型 |
| EditorShellService | Service 提取后，现有 333 个测试是否需要迁移？ | 现有测试直接 mock coordinator |

**建议**：每个 DI 的输出中应包含 "验证方法" 节，定义该设计的可测试性方案。PR-0301B spec 特别需要定义：提取后现有测试的迁移策略。

### 5.6 PR-0309 SPI 验证缺失（R6）

PR-0309 是 Provider SPI 的首个运行时实现。当前 SPI 是 declaration-only（`src/sync/` 中仅有 trait 定义和类型枚举）。

spec 应要求在 PR-0309 **开始实现之前** 验证 SPI trait 的可实现性：
- auth flow 是否完整？
- pull/push 接口是否支持 Google Calendar 的 incremental sync？
- conflict-map 抽象是否足够？

这可以通过一个 **mock provider 单元测试** 完成，验证 SPI trait 的接口完整性。建议作为 PR-0309 spec 的前置条件或首个 milestone。

---

## 6. 建议方案：设计研讨阶段

### 6.1 在 Planning Phase 中增设 Design Investigation

当前 Planning Phase 结构：
```
P1: 创建 Phase 0 spec (4个)
P2: 创建 PR-0301B spec
P3: 重写 3 个 spec
P4: 更新 5 个 spec
P5: 标记 PR-0310 DROP
```

建议调整为：
```
P1:  创建 Phase 0 spec (4个)          — 直接就绪，无设计阻塞
P2:  DI-1 EditorShellService 接口设计  — 设计研讨
P3:  DI-2 递归布局树数据模型           — 设计研讨
P4:  DI-3 Buffer 同步架构             — 设计研讨（依赖 DI-1 结论）
P5:  创建 PR-0301B spec               — 基于 DI-1 结论
P6:  重写 PR-0301/0302/0304 spec      — 基于 DI-1/DI-2/DI-3 结论
P7:  更新 PR-0303/0307/0308/0309/0311 — 基于 DI-1/DI-3 结论
P8:  标记 PR-0310 DROP
```

### 6.2 DI 交付物格式

每个 DI 产出一个设计研讨文档，格式建议：

```
DI-N-标题.md
├── 1. 问题陈述（当前代码状态 + 目标状态）
├── 2. 设计选项（每个选项含优缺点分析）
├── 3. 推荐方案（含依据）
├── 4. 接口定义（方法签名 / 数据结构 / 状态图）
├── 5. 迁移路径（从当前代码到目标的具体步骤）
└── 6. 验证标准（如何证明设计是正确的）
```

### 6.3 DI 执行方法论

每个 DI 需要判断：**纯文档研讨是否足够，还是需要原型代码验证？**

| 方案 | 适用场景 | 产出 | 风险 |
|------|---------|------|------|
| **方案 A：纯文档** | 设计选项可通过代码阅读 + 逻辑推理确定 | 设计文档 | 纸上方案可能在实现时发现不可行 |
| **方案 B：文档 + 原型** | 技术可行性有不确定性，需要代码验证 | 设计文档 + spike 分支/PR | 原型开发占用额外时间 |

逐 DI 评估：

| DI | 推荐方案 | 理由 |
|----|---------|------|
| DI-1 EditorShellService | **方案 A** | 提取方向明确（3 个 manager → service），设计问题是接口形态选择，代码阅读可确定 |
| DI-2 布局树模型 | **方案 A** | 递归二叉树是成熟模式（VS Code、IntelliJ 均如此），设计问题是 Dart 实现细节 |
| DI-3 Buffer 同步 | **方案 B** | 多实例 TextEditingController 同步在 Flutter 中缺少成熟先例。共享 controller 是否可行？事件广播的延迟特性？需要原型验证 |

DI-3 采用方案 B 时，建议在独立分支上编写最小原型（2 个 pane + 同一 note 的 TextEditingController 同步），验证同步模型后再固化到设计文档。原型代码不需要合入 main，仅作为设计证据。

### 6.4 DI 存放位置

- `docs/releases/v0.3/design/` 下独立文件 — 可被多个 PR spec 交叉引用
- DI-3 如采用方案 B，原型分支命名 `spike/di-3-buffer-sync`

### 6.5 DI 之间的依赖关系

```
DI-1 (EditorShellService)     DI-2 (布局树)
       ↓                           │
DI-3 (Buffer 同步)                  │ （无依赖）
       ↓                           ↓
  PR-0301B spec              PR-0301 spec
  PR-0303 spec               PR-0302 spec
  PR-0304 spec
```

DI-1 和 DI-2 **可并行**（分属不同 Track）。DI-3 **依赖 DI-1**（buffer sync 的 "buffer 放在哪" 由 EditorShellService 接口决定）。

---

## 7. 就绪度总览

### 7.1 PR 分级汇总

| 就绪度 | PR | 数量 | 比例 |
|--------|-----|------|------|
| ✅ 就绪（可直接写 spec） | 0300D, 0300A, 0300B, 0300C, 0306A, 0307, 0308, 0306 | 8 | 50% |
| ⚠️ 有风险但可启动 | 0309, 0311 | 2 | 12.5% |
| ❌ 需前置设计研讨 | 0301, 0301B, 0302, 0303, 0304, 0305 | 6 | 37.5% |

### 7.2 设计决策登记表

| ID | 决策点 | 归属 DI | 阻塞 PR | 优先级 |
|----|--------|---------|---------|--------|
| D1 | EditorShellService 形态 | DI-1 | 0301B/0303/0304 | P0 |
| D2 | 状态归属迁移 | DI-1 | 0301B/0303 | P0 |
| D3 | Coordinator 残留职责 | DI-1 | 0301B | P0 |
| D4 | 双版本 NoteTabManager 关系 | DI-1 | 0301B | P0 |
| D5 | 布局树节点结构 | DI-2 | 0301/0302 | P0 |
| D6 | 约束传播模型 | DI-2 | 0301/0302 | P1 |
| D7 | 布局持久化策略 | DI-2 | 0301 | P1 |
| D8 | 扁平→树迁移策略 | DI-2 | 0301 | P1 |
| D9 | 最大深度/pane 数限制 | DI-2 | 0301/0302 | P1 |
| D10 | Buffer 同步模型选型 | DI-3 | 0303/0305 | P0 |
| D11 | 同步粒度 | DI-3 | 0303/0305 | P1 |
| D12 | 光标独立性 | DI-3 | 0303 | P2 |
| D13 | 冲突处理策略 | DI-3 | 0303 | P1 |

### 7.3 更新后的 Planning Phase 关键路径

```
                ┌─ DI-2 (布局树) ──────────► PR-0301/0302 spec
P1 (Phase 0     │
 spec 4个) ─────┤
                │                            ┌─► PR-0301B spec
                └─ DI-1 (EditorShell) ───────┤
                         ↓                   ├─► PR-0304 spec
                   DI-3 (Buffer) ────────────┤
                                             └─► PR-0303 spec

并行：P1 + DI-1 + DI-2 可同时启动
串行：DI-3 必须在 DI-1 之后
```

---

## 8. 下一步行动

| # | 行动 | 阻塞关系 | 方法 | 优先级 |
|---|------|---------|------|--------|
| 1 | 建立 `docs/releases/v0.3/design/` 目录 | 无 | — | P0 |
| 2 | 执行 DI-1：EditorShellService 接口设计 | 无（可立即开始） | 方案 A（纯文档） | P0 |
| 3 | 执行 DI-2：递归布局树数据模型 | 无（可与 DI-1 并行） | 方案 A（纯文档） | P0 |
| 4 | 创建 Phase 0 spec（4 个） | 无（可与 DI-1/DI-2 并行） | — | P0 |
| 5 | 执行 DI-3：Buffer 同步架构 | 依赖 DI-1 结论 | 方案 B（文档 + `spike/di-3-buffer-sync` 原型） | P1 |
| 6 | 创建 PR-0301B spec | 依赖 DI-1 结论 | — | P1 |
| 7 | 重写 PR-0301/0302 spec | 依赖 DI-2 结论 | — | P1 |
| 8 | 重写 PR-0304 + 更新 PR-0303 spec | 依赖 DI-1 + DI-3 结论 | — | P1 |
| 9 | 更新 PR-0307/0308/0309/0311 spec | 无前置阻塞 | — | P2 |
| 10 | 标记 PR-0310 DROP | 无前置阻塞 | — | P2 |
| 11 | 精确化 Phase 1 Gate 验证标准 | 依赖 DI-1/DI-2/DI-3 结论 | — | P2 |
| 12 | 定义 PR-0305 性能基准 | 依赖 DI-3 结论 | — | P2 |
| 13 | 定义 v0.3 测试策略（新能力的测试方法论） | 依赖 DI 结论 | — | P2 |

---

## 附录 A：文件度量快照

| 文件 | 行数 | 归属 PR |
|------|------|---------|
| `notes_coordinator_impl.dart` | 1,514 | PR-0300D → PR-0301B |
| `note_explorer.dart` | 1,720 | §9 R2 已消除 |
| `notes_page.dart` | 802 | PR-0302 可能影响 |
| `note_content_area.dart` | 869 | PR-0303 可能影响 |
| `managers/note_tab_manager.dart` | 440 | PR-0301B 提取目标 |
| `note_tab_manager.dart`（根级） | 422 | 待确认与 managers/ 版本关系 |
| `managers/note_draft_manager.dart` | 258 | PR-0301B 提取目标 |
| `managers/note_save_tracker.dart` | 95 | PR-0301B 提取目标 |
| `note_editor.dart` | 110 | PR-0303 改造点 |
| `workspace_provider.dart` | 166 | PR-0301 替换目标 |
| `workspace_models.dart` | 66 | PR-0301 重写目标 |
| `explorer_drag_controller.dart` | 103 | PR-0302 参考（非 split） |

## 附录 B：现有 v0.3 PR Spec 文件清单

| 文件 | 存在？ | 审计判定 |
|------|--------|---------|
| `prs/PR-0300A-ffi-type-unification.md` | ❌ 不存在 | CREATE |
| `prs/PR-0300B-data-model-v2.md` | ❌ 不存在 | CREATE |
| `prs/PR-0300C-creation-path-unification.md` | ❌ 不存在 | CREATE |
| `prs/PR-0300D-coordinator-thinning.md` | ❌ 不存在 | CREATE |
| `prs/PR-0301-recursive-layout-tree.md` | ✅ 存在 | REWRITE |
| `prs/PR-0301B-editor-shell-service.md` | ❌ 不存在 | CREATE |
| `prs/PR-0302-drag-to-split-edge-zones.md` | ✅ 存在 | REWRITE |
| `prs/PR-0303-cross-pane-live-buffer-sync.md` | ✅ 存在 | UPDATE |
| `prs/PR-0304-tab-preview-pinned-model.md` | ✅ 存在 | REWRITE |
| `prs/PR-0305-markdown-segment-rendering-performance-gate.md` | ✅ 存在 | VALID |
| `prs/PR-0306-recursive-workspace-reliability-hardening.md` | ✅ 存在 | VALID |
| `prs/PR-0306A-links-index-open-foundation.md` | ✅ 存在 | VALID |
| `prs/PR-0307-workspace-launcher-experience.md` | ✅ 存在 | UPDATE |
| `prs/PR-0308-local-task-calendar-projection.md` | ✅ 存在 | UPDATE |
| `prs/PR-0309-google-calendar-provider-plugin.md` | ✅ 存在 | UPDATE |
| `prs/PR-0310-first-party-command-parser-plugins.md` | ✅ 存在 | DROP |
| `prs/PR-0311-windows-global-hotkey-quick-entry.md` | ✅ 存在 | UPDATE |
