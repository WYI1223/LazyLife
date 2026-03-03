# Module Spec: LayoutPersistence

> `lib/core/editor/layout_persistence.dart`
>
> 设计来源：[DI-3](../../../reports/v0.3/design-discussions/DI-3-layout-persistence.md) · [S2 Phase 2 布局持久化](../../rulings/S2-tab-draft-save-ownership.md)

---

## 职责

GroupLayout 和 EditorGroupModel tab 列表的文件 I/O + 去抖 + 原子写入。独立于 `GroupLayout` 数据结构本身（序列化方法在 `group_layout.dart`，文件操作在此模块）。

---

## 文件路径

`%APPDATA%/LazyLife/workspace_layout.json`

独立于 `settings.json` — 避免布局频繁写入干扰设置文件。

---

## 序列化范围

| 序列化 | 不序列化 |
|--------|---------|
| 树结构（SplitNode / LeafNode） | Draft 内容（EditBuffer 从 DB 重加载） |
| per-group tab 列表（atomId 数组） | Save 状态（getter 派生） |
| per-group activeTab、previewTab | 光标位置（未来增强） |
| activeGroupId | |
| `schema_version = 1` | |

---

## 写入策略

**统一 1s 去抖**：

| 触发 | 说明 |
|------|------|
| Split / tab-driven auto-collapse | 结构变化 |
| Resize（拖拽分隔条） | 比例变化 |
| Tab open / close / switch | Tab 列表变化 |

**原子写入**（复用 `LocalSettingsStore` 三阶段模式）：
1. 写入临时文件 `workspace_layout.json.tmp.{timestamp}`
2. 原子 rename → 目标（Windows fallback: delete → rename）
3. 失败时旧文件保持不变

---

## 两阶段恢复模型

| 阶段 | 范畴 | 依赖 | 产出 |
|------|------|------|------|
| Phase 1 — 结构恢复 | DI-3 | 纯 Dart（无 FFI） | GroupLayout 树 + EditorGroupModel（EditBuffer 均为 `loading`） |
| Phase 2 — 内容加载 | DI-4 | RustBridge + SQLite | EditBuffer `loading` → `ready` |

Phase 1 在 Critical Phase 执行（阻塞首帧，与 LocalSettingsStore 同步）。Phase 2 在 Background Phase 执行（DB 就绪后）。

---

## Recovery 策略

| 场景 | 行为 |
|------|------|
| 文件不存在 | 默认单 pane |
| JSON 解析失败 | 默认单 pane + 警告日志 |
| `schema_version > current` | 默认单 pane + 不覆盖文件（保护更高版本） |
| 无效树结构 | 默认单 pane + 警告日志 |
| atomId 在 DB 中不存在 | 跳过该 tab，继续恢复 |
| group 恢复后为空 + groups.length > 1 | group 销毁，树折叠（paneCount ≥ 1 不变量） |
| 临时文件残留 | 复用 LocalSettingsStore 临时文件恢复模式 |

---

## 约束

- schema_version > 当前版本时不覆写（向前兼容保护）
- 最大 8 pane（DI-3 D9）——恢复时也校验
- 恢复失败时 fallback 到单 pane，不抛异常

---

## 关联模块

- ← [GroupLayout](group-layout.md) — `toJson()` / `fromJson()`
- ← [EditorShellService](editor-shell-service.md) — 启动时调用 load，结构变化时触发 save
- → `LocalSettingsStore` — 复用原子写入模式

---

## 实施状态 `[PR-RB-07 已实施]`

| 阶段 | 状态 | PR |
|------|------|-----|
| LayoutPersistence 类 + recovery + debounce | 已实施 | PR-RB-07（v0.3，DI-3） |
| EditorShellService 集成 | 已实施 | PR-RB-07（v0.3，DI-3） |
