# DI-6: 跨 Track 隐藏依赖 + 增量交付

| 项目 | 值 |
|------|-----|
| **状态** | **RESOLVED** — 三 Track 模型已失效，替换为重排 PR 序列 |
| **关联决策点** | 无编号（§5.3 + §5.4 提出的工程问题） |
| **影响范围** | v0.3 整体 PR 规划（原 PR-0301 ~ PR-0305 重组为 PR-RB-00 ~ PR-RB-11 + PR-RB-12 conditional） |
| **前置依赖** | DI-1（EditorShellService 统一布局+编辑器状态）、DI-2/DI-3（布局树+持久化）、DI-4/DI-5（buffer 同步+光标） |
| **来源** | 01-design-readiness-audit.md §5.3 + §5.4 |
| **权威执行方案** | [v0.3-pr-spec-rebaseline-2026-03-01.md](../../../releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md) |

---

## 问题提取

### 来源 §5.3 — PR-0302 对 PR-0301B 的隐藏依赖

> §9 的依赖图中，PR-0302（Track A）只依赖 PR-0301（Track A）。但 drag-to-split 创建新 pane 后：
>
> - 新 pane 需要在 EditorShellService 中注册（获取 EditorGroupModel）
> - 新 pane 的 tab strip 需要初始化
>
> 如果 PR-0302 在 PR-0301B 之前完成，新 split 的 pane 只有布局容器但没有编辑器状态管理。
>
> **评估**：这不一定构成硬依赖 — PR-0302 可以创建空 pane，编辑器注册由后续 PR 补全。但 spec 必须明确这个边界：PR-0302 的 scope 是 "布局分割" 还是 "可用的编辑器窗格"？

### 来源 §5.4 — 增量交付价值

> 当前 Phase 1 的三条 Track 完成后分别提供什么用户价值？
>
> | Track | 单独完成后的用户价值 | 是否有意义？ |
> |-------|-------------------|------------|
> | Track A | 递归分屏 + drag — 但新 pane 可能没有编辑器状态管理 | ⚠️ 部分价值 |
> | Track B | EditorShellService + buffer sync + tab preview — 但只能在扁平布局上工作 | ⚠️ 部分价值 |
> | Track C | 链接索引可用 — 但 Launcher (PR-0307) 在 Phase 2 | ⚠️ 基础设施，无直接用户价值 |
>
> **结论**：三条 Track 必须全部完成（或至少 Track A + Track B）才能交付完整的 "IDE 级工作区" 体验。这意味着 Phase 1 Gate 是一个 **整体交付门禁**，不是三个独立的交付点。

---

## 裁决总结

DI-1 至 DI-5 的裁决已从根本上改变了 Phase 1 的架构结构。审计报告的三 Track 并行模型基于 "布局 / 编辑器状态 / 链接索引" 三个独立关注点可分离的假设。DI-1 裁决（EditorShellService 拥有 GroupLayout）打破了这一假设——Track A（布局）和 Track B（编辑器状态）在架构上不可分离。

DI-6 的三个讨论点不再需要逐一裁决，而是由 PR 重组整体解决。

| 原讨论点 | 裁决 | 依据 |
|---------|------|------|
| PR-0302 → PR-0301B 硬依赖 | **问题已消解** — 原 PR 边界不再存在 | DI-1：splitGroup() 是 Service API，GroupLayout 是 Service 内部组件 |
| Phase 1 三 Track 合并时序 | **三 Track 模型失效** — 替换为重排序列 | DI-1 统一 Track A + B；重排序列消除并行合并风险 |
| 依赖图调整 | **完全重画** — 见 [rebaseline §4](../../../releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md) | 从三条并行 Track 变为两阶段线性序列 |

完整的 PR 序列（PR-RB-00 ~ PR-RB-12）、依赖关系和执行顺序定义在 [v0.3-pr-spec-rebaseline-2026-03-01.md](../../../releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md)，DI-6 不再重复具体 PR 计划，仅保留三 Track 失效的分析推导和重排后的结构验证。

---

## 核心发现：三 Track 模型为何失效

### DI-1 的架构影响

DI-1 裁决 EditorShellService 为 workbench 级 singleton，状态字段包括：

```
EditorShellService
├── groups: Map<GroupId, EditorGroupModel>   ← 原 Track B
├── buffers: Map<AtomId, EditBuffer>         ← 原 Track B
├── layout: GroupLayout                       ← 原 Track A
└── activeGroupId: String
```

GroupLayout 不是独立模块——它是 Service 的内部组件。`splitGroup(groupId, axis)` 是 Service API（[editor-shell-service.md](../../../architecture/modules/core-editor/editor-shell-service.md) 第 49 行），split 操作同时创建布局节点和编辑器 group（[group-layout.md](../../../architecture/modules/core-editor/group-layout.md) 第 50 行："新 group 初始化：复制源 group 的 activeTab"）。

**结论**：布局（Track A）和编辑器状态（Track B）的所有权统一在 EditorShellService 下，无法独立交付。

### 原 PR 映射的坍缩

| 原 PR | 原 Track | 新映射 |
|-------|---------|--------|
| PR-0301（递归布局） | Track A | `PR-RB-06` — GroupLayout 是 EditorShellService 内部组件 |
| PR-0301B（EditorShellService） | Track B | `PR-RB-06` — Service 是核心提取目标 |
| PR-0302（drag-to-split） | Track A | `PR-RB-06` — splitGroup() 是 Service API，multi-pane split/close/resize 一并落地 |
| PR-0303（buffer 同步） | Track B | `PR-RB-08` — EditBuffer 状态机 + 跨 pane 同步 |
| PR-0304（tab 模型） | Track B | `PR-RB-06` — EditorGroupModel 是 Service 内部组件 |
| PR-0305（性能） | 交叉 | `PR-RB-08` — DI-4 SLA 性能验证 |

原六个 PR 坍缩为两个主要 PR（`PR-RB-06` + `PR-RB-08`），并新增 `PR-RB-07`（布局持久化，DI-3）和 `PR-RB-09`（EditorResolver，DI-10）作为独立关注点。

---

## 重排后的交付结构

### 重排原则

取代三 Track 并行模型，重排序列遵循以下原则（[rebaseline §2](../../../releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md)）：

1. **先闭合语义和数据契约**（S8/S1/S4/S7），再做编辑器基础设施（S2/DI）
2. 所有跨 feature 基础设施提升到 `lib/core/`（S9）
3. v0.3 只承诺本地工作流闭环
4. 每个 PR 可独立回归，不引入一次性大爆炸合并路径

### 依赖图

```
阶段一 — 语义与契约
RB-00 → RB-01 → RB-02 → RB-03 ─┬→ RB-04 (S7)
                                  └→ RB-05 (S9)
                                     [Gate A]

阶段二 — 编辑器基础设施
RB-01 + RB-02 → RB-06 → RB-07 → RB-08 → RB-09
                                     [Gate B]

收口
RB-03 + RB-05 → RB-10 → RB-11
```

阶段二的硬依赖仅为 `PR-RB-01`（S8 DTO）+ `PR-RB-02`（S1 字段），不依赖 `PR-RB-03/04/05`。建议执行顺序仍为先完成阶段一再启动阶段二（[rebaseline §7](../../../releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md)），但依赖关系允许在 `PR-RB-02` 完成后提前启动 `PR-RB-06`。

### 增量交付价值

审计报告 §5.4 的担忧——每条 Track 单独交付价值有限——在重排后已解决：

| 阶段 | PR | 单独完成后的价值 | 评估 |
|------|-----|---------------|------|
| 数据基础 | PR-RB-01 | S8 消除 NoteItem/AtomListItem 信息断裂 | ✅ FFI 类型统一 |
| 数据基础 | PR-RB-02 | title/content_type/view_hint 全链路贯通 | ✅ 模型现代化 |
| 语义闭合 | PR-RB-03 | 创建路径统一，消除"组织孤儿" | ✅ 独立用户价值 |
| 语义闭合 | PR-RB-04 | 提醒与 Atom 生命周期对齐 | ✅ 行为正确性 |
| 语义闭合 | PR-RB-05 | core-workspace 独立，Rule E 违规消解 | ✅ 架构价值 |
| 编辑器 M1 | PR-RB-06 | 多 pane split/close/resize 首次可用 | ✅ 首个用户可见新功能 |
| 编辑器 | PR-RB-07 | 布局重启恢复 | ✅ 体验必备 |
| 编辑器 M2 | PR-RB-08 | 同一 Atom 跨 pane 编辑可用 | ✅ "IDE 级工作区"核心交付 |
| 编辑器 | PR-RB-09 | content_type 感知编辑器 | ✅ 渐进增强 |
| 验证 | PR-RB-10 | Tag 面板验证 atom_ref + openTab 架构 | ✅ 架构验证 |

每个 PR 独立可测试、可合并。v0.2 基线提供完整的功能兜底——没有"从零到一"的风险。

---

## Gate 结构

重排后采用两级 Gate（替代原单一 Phase 1 Gate），加上 Release Gate：

### Gate A — 语义与契约（PR-RB-05 后）

| 验证项 | 标准 |
|--------|------|
| NoteItem 消除 | 手写业务代码中不再依赖 `NoteItem`（生成绑定文件除外） |
| atom_ref 伴随 | 所有创建入口都可观察到对应 `atom_ref` |
| 提醒调度 | Tasks/Calendar 页面不再承担提醒调度入口 |

### Gate B — 编辑器基础设施（PR-RB-09 后）

| 验证项 | 标准 |
|--------|------|
| 多 pane（M1） | split/close/resize 可用，支持不同 atom 并行查看 |
| 跨 pane 编辑（M2） | 同一 Atom 跨 pane 编辑可用，实时同步、光标独立 |
| DI-0 | 命名冲突消除（`NoteTabStrip` / `EditorGroupModel`） |
| DI-1/2 | group 生命周期、primary group 不消失、递归布局不变式成立 |
| DI-3 | 布局重启恢复与损坏 fallback 成立 |
| DI-4/5 | 跨 pane 内容实时一致、`_rev` 防陈旧、光标独立、无额外冲突机制 |

### Release Gate（v0.3）

标准 CI 通过：`cargo fmt/clippy/test` + `dart format/analyze/flutter test`。

Gate 具体执行方案待 DI-7 裁决。

---

## 关联

- ← DI-1（EditorShellService 统一 layout + editor state → Track A/B 不可分离）
- ← DI-2/DI-3（GroupLayout 树结构 + 持久化 → PR-RB-06/07 scope）
- ← DI-4/DI-5（buffer 同步 + 光标 → PR-RB-08 scope）
- ← S2 Phase 2（EditorShellService 提取 → PR-RB-06 执行蓝图）
- ← S9（`lib/core/editor/` + `lib/core/workspace/` → PR-RB-05/06）
- ← 09-acceptance-report §7.1（coordinator_impl 1,514 行 → PR-RB-06 提取后减重）
- → DI-7（Gate 具体标准 + 性能基线 + 测试策略）
- → [v0.3-pr-spec-rebaseline-2026-03-01.md](../../../releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md)（权威执行方案）
- ← 01 审计报告 §5.3 + §5.4

---

*前序议题：[DI-5 光标和冲突](DI-5-cursor-and-conflict.md)*
*下一个议题：[DI-7 Gate + 性能 + 测试](DI-7-gates-perf-testing.md)*
