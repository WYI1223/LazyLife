# 08c — 解决方案

> 基于 08b 语义裁决推导的结构性解耦、CI 防线、文档同步方案。
> 本文为 [08-reassessment-and-replanning.md](08-reassessment-and-replanning.md) 的第三部分。
> 裁决未确定的部分标记为 `[待裁决后确定]`。

| 字段 | 值 |
|------|-----|
| 日期 | 2026-02-26 |
| 前提 | [08b-semantic-decisions.md](08b-semantic-decisions.md) 裁决结果 |
| 状态 | **草稿 — 待裁决后细化** |

---

## 3.1 结构性解耦方案

### 3.1.1 notes↔workspace 解耦

**目标**：消除 D4 的 4 处直接导入。

**前提**：S2 裁决（Tab/Draft/Save 状态归属）。

**方案草案**：
1. 执行 Report 07 方案 — 迁移 NotesPage 消费者直接读 coordinator/managers
2. 删除 WP bridge 代码（~260 行）
3. 删除或缩减 WorkspaceProvider（pane 布局状态合并到 coordinator 或新的 LayoutManager）
4. 将 `workspace_models.dart` 中 notes 需要的类型（`WorkspaceNodeItem`、`WorkspaceNodeKind`）提取到 `lib/shared/` 或通过 `workspace_port.dart` 重新导出
5. `notes_coordinator.dart` 和 `notes_page.dart` 的 workspace import 替换为 shared types + workspace_port

**预期效果**：notes→workspace import 从 4 降至 0。

`[待裁决后确定：S2]`

### 3.1.2 notes↔tags 循环依赖打破

**目标**：消除双向依赖（Rule E #4 + #9）。

**方案**：
1. 将 `notes_style.dart` 中被 tags 使用的颜色常量（`kNotesSecondaryText` 等）提取到 `lib/shared/styles.dart`
2. `tag_filter.dart` 从 `shared/styles.dart` 导入
3. `note_explorer.dart` 对 `tag_filter.dart` 的导入保留（notes→tags 单向依赖可接受）或同样迁移到 shared

**预期效果**：tags→notes 反向导入消除，依赖变为单向 notes→tags。

### 3.1.3 Coordinator 瘦身

**目标**：将 `notes_coordinator_impl.dart` 从 1,782 行降至 ~1,300 行。

**方案**：
1. 删除 WP bridge（~260 行）— 依赖 3.1.1
2. 提取 typedef 声明和 default invoker 到 `notes_coordinator_types.dart`（~150 行）
3. 评估 getter 代理层是否可通过公开 manager 实例简化

**预期效果**：~1,300 行，低于 Report 06 的行动阈值（2,200 行），为 v0.3 留出充足的膨胀空间。

### 3.1.4 低优先级解耦

| 项 | 方案 | 优先级 |
|----|------|--------|
| entry→search（D2） | `SearchResultsView` 迁移到 `lib/shared/` 或 entry 内部 | LOW |
| entry→diagnostics（D5） | 保持现状或迁移 `DebugLogsPanel` 到 shared | LOW |
| D10 reminders | 基于 S7 裁决执行 | MEDIUM |

---

## 3.2 CI 防线方案

**目标**：防止 v0.3 开发中新增 Rule E 违规。

### 3.2.1 Rule E 自动化检查

**新增 CI step：`rule_e_check`**

- 扫描 `lib/features/*/` 的所有 `.dart` 文件
- 检测 `import '.*features/(?!<same_feature>)` 模式
- 白名单机制：维护 `tools/ci/rule_e_allowlist.yaml` 记录已知豁免（如 reminders infrastructure 豁免）
- 新增违规时 CI 失败

### 3.2.2 文件大小监控

- 警告阈值：单文件 1,500 行
- 阻塞阈值：单文件 2,200 行
- 豁免列表：已分析确认的大文件（note_explorer.dart 等）

### 3.2.3 结构规则检查（D1-D8 子集）

- dialogs/ 内文件不得导入 coordinator/manager
- managers/ 内文件不得导入 Flutter widget（`package:flutter/`）
- 所有 manager 通过构造器注入 invoker，不允许直接调用 FFI

---

## 3.3 文档同步方案

| # | 文档 | 行动 | 关联漂移 |
|---|------|------|---------|
| 1 | `architecture/overview.md` | 重写至 v0.2.5 实际状态，覆盖全部模块 | F1 |
| 2 | `api/ffi-contracts.md` | 按 API 域重组为「当前状态」文档；修正 `workspace_delete_folder` → `workspace_delete_node` | F2, F5 |
| 3 | CLAUDE.md FFI 表 | 同步 `entry_search` 签名；与 ffi-contracts.md 对齐 | F3 |
| 4 | `product/roadmap.md` | 补齐 PR-0306A、PR-0311 | F4 |
| 5 | `frontend-review/README.md` | 更新 Planned Outputs 列表至 08 | F8（已完成） |
| 6 | Extension Kernel docs | 添加 Flutter 命令系统映射章节（基于 S5 裁决） | F6 |
| 7 | Provider SPI docs | 添加 external_mappings 交互章节（基于 S6 裁决） | F7 |
