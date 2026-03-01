# Module Spec: ReminderScheduler

> `lib/core/reminders/reminder_scheduler.dart` + `lib/core/reminders/reminder_service.dart`
>
> 设计来源：[S7](../../rulings/S7-reminders-infrastructure.md) · [08b S7 节](../../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)

---

## 职责

本地通知调度基础设施。已在 v0.2.5 PR-0259 从 `features/reminders/` 迁入 `core/reminders/`（S7 裁决：Reminders 是平台基础设施，不是 feature）。

---

## 文件结构

```
lib/core/reminders/
├── reminder_scheduler.dart    ← 调度器：定时检查、通知发送
└── reminder_service.dart      ← 服务层：通知权限、渠道配置
```

---

## 模块定位（S7 裁决）

| 维度 | 决策 |
|------|------|
| 归属 | `lib/core/reminders/` — 平台基础设施 |
| 触发源 | Tasks（deadline DDL）、Calendar（event start）、Recurring（RRULE，未来） |
| 依赖 | `flutter_local_notifications` 包 |
| Rule E | `core/` 豁免 Rule E — 任何 feature 可合法引用 |

---

## 触发语义：绑定 Atom 生命周期（08b S7）

**核心原则**：提醒与 Atom 的**数据变更**绑定，不与**视图加载**绑定。提醒是 Atom 时间字段的属性衍生行为，不是某个视图的职责。

**v0.2 问题**：提醒调度由 `TasksController._scheduleReminders()` 和 `CalendarController._scheduleReminders()` 在视图数据加载后触发。导致覆盖缺口（不打开视图 → 无提醒）和触发依赖 UI 行为。

**v0.3 目标模型**：

| Atom 生命周期事件 | 提醒操作 |
|---|---|
| 创建 Atom（有 time fields） | 设置 reminder |
| 修改 Atom 的 time fields | 更新 reminder（重新调度） |
| 完成 / 取消 Atom（`task_status = done/cancelled`） | 取消 reminder |
| soft-delete Atom | 取消 reminder |
| App 启动 | 查询所有 `is_deleted=0` 且有 time fields 的 Atom → 批量 schedule |

**App 启动恢复**：当前实现使用进程内 Timer（非 OS 级定时通知），app 重启后所有 Timer 丢失。需要 bootstrap 恢复：

```
App 启动
  → ReminderScheduler.ensureInitialized()
  → 查询所有 is_deleted=0 且有 time fields 的 Atom → 批量 schedule
  → 后续：每次 Atom 创建/修改/完成 → 增量 schedule/cancel
```

这替代了"视图加载时顺便调度"的隐式恢复机制。

**调度逻辑位置**：time-matrix → reminder time 的计算（~15 行）是 Flutter 层的交互逻辑，不是 Core 层的领域不变量。留在 Flutter 符合 Rule A。

---

## S1 裁决验证

| S1 裁决 | 对 Reminders 的影响 |
|---|---|
| R1 Atom 统一容器 | 提醒逻辑已正确 — 基于 time-matrix，不基于 kind |
| R4 view_hint 自动推导 | 不影响 — 提醒不依赖 view_hint |
| R5 atom_ref 强制伴随 | 不影响 — 提醒基于 Atom 数据，与 workspace 位置正交 |

---

## 消费者

| Feature | 使用场景 |
|---------|---------|
| Tasks | deadline DDL 到期提醒 |
| Calendar | event 开始前提醒 |
| main.dart | App 启动时初始化 + bootstrap 恢复 |

---

## 实施状态

| 项目 | 状态 |
|------|------|
| `features/reminders/` → `core/reminders/` 迁移 | **已完成** — PR-0259 |
| 基本通知调度 | **已完成** |
| RRULE 循环提醒 | 未实施（依赖 recurrence_rule 引擎） |
| 提醒 UI 自定义（提前 N 分钟） | 未实施 |

---

## 关联模块

- ← `TasksController` — deadline 提醒触发
- ← `CalendarController` — event 提醒触发
- ← `main.dart` — 启动初始化
