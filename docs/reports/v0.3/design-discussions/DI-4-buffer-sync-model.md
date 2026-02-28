# DI-4: Buffer 同步模型 + 粒度

| 项目 | 值 |
|------|-----|
| **状态** | OPEN |
| **关联决策点** | D10、D11 |
| **阻塞 PR** | PR-0303（直接）、PR-0305（间接） |
| **前置依赖** | DI-1（D1/D2 确定 buffer 放在哪） |
| **来源** | 01-design-readiness-audit.md §4.3 |

---

## 问题提取

### 来源 §1 执行摘要

> **Buffer 同步架构未决定**（阻塞 PR-0303/0305 spec）— 当前 `NoteEditor` 使用 per-instance `TextEditingController`，无跨实例同步。同步模型的选型（共享 buffer / 事件驱动 / 集中式 store）直接决定 spec 内容。

### 来源 §4.3 设计空白详析

> ```dart
> // note_editor.dart L1-110（当前实现）
> class NoteEditor extends StatefulWidget {
>   final String content;
>   final ValueChanged<String> onChanged;
>   // per-instance TextEditingController — 无跨实例同步
> }
> ```
>
> 每个 editor widget 实例拥有独立的 `TextEditingController`。对于同一笔记在多个 pane 中打开的场景，当前代码 **无任何同步机制**。

### 设计决策（审计报告原文）

| # | 决策点 | 选项 | 影响范围 |
|---|--------|------|---------|
| D10 | 同步模型 | A: 共享 Controller / B: 事件广播 / C: 集中式 BufferStore | PR-0303 核心实现 |
| D11 | 同步粒度 | A: 全量替换 / B: 差分 patch / C: 按段（段落级） | PR-0303 + PR-0305 性能 |

### 审计报告 §6.3 — 执行方法论评估

> DI-3 Buffer 同步 → **方案 B（文档 + 原型）**
>
> 理由：多实例 TextEditingController 同步在 Flutter 中缺少成熟先例。共享 controller 是否可行？事件广播的延迟特性？需要原型验证。
>
> 建议在独立分支上编写最小原型（2 个 pane + 同一 note 的 TextEditingController 同步），验证同步模型后再固化到设计文档。原型代码不需要合入 main，仅作为设计证据。

---

## 待讨论

1. **D10**：三种同步模型的可行性和权衡
2. **D11**：同步粒度对性能的影响，特别是长文档场景
3. 是否同意采用"文档 + 原型"（方案 B）的 DI 方法论？
4. 原型验证的最小 scope 是什么？

---

## 关联

- ← DI-1（D1/D2 确定 EditorShellService 接口和 buffer 归属）
- → DI-5（光标/冲突处理建立在同步模型之上）
- → DI-7（性能基线与同步粒度相关）
- ← 01 审计报告 §4.3 + §6.3

---

*前序议题：[DI-3 布局持久化](DI-3-layout-persistence.md)*
*下一个议题：[DI-5 光标独立性 + 冲突处理](DI-5-cursor-and-conflict.md)*
