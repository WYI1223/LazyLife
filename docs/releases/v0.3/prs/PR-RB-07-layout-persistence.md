# PR-RB-07: DI-3 布局持久化

- Proposed title: `feat(editor): PR-RB-07 layout persistence with atomic write and corruption recovery`
- Status: Merged

## Goal

实现 `workspace_layout.json` 持久化：序列化 `GroupLayout` + per-group tab 列表到 JSON 文件，1s 去抖写入，atomic write 防损坏，启动时两阶段恢复 Phase-1（纯结构恢复，无 FFI 依赖）。

前置条件：PR-RB-06（GroupLayout + EditorGroupModel 已落地，已合并。`GroupLayout.toJson()/fromJson()` 树序列化已落地）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI-3 | `DI-3-layout-persistence.md` D7/D8/D9 | 持久化格式 / atomic write / corruption recovery / 8 pane 限制 |
| Module Spec | `modules/core-editor/layout-persistence.md` | LayoutPersistence API + 两层分离（data conversion / file I/O） |
| DI-1 Q2 | `DI-1-editor-shell-service.md` | group 零 tab + `groups.length > 1` 时 auto-collapse → tab list 和 layout 必须联合序列化 |
| DI-7 | `DI-7-gates-perf-testing.md` Q2-SLA | startup recovery <200ms（CI guard <1000ms） |
| Rebaseline | `v0.3-pr-spec-rebaseline-2026-03-01.md` §4 PR-RB-07 | Scope + 依赖 |

## 设计方案

### JSON Schema (v1)

```json
{
  "schema_version": 1,
  "activeGroupId": "g1",
  "layout": {
    "type": "split",
    "axis": "horizontal",
    "fraction": 0.5,
    "first": { "type": "leaf", "groupId": "g1" },
    "second": { "type": "leaf", "groupId": "g2" }
  },
  "groups": {
    "g1": { "tabs": ["atom-uuid-1", "atom-uuid-2"], "activeTab": "atom-uuid-1", "previewTab": null },
    "g2": { "tabs": ["atom-uuid-3"], "activeTab": "atom-uuid-3", "previewTab": null }
  }
}
```

**序列化内容**：tree structure + axis/fraction + groupId + per-group tabs/activeTab/previewTab + activeGroupId。

**不序列化**：draft content（EditBuffer 从 DB 重载）、save state（derived）、cursor position（future）。

### 文件路径

`%APPDATA%/LazyLife/workspace_layout.json` — 与 `settings.json` 同目录但独立文件（变更频率和 schema 不同）。

### 持久化触发 + 去抖

所有结构变更（split/close/resize/tab open/close/switch）通知 `LayoutPersistence`，统一 **1s 去抖** 后写入。

### Atomic Write

复用 `LocalSettingsStore._writeFileWithTempReplace()` 三阶段模式：
1. 写入 `.tmp.{timestamp}` 临时文件（`flush: true`）
2. Atomic rename 到目标路径
3. 失败时旧文件不受影响

### Corruption Recovery（7 场景）

| 场景 | 行为 |
|------|------|
| 文件不存在 | 默认单 pane |
| JSON 解析失败 | 默认单 pane + log warning |
| `schema_version` > 当前支持版本 | 默认单 pane + **不覆写**文件 |
| 无效树结构（fraction ≤ 0 等） | 默认单 pane + log warning |
| tab 引用的 atomId 不存在于 DB | 跳过该 tab，继续恢复 |
| group tab 清空 + groups.length > 1 | group 自动销毁，树折叠（paneCount ≥ 1 不变量） |
| 残余 `.tmp.*` 文件 | 找最新 tmp，rename 到目标 |

### 两阶段恢复

| 阶段 | 时机 | 依赖 | 产出 |
|------|------|------|------|
| Phase 1（本 PR） | Critical Phase（同步，阻塞首帧） | 纯 Dart，无 FFI | GroupLayout + EditorGroupModel（tabs populated，EditBuffer = loading） |
| Phase 2（PR-RB-08） | Background Phase（async，DB ready 后） | RustBridge + SQLite | EditBuffer loading → ready |

### 两层分离

| 层 | 位置 | 职责 |
|----|------|------|
| Data conversion | `group_layout.dart` 内 `toJson()` / `fromJson()` | 数据结构 ↔ JSON Map |
| File I/O | `layout_persistence.dart` | 文件读写 + 1s debounce + atomic write + temp recovery |

## Task Breakdown

| Task | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|
| T1 | `EditorGroupModel` tabs 序列化（`toJson()` / `fromJson()`）— GroupLayout 树序列化已由 PR-RB-06 完成 | `editor_group_model.dart` | 新增 ~40 行 | — |
| T2 | `LayoutPersistence` 类：`load()` / `scheduleSave()` / atomic write / debounce / recovery | `lib/core/editor/layout_persistence.dart` | 新文件 ~200 行 | T1 |
| T3 | `LocalPaths` 添加 `workspaceLayoutFileName` 常量 | `lib/core/local_paths.dart` | 新增 1 行 | — |
| T4 | `EditorShellService` 集成：构造时 `load()`，结构变更时 `scheduleSave()` | `editor_shell_service.dart` | 编辑 ~20 行 | T2 |
| T5 | `main.dart` Critical Phase 集成：Phase 1 restore | `main.dart` | 编辑 ~5 行 | T2 |
| T6 | 单元测试：toJson/fromJson round-trip + 7 corruption 场景 + debounce | `test/layout_persistence_test.dart` | 新文件 ~250 行 | T2 |
| T7 | 性能测试：startup recovery Stopwatch guard <1000ms | `test/layout_persistence_test.dart` | 新增 ~15 行 | T2 |
| T8 | 文档更新 | `CLAUDE.md`、`data-model.md` | 编辑 | T2 |

## Planned File Changes

- `[add]` `apps/lazynote_flutter/lib/core/editor/layout_persistence.dart` (~200 行)
- `[edit]` `apps/lazynote_flutter/lib/core/editor/group_layout.dart`（LayoutPersistence 组装 JSON 时调用已有 toJson/fromJson）
- `[edit]` `apps/lazynote_flutter/lib/core/editor/editor_group_model.dart`（新增 tabs toJson/fromJson）
- `[edit]` `apps/lazynote_flutter/lib/core/editor/editor_shell_service.dart`（集成）
- `[edit]` `apps/lazynote_flutter/lib/core/local_paths.dart`
- `[edit]` `apps/lazynote_flutter/lib/main.dart`
- `[add]` `apps/lazynote_flutter/test/layout_persistence_test.dart`

## Verification

```bash
cd apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

```bash
# workspace_layout.json 相关文件存在
test -f apps/lazynote_flutter/lib/core/editor/layout_persistence.dart
rg "workspaceLayoutFileName" apps/lazynote_flutter/lib/core/local_paths.dart
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| Atomic write 在 Windows 上 rename 失败 | MEDIUM | 复用 `LocalSettingsStore` 已验证的 fallback 逻辑 |
| Schema v2 迁移兼容性 | LOW | `schema_version` 字段预留；unknown version 不覆写 |
| Phase 1 同步 load 阻塞首帧 | LOW | JSON 解析 <10ms（文件 <10KB）；DI-7 SLA <200ms |

## Acceptance Criteria

- [x] `workspace_layout.json` 在 split/tab 变更后 1s 内写入
- [x] Atomic write 保证文件不会半写损坏
- [x] 7 个 corruption 场景全部 gracefully fallback 到默认单 pane
- [x] 启动时 Phase 1 恢复正确重建 layout + tabs（无 content）
- [x] `schema_version` > 当前版本时不覆写文件
- [x] JSON round-trip 测试通过
- [x] `activeGroupId` 字段正确序列化和恢复
- [x] §Verification CI gates 全部通过（逐项执行并记录输出）
