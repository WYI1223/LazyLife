# S7: Reminders 模块定位

| 字段 | 值 |
|------|-----|
| 状态 | **Landed** — v0.2.5 PR-0259 已执行模块迁移 |
| 裁决日期 | 2026-02-26 |
| 关联 PR | PR-0259（已完成） |

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

| Atom 生命周期事件 | 提醒操作 |
|------------------|---------|
| 创建 Atom（有 time fields） | 设置 reminder |
| 修改 Atom 的 time fields | 更新 reminder |
| 完成 / 取消 Atom | 取消 reminder |
| 删除 Atom | 取消 reminder |

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
| 触发语义改为生命周期驱动 | v0.3 待实施（需在 Atom CRUD 的 FFI 后统一挂接） |
| App 启动恢复逻辑 | v0.3 待实施 |
