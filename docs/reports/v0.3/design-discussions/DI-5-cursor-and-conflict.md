# DI-5: 光标独立性 + 冲突处理

| 项目 | 值 |
|------|-----|
| **状态** | OPEN |
| **关联决策点** | D12、D13 |
| **阻塞 PR** | PR-0303 |
| **前置依赖** | DI-4（D10 同步模型确定后才能讨论冲突） |
| **来源** | 01-design-readiness-audit.md §4.3 |

---

## 问题提取

### 来源 §4.3 PR-0303 设计问题清单

> 2. **光标处理**：多窗格编辑同一笔记时，光标位置是否同步？各自独立？
> 3. **冲突场景**：两个 pane 同时编辑同一行如何处理？

### 设计决策（审计报告原文）

| # | 决策点 | 选项 | 影响范围 |
|---|--------|------|---------|
| D12 | 光标独立性 | A: 各 pane 光标独立 / B: 光标也同步 | PR-0303 UX |
| D13 | 冲突处理 | A: Last-write-wins / B: 不允许同时编辑 / C: Operational Transform | PR-0303 复杂度 |

### PR-0303 spec 中的相关 AC

> - Editing note in pane A updates pane B view for same note.
> - Dirty/saving indicators are consistent across panes.
> - Stale async save completion cannot overwrite newer buffer content.

### 审计报告补充

> 性能影响：同步频率（每次击键？debounce？）对长文档的影响

---

## 待讨论

1. **D12**：光标同步 vs 独立 — UX 预期是什么？
2. **D13**：冲突处理 — 本地同一进程内是否需要 OT 级别的复杂度？
3. 同步频率（即时 vs debounce）和 UX 响应的平衡

---

## 关联

- ← DI-4（D10/D11 同步模型和粒度）
- ← 01 审计报告 §4.3

---

*前序议题：[DI-4 Buffer 同步模型](DI-4-buffer-sync-model.md)*
*下一个议题：[DI-6 跨 Track 隐藏依赖](DI-6-cross-track-dependencies.md)*
