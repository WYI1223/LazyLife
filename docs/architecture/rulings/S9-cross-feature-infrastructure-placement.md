# S9: 跨 feature 基础设施模块归属

| 字段 | 值 |
|------|-----|
| 状态 | **Accepted** — v0.3 PR-RB-05 实现 |
| 引入版本 | v0.2.5 (PR-0256) |
| 废弃者 | — |
| 裁决日期 | 2026-02-28 |
| 关联 PR | PR-0301B（EditorShellService 提取）、PR-0300D（WorkspaceTreeService 提取） |

---

## 决策

**被多个 feature 消费的基础设施模块归入 `lib/core/`，不放在任何 `lib/features/<name>/` 下。** 遵循 Rule E（features 不互相导入）和 S7 先例（Reminders → `core/`）。

---

## 规则

1. **Rule E 驱动**：若一个模块被 2 个以上 feature 导入，放在 `features/<name>/` 下会导致 Rule E 违规。该模块必须提升到 `lib/core/` 或 `lib/shared/`
2. **core vs shared 判定**：`lib/core/` 放平台/系统基础设施（状态管理、数据服务），`lib/shared/` 放跨 feature UI 原语（颜色常量、通用 widget）
3. **对称组织**：`lib/core/` 下按职责域分子目录（`editor/`、`workspace/`、`reminders/`、`settings/`），每个子目录是一个独立的基础设施模块

---

## 裁决实例

| 模块 | 来源 | 目标位置 | 消费者 | 裁决来源 |
|------|------|---------|--------|---------|
| EditorShellService | `features/notes/` coordinator 内部 | `lib/core/editor/` | NotesCoordinator，未来 TasksController / CalendarController | DI-1 Q5 |
| WorkspaceTreeService | `features/notes/managers/workspace_tree_manager.dart` | `lib/core/workspace/` | NotesCoordinator，未来 TasksController / CalendarController | DI-1 Q4.3 |
| ReminderScheduler | `features/reminders/` | `lib/core/reminders/` | main.dart, TasksController, CalendarController | S7（已完成） |

### EditorShellService — `lib/core/editor/`

```
lib/core/editor/
├── editor_shell_service.dart     ← 主 service（singleton）
├── editor_group_model.dart       ← EditorGroupModel + TabEntry
├── edit_buffer.dart              ← EditBuffer（per-atom 状态机）
├── group_layout.dart             ← GroupLayout（递归布局树，从 WorkspaceProvider 迁入）
├── layout_persistence.dart       ← 布局文件 I/O + 去抖 + atomic write（DI-3）
└── editor_resolver.dart          ← content_type → EditorPane（DI-10）
```

编辑器 workbench 骨架：管理 tab 模型、编辑缓冲区、pane 布局。设计细节见 S2 Phase 2 设计规则、DI-4（buffer 同步模型）、DI-10（EditorResolver）。

### WorkspaceTreeService — `lib/core/workspace/`

```
lib/core/workspace/
├── workspace_tree_service.dart    ← 从 features/notes/managers/ 搬入
└── workspace_models.dart          ← 从 features/workspace/ 迁入
```

组织结构基础设施：workspace tree CRUD 的 FFI 封装。语义依据见 S1 R6（指定默认路径模型）和 S3（Tag × Workspace 正交性）。

---

## `lib/core/` 目标结构

```
lib/core/
├── editor/                       ← EditorShellService（编辑器基础设施）
├── workspace/                    ← WorkspaceTreeService（组织结构基础设施）
├── reminders/                    ← ReminderScheduler（通知基础设施）— S7 已完成
├── settings/                     ← LocalSettingsStore（配置基础设施）
├── rust_bridge.dart              ← FRB facade
├── bindings/                     ← 自动生成的 FFI 绑定
├── local_paths.dart              ← 路径解析
├── debug/                        ← LogReader
└── diagnostics/                  ← DartEventLogger
```

---

## 理由

1. **Rule E 合规**：`core/` 被所有 features 合法引用，避免 features 互相导入
2. **S7 先例验证**：Reminders 迁移（PR-0259）证明此模式有效，Rule E violations 归零
3. **对称可预测**：开发者看到 `core/<domain>/` 就知道是跨 feature 基础设施，无需查阅文档
4. **渐进迁移**：每个模块独立搬迁，不需要一次性重构

---

## 实施状态

| 项目 | 状态 |
|------|------|
| ReminderScheduler → `core/reminders/` | **已完成** — PR-0259（S7） |
| EditorShellService → `core/editor/` | v0.3 待实施（设计完成 — DI-1） |
| WorkspaceTreeService → `core/workspace/` | v0.3 待实施（DI-1 Q4.3） |

---

## 关联

- ← S7（Reminders 先例）
- ← S2（EditorShellService 是 Phase 2 的目标产物）
- ← S1 R6 + S3（WorkspaceTreeService 独立提取的语义依据）
- ← DI-1 Q4.3, Q5（具体裁决）
- ← Rule E（`docs/architecture/engineering-standards.md`）
