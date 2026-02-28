# DI-6: 跨 Track 隐藏依赖 + 增量交付

| 项目 | 值 |
|------|-----|
| **状态** | OPEN |
| **关联决策点** | 无编号（§5.3 + §5.4 提出的工程问题） |
| **影响 PR** | PR-0302（隐藏依赖）、Phase 1 整体（增量交付） |
| **前置依赖** | 无 |
| **来源** | 01-design-readiness-audit.md §5.3 + §5.4 |

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

## 待讨论

1. PR-0302 是否真的对 PR-0301B 有硬依赖？如何在 spec 中处理这个边界？
2. Phase 1 三条 Track 的合并时序 — 是否需要一个集成测试阶段？
3. 是否调整依赖图以反映隐藏依赖？

---

## 关联

- ← DI-1（EditorShellService 接口影响 pane 注册方式）
- → DI-7（Phase 1 Gate 作为整体交付门禁）
- ← 01 审计报告 §5.3 + §5.4

---

*前序议题：[DI-5 光标和冲突](DI-5-cursor-and-conflict.md)*
*下一个议题：[DI-7 Gate + 性能 + 测试](DI-7-gates-perf-testing.md)*
