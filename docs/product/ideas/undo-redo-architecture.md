# Idea: Undo/Redo 架构考量

| 项目 | 值 |
|------|-----|
| **来源** | DI-1 Q3 细化讨论（EditBuffer 设计） |
| **优先级** | 未定 |
| **关联** | EditBuffer、多 Pane 编辑、DI-4（Buffer 同步）、DI-5（光标/冲突） |

---

## 背景

在设计 EditBuffer（统一 draft + save 状态的 per-atom 对象）时，分析了 Undo（Ctrl+Z）与 dirty 判定的交互关系。结论：当前设计天然兼容 undo，但未来可能需要更深入的 undo 架构设计。

## 当前结论（v0.3 EditBuffer 层面）

- Undo 由 Flutter `TextEditingController` 内置 undo 栈在 widget 层处理
- EditBuffer 只通过 `onChanged` 接收结果内容，undo 和普通编辑无区别
- `isDirty` 采用字符串比较（`content != lastSavedContent`），undo 回退到已保存内容时正确归 false
- `_editVersion` 仅用于防陈旧保存，不参与 dirty 判定

## 未来可能的演进方向

### 1. 多 Pane Undo 隔离

同一笔记在 Pane A 和 Pane B 同时编辑时，各 pane 的 `TextEditingController` 有独立的 undo 栈。
- Pane A 输入 "abc" → Pane B 同步收到 "abc"（但 B 的 undo 栈没有这条记录）
- 用户在 Pane B 按 Ctrl+Z → 不会撤销 "abc"（因为 B 没有对应的 undo entry）
- 这是否是期望行为？VS Code 采用此模型（各 editor instance 独立 undo 栈）

### 2. 协作式 Undo（OT/CRDT）

如果未来引入多设备实时同步（sync provider），undo 语义会变得复杂：
- 本地 undo 应该只撤销本地操作，还是全局最后操作？
- 需要 Operation Transform 或 CRDT 来正确处理并发 undo
- 这与 `hlc_timestamp`（Atom 中已预留的 CRDT 字段）相关

### 3. 结构化 Undo（非纯文本）

如果编辑器未来支持块级编辑（如 Notion-style blocks），undo 粒度可能不再是字符级，而是块操作级。这需要自定义 undo 栈，脱离 TextEditingController 的内置实现。

## 备注

以上为长期思考方向，v0.3 不需要处理。当前 EditBuffer 的字符串比较 + widget 层 undo 栈是正确且充分的设计。
