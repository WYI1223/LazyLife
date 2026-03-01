# v0.3 PR Spec Review Resolution Report

> 日期：2026-03-01
> 范围：PR-RB-00 ~ PR-RB-11 全量 spec review
> 状态：**全部已修复**（R1 5 条 + R2 3 条）

---

## Review 发现总览

### R1（第一轮）

| # | 严重度 | 发现 | 判定 | 最终严重度 |
|---|--------|------|------|-----------|
| 1 | HIGH | Reminder 解耦契约硬冲突 | 接受，已修复 | HIGH |
| 2 | MEDIUM | DI-4 EditOp 预留未落入 PR | 接受，降级 | LOW |
| 3 | MEDIUM | frb_generated.rs 路径笔误 | 接受，已修复 | MEDIUM |
| 4 | MEDIUM | Ruling 文件名引用不一致 | 接受，已修复 | MEDIUM |
| 5 | LOW | 收口清理项文件名写错 | 接受，已修复 | LOW |

### R2（第二轮）

| # | 严重度 | 发现 | 判定 | 最终严重度 |
|---|--------|------|------|-----------|
| 6 | MEDIUM | EditOp 预留类型 `Object?` 与 DI-4 强类型 `EditOp?` 不一致 | 接受，已修复 | MEDIUM |
| 7 | MEDIUM | Gate A 提醒解耦检查口径比 DI-7 要求弱 | 接受，已修复 | MEDIUM |
| 8 | LOW | RB-01 自动生成文件清单有重复条目 | 接受，已修复 | LOW |

---

## 逐条分析与修复

### Issue 1 — HIGH：Reminder 解耦契约硬冲突（R1）

**发现**：PR-RB-04 在 `tasks_controller.dart` 和 `calendar_controller.dart` 中直接调用 `scheduleReminderForAtom` / `cancelReminderForAtom`，但 PR-RB-11 Gate A 和 DI-7 要求这两个 feature 目录中 `ReminderScheduler` / `scheduleReminder` 引用为零。

**判定**：接受。冲突是真实存在的——PR-RB-04 将 hook 写入 feature controller，但 Gate A 验证标准要求物理层面零引用。

**修复**：引入 `lib/core/reminders/reminder_lifecycle.dart` 中间层。

- `ReminderLifecycle` 类定义 `onSchedule` / `onCancel` 回调 typedef
- `main.dart` 构造实例（内部委托到 `ReminderScheduler`），注入各 controller
- Feature controller 通过注入的回调间接触发调度，**不 import `ReminderScheduler`**
- Gate A 验证通过：`features/tasks/` 和 `features/calendar/` 中零 `ReminderScheduler` 引用

**修改文件**：
- `PR-RB-04-s7-reminder-lifecycle.md`：Hook 集成方案重写、Scope 更新、Task Breakdown 增加 T5b、Planned File Changes 增加新文件、Verification 增加 Gate A 检查
- `PR-RB-11-closure.md`：Gate A 验证注释更新

---

### Issue 2 — MEDIUM→LOW：DI-4 EditOp 预留未落入 PR（R1）

**发现**：DI-4 定义 `edit(String, {EditOp? op})`，但 PR-RB-06 实现为 `void edit(String newContent)` 无 op 参数。

**判定**：接受，降级为 LOW。DI-4 §"v0.3 实现 vs 预留"表明确将 EditOp 归为「v0.3 接口预留」非「v0.3 实现」。但为避免 v0.4 breaking change，接受前向兼容预留。

**R1 修复**：PR-RB-06 EditBuffer 接口签名改为 `void edit(String newContent, {Object? op})`。

**R2 追加修复**（Issue 6）：`Object?` 改为 `EditOp?`，并补上 `EditOp` sealed class 定义。见 Issue 6。

**修改文件**：
- `PR-RB-06-core-editor-foundation.md`：EditBuffer 接口签名更新 + EditOp 类型定义补充

---

### Issue 3 — MEDIUM：frb_generated.rs 路径错误（R1）

**发现**：PR-RB-01 Planned File Changes 写 `apps/lazynote_flutter/lib/core/bindings/frb_generated.rs`，但该路径不存在。

**判定**：接受。`.rs` 后缀是笔误，Dart bindings 目录下应为 `.dart`。

**修复**：改为 `apps/lazynote_flutter/lib/core/bindings/frb_generated.dart`。

**修改文件**：
- `PR-RB-01-s8-dto-unification.md`：路径后缀修正

---

### Issue 4 — MEDIUM：Ruling 文件名引用不一致（R1）

**发现**：多个 spec 使用了不存在的 ruling 文件名。

| 错误引用 | 实际文件名 | 出现位置 |
|---------|-----------|---------|
| `S1-atom-six-layer.md` | `S1-atom-projection.md` | PR-RB-10, PR-RB-11 |
| `S8-dto-unification.md` | `S8-noteitem-unification.md` | PR-RB-10 |
| `S9-cross-feature-infra.md` | `S9-cross-feature-infrastructure-placement.md` | PR-RB-11 |

**判定**：接受。使用了 ruling 内容的语义名称而非实际文件名。

**修复**：全部更正为仓库实际文件名。

**修改文件**：
- `PR-RB-10-s3-tag-panel.md`：Execution Contract 表 S1/S8 文件名修正
- `PR-RB-11-closure.md`：Planned File Changes 中 ruling 文件名范围修正

---

### Issue 5 — LOW：收口清理项文件名写错（R1）

**发现**：PR-RB-11 写 `note_tab_state_manager.dart`，但实际文件是 `note_tab_manager.dart`（类名 `NoteTabStateManager` 与文件名不一致）。

**判定**：接受。混淆了类名和文件名。

**修复**：更正为 `note_tab_manager.dart`（含类 NoteTabStateManager）。

**修改文件**：
- `PR-RB-11-closure.md`：Lane A 清理检查项文件名修正

---

### Issue 6 — MEDIUM：EditOp 预留类型与 DI-4 强类型不一致（R2）

**发现**：R1 修复后使用 `Object?` 作为 op 参数类型，但 DI-4 裁决明确定义了 `EditOp?` 强类型，并预留 `SnapshotReplace` / `TextDelta` / `StructuredOp` 三个子类型。

**判定**：接受。DI-4 第 437~438 行明确要求 v0.3 定义 `SnapshotReplace` 类并预留 `TextDelta` + `StructuredOp`。使用 `Object?` 丢失了强类型契约。

**修复**：
1. PR-RB-06 EditBuffer 签名改为 `void edit(String newContent, {EditOp? op})`
2. 补充 `EditOp` sealed class 定义：`SnapshotReplace`（v0.3 唯一实现）+ `TextDelta` / `StructuredOp`（注释预留）
3. v0.3 调用方不传 op（默认 null，等价于 `SnapshotReplace`）

**修改文件**：
- `PR-RB-06-core-editor-foundation.md`：EditBuffer 章节增加 EditOp sealed class 定义 + 签名改为 `EditOp?`

---

### Issue 7 — MEDIUM：Gate A 提醒解耦检查口径偏弱（R2）

**发现**：PR-RB-04 和 PR-RB-11 的 Gate A 验证命令只 grep `ReminderScheduler|scheduleReminder`，但 DI-7 第 66 行要求的是 **import 级静态检查**（`不存在 reminder_scheduler 导入`）。PR-RB-04 第 136 行自己也写了 `不出现 import ...reminder_scheduler.dart 或 import ...reminder_service.dart`，但验证命令未覆盖这些模式。

**判定**：接受。grep 模式需要扩展以覆盖 `reminder_scheduler` 和 `reminder_service` import 路径。

**修复**：PR-RB-04 和 PR-RB-11 的验证命令 grep 模式统一扩展为：
```
ReminderScheduler|scheduleReminder|reminder_scheduler|reminder_service
```

**修改文件**：
- `PR-RB-04-s7-reminder-lifecycle.md`：Structural verification grep 模式扩展
- `PR-RB-11-closure.md`：Gate A 验证 grep 模式扩展

---

### Issue 8 — LOW：RB-01 自动生成文件清单重复条目（R2）

**发现**：R1 将 `frb_generated.rs` 改为 `frb_generated.dart` 后，与原有的第 207 行 `frb_generated.dart` 重复。

**判定**：接受。R1 修复时未注意到已有同名 `.dart` 条目。

**修复**：删除重复行，保留一个 `frb_generated.dart` 条目。

**修改文件**：
- `PR-RB-01-s8-dto-unification.md`：去重

---

## 修改文件汇总

| 文件 | R1 修改 | R2 修改 |
|------|---------|---------|
| `PR-RB-04-s7-reminder-lifecycle.md` | Hook 方案重写 + ReminderLifecycle 中间层 + Task/File/Verification 更新 | grep 模式扩展（+`reminder_service`） |
| `PR-RB-06-core-editor-foundation.md` | EditBuffer.edit() 签名增加 op 参数 | `Object?` → `EditOp?` + EditOp sealed class 定义 |
| `PR-RB-01-s8-dto-unification.md` | `.rs` → `.dart` 修正 | 去重 |
| `PR-RB-10-s3-tag-panel.md` | S1/S8 ruling 文件名修正 | — |
| `PR-RB-11-closure.md` | ruling 文件名 + manager 文件名 + Gate A 注释 | grep 模式扩展（+`reminder_service`） |

---

## 验证

所有修复后，跨文件契约一致性确认：

1. **Reminder 解耦链路一致**：
   - PR-RB-04 → controller 通过注入的 `ReminderLifecycle` 回调间接调度 ✓
   - PR-RB-04 Verification → grep 覆盖 `reminder_scheduler` + `reminder_service` import ✓
   - PR-RB-11 Gate A → 同等口径 grep ✓
   - DI-7 Gate A → import 级静态检查要求已满足 ✓

2. **EditOp 签名一致**：
   - DI-4 → `edit(String, {EditOp? op})` + `SnapshotReplace` 类定义 ✓
   - PR-RB-06 → `edit(String newContent, {EditOp? op})` + `EditOp` sealed class 定义 ✓

3. **文件路径一致**：
   - PR-RB-01 → `frb_generated.dart`（无重复）✓

4. **Ruling 文件名一致**：
   - 所有引用匹配 `docs/architecture/rulings/` 实际文件名 ✓

5. **Manager 文件名一致**：
   - PR-RB-06 T12 删除 `note_tab_manager.dart` ✓
   - PR-RB-11 检查 `note_tab_manager.dart`（含类 NoteTabStateManager）✓
