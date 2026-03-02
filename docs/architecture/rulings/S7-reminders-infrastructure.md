# S7: Reminders 模块定位

| 字段 | 值 |
|------|-----|
| 状态 | **Landed** — PR-0259 模块迁移 + PR-RB-04 生命周期触发 |
| 引入版本 | v0.2.5 (PR-0256) |
| 废弃者 | — |
| 裁决日期 | 2026-02-26 |
| 关联 PR | PR-0259（模块迁移，已完成）、PR-RB-04（生命周期触发 + 启动恢复，已完成） |

---

## 决策

**Reminders 是平台基础设施，不是 feature 模块。** 从 `lib/features/reminders/` 迁移到 `lib/core/reminders/`，消除 Rule E 违规。触发语义从视图驱动改为绑定 Atom 生命周期。

---

## 规则

1. **模块归属**：Reminders 属于 `lib/core/`（平台基础设施），与 RustBridge、LocalSettingsStore 同级
2. **Atom 生命周期触发**：提醒与 Atom 数据变更绑定，不与视图加载绑定
3. **单例合理性**：整个 app 共享一个通知通道，ReminderScheduler 的静态单例模式是正确设计
4. **Rule E 自然消解**：`core/` 被所有 features 合法引用，迁移后 calendar/tasks 的导入不再是 Rule E 违规

---

## Atom 生命周期触发语义

### 当前问题（视图驱动触发）

提醒由 `TasksController._scheduleReminders()` 和 `CalendarController._scheduleReminders()` 在视图数据加载后触发，导致：

- **覆盖缺口**：有时间字段的 Atom 若不被 Tasks 或 Calendar 视图加载，不会收到提醒
- **依赖 UI 行为**：用户不打开 Tasks/Calendar 视图 → 无提醒

### 目标模型（生命周期驱动触发）

| Atom 生命周期事件 | 提醒操作 | 实施状态 |
|------------------|---------|---------|
| 创建 Atom（有 time fields） | 设置 reminder | **已完成** — PR-RB-04 |
| 修改 Atom 的 time fields | 更新 reminder（cancel + re-schedule） | **已完成** — PR-RB-04 |
| 完成 / 取消 Atom（status → done/cancelled） | 取消 reminder | **已完成** — PR-RB-04 |
| 清除完成/取消状态（status → null） | 重新设置 reminder | **已完成** — PR-RB-04（Q1 决策：un-complete 触发 re-schedule） |
| 软删除 Atom（单条） | 取消 reminder | 随各删除路径自然覆盖 |
| 批量软删除（`workspace_delete_folder(delete_all)`） | 批量取消 reminder | **延期至 v0.4 `PR-0401`** — 依赖 DI-12 单根树结构变更，避免遍历逻辑重复改造 |

### App 启动恢复

```
App 启动
  → ReminderScheduler.ensureInitialized()
  → 查询所有 is_deleted=0 且有 time fields 的 Atom → 批量 schedule
  → 后续：每次 Atom 创建/修改/完成 → 增量 schedule/cancel
```

---

## 不选其他方案的理由

- **接口注入（B）**：ReminderScheduler 是天然单例，加接口注入增加间接层但不解决触发碎片化。已有 `setServiceForTesting()` 支持测试注入
- **Core API 暴露（C）**：Rust Core 无法直接调用 Windows 通知 API（`flutter_local_notifications` 是 Flutter 平台插件）。调度决策逻辑仅 ~15 行，不值得 FFI round-trip

---

## 理由

1. **平台能力定位**：封装 OS 通知 API，与 RustBridge（FFI）、LocalSettingsStore（文件 IO）同级
2. **Atom 中心触发**：与 S1 Atom 统一容器一致 — 提醒由 Atom 的时间字段决定，不由视图决定
3. **启动恢复完备**：显式 bootstrap 恢复替代隐式的"视图加载顺便调度"
4. **调度逻辑位置正确**：time-matrix → reminder time 的计算（~15 行）是交互逻辑，符合 Rule A

---

## 实施状态

| 项目 | 状态 |
|------|------|
| 模块迁移（features/ → core/） | **已完成** — PR-0259 |
| Rule E 违规消除 | **已完成** — 0 violations |
| 触发语义改为生命周期驱动 | **已完成** — PR-RB-04 |
| App 启动恢复逻辑 | **已完成** — PR-RB-04 |
| ReminderLifecycle 中间层 | **已完成** — PR-RB-04（`lib/core/reminders/reminder_lifecycle.dart`） |
| DI-7 Gate A（Tasks/Calendar 零引用 ReminderScheduler） | **已完成** — PR-RB-04 |

---

## 实施决策记录（PR-RB-04）

| 决策 | 结论 | 理由 |
|------|------|------|
| Q1: 清除完成状态（un-complete）是否 re-schedule？ | **是** — `toggleStatus` 清除 done/cancelled 时调用 `onSchedule` | 恢复活跃状态的 timed atom 应重新获得提醒 |
| Q2: `workspace_delete_folder(delete_all)` cancel hook | **延期至 v0.4 `PR-0401`（DI-12 单根化）** | 依赖 workspace tree 结构变更，避免遍历逻辑重复改造；当前启动恢复已覆盖重启后场景（软删除 atom 不被 `fetch_timed` 选中） |
| Q3: Hook 数据来源（mutation 响应不含时间字段时如何获取完整 atom） | **新增 `atom_get`** — `note_get` 仅返回 `view_hint='note'` 行，task/event 静默失败 | `atom_get` 通过 `TaskService.get_atom_record` 查询任意类型 atom（无 view_hint 过滤），返回标准 `AtomItemResponse`；初版使用 `note_get` 的 bug 已在同 PR 修复 |
