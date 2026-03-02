# PR-RB-05: S9 core-workspace 抽取

- Proposed title: `refactor(frontend): PR-RB-05 extract workspace tree and layout to lib/core/workspace/`
- Status: Draft

## Goal

按 S9 ruling 将 workspace 相关模块从 `features/notes/managers/` 和 `features/workspace/` 迁移到 `lib/core/workspace/`，消除跨 feature 依赖（notes → workspace 的 Rule E 违规）。`WorkspaceTreeManager` 重命名为 `WorkspaceTreeService`。

前置条件：PR-RB-03（`atom_ref` 升级完成，workspace 模型稳定）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| Ruling | `docs/architecture/rulings/S9-cross-feature-infrastructure-placement.md` | 定义 `core/workspace/` 目标结构 |
| Ruling | Rule E (`docs/architecture/engineering-standards.md`) | 跨 feature import 禁止 |
| DI-1 | `docs/reports/v0.3/design-discussions/DI-1-editor-shell-service.md` | workspace 作为 core 基础设施的定位 |
| Rebaseline | `docs/releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md` §4 PR-RB-05 | Scope + 依赖 |
| Acceptance Report | `09-acceptance-report.md` §7.1 | `coordinator_impl` 1,514 行 → 提取后减重 |

## 当前文件分布

### `features/workspace/`（2 文件，pane layout）

| 文件 | 行数 | 内容 |
|------|------|------|
| `workspace_provider.dart` | 167 | `WorkspaceProvider` — pane split/merge layout 管理 |
| `workspace_models.dart` | 67 | `WorkspaceLayoutState`、`WorkspaceSplitDirection`、split/merge result 类型 |

### `features/notes/managers/`（4 文件，workspace tree）

| 文件 | 行数 | 内容 |
|------|------|------|
| `workspace_tree_manager.dart` | 529 | tree CRUD、状态跟踪、revision counter |
| `workspace_tree_types.dart` | 55 | 13 个 typedef（injectable FFI invokers + hooks） |
| `workspace_tree_children_loader.dart` | 380 | 子节点加载、uncategorized 投影 |
| `workspace_tree_error_utils.dart` | 34 | 错误格式化工具 |

### 消费者

| 消费者 | 导入来源 | 用途 |
|--------|---------|------|
| `notes_coordinator.dart` | `features/workspace/*` + `managers/workspace_tree_*` | 构造 + 委托 |
| `notes_coordinator_impl.dart` | 同上 | FFI invoker 注入 |
| `notes_page.dart` | `features/workspace/*` | pane layout UI |
| 11 个测试文件 | 各种 workspace 导入 | 测试 |

## 迁移方案

### 目标结构

```
lib/core/workspace/
├── workspace_tree_service.dart          ← features/notes/managers/workspace_tree_manager.dart (重命名)
├── workspace_tree_types.dart            ← features/notes/managers/workspace_tree_types.dart
├── workspace_tree_children_loader.dart  ← features/notes/managers/workspace_tree_children_loader.dart
├── workspace_tree_error_utils.dart      ← features/notes/managers/workspace_tree_error_utils.dart
├── workspace_provider.dart              ← features/workspace/workspace_provider.dart
└── workspace_models.dart                ← features/workspace/workspace_models.dart
```

迁移后 `features/workspace/` 目录删除。`features/notes/managers/` 中 workspace 文件删除。

### Notes-specific 回调保持不变

`WorkspaceTreeService`（原 Manager）的构造函数接受 injectable callbacks（`WorkspaceCreateNoteAndGetAtomId`、`WorkspaceFlushPendingSave` 等）。这些回调由 `NotesCoordinator` 注入，是 coordinator 层的编排逻辑，不是 workspace 的内部依赖。DI-1 确认保持此 injectable 模式。

### Module 字符串更新

`DartEventLogger` 模块标识从 `'notes.workspace_tree_manager'` 更新为 `'core.workspace_tree_service'`。

## Scope

In scope:

- 移动 6 个文件到 `lib/core/workspace/`
- `WorkspaceTreeManager` → `WorkspaceTreeService` 重命名（类名 + 文件名）
- 更新全部消费者导入路径
- 更新全部测试文件导入路径
- 删除空的 `features/workspace/` 目录
- `notes_coordinator.dart` re-export 路径更新
- DartEventLogger module 字符串更新
- `architecture_check.dart` Rule E allowlist 移除 `notes → workspace` 条目（violation 已消除）

Out of scope:

- `WorkspaceTreeService` 内部逻辑变更（仅移动 + 重命名）
- notes-specific callback 接口重构（保持 injectable 模式）
- `WorkspaceProvider` 逻辑变更（仅移动）

## Task Breakdown

### Phase 1: 创建目录 + 移动文件

| Task | 内容 | 变更 | 依赖 |
|------|------|------|------|
| T1 | 创建 `lib/core/workspace/` 目录 | 新目录 | — |
| T2 | 移动 `workspace_models.dart` → `core/workspace/` | move | T1 |
| T3 | 移动 `workspace_provider.dart` → `core/workspace/` | move | T1 |
| T4 | 移动 + 重命名 `workspace_tree_manager.dart` → `core/workspace/workspace_tree_service.dart` | move + rename class | T1 |
| T5 | 移动 `workspace_tree_types.dart` → `core/workspace/` | move | T1 |
| T6 | 移动 `workspace_tree_children_loader.dart` → `core/workspace/` | move | T1 |
| T7 | 移动 `workspace_tree_error_utils.dart` → `core/workspace/` | move | T1 |

### Phase 2: 内部引用更新

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T8 | 各 `core/workspace/*.dart` 文件之间的相互引用更新 | 6 files | 编辑 import 路径 | T2~T7 |
| T9 | `WorkspaceTreeManager` → `WorkspaceTreeService` 类名重命名（文件内全局替换） | `workspace_tree_service.dart` | 编辑 | T4 |
| T10 | DartEventLogger module 字符串更新 | `workspace_tree_service.dart` | 编辑 `'notes.workspace_tree_manager'` → `'core.workspace_tree_service'` | T4 |

### Phase 3: 消费者导入更新

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T11 | `notes_coordinator.dart` re-export 路径更新 | `notes_coordinator.dart` | 编辑 export 语句 | T8 |
| T12 | `notes_coordinator_impl.dart` import 更新 + `WorkspaceTreeManager` → `WorkspaceTreeService` | `notes_coordinator_impl.dart` | 编辑 | T9 |
| T13 | `notes_page.dart` import 更新 | `notes_page.dart` | 编辑 | T8 |
| T14 | 其他 Flutter 文件中 `features/workspace/` import 更新（`rg` 扫描） | 各文件 | 编辑 | T8 |

### Phase 4: 测试 + 清理

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T15 | 11 个测试文件 import 路径更新 | `test/*.dart` | 编辑 | T8 |
| T16 | 删除空 `lib/features/workspace/` 目录 | 目录删除 | T2, T3 |
| T17 | `architecture_check.dart` Rule E allowlist 移除 `notes → workspace` | `tools/ci/rule_e_allowlist.yaml` | 编辑 | T16 |

### Phase 5: 文档

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T18 | 更新 `CLAUDE.md` 路径表 | `CLAUDE.md` | 编辑 | T16 |
| T19 | 更新 `overview.md` 路径表 | `docs/architecture/overview.md` | 编辑 | T16 |
| T20 | `S9-cross-feature-infrastructure-placement.md` 标注 workspace 部分 implemented | rulings | 编辑 | T16 |

### Critical Path

```
T1 → T2~T7 (并行移动) → T8/T9/T10 → T11~T14 (并行) → T15 → T16 → T17~T20 (并行)
```

## Planned File Changes

### 移动（6 files）
- `[move]` `lib/features/workspace/workspace_models.dart` → `lib/core/workspace/`
- `[move]` `lib/features/workspace/workspace_provider.dart` → `lib/core/workspace/`
- `[move+rename]` `lib/features/notes/managers/workspace_tree_manager.dart` → `lib/core/workspace/workspace_tree_service.dart`
- `[move]` `lib/features/notes/managers/workspace_tree_types.dart` → `lib/core/workspace/`
- `[move]` `lib/features/notes/managers/workspace_tree_children_loader.dart` → `lib/core/workspace/`
- `[move]` `lib/features/notes/managers/workspace_tree_error_utils.dart` → `lib/core/workspace/`

### 编辑（消费者）
- `[edit]` `lib/features/notes/notes_coordinator.dart`
- `[edit]` `lib/features/notes/notes_coordinator_impl.dart`
- `[edit]` `lib/features/notes/notes_page.dart`
- `[edit]` 其他引用 `features/workspace/` 的文件

### 删除
- `[delete]` `lib/features/workspace/` 目录

### CI / Docs
- `[edit]` `tools/ci/rule_e_allowlist.yaml`
- `[edit]` `CLAUDE.md`
- `[edit]` `docs/architecture/overview.md`
- `[edit]` `docs/architecture/rulings/S9-cross-feature-infrastructure-placement.md`

## Verification

### CI gates

```bash
cd apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

### Structural verification

```bash
# features/workspace/ 目录不存在
test ! -d apps/lazynote_flutter/lib/features/workspace

# core/workspace/ 目录存在且包含 6 文件
ls apps/lazynote_flutter/lib/core/workspace/
# Expected: 6 .dart files

# 无 features/workspace import 残留
rg "features/workspace" apps/lazynote_flutter/lib/ --type dart
# Expected: zero matches

# WorkspaceTreeManager 类名归零（应为 WorkspaceTreeService）
rg "WorkspaceTreeManager" apps/lazynote_flutter/lib/ --type dart
# Expected: zero matches

# Rule E allowlist 不再包含 notes → workspace
rg "notes.*workspace" tools/ci/rule_e_allowlist.yaml
# Expected: zero matches

# architecture_check 通过
cd apps/lazynote_flutter && dart run ../../tools/ci/architecture_check.dart
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| Import 路径遗漏 | MEDIUM | `flutter analyze` 编译错误自动暴露；`rg "features/workspace"` 扫描 |
| Re-export 链断裂导致外部 API 变化 | LOW | `notes_coordinator.dart` re-export 更新为新路径即可 |
| 测试 import 遗漏 | LOW | `flutter test` 编译失败暴露 |

## Test Baseline

Entry: PR-RB-03 exit count（或 PR-RB-04 exit count，取决于执行顺序）
Exit: **= 入口 count**（纯移动，无测试删减或新增）

## Acceptance Criteria

- [ ] `lib/core/workspace/` 包含 6 个文件
- [ ] `lib/features/workspace/` 目录已删除
- [ ] `features/notes/managers/` 中无 workspace 文件
- [ ] `WorkspaceTreeManager` 已重命名为 `WorkspaceTreeService`
- [ ] `architecture_check.dart` Rule E allowlist 不含 `notes → workspace`
- [ ] §Verification CI gates 全部通过（逐项执行并记录输出）
