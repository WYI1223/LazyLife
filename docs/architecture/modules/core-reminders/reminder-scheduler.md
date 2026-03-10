# Module Spec: Core Reminders

> `lib/core/reminders/` — 本地通知调度基础设施
>
> 设计来源：[S7](../../rulings-legacy/S7-reminders-infrastructure.md) · [08b S7 节](../../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)

---

## 职责

本地通知调度基础设施。已在 v0.2.5 PR-0259 从 `features/reminders/` 迁入 `core/reminders/`（S7 裁决：Reminders 是平台基础设施，不是 feature）。

PR-RB-04 引入生命周期驱动模型：提醒调度从视图加载触发迁移为 Atom 生命周期触发。

---

## 文件结构

```
lib/core/reminders/
├── reminder_lifecycle.dart   ← 中间层：typedef + ReminderLifecycle 类（controller 间接调用入口）
├── reminder_scheduler.dart   ← 调度器：定时检查、通知发送、启动恢复
└── reminder_service.dart     ← 服务层：通知权限、渠道配置
```

---

## 调用链

```
Feature Controllers                    Core Reminders                    FFI
─────────────────                      ──────────────                    ───
TasksController ──┐
CalendarController ┤                   ReminderLifecycle
SingleEntryController ┤  onSchedule/   ├─ onSchedule(atomId)
NotesCoordinator ─┘    onCancel          │  → atom_get(atomId)  ──────► atom_get
                       ───────────►      │  → ReminderScheduler
                                         │     .scheduleReminderForAtom()
                                         │
                                         ├─ onCancel(atomId)
                                         │  → ReminderScheduler
                                         │     .cancelReminder()
                                         │
main.dart (bootstrap)                    └─ recoverOnStartup()
  → ReminderScheduler                       → atoms_list_timed() ─────► atoms_list_timed
     .recoverOnStartup()                    → bulk scheduleRemindersForAtoms()
```

**关键约束**：`features/tasks/` 和 `features/calendar/` 不直接 import `ReminderScheduler` 或 `ReminderService`。所有调度通过注入的 `ReminderLifecycle.onSchedule` / `onCancel` 回调间接调用（DI-7 Gate A）。

---

## 模块定位（S7 裁决）

| 维度 | 决策 |
|------|------|
| 归属 | `lib/core/reminders/` — 平台基础设施 |
| 触发源 | Tasks（deadline DDL）、Calendar（event start）、Recurring（RRULE，未来） |
| 依赖 | `flutter_local_notifications` 包 |
| Rule E | `core/` 豁免 Rule E — 任何 feature 可合法引用 |
| 数据路径 | `atom_get`（FFI）— 查询任意类型 atom，不受 `view_hint` 过滤 |

---

## 触发语义：绑定 Atom 生命周期

**核心原则**：提醒与 Atom 的**数据变更**绑定，不与**视图加载**绑定。提醒是 Atom 时间字段的属性衍生行为，不是某个视图的职责。

**v0.2 问题**：提醒调度由 `TasksController._scheduleReminders()` 和 `CalendarController._scheduleReminders()` 在视图数据加载后触发。导致覆盖缺口（不打开视图 → 无提醒）和触发依赖 UI 行为。

**v0.3 生命周期模型（PR-RB-04 已实施）**：

| Atom 生命周期事件 | 提醒操作 | 触发位置 |
|---|---|---|
| 创建 Atom（有 time fields） | schedule | FFI 创建函数返回后 → `onSchedule` |
| 修改 Atom 的 time fields | update (cancel + re-schedule) | `calendar_update_event` 返回后 → `onSchedule` |
| 完成 / 取消 Atom | cancel | `atom_update_status` 返回后 → `onCancel` |
| soft-delete Atom | cancel | 延期至 v0.4 PR-0401（Q2 裁决） |
| App 启动 | bulk schedule | bootstrap → `recoverOnStartup()` |

**App 启动恢复**：当前实现使用进程内 Timer（非 OS 级定时通知），app 重启后所有 Timer 丢失。Bootstrap 恢复流程：

```
App 启动
  → _bootstrapLocalRuntime() (background, non-blocking)
  → ReminderScheduler.recoverOnStartup()
    → atoms_list_timed() — 查询所有 is_deleted=0 且有 time fields 的 Atom
    → 批量 scheduleRemindersForAtoms()
  → 后续：每次 Atom 创建/修改/完成 → 通过 ReminderLifecycle 增量 schedule/cancel
```

**调度逻辑位置**：time-matrix → reminder time 的计算是 Flutter 层的交互逻辑，不是 Core 层的领域不变量。留在 Flutter 符合 Rule A。

---

## S1 裁决验证

| S1 裁决 | 对 Reminders 的影响 |
|---|---|
| R1 Atom 统一容器 | 提醒逻辑已正确 — 基于 time-matrix，不基于 kind |
| R4 view_hint 自动推导 | 不影响 — 提醒不依赖 view_hint |
| R5 atom_ref 强制伴随 | 不影响 — 提醒基于 Atom 数据，与 workspace 位置正交 |

---

## 消费者

| 消费者 | 使用场景 | 调用方式 |
|--------|---------|---------|
| TasksController | status toggle → cancel | 注入 `onCancel` 回调 |
| CalendarController | createEvent / updateEvent → schedule | 注入 `onSchedule` 回调 |
| SingleEntryController | entry_schedule / entry_create_task → schedule | 注入 `onSchedule` 回调 |
| NotesCoordinator | 创建含时间字段的 note → schedule | 注入 `onSchedule` 回调 |
| main.dart | 启动恢复 + 构造 ReminderLifecycle 实例 | 直接调用 `ReminderScheduler` |

---

## 实施状态

| 项目 | 状态 |
|------|------|
| `features/reminders/` → `core/reminders/` 迁移 | **已完成** — PR-0259 |
| 基本通知调度 | **已完成** |
| 生命周期触发模型 + ReminderLifecycle 中间层 | **已完成** — PR-RB-04 |
| 启动恢复 (`recoverOnStartup`) | **已完成** — PR-RB-04 |
| `atom_get` FFI 数据路径 | **已完成** — PR-RB-04 |
| soft-delete cancel hook (`delete_all`) | 延期至 v0.4 PR-0401（Q2 裁决） |
| RRULE 循环提醒 | 未实施（依赖 recurrence_rule 引擎） |
| 提醒 UI 自定义（提前 N 分钟） | 未实施 |

---

## 关联模块

- ← `TasksController` — status toggle 时通过 `onCancel` 间接触发
- ← `CalendarController` — create/update event 时通过 `onSchedule` 间接触发
- ← `SingleEntryController` — schedule/task 创建时通过 `onSchedule` 间接触发
- ← `NotesCoordinator` — 带时间字段的 note 创建时通过 `onSchedule` 间接触发
- ← `main.dart` — 启动初始化 + bootstrap 恢复 + ReminderLifecycle 构造
- → `atom_get` (FFI) — onSchedule 内获取完整 atom 数据
- → `atoms_list_timed` (FFI) — 启动恢复时获取所有 timed atoms
