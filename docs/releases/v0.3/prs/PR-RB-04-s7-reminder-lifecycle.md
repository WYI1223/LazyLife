# PR-RB-04: S7 生命周期提醒

- Proposed title: `feat(reminders): PR-RB-04 migrate to Atom lifecycle triggers with startup recovery`
- Status: Implemented

## Goal

将提醒调度从 "视图加载触发" 迁移到 "Atom 生命周期触发"：创建/修改时间/完成/删除 Atom 时自动 schedule/cancel 提醒。新增启动恢复：app 启动时批量重新调度所有 timed atom 的提醒。

前置条件：PR-RB-03（创建 API 统一后，所有创建路径可统一挂接提醒 hook）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| Ruling | `docs/architecture/rulings/S7-reminders-infrastructure.md` | v0.3 deferred items：trigger semantic migration + startup recovery |
| Rebaseline | `docs/releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md` §4 PR-RB-04 | Scope + 依赖 |
| DI-7 | `docs/reports/v0.3/design-discussions/DI-7-gates-perf-testing.md` | Gate A 验证：Tasks/Calendar 不再承担提醒调度入口 |

## 差距分析

### 当前触发模型（视图驱动）

| 触发点 | 位置 | 覆盖范围 | 问题 |
|--------|------|---------|------|
| `TasksController.loadAll()` → `_scheduleReminders()` | `tasks_controller.dart:129,194` | 仅 Today section | Upcoming / Inbox 未覆盖 |
| `CalendarController.loadWeek()` → `_scheduleReminders()` | `calendar_controller.dart:117,185` | 仅当前周 | 其他周未覆盖 |
| `SingleEntryController` | 无 | 零覆盖 | `> schedule` 命令创建的 event 无提醒 |
| `NotesCoordinator` | 无 | 零覆盖 | note 带时间字段时无提醒 |
| App 启动 | `main.dart:45` 仅初始化 plugin | 零覆盖 | 重启后所有提醒丢失 |

### 目标触发模型（生命周期驱动）

| Atom 生命周期事件 | 提醒动作 | 触发位置 |
|------------------|---------|---------|
| 创建 Atom（有时间字段） | schedule | FFI 创建函数返回后 |
| 修改时间字段 | update (cancel + re-schedule) | `calendar_update_event` 返回后 |
| 完成/取消 (`done`/`cancelled`) | cancel | `atom_update_status` 返回后 |
| 软删除 | cancel | `workspace_delete_folder(delete_all)` 返回后 — **延期至 v0.4 PR-0401**（Q2 裁决） |
| App 启动 | bulk schedule | bootstrap 阶段 |

### 需要新增的 FFI 函数

启动恢复需要查询所有 timed atom。当前无合适的 FFI 函数。

```rust
/// 返回所有未删除且有时间字段的 atom（供启动恢复用）
pub async fn atoms_list_timed() -> AtomListResponse
```

Core 层对应查询：
```sql
SELECT ... FROM atoms
WHERE is_deleted = 0
  AND (start_at IS NOT NULL OR end_at IS NOT NULL)
```

## Scope

In scope:

- 移除 `TasksController._scheduleReminders()` 视图驱动调用
- 移除 `CalendarController._scheduleReminders()` 视图驱动调用
- 新增 `lib/core/reminders/reminder_lifecycle.dart` 中间层（controller 不直接引用 ReminderScheduler）
- 在各 mutation 返回后通过注入的 `ReminderLifecycle` 回调挂接调度
- 新增 FFI `atoms_list_timed()` + Core 查询
- App 启动恢复：`main.dart` bootstrap 调用 `atoms_list_timed()` → bulk schedule
- `ReminderScheduler` 新增单 atom 调度 API
- `TasksController.toggleStatus()` 通过注入回调添加 cancel hook

Out of scope:

- `PlatformReminderService` 实现变更（Timer-based 方案不变）
- OS 级定时通知持久化（Windows 限制，启动恢复已覆盖）
- 提醒 UI 配置（提前时间、自定义等）

## 设计方案

### ReminderScheduler API 扩展

当前 `scheduleRemindersForAtoms(List<AtomListItem>)` 是 bulk API。新增单 atom 便捷 API：

```dart
/// 为单个 atom 调度提醒（创建/修改时间后调用）
static Future<void> scheduleReminderForAtom(AtomListItem atom) async {
  await scheduleRemindersForAtoms([atom]);
}

/// 启动恢复：查询所有 timed atoms 并批量调度
static Future<void> recoverOnStartup() async {
  final response = await rustApi.atomsListTimed();
  if (response.ok) {
    await scheduleRemindersForAtoms(response.items);
  }
}
```

### Hook 集成方案

生命周期 hook 通过 `lib/core/reminders/reminder_lifecycle.dart`（新增）统一中转，各 feature controller **不直接 import `ReminderScheduler`**。这满足 DI-7 Gate A 和 PR-RB-11 Gate A 的验证标准：`features/tasks/` 和 `features/calendar/` 中 `ReminderScheduler` / `scheduleReminder` 零引用。

#### ReminderLifecycle 中间层

```dart
/// lib/core/reminders/reminder_lifecycle.dart
///
/// Feature controller 通过此中间层触发提醒调度。
/// Controller 不直接引用 ReminderScheduler。
typedef OnAtomMutated = Future<void> Function(String atomId);
typedef OnAtomCancelled = Future<void> Function(String atomId);

class ReminderLifecycle {
  final OnAtomMutated onSchedule;
  final OnAtomCancelled onCancel;

  const ReminderLifecycle({required this.onSchedule, required this.onCancel});
}
```

`main.dart` 初始化时构造 `ReminderLifecycle` 实例（内部委托到 `ReminderScheduler`），通过依赖注入传入各 controller。

#### 变更表

| 变更位置 | 变更内容 |
|---------|---------|
| `tasks_controller.dart` `loadAll()` | 移除 `_scheduleReminders()` 调用 |
| `tasks_controller.dart` `toggleStatus()` | 成功后：调用注入的 `reminderLifecycle.onCancel(atomId)`（如 `done`/`cancelled`） |
| `calendar_controller.dart` `loadWeek()` | 移除 `_scheduleReminders()` 调用 |
| `calendar_controller.dart` `createEvent()` | 成功后：调用注入的 `reminderLifecycle.onSchedule(atomId)` |
| `calendar_controller.dart` `updateEvent()` | 成功后：调用注入的 `reminderLifecycle.onSchedule(atomId)` |
| `single_entry_controller.dart` | `entry_schedule`/`entry_create_task` 成功后调用注入的 `reminderLifecycle.onSchedule(atomId)` |
| `notes_coordinator_impl.dart` | 创建路径成功后：如 atom 有时间字段则调用注入的 `reminderLifecycle.onSchedule(atomId)` |
| `main.dart` | 构造 `ReminderLifecycle` 实例 + bootstrap 阶段调用 `ReminderScheduler.recoverOnStartup()` |
| `lib/core/reminders/reminder_lifecycle.dart` | **新增文件**：中间层 typedef + 类定义 |

**关键约束**：`features/tasks/` 和 `features/calendar/` 中不出现 `import ...reminder_scheduler.dart` 或 `import ...reminder_service.dart`。所有调度逻辑通过注入的回调间接调用。

### Hook 数据来源

当前问题：部分 mutation 响应（`EntryActionResponse`）不包含时间字段。解决方案：

- PR-RB-03 已扩展响应包含 `node_uuid`，但时间字段仍不在 response 中
- **方案（Q3 裁决）**：mutation 成功后，用返回的 `atom_id` 调用 `atom_get` 获取完整 `AtomListItem`，再传给 scheduler。`atom_get` 通过 `TaskService.get_atom_record` 查询任意类型 atom（无 `view_hint` 过滤），避免 `note_get` 仅返回 `view_hint='note'` 导致 task/event 静默失败
- 对于返回 `AtomItemResponse` 的函数（note 系列），可直接使用 `item` 字段；对于返回 `EntryActionResponse` 的函数（entry 系列），需调用 `atom_get` 补查

## Task Breakdown

### Phase 1: Core + FFI

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T1 | Core: `AtomRepository` 新增 `list_timed()` 查询 | `crates/lazynote_core/src/repo/atom_repo.rs` | 新增方法 + SQL | — |
| T1b | Core: `AtomRepository` 新增 `get_section_atom()` 单 atom 查询（Q3 裁决） | `crates/lazynote_core/src/repo/atom_repo.rs` | 新增方法 + SQL | — |
| T2 | Core: `TaskService` 暴露 `fetch_timed()` | `crates/lazynote_core/src/service/task_service.rs` | 新增方法 | T1 |
| T2b | Core: `TaskService` 暴露 `get_atom_record()` 单 atom 查询（Q3 裁决） | `crates/lazynote_core/src/service/task_service.rs` | 新增方法 | T1b |
| T3 | FFI: 新增 `atoms_list_timed()` 导出 | `crates/lazynote_ffi/src/api.rs` | 新增函数 ~15 行 | T2 |
| T3b | FFI: 新增 `atom_get()` 导出（Q3 裁决：`onSchedule` 数据路径） | `crates/lazynote_ffi/src/api.rs` | 新增函数 + 5 测试 | T2b |
| T4 | Codegen: `scripts/gen_bindings.ps1` | bindings | 自动生成 | T3, T3b |

### Phase 2: ReminderScheduler + Lifecycle 中间层

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T5 | 新增 `scheduleReminderForAtom()` 单 atom API | `reminder_scheduler.dart` | 新增 ~5 行 | — |
| T5b | 新增 `ReminderLifecycle` 中间层（typedef + 类） | `lib/core/reminders/reminder_lifecycle.dart` | 新文件 ~25 行 | T5 |
| T6 | 新增 `recoverOnStartup()` | `reminder_scheduler.dart` | 新增 ~10 行 | T4 |

### Phase 3: 移除视图驱动触发

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T7 | `TasksController.loadAll()` 移除 `_scheduleReminders()` 调用 + 移除 `ReminderScheduler` import | `tasks_controller.dart` | 删除调用 ~5 行 | T6 |
| T8 | `CalendarController.loadWeek()` 移除 `_scheduleReminders()` 调用 + 移除 `ReminderScheduler` import | `calendar_controller.dart` | 删除调用 ~5 行 | T6 |

### Phase 4: 挂接生命周期 Hooks（通过注入回调）

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T9 | `TasksController` 注入 `ReminderLifecycle` + `toggleStatus()` 调用 `onCancel` | `tasks_controller.dart` | 新增 ~8 行 | T5b |
| T10 | `CalendarController` 注入 `ReminderLifecycle` + `createEvent()` 调用 `onSchedule` | `calendar_controller.dart` | 新增 ~10 行 | T5b |
| T11 | `CalendarController.updateEvent()` 调用 `onSchedule` | `calendar_controller.dart` | 新增 ~5 行 | T10 |
| T12 | `SingleEntryController` 注入 `ReminderLifecycle` + 创建后 hook | `single_entry_controller.dart` | 新增 ~15 行 | T5b |
| T13 | `NotesCoordinator` 注入 `ReminderLifecycle` + 创建路径 conditional hook | `notes_coordinator_impl.dart` | 新增 ~10 行 | T5b |

### Phase 5: 启动恢复 + 组装

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T14 | `main.dart` 构造 `ReminderLifecycle` 实例 + 注入各 controller + bootstrap 调用 `recoverOnStartup()` | `main.dart` | 新增 ~10 行 | T5b, T6 |

### Phase 6: Tests + Docs

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T15 | Rust 测试：`list_timed()` 查询测试 | `crates/lazynote_core/tests/` | 新增 | T2 |
| T16 | Flutter 测试：scheduler 单元测试（lifecycle hooks + recovery） | `test/reminder_scheduler_test.dart` | 编辑/新增 | T6 |
| T17 | Flutter 测试：controller 测试确认视图不再触发 schedule | `test/tasks_controller_test.dart` 等 | 编辑 | T7, T8 |
| T18 | 文档更新 + S7 ruling 标注 implemented | docs | 编辑 | T14 |

### Critical Path

```
T1 → T2 → T3 ─┐
T1b → T2b → T3b ┤→ T4 → T6 → T14 (启动恢复 + onSchedule 数据路径)
T5 无依赖 → T5b → T7~T13 (hook 挂接)
```

## Planned File Changes

### Rust
- `[edit]` `crates/lazynote_core/src/repo/atom_repo.rs`
- `[edit]` `crates/lazynote_core/src/service/atom_service.rs`（或 `task_service.rs`）
- `[edit]` `crates/lazynote_ffi/src/api.rs`

### Flutter
- `[regen]` `apps/lazynote_flutter/lib/core/bindings/*.dart`
- `[edit]` `apps/lazynote_flutter/lib/core/reminders/reminder_scheduler.dart`
- `[add]` `apps/lazynote_flutter/lib/core/reminders/reminder_lifecycle.dart`（中间层 ~25 行）
- `[edit]` `apps/lazynote_flutter/lib/features/tasks/tasks_controller.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/calendar/calendar_controller.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/entry/single_entry_controller.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart`
- `[edit]` `apps/lazynote_flutter/lib/main.dart`

### Docs
- `[edit]` `docs/architecture/rulings/S7-reminders-infrastructure.md`
- `[edit]` `docs/architecture/modules/core-reminders/reminder-scheduler.md`
- `[edit]` `docs/api/ffi-contracts.md`
- `[edit]` `CLAUDE.md`

## Verification

### CI gates

```bash
cd crates/
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all

cd apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

### Structural verification

```bash
# Tasks/Calendar 不再包含 _scheduleReminders 方法
rg "_scheduleReminders" apps/lazynote_flutter/lib/features/tasks/
rg "_scheduleReminders" apps/lazynote_flutter/lib/features/calendar/
# Expected: zero matches

# Tasks/Calendar 不直接引用 ReminderScheduler（Gate A 契约，import 级静态检查，与 DI-7 一致）
rg "ReminderScheduler\|scheduleReminder\|reminder_scheduler\|reminder_service" apps/lazynote_flutter/lib/features/tasks/
rg "ReminderScheduler\|scheduleReminder\|reminder_scheduler\|reminder_service" apps/lazynote_flutter/lib/features/calendar/
# Expected: zero matches

# ReminderLifecycle 中间层存在
test -f apps/lazynote_flutter/lib/core/reminders/reminder_lifecycle.dart

# main.dart 包含 recoverOnStartup
rg "recoverOnStartup" apps/lazynote_flutter/lib/main.dart
# Expected: 1 match

# atoms_list_timed FFI 函数存在
rg "atoms_list_timed" crates/lazynote_ffi/src/api.rs
# Expected: ≥ 1 match
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 启动恢复 bulk schedule 大量 atom 导致启动慢 | MEDIUM | `recoverOnStartup` 在 background bootstrap 阶段执行（不阻塞首帧）；实际 timed atom 数量有限 |
| Mutation hook 遗漏某个路径 | MEDIUM | Gate A 验证：Tasks/Calendar 页面不再承担调度入口 + 手动验证 `> schedule` 命令 |
| Timer-based 提醒在 app 后台被杀后丢失 | LOW | 已知 Windows 限制；下次前台恢复时 `recoverOnStartup` 重新调度（需 app 重启） |

## Test Baseline

Entry: PR-RB-03 exit count (Rust 211, Flutter 347)
Exit: **Rust 216 (+5 atom_get tests), Flutter 347 (unchanged)**

## Acceptance Criteria

- [x] `TasksController.loadAll()` 不再调用 `_scheduleReminders()`
- [x] `CalendarController.loadWeek()` 不再调用 `_scheduleReminders()`
- [x] `atom_update_status` 成功且状态为 `done`/`cancelled` 时取消提醒
- [x] `calendar_update_event` 成功后更新提醒
- [x] `entry_schedule` / `entry_create_task` 成功后调度提醒
- [x] App 启动时批量恢复所有 timed atom 的提醒
- [x] FFI `atoms_list_timed()` 返回所有未删除 timed atom
- [x] FFI `atom_get()` 返回任意类型 atom（Q3 裁决新增）
- [x] 全部 Rust tests 通过 (216/216)
- [x] 全部 Flutter tests 通过 (347/347)
- [x] CI green (fmt + clippy + analyze)
