# DI-5: 光标独立性 + 冲突处理

| 项目 | 值 |
|------|-----|
| **状态** | **RESOLVED** — D12、D13 全部裁决完毕 |
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

## 裁决总结

DI-5 的全部决策点在 DI-4 裁决过程中已被实质性解决。DI-5 确认并记录这些逻辑推论，不引入新的架构约束。

| 决策 | 裁决 | 依据 |
|------|------|------|
| D12 光标独立性 | **各 pane 光标独立** | DI-4 Q1 排除共享 TextEditingController 的逻辑推论；符合 VSCode/IntelliJ 用户心智 |
| D13 冲突处理 | **无需专门机制** | 单线程 + 排他焦点 = 无并发写入；save race 已由 `_rev` stale check 覆盖 |
| 同步频率 | **已由 DI-4 Q1 解构为两层，DI-5 无需新增裁决** | buffer 通知层无条件每次击键触发；消费者响应层各自自决去抖策略 |

---

## D12: 光标独立性 — RESOLVED

### DI-4 已有证据链

1. **DI-4 Q1 排除共享 TextEditingController**：`TextEditingController` 包含 `selection`（光标 + 选区），共享 = 所有 pane 光标位置锁定，判定**不可行**
2. **DI-4 Q1 光标行为声明**：「只有焦点 pane 显示光标（Flutter 默认行为），非焦点 pane 只显示文本」
3. **DI-4 Q3 桥接机制**：确定 manual listener + 每 pane 独立 `TextEditingController` 的模式

三条裁决的逻辑推论 = 光标必然独立。选项 B（光标同步）在技术上已被排除。

### 用户场景验证

| 场景 | 独立光标表现 | 同步光标表现 |
|------|------------|------------|
| 对照编辑（看第 1 段写第 10 段） | Pane A 光标在段 1，Pane B 光标在段 10 — **正确** | 两个 pane 光标都在段 10 — **场景失效** |
| 参考引用（一边看一边写） | 阅读 pane 光标停留在参考位置 — **正确** | 阅读 pane 光标跟着跳 — **干扰阅读** |
| Split 后各自操作 | 各自独立 — **符合 VSCode/IntelliJ 行为** | 不符合任何已知 IDE 行为 |

### 裁决

**D12 = 选项 A（各 pane 光标独立）。** 这是 DI-4 架构选择的必然推论。

---

## D13: 冲突处理 — RESOLVED

### 核心判断：本地同一进程内不存在真正的冲突

**原因分析**：

1. **键盘焦点排他性**：用户在任一时刻只能在一个 pane 中打字。Dart 单线程事件循环保证 `buffer.edit()` 调用是原子串行的——两个 `edit()` 调用不可能交叉执行。

2. **数据流单向串行**：
```
用户在 Pane A 键入 → TextField.onChanged → buffer.edit(newContent)
  → _content 原子替换 → _rev++ → notifyListeners()
  → Pane B._onBufferChanged: controller.text = newContent（字符串比较 guard）
```
整个链路在同一帧或相邻帧内完成。不存在 Pane A 和 Pane B 同时写入 buffer 的窗口。

3. **Save race 已由 `_rev` 解决**（DI-4 Q3 + DI-1 Q3）：debounce 调度保存时记录 `scheduledRev`，保存执行时检查 `currentRev == scheduledRev`，过时则丢弃。

### 三选项评估

| 选项 | 评估 |
|------|------|
| A: Last-write-wins | **天然行为** — 单线程 + 排他焦点 = 后写覆盖前写，这就是正常编辑 |
| B: 禁止同时编辑 | **不需要** — 物理上已不可能同时编辑（单键盘焦点） |
| C: Operational Transform | **严重过度设计** — OT 解决网络延迟下的并发，本地无网络延迟 |

### 边界场景检查

| 场景 | 是否冲突 | 处理 |
|------|---------|------|
| 用户在 Pane A 快速打字，Pane B 实时更新 | 否 | DI-4 Q1 实时同步正常工作 |
| 用户在 Pane A 打字期间 save 完成 | 否 | `_rev` stale check |
| 用户切换到 Pane B 打字 | 否 | 焦点切换后 Pane B 的 controller 已同步为最新内容 |
| 程序化修改（find-replace）+ 用户同时打字 | 否 | find-replace 调用 `buffer.edit()`，串行执行 |
| 外部 Provider 同步推入新内容 | **潜在冲突** | v0.3 无 provider sync 实现；v0.4+ 属 S6 裁决域 |

### 裁决

**D13 = 无需专门冲突处理机制。** 「Last-write-wins」不是一种策略选择，而是单线程单焦点架构的天然行为。

---

## 同步频率：已由 DI-4 解构

DI-5 原文「同步频率（即时 vs debounce）」已由 DI-4 Q1 解构为两层模型，DI-5 无需新增裁决：

| 层 | 裁决 | 频率 | 来源 |
|---|------|------|------|
| Buffer 通知层 | `edit()` → `notifyListeners()` 无条件触发 | 每次击键 | DI-4 Q1 |
| 消费者响应层 | 各消费者自行决定响应策略 | **下放至各 EditorPane / 预览 / 大纲自决** | DI-4 Q1 消费者分层原则 |

核心原则：**通知无条件，消费有策略**（DI-4 Q1 裁决）。

---

## 开放项记录（不阻塞 DI-5 关闭）

| 项 | 归属 | 说明 |
|---|------|------|
| Undo/Redo 跨 pane 语义 | 独立设计项 | 已有 `docs/product/idea_temp/undo-redo-architecture.md` 占位 |
| Scroll position 独立性 | UI 实现细节 | 必然独立（split 核心价值 = 看不同位置），不需裁决 |

---

## 关联

- ← DI-4（D10/D11 同步模型和粒度，Q1 排除共享 controller，Q3 桥接机制）
- ← DI-1（Q3 EditBuffer 统一 draft + save）
- ← 01 审计报告 §4.3
- → `docs/product/idea_temp/undo-redo-architecture.md`（开放项）

---

*前序议题：[DI-4 Buffer 同步模型](DI-4-buffer-sync-model.md)*
*下一个议题：[DI-6 跨 Track 隐藏依赖](DI-6-cross-track-dependencies.md)*
