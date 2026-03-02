# Module Specs

> 按代码模块组织的实现指导文档。每个 spec 对应 `lib/core/` 下的一个具体模块，蒸馏自 DIs（设计讨论）和 Rulings（语义裁决）中的最终决策。
>
> **文档层级定位**：Rulings 回答 "why"（约束与决策），DIs 回答 "how decided"（分析过程），**Module Specs 回答 "how to build"**（接口、状态、生命周期、约束）。

---

## 索引

### `core-editor/` — 编辑器 Workbench 基础设施

| Spec | 文件位置 | 设计来源 |
|------|---------|---------|
| [EditorShellService](core-editor/editor-shell-service.md) | `lib/core/editor/editor_shell_service.dart` | S2 Phase 2, DI-1 |
| [EditBuffer](core-editor/edit-buffer.md) | `lib/core/editor/edit_buffer.dart` | DI-1 Q3, DI-4 D10/D11/D12 |
| [EditorGroupModel](core-editor/editor-group-model.md) | `lib/core/editor/editor_group_model.dart` | DI-1 Q1/Q2 |
| [GroupLayout](core-editor/group-layout.md) | `lib/core/editor/group_layout.dart` | DI-1, DI-3 |
| [LayoutPersistence](core-editor/layout-persistence.md) | `lib/core/editor/layout_persistence.dart` | DI-3 |
| [EditorResolver](core-editor/editor-resolver.md) | `lib/core/editor/editor_resolver.dart` | DI-10, S2 Phase 3 |

### `core-workspace/` — 组织结构基础设施

| Spec | 文件位置 | 设计来源 |
|------|---------|---------|
| [WorkspaceTreeService](core-workspace/workspace-tree-service.md) | `lib/core/workspace/workspace_tree_service.dart` | DI-1 Q4.3, S9, S1 R5/R6, DI-12(v0.4 addendum) |

### `core-reminders/` — 通知基础设施

| Spec | 文件位置 | 设计来源 |
|------|---------|---------|
| [ReminderScheduler](core-reminders/reminder-scheduler.md) | `lib/core/reminders/reminder_scheduler.dart` | S7, 08b |

---

## 编写原则

1. **蒸馏而非复制** — 提取最终决策和接口，不重复 DI 的分析过程
2. **接口优先** — 每个 spec 必须包含：公共 API、状态字段、生命周期规则、约束
3. **双向链接** — spec 链接到 ruling/DI 来源，ruling/DI 链接回 spec
4. **实现可读** — 开发者读 spec 即可开始编码，不需要翻阅多个 DI 文档
