# DI-3: 布局持久化、迁移策略、深度限制

| 项目 | 值 |
|------|-----|
| **状态** | **RESOLVED** — D7、D8、D9 全部裁决完毕 |
| **关联决策点** | D7、D8、D9 |
| **阻塞 PR** | PR-0301 |
| **前置依赖** | DI-2（D5 节点结构确定后才能定义序列化） |
| **来源** | 01-design-readiness-audit.md §4.2 |

---

## 问题提取

### 来源 §4.2 PR-0301 设计问题清单

> 3. **序列化格式**：树状态是否持久化？JSON schema 是什么？
> 4. **从扁平模型迁移**：现有 `WorkspaceLayoutState`（`paneOrder` + `paneFractions`）如何迁移到树模型？向后兼容还是一次性替换？
> 5. **最大深度限制**：是否需要？pane 数上限从 4 改为多少？

### 设计决策（审计报告原文）

| # | 决策点 | 选项 | 影响范围 |
|---|--------|------|---------|
| D7 | 持久化 | A: JSON 序列化 / B: 不持久化（每次启动恢复默认） / C: 按 session 保存 | PR-0301 scope |
| D8 | 迁移策略 | A: 向后兼容（旧模型 → 新模型转换器） / B: 一次性替换 | PR-0301 风险 |
| D9 | 最大深度/pane数 | 无限制？深度上限？pane 数上限？ | PR-0301 + PR-0302 AC |

### 当前基线

- 当前布局 **不持久化** — 每次启动默认单 pane
- 当前 max 4 pane，min 200px（hardcoded in `WorkspaceProvider`）
- `WorkspaceLayoutState` 是不可变快照，仅在内存中存在
- `LocalSettingsStore` 提供 JSON + schema version + atomic write + temp file recovery 基础设施

---

## D7 裁决：JSON 持久化 + 独立文件 + 去抖写入

### 选项分析

| 选项 | 描述 | 优点 | 缺点 |
|------|------|------|------|
| A: JSON 序列化 | 每次布局变更持久化到磁盘 | 重启后恢复用户布局；sealed class 天然映射 JSON | 需要文件 I/O + recovery 逻辑 |
| B: 不持久化 | 每次启动恢复默认单 pane | 零实现成本 | 用户精心布置的分屏每次重启丢失，UX 不可接受 |
| C: 按 session 保存 | 退出时保存，启动时恢复 | 减少写入频率 | 非正常退出（crash）丢失布局；需要 shutdown hook |

### 结论：选项 A

用户花时间布置多 pane 分屏后，重启丢失布局是不可接受的 UX。VS Code、IntelliJ 均持久化布局。DI-2 的 sealed class 结构天然映射 JSON，技术成本低。

### 存储位置：独立文件

**文件路径**：`%APPDATA%/LazyLife/workspace_layout.json`，与 `settings.json` 同目录。

**不放入 `settings.json` 的理由**：

| 维度 | settings.json | 独立文件 |
|------|--------------|---------|
| 变更频率 | 极低（用户改语言/主题） | 高（每次 split/resize/close） |
| 写入风险 | 频繁写入增加 settings 损坏概率 | 布局文件损坏不影响 settings |
| Schema 耦合 | 布局 schema 变化需要 settings schema_version 升级 | 独立版本管理 |

### 写入策略：统一去抖

| 触发场景 | 写入时机 |
|---------|---------|
| Split / Close pane | 操作完成后触发去抖 |
| Resize（拖拽分隔线） | 拖拽过程中频繁变化 → 去抖 |
| Tab open / close / switch | 编辑器状态变化 → 去抖 |

统一 **1 秒去抖**（debounce）：最后一次变更后 1 秒写入磁盘。简单统一，避免 resize 拖拽每帧写磁盘。

### 序列化范围

布局持久化与 tab 列表持久化是**不可分割的**。

**推导**：DI-1 Q2 规则——非 primary group 最后一个 tab 关闭 → group 销毁 → leaf 坍缩。如果恢复时 group 无 tab，立即触发销毁，树坍缩回单 pane。**布局持久化无 tab 数据 = 无效持久化**。

| 序列化 | 不序列化 |
|--------|---------|
| 树结构（SplitNode / LeafNode） | Draft 内容（EditBuffer 从 DB 重新加载） |
| axis + fraction + groupId | Save 状态（派生值） |
| Per-group tab 列表（atomId 数组） | 光标位置（未来增强） |
| Per-group activeTab | |
| Per-group previewTab | |
| activeGroupId | |

### JSON Schema

```json
{
  "schema_version": 1,
  "activeGroupId": "g1",
  "layout": {
    "type": "split",
    "axis": "horizontal",
    "fraction": 0.5,
    "first": { "type": "leaf", "groupId": "g1" },
    "second": {
      "type": "split",
      "axis": "vertical",
      "fraction": 0.5,
      "first": { "type": "leaf", "groupId": "g2" },
      "second": { "type": "leaf", "groupId": "g3" }
    }
  },
  "groups": {
    "g1": {
      "tabs": ["atom-uuid-1", "atom-uuid-2"],
      "activeTab": "atom-uuid-1",
      "previewTab": null
    },
    "g2": {
      "tabs": ["atom-uuid-3"],
      "activeTab": "atom-uuid-3",
      "previewTab": "atom-uuid-3"
    },
    "g3": {
      "tabs": ["atom-uuid-4"],
      "activeTab": "atom-uuid-4",
      "previewTab": null
    }
  }
}
```

单 pane 默认：

```json
{
  "schema_version": 1,
  "activeGroupId": "g1",
  "layout": { "type": "leaf", "groupId": "g1" },
  "groups": {
    "g1": {
      "tabs": [],
      "activeTab": null,
      "previewTab": null
    }
  }
}
```

### 恢复流程

读取文件 → 反序列化树 → 为每个 group 创建 `EditorGroupModel`（含 tab 列表）→ 每个 active tab 的 `EditBuffer` 从 DB 加载内容。

### Recovery 策略

复用 `LocalSettingsStore` 的已验证模式：

| 场景 | 行为 |
|------|------|
| 文件不存在 | 默认单 pane（首次启动或手动删除） |
| JSON 解析失败 | 默认单 pane + 日志警告 |
| schema_version > 当前版本 | 默认单 pane + 不覆写（保护未来版本数据） |
| 树结构不合法（fraction ≤ 0、缺少必要字段等） | 默认单 pane + 日志警告 |
| Tab 中的 atomId 在 DB 中不存在 | 跳过该 tab，继续恢复其余 |
| Group 恢复后 tab 列表为空（非 primary） | 该 group 销毁，树坍缩（DI-1 Q2） |
| Temp file 残留 | 复用 temp file recovery 模式 |

### Atomic Write

复用 `LocalSettingsStore` 三阶段写入：

1. 写入 `workspace_layout.json.tmp.{timestamp}`（`flush: true`）
2. 原子 rename temp → target（Windows fallback: delete target → rename）
3. 写入失败时保留旧文件不变

---

## D8 裁决：一次性替换（Option B）

### 分析

D8 是**伪命题** — 当前布局不持久化，磁盘上没有旧格式数据需要迁移。

| 维度 | 分析 |
|------|------|
| 磁盘数据 | 无旧 layout 文件存在 |
| 内存模型 | `WorkspaceLayoutState` → `GroupLayout` 是代码替换，不是数据迁移 |
| WorkspaceProvider | S2 Phase 2 完全删除，替换为 EditorShellService |

### 结论：选项 B（一次性替换）

直接用 `GroupLayout` + `EditorShellService` 替换 `WorkspaceLayoutState` + `WorkspaceProvider`。无旧文件需要迁移。

### v0.3 内部 Schema 演进

如果 v0.3 开发过程中需要变更 `workspace_layout.json` 的 schema：

| 场景 | 行为 |
|------|------|
| Dev 期间 schema 变更 | 旧文件 schema_version < 新版本 → 回退到默认单 pane |
| 正式发布后 schema 变更 | 通过 migration 函数处理（与 `LocalSettingsStore` 一致） |

---

## D9 裁决：Pane 数上限 8，无深度限制

### Pane 数上限 = 8

| 理由 | 说明 |
|------|------|
| 物理限制 | 1920×1080 屏幕，min 200px → 水平最多 ~9 pane。8 是安全值 |
| UX 限制 | 8 个 pane 每个已经非常小，更多无实用价值 |
| 性能 | 8 pane = 最多 15 树节点，rebuild/resolve 开销可忽略 |
| VS Code 参考 | VS Code 无硬限制，实际使用很少超过 4-6 |

### 不设深度限制

| 理由 | 说明 |
|------|------|
| Pane 数 ≤ 8 自然限制深度 | 8 pane = 最大 7 层深（极端情况），实际使用 3-4 层 |
| Min-size 约束是更自然的限制 | `canSplit` 检查 resolve 后每个 pane ≥ 200×200，物理空间不够就拒绝 |
| 代码简化 | 只需检查 `allGroupIds.length < maxPaneCount`，不需要额外遍历计算深度 |

### 验证逻辑

```
canSplit(groupId, axis, containerSize):
  if allGroupIds.length >= 8:
    return false                    // O(1) 快速拒绝
  候选树 = split(groupId, axis)
  结果 = 候选树.resolve(containerSize)
  return 所有 leaf Rect ≥ 200×200   // 精确验证
```

Pane 数检查在 resolve 之前（O(1) 快速拒绝），min-size 检查在 resolve 之后（精确验证）。

---

## DI-3 ↔ DI-4 边界：两阶段恢复模型

布局恢复涉及两个具有不同依赖的阶段。DI-3 和 DI-4 各负责一个阶段，边界必须明确。

### 两阶段定义

```
阶段 1 — 结构恢复（DI-3 范畴）
  输入: workspace_layout.json
  依赖: 纯 Dart，无 FFI / DB 依赖
  产出: GroupLayout 树 + EditorGroupModel（含 tab 列表，EditBuffer 均为 loading 状态）
  时机: Critical Phase（与 LocalSettingsStore 同级，保证第一帧有正确布局）

阶段 2 — 内容加载（DI-4 范畴）
  输入: 阶段 1 产出的 EditBuffer（loading 状态）+ atomId 列表
  依赖: RustBridge + SQLite（FFI 调用）
  产出: EditBuffer loading → ready（内容填充）
  时机: Background Phase（DB 就绪后异步执行）
```

### DI-3 的职责边界

| DI-3 负责 | DI-3 不负责 |
|-----------|-----------|
| JSON → GroupLayout 树反序列化 | EditBuffer 内容从 DB 加载 |
| EditorGroupModel 创建（tab 列表 + activeTab + previewTab） | EditBuffer loading → ready 状态转换 |
| 结构层 recovery（JSON 损坏 → 默认单 pane） | 内容层 recovery（atomId 不存在 → 跳过 tab）的执行策略 |
| GroupLayout 树 + EditorGroupModel 序列化到 JSON | 加载优先级（先 active tab？并行？懒加载？） |
| 去抖写入时机 | Buffer 同步机制 |

### DI-4 的入口约定

DI-4 接收 DI-3 的产出作为前提条件：

- GroupLayout 树已重建，所有 LeafNode 的 groupId 有效
- 每个 EditorGroupModel 的 tab 列表已填充（atomId 数组）
- 每个 tab 对应的 EditBuffer 已创建，处于 `loading` 状态
- DI-4 负责定义：如何将这些 `loading` 状态的 EditBuffer 加载为 `ready`（加载顺序、并行策略、失败处理）

### 用户可见行为

| 阶段 | 用户看到 |
|------|---------|
| 阶段 1 完成 | 正确的分屏布局 + tab 条 + 每个 pane 内 loading 占位 |
| 阶段 2 进行中 | active tab 内容逐个出现（loading → 编辑器内容） |
| 阶段 2 完成 | 完整的工作区恢复 |

### 边界情况归属

| 场景 | 归属 | 行为 |
|------|------|------|
| JSON 文件不存在 / 损坏 | DI-3 | 默认单 pane |
| 树结构不合法 | DI-3 | 默认单 pane |
| DB 尚未就绪 | DI-4 | EditBuffer 保持 `loading`，UI 显示 loading |
| atomId 在 DB 中不存在 | DI-4 | 跳过该 tab；非 primary group 因此清空 → 坍缩 |
| 用户在 loading 阶段关闭 tab | DI-3（结构操作） | 允许——仅更新 GroupLayout + EditorGroupModel |
| 用户在 loading 阶段尝试编辑 | DI-4（Buffer 状态） | `loading` 状态拒绝 `edit()` 调用，UI 禁用编辑 |
| DB 加载失败（FFI 通用异常） | DI-4 | EditBuffer 标记 `error` 状态（`markError()`），UI 显示错误占位 + retry 按钮，不影响布局结构（DI-4 Q4 细化4） |

---

## 开放设计项

### 1. `LocalPaths` 扩展

在 `local_paths.dart` 增加 `workspaceLayoutFileName` 常量（`'workspace_layout.json'`），与现有 `settingsFileName`、`entryDbFileName` 保持一致。

### 2. 序列化方法归属

**推荐两层拆分**：

| 层 | 职责 | 位置 |
|---|------|------|
| 数据转换 | `GroupLayout.toJson()` / `GroupLayout.fromJson()` — 纯数据结构 ↔ JSON Map | `group_layout.dart` 内 |
| 文件 I/O | `LayoutPersistence` — 文件读写 + 去抖 + atomic write + temp file recovery | 独立文件 `lib/core/editor/layout_persistence.dart` |

理由：`toJson()`/`fromJson()` 是数据结构的"另一种表示"，与 `GroupLayout` 天然绑定（sealed class 变了，序列化必须变）。而文件 I/O、去抖、temp file、recovery 是基础设施逻辑，变化原因不同。

---

## 关联

- ← DI-2（D5 节点结构 — sealed class JSON 序列化基础）
- ← DI-1 Q2（Pane 生命周期 — tab 列表与布局不可分割的推导依据）
- ← 01 审计报告 §4.2
- → DI-4（阶段 2 内容加载 — 接收 DI-3 的结构恢复产出）
- → PR-0301（布局树实现 + 持久化）

---

*前序议题：[DI-2 布局树节点结构](DI-2-layout-tree-structure.md)（RESOLVED）*
*下一个议题：[DI-4 Buffer 同步模型](DI-4-buffer-sync-model.md)*
