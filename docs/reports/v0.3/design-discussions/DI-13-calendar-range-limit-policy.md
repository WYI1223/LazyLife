# DI-13: Calendar Range 查询默认 Limit 策略

| 属性 | 值 |
|------|-----|
| 状态 | PENDING |
| 关联裁决 | — |
| 影响范围 | `lazynote_ffi` FFI 层、`lazynote_core` repo 层、`ffi-contracts.md`、`CLAUDE.md` |
| 前置输入 | PR-RB-04 review Finding 1；Issue #46（FFI 测试 DB 隔离） |
| 目标版本 | v0.3 |

---

## 背景

`calendar_list_by_range` 当前使用与 tasks 相同的 `normalize_section_limit()` 默认分页（`limit=50, max=50`）。在 PR-RB-04 开发过程中发现：当同一时间范围内事件数超过 50 时，查询结果被静默截断，导致 UI 数据丢失。

Calendar 与 Tasks 的查询语义本质不同：
- **Tasks (inbox/today/upcoming)**：列表型视图，用户可翻页，分页合理
- **Calendar (range query)**：时间窗口内的完整投影，用户期望看到所有事件；时间范围本身已是自然约束

PR-RB-04 review 指出该改动超出 PR 主目标，应独立讨论并决策。

---

## 讨论边界

**In scope:**
1. `calendar_list_by_range` 是否应取消默认 limit
2. 如果取消 limit，是否需要安全上限防止极端查询
3. API contract 文档如何更新

**Out of scope:**
- Tasks 系列 (inbox/today/upcoming) 的分页策略（保持现状）
- UI 层面的虚拟化 / 懒加载优化
- 数据库性能优化（索引策略等）

---

## 待裁决问题

### Q1. `calendar_list_by_range` 是否应取消默认 limit=50？

**A. 保持 limit=50 不变**
- 优点：与既有 API contract 一致；防止大结果集
- 缺点：时间范围内事件被静默截断，UI 数据不完整；已证实导致 bug

**B. 取消默认 limit，使用 u32::MAX**
- 优点：时间范围是自然约束，不会出现无界查询；UI 获得完整数据
- 缺点：理论上极端大范围（如 10 年）可能返回大结果集；API contract breaking change

**C. 提高默认 limit 到合理上限（如 500 或 1000）**
- 优点：兼顾完整性和安全性；非 breaking change（仅放宽）
- 缺点：仍可能截断；阈值选择缺乏数据依据

### Q2. 如果放开 limit，是否需要安全上限？

**A. 无上限（u32::MAX）**
- 日历场景中时间范围（通常 1 天 ~ 1 月）已是天然约束，事件密度有限

**B. 设置宽松上限（如 10000）**
- 防御性设计，但实际触及概率极低

### Q3. API contract 文档更新策略

**A. 标记为 breaking change，更新 `API_COMPATIBILITY.md`**
- 严格遵循 governance 流程

**B. 标记为行为增强（non-breaking），仅更新 `ffi-contracts.md` 和 `CLAUDE.md`**
- 放宽 limit 对调用方无负面影响（返回更多数据 ⊇ 原有数据）

---

## 相关证据

- **Issue #46**: FFI 测试持久 DB 累积数据 → 同一 range 内超过 50 事件 → `calendar_list_by_range_includes_done_events` 测试失败
- **复现方式**: 对同一时间区间运行 calendar 创建测试 60+ 次，第 49 次开始出现截断

---

## 备注

本 DI 从 PR-RB-04 review Finding 1 中提取。待裁决后独立 PR 提交变更。
