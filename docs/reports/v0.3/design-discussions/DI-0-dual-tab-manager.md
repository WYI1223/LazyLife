# DI-0: 双版本 NoteTabManager 关系确认

| 项目 | 值 |
|------|-----|
| **状态** | RESOLVED |
| **关联决策点** | D4 |
| **阻塞 PR** | PR-0301B |
| **前置依赖** | 无 |
| **来源** | 01-design-readiness-audit.md §2.2、§4.1 D4 |

---

## 问题提取

### 来源 §2.2

> `note_tab_manager.dart` 存在两个版本 — `managers/note_tab_manager.dart`（440 行）和根级 `note_tab_manager.dart`（422 行）。PR-0301B spec 需要首先澄清哪个是规范版本，或者两者的关系。

### 来源 §4.1 D4

| # | 决策点 | 选项 | 影响范围 |
|---|--------|------|---------|
| D4 | 双版本 NoteTabManager | 规范版本是哪个？另一个的去留？ | PR-0301B 实施范围 |

### 代码基线

| 文件 | 行数 | 角色（审计描述） |
|------|------|------|
| `managers/note_tab_manager.dart` | 440 | Per-pane tab 状态管理 |
| `note_tab_manager.dart`（根级） | 422 | Tab 管理器（v0.2 遗留） |

---

## 调查事实

两个文件是**正交层的不同组件**，不是同一个东西的两个版本：

| 维度 | `managers/note_tab_manager.dart` | `note_tab_manager.dart`（根级） |
|------|-----|-----|
| 类名 | `NoteTabStateManager extends ChangeNotifier` | `NoteTabManager extends StatefulWidget` |
| 性质 | 纯逻辑类 — 状态管理，无 UI | UI widget — 渲染 tab 条 |
| 职责 | open/close/activate/preview 状态，per-pane tab 列表 | 渲染 tab chip、处理点击/右键菜单/滚轮 |
| 所有者 | `NotesCoordinator`（私有字段） | `NotesPage._buildEditorPane()` |
| 两者关系 | 无直接引用。widget 通过 coordinator 间接访问 state manager |

### 关键参考：S2 裁决

S2 Phase 2（`docs/architecture/rulings/S2-tab-draft-save-ownership.md`）已定义提取路径：

> 从 coordinator 提取 `NoteTabManager` → `EditorGroupModel[]`

即 `NoteTabStateManager` 在 PR-0301B 中将重命名为 `EditorGroupModel`。逻辑类的命名冲突由 S2 自然消除。

---

## D4 裁决

**两者均保留，不存在"二选一"问题。两者分别按以下路径重命名：**

| 文件 | 当前类名 | 目标类名 | 目标文件名 | 时机 | 依据 |
|------|---------|---------|-----------|------|------|
| `managers/note_tab_manager.dart` | `NoteTabStateManager` | `EditorGroupModel` | `lib/core/editor/editor_group_model.dart`（DI-1 Q5 已确定） | PR-0301B | S2 Phase 2 |
| `note_tab_manager.dart`（根级） | `NoteTabManager` | `NoteTabStrip` | `note_tab_strip.dart` | PR-0300D | 本裁决 |

### widget 重命名影响范围

| 文件 | 变更 |
|------|------|
| `notes_page.dart:12` | import 路径更新 |
| `tab_open_intent_migration_test.dart:4` | import 路径更新 |
| `notes_ui_shell_alignment_test.dart:70,112` | `Key('note_tab_manager')` → `Key('note_tab_strip')` |

### 影响 PR spec

- **PR-0300D**：scope 中增加 widget 重命名（`NoteTabManager` → `NoteTabStrip`）
- **PR-0301B**：spec 中明确提取源为 `NoteTabStateManager`，目标名称 `EditorGroupModel`（S2 已定义）

---

## 关联

- → DI-1（EditorShellService 接口，**RESOLVED**）：提取源 = `NoteTabStateManager`，目标 = `EditorGroupModel`（含 `TabEntry { atomId, title }`），位置 = `lib/core/editor/`
- ← S2 裁决（`docs/architecture/rulings/S2-tab-draft-save-ownership.md`）
- ← 01 审计报告 §2.2 + §4.1

---

*下一个议题：[DI-1 EditorShellService 接口](DI-1-editor-shell-service.md)*
