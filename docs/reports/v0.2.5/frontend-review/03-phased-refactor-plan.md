# 分阶段重构计划（2–4 周，含回归验证与 PR 门禁）

---

## 0. 文档信息与输入依据

| 项目 | 值 |
|------|-----|
| **项目名称** | LazyNote — Flutter 前端分阶段重构 |
| **计划负责人** | AI Agent（Claude） |
| **审核人** | 前端 TL（WYI1223，已签字） |
| **协同人** | TPM / PM / QA（待指定） |
| **日期** | 2026-02-24 |
| **报告版本** | M3 完成（M1 阶段设计 ✓ · M2 回归与门禁 ✓ · M3 风险/资源/收口 ✓ · TL 审核签字 ✓） |
| **代码基线** | branch: `main`, commit: `4144598`（与体检报告、拆分方案一致） |
| **运行环境** | Flutter 3.41.0 · Dart 3.11.0 · FRB 2.11.1 · Windows 11 |
| **计划窗口** | 2026-03-03 ~ 2026-03-28（4 周） |

### 关联文档版本

| 文档 | 路径 | 状态 |
|------|------|------|
| 代码体检报告（PR-0255A） | `docs/reports/v0.2.5/frontend-review/01-code-health-report.md` | M4 完成，TL 已签 |
| 模块拆分方案（PR-0255B） | `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md` | M3 完成，TL 已签 |
| 架构规则 | `docs/architecture/engineering-standards.md` Rule A–F | 基线约束 |

### 当前约束

| 类别 | 约束 |
|------|------|
| **发布约束** | 非公开发布窗口期，重构可执行。v0.3 计划中但未设硬截止日期 |
| **功能并行** | v0.3 高级布局/拖拽分屏功能处于设计阶段，执行期不会进入本轮冻结模块 |
| **人员约束** | 前端 Owner 空缺（AI Agent 主导），TL review 带宽有限（每周 ~4h） |
| **技术约束** | 保持 ChangeNotifier + AnimatedBuilder；不换框架；不改 Rust FFI 接口签名 |
| **测试基线** | 313 pass / 0 known-fail，`flutter analyze` 零警告 |

---

## 1. 计划摘要

### 总体执行策略

**"先止血建门禁（Phase 0），再从清洁缝隙开始低风险提取（Phase 1），然后处理高风险多孔域 + 编排层（Phase 2），最后收口固化（Phase 3）。NoteExplorer 对话框提取与 Phase 1 并行。"**

### 阶段概览（4 阶段 / 4 周）

| 阶段 | 时间窗口 | 目标 | 对应 0255B Phase |
|------|---------|------|----------------|
| Phase 0 | Week 1 前半（3 天） | 止血与执行基线 | 前置准备（A1 + A3 样板） |
| Phase 1 | Week 1 后半 ~ Week 2（7 天） | 清洁/中等缝隙 manager 提取 + Explorer 对话框 | A2 + A4 + B1 + D |
| Phase 2 | Week 3（5 天） | 剩余 manager + Coordinator 切换 | B2 + C |
| Phase 3 | Week 4 前半（3 天） | 收口固化 + EntryShellPage 解耦 | E + 收口 |

### Top 5 关键路径任务

1. **WorkspacePort 接口定义**（Phase 0）→ 阻塞 WorkspaceTreeManager 提取
2. **WorkspaceTreeManager 提取**（Phase 1）→ 最大单体提取（~700 行），验证拆分模式
3. **NoteListManager 提取**（Phase 2）→ 多孔域，依赖全部 Phase 1 manager 就位
4. **NotesCoordinator 切换**（Phase 2）→ 唯一 breaking point，消费者从 NotesController 迁移
5. **SectionRegistry 落地**（Phase 3）→ 消除 EntryShellPage 6 处跨 feature import

### 主要风险

| 风险 | 影响 | 缓解（详见 Section 3 各阶段） |
|------|------|------|
| Coordinator 切换引入回归 | 全笔记主流程 | S4 测试分两阶段迁移（0255B Section 8.2） |
| NoteListManager 多孔域耦合 | 列表/Tab/筛选联动 | 等所有下游 manager 就位后再提取 |
| TL review 带宽不足 | PR 合并阻塞 | Phase 1 低风险 PR 可由 AI Agent 预审 |
| 测试基线新增失败 | 回归判定模糊 | 基线为 313 pass / 0 known-fail，门槛为"不引入新失败" |

### 功能冻结

- **冻结模块**：`lib/features/notes/` 全目录（仅允许 bugfix + 本轮重构 PR）
- **冻结接口**：NotesController public API 签名在 Phase 1 期间不变（Phase 2 Coordinator 切换时统一迁移）
- **不冻结**：tasks、calendar、search、settings、diagnostics、reminders（不在本轮范围）

### 对 PM/TPM 的即时请求

1. 确认 4 周窗口内无硬性功能交付要求
2. 安排 QA（或 TL 兼任）在 Phase 1/2 结束时各执行 1 次阶段回归
3. 确认 `lib/features/notes/` 冻结期间无并行功能需求进入

---

## 2. 执行边界与前置条件

### 2.1 本次执行范围（Must）

来源：0255B Section 4.1 拆分对象清单 + Section 6.2 排序结果。

| 拆分对象 | 拆分单元数 | 来源 |
|---------|-----------|------|
| NotesController → Coordinator + 6 Managers | 7 + 1 接口（WorkspacePort） | 0255B Phase A+B+C |
| NoteExplorer → 瘦 State + 4 对话框 + Builder | 5 | 0255B Phase D |
| EntryShellPage → SectionRegistry | 1 | 0255B Phase E |
| **合计** | **14**（与 0255B Section 4.1 的 13 个拆分单元 + 1 个前置接口一致） | |

### 2.2 本次不纳入范围（Won't）

| 不纳入项 | 原因 |
|---------|------|
| P2 模块拆分（SingleEntryController, TagFilter, DebugLogsPanel 等） | 0255B Section 7.1 冻结清单 |
| NotesPage / NoteContentArea 结构拆分 | 0255B 定义为伴随受益，无独立拆分动作 |
| 状态管理框架迁移 | 保持 ChangeNotifier，0255B Section 2.2 约束 |
| Rust FFI 接口签名变更 | 本轮不改 `api.rs`，invoker 仅下沉不改签名 |
| `lib/shared/` 共享层建设 | 0255B Section 5.4 决策：ROI 不足 |
| 测试框架升级或 E2E 测试建设 | 超出本轮范围 |

### 2.3 前置条件

在 Phase 0 开始前，以下条件必须满足：

| # | 前置条件 | 责任人 | 状态 |
|---|---------|--------|------|
| P1 | 0255A + 0255B 报告已签字 | TL | ✓ 已完成 |
| P2 | `flutter analyze` 零警告 | Agent 验证 | ✓ 已确认 |
| P3 | 测试基线确认（313 pass / 0 known-fail） | Agent 验证 | ✓ 已确认 |
| P4 | `lib/features/notes/` 冻结确认（PM/TPM） | PM | ✓ 已确认 |
| P5 | TL 每周 ~4h review 带宽确认 | TL | ✓ 已确认 |
| P6 | QA 阶段回归安排确认（Phase 1/2 结束时各 1 次） | QA/TPM | ✓ 已确认 |

---

## 3. 分阶段计划

### Phase 0：止血与执行基线（Week 1 前半，3 天）

| 字段 | 值 |
|------|-----|
| **时间窗口** | 2026-03-03 ~ 2026-03-05 |
| **阶段目标** | 建立安全执行基础设施，让后续拆分 PR 有可验证、可回退的环境 |
| **范围** | WorkspacePort 接口定义 · 回归清单 v1 · PR 门禁规则确认 · 样板 PR（最简 manager 提取） |
| **不包含** | 除样板 PR（NoteSaveTracker）外的任何业务 manager 正式提取 |
| **前置依赖** | Section 2.3 前置条件全部满足 |
| **负责人** | AI Agent（Owner 角色） |
| **协作角色** | TL（review 样板 PR）、TPM（冻结确认） |

**任务清单：**

| ID | 任务 | 输出物 | 预计工作量 | 前置 |
|----|------|--------|-----------|------|
| P0-1 | 创建 `workspace_port.dart` 抽象接口 | PR（<30 行） | 0.5d | 无 |
| P0-2 | 编写回归清单 v1（核心笔记主流程 8–10 步） | 文档 | 0.5d | 无 |
| P0-3 | 确认 PR 门禁规则（0255B Section 3.3 D1–D8 + S1–S7） | 文档确认 | 0.5d | 无 |
| P0-4 | 样板 PR：提取 NoteSaveTracker（最简 manager，纯状态枚举无 invoker） | PR | 1.0d | P0-3 |
| P0-5 | 样板 PR review + 合并 + 回归验证 | 合并记录 | 0.5d | P0-4 |

**阶段风险：**
- 样板 PR 暴露未预见的测试断裂 → 缓解：NoteSaveTracker 是最简 manager，影响面最小
- 前置条件 P4–P6 未及时确认 → 缓解：提前 1 周沟通

**阶段 DoD：**
- [x] `workspace_port.dart` 已合并
- [x] NoteSaveTracker 样板 PR 已合并，无新增失败（313 → 316 pass / 0 known-fail，新增 3 个 tracker 测试）
- [x] 回归清单 v1 已确认
- [x] PR 门禁规则文档化

**验证方式：** `flutter analyze` + `flutter test` + 回归清单 v1 手工走查

---

### Phase 1：清洁/中等缝隙提取 + Explorer 对话框（Week 1 后半 ~ Week 2，7 天）

| 字段 | 值 |
|------|-----|
| **时间窗口** | 2026-03-06 ~ 2026-03-14 |
| **阶段目标** | 提取清洁缝隙 manager（0255B A2 + A4）+ 中等缝隙 NoteTagManager（0255B B1）+ Explorer 对话框/Builder（0255B D），建立拆分节奏 |
| **范围** | WorkspaceTreeManager（A2）· NoteDraftManager（A4）· NoteTagManager（B1）· 4 个 Explorer 对话框（D1）· ExplorerTreeBuilder（D2） |
| **不包含** | NoteTabManager（B2，依赖 Phase 0 的 SaveTracker + Phase 1 的 DraftManager）· NoteListManager（C1）· NotesCoordinator（C2） |
| **前置依赖** | Phase 0 DoD 全部满足 |
| **负责人** | AI Agent（Owner 角色） |
| **协作角色** | TL（review 全部 PR）、QA（阶段结束回归） |

**任务清单：**

| ID | 任务 | 对应 0255B | 预计工作量 | 前置 |
|----|------|-----------|-----------|------|
| P1-1 | 提取 WorkspaceTreeManager（L708–1185, L2699–2714, L2735–2933） | A2 | 2.0d | P0-1 |
| P1-2 | 提取 NoteDraftManager（L1885–1921, L2348–2464） | A4 | 1.0d | P0-4 |
| P1-3 | 提取 NoteTagManager（L1372–1467, L1588–1664, L2716–2733） | B1 | 1.5d | 无 |
| P1-4 | 提取 CreateFolderDialog（L1573–1696） | D1 | 0.5d | 无 |
| P1-5 | 提取 DeleteFolderDialog（L1698–1841） | D1 | 0.5d | 无 |
| P1-6 | 提取 RenameNodeDialog（L1898–2019） | D1 | 0.5d | 无 |
| P1-7 | 提取 MoveNodeDialog（L2021–2179） | D1 | 0.5d | 无 |
| P1-8 | 提取 ExplorerTreeBuilder（L1193–1567） | D2 | 1.0d | P1-4~7 |

**并行说明：** P1-1/P1-2/P1-3（manager 提取）和 P1-4~P1-7（对话框提取）可完全并行执行。

**阶段风险：**
- WorkspaceTreeManager 体量最大（~700 行），提取范围可能遗漏辅助方法 → 缓解：提前标注精确行号（0255B 已做）
- 对话框提取后 NoteExplorer 内部回调连接断裂 → 缓解：每个对话框独立 PR，逐个验证
- NoteTagManager 的 filter→list 回调桥接需在 NotesController facade 中临时保留 → 缓解：S4 策略（facade 过渡期）

**阶段 DoD：**
- [ ] 3 个 manager（WorkspaceTree + Draft + Tag）提取完成（WorkspaceTree <550 行；Draft <300 行；Tag <350 行）
- [ ] 4 个对话框提取为独立 Widget
- [ ] ExplorerTreeBuilder 提取完成
- [ ] NotesController 保留为 facade，转发到已提取 manager
- [ ] 测试基线不变（313 pass / 0 known-fail）
- [ ] 阶段回归通过（回归清单 v1 + 工作区树专项）

**验证方式：** `flutter analyze` + `flutter test` + 回归清单 v1 + 工作区树 CRUD 专项走查 + 对话框交互验证

---

### Phase 2：中等/多孔域 + Coordinator 切换（Week 3，5 天）

| 字段 | 值 |
|------|-----|
| **时间窗口** | 2026-03-17 ~ 2026-03-21 |
| **阶段目标** | 提取剩余 manager + 创建 NotesCoordinator 替换 NotesController（唯一 breaking point） |
| **范围** | NoteTabManager · NoteListManager · NotesCoordinator · 消费者迁移（NotesPage/NoteContentArea `_controller` → `_coordinator`） |
| **不包含** | EntryShellPage SectionRegistry（Phase 3）· 新功能 |
| **前置依赖** | Phase 1 DoD 全部满足 |
| **负责人** | AI Agent（Owner 角色） |
| **协作角色** | TL（Coordinator PR 必须 TL review）、QA（阶段结束全量回归） |

**任务清单：**

| ID | 任务 | 对应 0255B | 预计工作量 | 前置 |
|----|------|-----------|-----------|------|
| P2-1 | 提取 NoteTabManager（L597–667, L1676–1879 + 整合现有 tab_manager） | B2 | 1.5d | P0-4 + P1-2 |
| P2-2 | 提取 NoteListManager（L1923–2148, L521–543） | C1 | 1.5d | P1-3 + P2-1 |
| P2-3 | 创建 NotesCoordinator + 消费者迁移（`_controller` → `_coordinator`） | C2 | 1.5d | P2-1 + P2-2 |
| P2-4 | 测试批量迁移（NotesController 引用 → NotesCoordinator） | — | 0.5d | P2-3 |

**阶段风险（本轮最高风险阶段）：**
- **R2 createNote 编排遗漏**：高基数跨域操作迁移到 coordinator 时可能遗漏副作用 → 缓解：`createNote` 现有 92 行逻辑按原样迁移，不重构内部流程
- **R3 测试 mock 断裂**：16 个测试文件（59 处匹配）直接引用 `NotesController`，Coordinator 切换时需逐文件适配 → 缓解：S4 策略分两阶段（P2-3 facade + P2-4 批量迁移）
- **R1 异步时序变化**：manager 分离后 notifyListeners 触发顺序可能改变 → 缓解：Coordinator 内 `notifyListeners()` 时序保持与原 controller 一致

**阶段 DoD：**
- [ ] 原 `notes_controller.dart` 文件删除
- [ ] `notes_coordinator.dart` <300 行，持有全部 6 个 manager
- [ ] 全部消费者（NotesPage, NoteContentArea, NoteExplorer, NoteTabManager, first_party_ui_slots, entry_shell_page）已迁移到 NotesCoordinator
- [ ] 测试基线不变（313 pass / 0 known-fail）
- [ ] 全量阶段回归通过（回归清单 v1 + 全主流程 + 工作区/标签/草稿专项）
- [ ] 无新增 P0 缺陷

**验证方式：** `flutter analyze` + `flutter test` + 回归清单 v1 全量 + 笔记创建→编辑→保存→标签→工作区→搜索端到端走查

---

### Phase 3：收口固化 + EntryShellPage 解耦（Week 4 前半，3 天）

| 字段 | 值 |
|------|-----|
| **时间窗口** | 2026-03-24 ~ 2026-03-26 |
| **阶段目标** | 消除 EntryShellPage 跨 feature import，固化门禁规则，输出复盘 |
| **范围** | SectionRegistry 落地 · code review checklist 固化 · 复盘文档 · 边界图更新 |
| **不包含** | 新模块拆分 · 功能开发 |
| **前置依赖** | Phase 2 DoD 全部满足 |
| **负责人** | AI Agent（Owner 角色） |
| **协作角色** | TL（验收签字）、TPM（收口汇报） |

**任务清单：**

| ID | 任务 | 对应 0255B | 预计工作量 | 前置 |
|----|------|-----------|-----------|------|
| P3-1 | 创建 SectionRegistry + 迁移 EntryShellPage 全部 section | E1 | 1.0d | P2-3 |
| P3-2 | 验证 EntryShellPage 零跨 feature import | — | 0.5d | P3-1 |
| P3-3 | 更新 As-is → To-be 边界图（0255B Section 3.1/3.2） | 文档 | 0.5d | P2-3 |
| P3-4 | 输出重构复盘文档（已完成/未完成/剩余债务/收益评估） | 文档 | 0.5d | P3-1~3 |
| P3-5 | TL 阶段验收 + 计划收口签字 | 签字 | 0.5d | P3-4 |

**阶段风险：**
- SectionRegistry 改变注册方式，所有 section 的测试需确认 → 缓解：注册点在 app 层，各 feature 测试无需改动
- 复盘范围失控 → 缓解：严格限定为"已完成/未完成/收益/债务"四个维度

**阶段 DoD：**
- [ ] EntryShellPage 零跨 feature import（`grep` 验证）
- [ ] 测试基线不变
- [ ] 复盘文档完成
- [ ] 边界图更新反映 To-be 实际状态
- [ ] 剩余技术债进入 Debt Log
- [ ] TL 签字收口

**验证方式：** `flutter analyze` + `flutter test` + `grep` 跨 feature import 验证 + 回归清单 v1

---

### 3.2 阶段间预留缓冲

| 位置 | 缓冲 | 用途 |
|------|------|------|
| Week 4 后半（3/27–3/28） | 2 天 | Phase 2 延期吸收 / Phase 3 未完成项 / 紧急 bugfix |

> 如果 Phase 2 按时完成且无重大回归，缓冲天可用于 0255B Section 6.3 次优先级候选的评估。

---

## 4. 任务拆解与关键路径

### 4.1 任务拆解粒度说明

所有任务满足以下约束：

- **可在 0.5–2 天内完成并提交 PR**
- 有清晰输入（前置任务产出）和输出（PR / 文档）
- 有明确责任人
- 有可验证的完成标准

### 4.2 统一任务清单

以下汇总 Section 3 各阶段的任务，补充模块归属、任务类型和验收标准。

#### Phase 0 任务（止血与执行基线）

| 任务 ID | 任务名称 | 模块 | 类型 | 前置依赖 | 负责人 | 预计人日 | 输出物 | 验收标准 | 状态 |
|---------|---------|------|------|---------|--------|---------|--------|---------|------|
| P0-1 | 创建 `workspace_port.dart` 抽象接口 | notes | 结构拆分 | 无 | Agent | 0.5 | PR（<30 行） | 接口声明 WorkspaceTreeManager 所需的全部方法签名（约 8–10 个）；`flutter analyze` 零警告 | 已完成（2026-02-24） |
| P0-2 | 编写回归清单 v1 | 仓库治理 | 回归 | 无 | Agent | 0.5 | 文档 | 覆盖笔记核心主流程 8–10 步（Section 5.2A）；TL 确认 | 已完成（2026-02-24） |
| P0-3 | 确认 PR 门禁规则 | 仓库治理 | 门禁/规范 | 无 | Agent | 0.5 | 文档确认 | 0255B D1–D8 + S1–S7 规则文档化（Section 6 落地）；TL 确认 | 已完成（2026-02-24） |
| P0-4 | 样板 PR：提取 NoteSaveTracker | notes/managers | 结构拆分 | P0-3 | Agent | 1.0 | PR | NoteSaveTracker 为独立 ChangeNotifier，<250 行，可独立实例化测试；原 controller facade 转发；CI 全绿 | 已完成（2026-02-24） |
| P0-5 | 样板 PR review + 合并 + 回归验证 | notes | 回归 | P0-4 | TL + Agent | 0.5 | 合并记录 | TL review 通过；回归清单 v1 已完成（REG-04 记录为非阻塞遗留）；测试基线不变（316 pass / 0 known-fail） | 已完成（2026-02-24） |

#### Phase 1 任务（清洁/中等缝隙提取 + Explorer 对话框）

| 任务 ID | 任务名称 | 模块 | 类型 | 前置依赖 | 负责人 | 预计人日 | 输出物 | 验收标准 | 状态 |
|---------|---------|------|------|---------|--------|---------|--------|---------|------|
| P1-1 | 提取 WorkspaceTreeManager | notes/managers | 结构拆分 | P0-1 | Agent | 2.0 | PR | 独立 ChangeNotifier，持有 workspace ×6 invoker + WorkspacePort，<550 行（物理行 533 / 非空行 499）；原 controller facade 转发；CI 全绿 | 已完成（2026-02-25） |
| P1-2 | 提取 NoteDraftManager | notes/managers | 结构拆分 | P0-4 | Agent | 1.0 | PR | 独立 ChangeNotifier，持有 noteUpdate invoker，<300 行；自保存定时器隔离；CI 全绿 | 已完成（2026-02-25） |
| P1-3 | 提取 NoteTagManager | notes/managers | 结构拆分 | 无 | Agent | 1.5 | PR | 独立 ChangeNotifier，持有 noteSetTags + tagsList invoker，<350 行；标签变更队列独立；CI 全绿 | 已完成（2026-02-25） |
| P1-4 | 提取 CreateFolderDialog | notes/dialogs | 结构拆分 | 无 | Agent | 0.5 | PR | 独立 StatefulWidget，~130 行，接收回调参数；可独立 widget test；CI 全绿 | 评审中（2026-02-25） |
| P1-5 | 提取 DeleteFolderDialog | notes/dialogs | 结构拆分 | 无 | Agent | 0.5 | PR | 独立 StatefulWidget，~150 行；含 dissolve/delete-all 选择；CI 全绿 | 未开始 |
| P1-6 | 提取 RenameNodeDialog | notes/dialogs | 结构拆分 | 无 | Agent | 0.5 | PR | 独立 StatefulWidget，~130 行；CI 全绿 | 未开始 |
| P1-7 | 提取 MoveNodeDialog | notes/dialogs | 结构拆分 | 无 | Agent | 0.5 | PR | 独立 StatefulWidget，~160 行；含移动目标加载；CI 全绿 | 未开始 |
| P1-8 | 提取 ExplorerTreeBuilder | notes | 结构拆分 | P1-4~7 | Agent | 1.0 | PR | 独立辅助类，<400 行，纯输入→输出；CI 全绿 | 未开始 |

#### Phase 2 任务（中等/多孔域 + Coordinator 切换）

| 任务 ID | 任务名称 | 模块 | 类型 | 前置依赖 | 负责人 | 预计人日 | 输出物 | 验收标准 | 状态 |
|---------|---------|------|------|---------|--------|---------|--------|---------|------|
| P2-1 | 提取 NoteTabManager | notes/managers | 结构拆分 | P0-4 + P1-2 | Agent | 1.5 | PR | 独立 ChangeNotifier，整合现有 `note_tab_manager.dart` (431行 UI) + controller Tab 逻辑，<400 行状态层；CI 全绿 | 未开始 |
| P2-2 | 提取 NoteListManager | notes/managers | 结构拆分 | P1-3 + P2-1 | Agent | 1.5 | PR | 独立 ChangeNotifier，持有 notesList + noteGet invoker，<400 行；CI 全绿 | 未开始 |
| P2-3 | 创建 NotesCoordinator + 消费者迁移 | notes | 结构拆分 | P2-1 + P2-2 | Agent | 1.5 | PR | Coordinator <300 行；6 个消费者文件（NotesPage, NoteContentArea, NoteExplorer, NoteTabManager, first_party_ui_slots, entry_shell_page）全部从 `_controller` 迁移到 `_coordinator`；原 `notes_controller.dart` 删除；CI 全绿 | 未开始 |
| P2-4 | 测试批量迁移 | notes | 测试 | P2-3 | Agent | 0.5 | PR | 16 个测试文件中的 `NotesController` 引用全部适配为 `NotesCoordinator`；313 pass / 0 known-fail 基线不变 | 未开始 |

#### Phase 3 任务（收口固化 + EntryShellPage 解耦）

| 任务 ID | 任务名称 | 模块 | 类型 | 前置依赖 | 负责人 | 预计人日 | 输出物 | 验收标准 | 状态 |
|---------|---------|------|------|---------|--------|---------|--------|---------|------|
| P3-1 | 创建 SectionRegistry + 迁移 EntryShellPage | entry/app | 结构拆分 | P2-3 | Agent | 1.0 | PR | EntryShellPage 零跨 feature import；各 section 通过 registry builder 注册；CI 全绿 | 未开始 |
| P3-2 | 验证 EntryShellPage 零跨 feature import | entry | 回归 | P3-1 | Agent | 0.5 | 验证记录 | `rg -n "features/" apps/lazynote_flutter/lib/features/entry/entry_shell_page.dart` 仅匹配 `features/entry/` 内部 import | 未开始 |
| P3-3 | 更新 As-is → To-be 边界图 | 文档 | 文档 | P2-3 | Agent | 0.5 | 文档 PR | 0255B Section 3.1/3.2 边界图反映拆分后实际状态 | 未开始 |
| P3-4 | 输出重构复盘文档 | 文档 | 文档 | P3-1~3 | Agent | 0.5 | 文档 | 覆盖"已完成/未完成/剩余债务/收益评估"四维度 | 未开始 |
| P3-5 | TL 阶段验收 + 计划收口签字 | 仓库治理 | 验收 | P3-4 | TL | 0.5 | 签字 | TL 确认全部 DoD 达成 | 未开始 |

### 4.3 关键路径

#### 4.3.1 主关键路径（串行依赖链）

```
P0-1 WorkspacePort
  └──► P1-1 WorkspaceTreeManager (2.0d)
         └──► [等待 Phase 1 全部完成]

P0-3 PR 门禁确认
  └──► P0-4 NoteSaveTracker 样板 PR (1.0d)
         ├──► P1-2 NoteDraftManager (1.0d)
         │      └──► P2-1 NoteTabManager (1.5d)
         │             └──► P2-2 NoteListManager (1.5d)
         │                    └──► P2-3 NotesCoordinator + 消费者迁移 (1.5d) ★ Breaking point
         │                           └──► P2-4 测试批量迁移 (0.5d)
         │                                  └──► P3-1 SectionRegistry (1.0d)
         └──► P0-5 样板 review (0.5d)

P1-3 NoteTagManager (无前置，1.5d)
  └──► P2-2 NoteListManager（filter 依赖）
```

**主关键路径总工期**：P0-3→P0-4→P1-2→P2-1→P2-2→P2-3→P2-4→P3-1 = **0.5+1.0+1.0+1.5+1.5+1.5+0.5+1.0 = 8.5 人日**

#### 4.3.2 并行路径

以下任务可与主关键路径**完全并行**：

| 并行组 | 任务 | 总工期 | 前置 |
|--------|------|--------|------|
| NoteExplorer 对话框 | P1-4 → P1-5 → P1-6 → P1-7 → P1-8 | 3.0d | 无（可从 Phase 0 第一天开始） |
| NoteTagManager | P1-3 | 1.5d | 无 |
| 文档收口 | P3-3 + P3-4 | 1.0d | P2-3 完成后 |

#### 4.3.3 关键路径延误影响

| 延误任务 | 影响 | 缓解 |
|---------|------|------|
| **P0-4 样板 PR 延期** | 全部 manager 提取推迟（阻塞 P1-2 → P2-1 → P2-2 → P2-3） | NoteSaveTracker 是最简 manager（纯状态枚举），延期概率低 |
| **P1-1 WorkspaceTreeManager 延期** | 不阻塞主关键路径（仅阻塞 Phase 1 DoD）；但如果延期进入 Phase 2 窗口，缓冲空间缩小 | 最大单体提取，行号已精确标注 |
| **P2-3 Coordinator 切换延期** | 阻塞测试迁移和 SectionRegistry，直接影响收口 | 唯一 breaking point，需 TL 优先 review |
| **P2-4 测试迁移延期** | 阻塞 Phase 3 所有任务 | 16 个测试文件的 mock 模式统一（均为构造函数注入 lambda），可批量替换 |

#### 4.3.4 不可替代任务

| 任务 | 必须由谁处理 | 原因 |
|------|------------|------|
| P0-5 样板 review | TL | 建立拆分节奏标杆，需 TL 确认拆分模式 |
| P2-3 Coordinator PR review | TL | 唯一 breaking point，消费者迁移影响 6 个文件 |
| P3-5 收口签字 | TL | 计划验收权限 |

---

## 5. 回归验证计划

### 5.1 回归策略（分层验证）

| 层级 | 验证时机 | 验证内容 | 执行人 | 通过标准 |
|------|---------|---------|--------|---------|
| **PR 级验证** | 每个 PR 合并前 | CI 全绿 + 作者自测 + Reviewer spot check | 作者 + Reviewer | CI 通过（含 `flutter analyze` + `flutter test` + `dart format`） |
| **阶段级验证** | Phase 0/1/2/3 结束时 | 核心主流程回归 + 高风险模块专项 + 非功能观察 | Agent + QA/TL | 回归清单 v1 全部通过 + 无新增 P0 缺陷 |
| **里程碑级验证** | 本轮结束（Phase 3 收口前） | 全量回归 + 端到端走查 + 边界图验证 | Agent + QA + TL | 全部回归通过 + 边界图与代码一致 |

### 5.2 回归范围定义

#### A. 核心主流程（必须，每阶段必跑）

以下为回归清单 v1 草案，覆盖笔记核心链路（创建→编辑→保存→组织→搜索）：

> P0-2 交付文件：`docs/reports/v0.2.5/frontend-review/04-regression-checklist-v1.md`（作为阶段执行记录的基线文档）。

| 用例 ID | 用例名称 | 关联模块 | 操作步骤 | 通过标准 |
|---------|---------|---------|---------|---------|
| REG-01 | 创建笔记并自动选中 | NotesController/Coordinator | 1. 点击创建按钮 2. 观察笔记列表 3. 观察编辑器 | 新笔记出现在列表顶部；编辑器自动聚焦；Tab 栏新增条目 |
| REG-02 | 编辑笔记内容触发自动保存 | NoteDraftManager | 1. 选中一条笔记 2. 输入内容 3. 等待自动保存 | 保存状态依次经过 dirty → saving → saved；badge 短暂显示后消失 |
| REG-03 | 手动切换笔记触发保存守卫 | NoteTabManager + NoteDraftManager | 1. 编辑笔记 A 2. 切换到笔记 B 3. 观察保存状态 | 笔记 A 内容已保存后才切换到 B；B 的内容正确加载 |
| REG-04 | 标签创建与筛选 | NoteTagManager | 1. 为笔记添加标签 2. 激活标签筛选 3. 清除筛选 | 标签正确显示；筛选后列表仅含匹配项；清除后恢复全列表 |
| REG-05 | 工作区创建文件夹 | WorkspaceTreeManager | 1. 在 Explorer 中右键 2. 创建文件夹 3. 观察树更新 | 文件夹出现在树中正确位置；Explorer 自动刷新 |
| REG-06 | 工作区拖拽移动笔记 | WorkspaceTreeManager | 1. 拖拽笔记到文件夹 2. 观察树更新 | 笔记移入目标文件夹；原位置消失；树结构正确 |
| REG-07 | 工作区删除文件夹（dissolve） | WorkspaceTreeManager | 1. 右键删除文件夹 2. 选择 dissolve 模式 | 文件夹消失；子项上移到父级；Tab 中打开的笔记不受影响 |
| REG-08 | 搜索笔记并打开 | SingleEntryController | 1. 在搜索栏输入关键词 2. 点击搜索结果 | 搜索结果正确展示；点击后在编辑器中打开对应笔记 |
| REG-09 | 窗口关闭保存守卫 | NotesPage + NoteDraftManager | 1. 编辑未保存笔记 2. 尝试关闭窗口 | 弹出保存确认对话框；确认后保存并关闭；取消后留在编辑器 |
| REG-10 | Section 导航往返 | EntryShellPage | 1. 从 Home 进入 Notes 2. 切换到 Tasks 3. 返回 Notes | 各 section 正确渲染；返回 Notes 后状态保持（Tab、列表、编辑器） |

#### B. 高风险模块专项验证（按阶段增量执行）

##### Phase 0 完成后增加

| 用例 ID | 用例名称 | 关联变更 | 操作步骤 | 通过标准 |
|---------|---------|---------|---------|---------|
| HF-01 | NoteSaveTracker 状态枚举独立后保存流程完整 | P0-4 | 1. 创建笔记 2. 编辑触发自保存 3. 手动 retry 4. 观察 badge | 保存状态枚举转换正确：clean→dirty→saving→saved；失败时显示 error 并可 retry |

##### Phase 1 完成后增加

| 用例 ID | 用例名称 | 关联变更 | 操作步骤 | 通过标准 |
|---------|---------|---------|---------|---------|
| HF-02 | WorkspaceTree CRUD 全流程 | P1-1 | 创建文件夹→在文件夹中创建笔记→重命名→移动→删除（两种模式） | 所有操作成功；树状态正确刷新；Tab 对账正确 |
| HF-03 | 草稿自动保存独立后时序正确 | P1-2 | 1. 快速连续编辑多笔记 2. 观察自保存定时器 3. 切换 Tab | 每个笔记的自保存独立触发；切换 Tab 时 flush 当前草稿 |
| HF-04 | 标签变更队列序列化 | P1-3 | 1. 快速连续添加/删除标签 2. 观察最终状态 | 标签变更按顺序执行；最终状态反映最后一次用户操作 |
| HF-05 | 对话框独立后交互完整 | P1-4~7 | 分别打开创建/删除/重命名/移动对话框，验证输入校验和结果反馈 | 每个对话框正确显示；校验规则不变；操作结果反馈不变 |
| HF-06 | ExplorerTreeBuilder 渲染与折叠 | P1-8 | 1. 展开/折叠多级文件夹 2. 验证 uncategorized 区域 3. 懒加载子节点 | 树渲染正确；折叠状态保持；懒加载触发正确 |

##### Phase 2 完成后增加（本轮最高风险）

| 用例 ID | 用例名称 | 关联变更 | 操作步骤 | 通过标准 |
|---------|---------|---------|---------|---------|
| HF-07 | NoteTabManager 独立后 Tab 完整生命周期 | P2-1 | open→activate→preview→pin→close→close-others→close-right | Tab 操作语义不变；preview→pin 双击提升正确；close 时保存守卫触发 |
| HF-08 | NoteListManager 独立后列表筛选联动 | P2-2 | 1. 加载列表 2. 标签筛选 3. 清除筛选 4. 列表分页 | 列表加载正确；筛选后项目正确；详情缓存命中 |
| HF-09 | Coordinator createNote 全编排 | P2-3 | 1. 创建笔记 2. 观察列表+Tab+草稿+标签+工作区+焦点 | 与原 NotesController.createNote() 行为完全一致（触达全部 8 个域） |
| HF-10 | Coordinator 切换后分屏操作 | P2-3 | 1. 分屏 2. 切换 pane 3. 各 pane 独立操作 4. 合并 pane | 分屏/合并操作正确；pane 间状态隔离 |
| HF-11 | 测试迁移后全量测试基线 | P2-4 | `flutter test` | 313 pass / 0 known-fail（不变） |

##### Phase 3 完成后增加

| 用例 ID | 用例名称 | 关联变更 | 操作步骤 | 通过标准 |
|---------|---------|---------|---------|---------|
| HF-12 | SectionRegistry 各 section 注册 | P3-1 | 从 Home 逐一进入全部 6 个 section | 每个 section 正确渲染；无 import 错误；切换流畅 |

#### C. 非功能验证（每阶段观察）

| 检查项 | 方法 | 通过标准 |
|--------|------|---------|
| 启动速度 | 人工观察冷启动到首帧 | 无明显退化（±500ms 内） |
| 页面切换流畅度 | Notes↔Tasks↔Calendar 快速切换 | 无卡顿、闪烁或白屏 |
| 异常日志 | 检查 `logs/` 目录 | 无新增 ERROR 级别日志 |
| 内存泄漏观察 | 反复打开/关闭 Notes section 10 次 | 无明显内存增长（Task Manager 观察） |

### 5.3 回归执行方式

| 方式 | 说明 | 执行时机 |
|------|------|---------|
| **自动化回归（CI）** | `flutter analyze`（零警告）+ `flutter test`（313 pass / 0 known-fail）+ `dart format`（零 diff） | **每个 PR** 合并前自动执行 |
| **手工回归（回归清单 v1）** | REG-01~10 步骤走查 | **每阶段结束**（Phase 0/1/2/3 各 1 次） |
| **高风险专项（增量）** | HF-XX 对应阶段的新增验证项 | 阶段结束时叠加到手工回归 |
| **非功能观察** | Section C 检查项 | 每阶段结束 + 收口前 |
| **里程碑全量** | REG 全量 + HF 全量 + 非功能 + 端到端走查 | Phase 3 收口前 |

### 5.4 回归通过标准

| 层级 | 通过标准 |
|------|---------|
| **PR 级** | CI 全绿（`flutter analyze` 零警告 + `flutter test` 不引入新失败 + `dart format` 零 diff） |
| **阶段级** | CI 全绿 + 回归清单 v1 全部通过 + 阶段专项验证无 blocker + 无新增 P0/P1 缺陷 |
| **里程碑级** | 全部 PR 级 + 阶段级标准达成 + 非功能无明显退化 + 边界图与代码一致 |

### 5.5 测试迁移影响矩阵

Coordinator 切换（P2-3 + P2-4）是测试影响最大的变更点。以下为需要适配的测试文件清单：

| 测试文件 | 行数 | 当前 `NotesController` 引用方式 | 迁移动作 |
|---------|------|-------------------------------|---------|
| `notes_page_c1_test.dart` | 256 | 构造函数注入 lambda invoker | 切换到 NotesCoordinator 构造 |
| `notes_page_c2_test.dart` | 193 | 同上 | 同上 |
| `notes_page_c3_test.dart` | 681 | 同上 | 同上 |
| `notes_page_c4_test.dart` | 1,629 | 同上 | 同上 |
| `notes_controller_tabs_test.dart` | 581 | 直接实例化 controller | 切换到 Coordinator 或对应 manager 单元测试 |
| `notes_controller_workspace_bridge_test.dart` | 381 | 直接实例化 controller | 切换到 Coordinator/WorkspaceTreeManager |
| `notes_controller_workspace_tree_guards_test.dart` | 457 | 直接实例化 controller | 切换到 WorkspaceTreeManager 单元测试 |
| `note_explorer_tree_test.dart` | 1,371 | 通过 widget 间接引用 controller | 切换 widget 参数为 coordinator |
| `note_explorer_workspace_delete_test.dart` | 108 | 同上 | 同上 |
| `notes_page_explorer_slot_wiring_test.dart` | 243 | 同上 | 同上 |
| `notes_ui_shell_alignment_test.dart` | 140 | 同上 | 同上 |
| `explorer_context_actions_test.dart` | 392 | 同上 | 同上 |
| `workspace_split_v1_test.dart` | 360 | 构造函数注入 + WorkspaceProvider | 切换到 Coordinator |
| `workspace_integration_flow_test.dart` | 354 | 构造函数注入 | 切换到 Coordinator |
| `tab_open_intent_migration_test.dart` | 122 | 构造函数注入 | 切换到 Coordinator |
| `cross_lane_workspace_extension_smoke_test.dart` | 128 | 构造函数注入 | 切换到 Coordinator |

**迁移策略（对应 0255B S4）：**

- **阶段一（Phase 0–1）：** controller 保留 facade，转发到已提取 manager。测试不变，无需迁移。
- **阶段二（Phase 2 P2-3 + P2-4）：** coordinator 替换 controller 后批量迁移。
  - 所有测试的 mock 模式统一（构造函数注入 lambda），可通过文本替换 + 少量手工适配完成。
  - 预计 3 类改动：① `import` 路径替换 ② 构造函数名替换 ③ 少量 getter 名适配。
  - 迁移完成后立即 `flutter test` 验证 313 pass / 0 known-fail。

**不受影响的测试文件**（无 `NotesController` 引用，无需迁移）：

`smoke_test.dart`（9 个路由测试）、`single_entry_*` 测试（5 个文件）、`calendar_*` 测试（3 个文件）、`tasks_page_test.dart`、`workspace_provider_test.dart`、`workspace_contract_smoke_test.dart`、`debug_logs_panel_test.dart`、`rust_bridge_test.dart`、`local_settings_store_test.dart`、core 测试（6 个文件）、`reminder_scheduler_test.dart`、`ui_slots_host_test.dart`、`command_parser_test.dart`、`command_router_test.dart`。

---

## 6. PR 门禁与合并规则

### 6.1 PR 分类

重构期间的 PR 分为三类，适用不同审核强度：

| 类型 | 定义 | 审核要求 | 示例 |
|------|------|---------|------|
| **Type A：纯重构 PR** | 不改用户可见行为，仅调整代码结构 | CI 全绿 + 1 名 Reviewer（Agent 可预审低风险 PR） | 提取 NoteSaveTracker、提取对话框 |
| **Type B：重构 + 小范围行为修正** | 拆分过程中发现并修正的 bug，需显式说明 | CI 全绿 + TL review + 回归清单对应项 | Coordinator 切换时修正 notifyListeners 时序 |
| **Type C：功能 PR（非重构）** | 新功能或非重构的 bugfix | 受冻结策略约束（`lib/features/notes/` 冻结期间仅允许 bugfix） | 新增命令注册到 SingleEntryController |

> **重构窗口期限制：** `lib/features/notes/` 目录内的 Type C PR 仅允许紧急 bugfix，需 TL 批准。

### 6.2 重构 PR 必填内容（作者责任）

每个重构 PR 描述必须包含以下字段（基于现有 `.github/PULL_REQUEST_TEMPLATE.md` 扩展）：

| 字段 | 必填 | 说明 |
|------|------|------|
| **背景/目的** | 是 | 关联体检项（0255A P0-1/P0-2/P1-1）或拆分方案条目（0255B A1–E1）或计划任务 ID（P0-1~P3-5） |
| **改动范围** | 是 | 列出修改/新增/删除的文件 |
| **是否影响接口** | 是 | NotesController/Coordinator public API 是否变化（Type A 应为"否"） |
| **验证方式** | 是 | 手工验证步骤 和/或 自动化测试命令 |
| **风险与回滚** | 是 | 本 PR 可否独立 revert？回滚后是否影响其他已合并 PR？ |
| **关联任务 ID** | 是 | 对应本文档 Section 4 的任务 ID（如 P1-1） |

### 6.3 审核与合并门禁

#### 6.3.1 CI 自动门禁（全部 PR 必须通过）

以下检查由 `.github/workflows/ci.yml` 的 `flutter_windows` job 自动执行：

| 检查项 | 命令 | 通过标准 |
|--------|------|---------|
| 代码格式 | `dart format --output=none --set-exit-if-changed .` | 零 diff |
| 静态分析 | `flutter analyze` | 零警告 |
| 单元/Widget 测试 | `flutter test` | 不引入新失败（基线 313 pass / 0 known-fail） |
| Windows 构建 | `flutter build windows --debug` | 构建成功 |

> 如 PR 涉及 `crates/lazynote_ffi/src/api.rs` 变更（本轮不预期），`api_contract_docs_guard` job 和 `rust_ubuntu` job 也需通过。

#### 6.3.2 人工审核门禁

| 角色 | 职责 | 参与条件 |
|------|------|---------|
| **作者（Agent）** | 提交完整 PR 描述 + 自测记录 + 回归步骤 | 所有 PR |
| **TL** | 技术 review（边界与结构合规）| **必须**：P0-5 样板 review、P2-3 Coordinator PR、P3-5 收口。**建议**：全部 manager 提取 PR |
| **QA/TL 兼任** | 阶段回归执行 | Phase 1/2 结束时各 1 次 |

#### 6.3.3 推荐合并门槛（checklist）

每个重构 PR 合并前，作者和 Reviewer 逐项确认：

- [ ] PR 描述完整（Section 6.2 必填项齐全）
- [ ] CI 全绿（lint / build / test）
- [ ] 至少 1 名 Reviewer 通过（高风险 PR 必须 TL 通过）
- [ ] 自测记录可复现（步骤 + 结果）
- [ ] 涉及核心流程时，回归清单 v1 对应步骤已执行
- [ ] 可回滚方案明确（至少可独立 revert PR）
- [ ] 无混入无关改动（纯重构 PR 不包含功能变更）
- [ ] 拆分后模块符合行数目标（WorkspaceTree <550 行；其他 manager/coordinator 阈值按 Section 4.2）
- [ ] 拆分后依赖方向符合 0255B D1–D8 规则

### 6.4 结构合规性检查（对应 0255B D1–D8）

每个拆分 PR 需通过以下结构检查（Reviewer 责任）：

> **前置说明：** D5、D6 的检查目标目录（`managers/`、`dialogs/`）在 Phase 0 基线中尚不存在，需在对应目录被首个 PR 创建后才开始执行。目录不存在时该规则自动通过（无文件即无违规）。

| 规则 | 检查方法 | 预期结果 |
|------|---------|---------|
| D1 Widget → Coordinator：允许 | 检查 Page/Explorer 的 import 列表 | 仅 import coordinator，不 import manager |
| D2 Widget → Manager：禁止 | `rg -n "import.*managers/" apps/lazynote_flutter/lib/features/notes/notes_page.dart apps/lazynote_flutter/lib/features/notes/note_content_area.dart apps/lazynote_flutter/lib/features/notes/note_explorer.dart` | 零匹配 |
| D3 Manager → Manager：受限允许 | 检查 manager 文件的构造函数参数 | 仅通过构造函数注入，无自行构造其他 manager |
| D4 Manager → Invoker：允许 | 检查 manager 的 import 和构造函数 | invoker 通过构造函数注入 |
| D5 Manager → Widget：禁止 | `if (Test-Path "apps/lazynote_flutter/lib/features/notes/managers") { rg -n "import.*flutter" apps/lazynote_flutter/lib/features/notes/managers/ } else { Write-Output "[skip] managers/ not created yet" }` | 目录存在时仅允许 `package:flutter/foundation.dart`（ChangeNotifier），无 material/widgets；目录不存在时 skip |
| D6 Dialog → Coordinator/Manager：禁止 | `if (Test-Path "apps/lazynote_flutter/lib/features/notes/dialogs") { rg -n "import.*(coordinator|manager)" apps/lazynote_flutter/lib/features/notes/dialogs/ } else { Write-Output "[skip] dialogs/ not created yet" }` | 目录存在时零匹配；目录不存在时 skip；对话框仅通过回调参数通信 |
| D7 跨 feature：禁止直接 import（分阶段） | `rg -n "features/workspace" apps/lazynote_flutter/lib/features/notes/` | **Phase 0–1：** 允许残留（现有 `notes_controller.dart` 中 workspace import 尚未迁移），但新增文件禁止引入新的跨 feature import；**Phase 2 P2-3 后：** 零匹配（`workspace_port.dart` 定义在 notes 内部，不 import `features/workspace/`；`WorkspaceTreeManager` 仅依赖 `WorkspacePort`）；**Phase 3 P3-1 后：** 零匹配（与 Phase 2 一致） |
| D8 notes_style 临时豁免 | `rg -n "notes_style" apps/lazynote_flutter/lib/features/tags/` | 允许 `tag_filter.dart` → `notes_style.dart`（纯样式常量） |

### 6.5 禁止事项

- **禁止**在重构 PR 中混入无关功能变更
- **禁止**在 `lib/features/notes/` 冻结期间绕过 TL review 直接合并 Type C PR
- **禁止**在未更新回归步骤时大改核心交互逻辑
- **禁止**"先合并后补文档/补验证"（除紧急修复，需 TL 批准）
- **禁止**在 Phase 0–1 期间修改 NotesController public API 签名（facade 过渡期保持稳定）
- **禁止**多个 manager 提取合并为单个 PR（每个 PR 只提取一个 manager，对应 0255B S1）

### 6.6 回滚策略

| 场景 | 回滚方式 | 影响 |
|------|---------|------|
| 单个 manager 提取 PR 引入回归 | `git revert <commit>` | controller facade 回退到直接实现，零用户影响 |
| 对话框提取 PR 引入回归 | `git revert <commit>` | NoteExplorer 回退到内联对话框，零用户影响 |
| Coordinator 切换 PR 引入回归 | `git revert <commit>`（需同时 revert P2-4 测试迁移） | 回退到 NotesController facade，所有已提取 manager 保留但 facade 恢复 |
| SectionRegistry PR 引入回归 | `git revert <commit>` | EntryShellPage 回退到直接 import |

> **关键约束：** Coordinator 切换（P2-3）是唯一的 breaking point。该 PR 和 P2-4 是强绑定的，回滚时必须一起 revert。因此建议 P2-3 和 P2-4 在同一天内连续合并。

## 7. 冻结策略与并行开发协同

### 7.1 冻结策略

本轮重构期间（2026-03-03 ~ 2026-03-28）执行三类冻结：

#### 7.1.1 模块冻结

| 冻结模块 | 冻结范围 | 允许的变更 | 禁止的变更 |
|---------|---------|-----------|-----------|
| `lib/features/notes/` | 全目录 | 本轮重构 PR（P0-1~P3-2）+ 紧急 bugfix（需 TL 批准） | 新功能、结构性改动（非计划拆分）、UI 样式大改 |
| `lib/features/workspace/` | `workspace_provider.dart`, `workspace_models.dart` | bugfix | 新增 public API、改变 TreeNode 数据结构 |

#### 7.1.2 接口冻结

| 冻结接口 | 冻结时段 | 说明 |
|---------|---------|------|
| NotesController public API 签名 | Phase 0–1 | facade 过渡期保持稳定，消费者不需修改。Phase 2 P2-3 统一切换到 NotesCoordinator |
| FFI invoker typedef 签名 | 全程 | 12 个 invoker typedef 不变，仅下沉到对应 manager 构造函数 |
| WorkspaceProvider public API | 全程 | 不改变现有 API，notes 通过 WorkspacePort 抽象访问 |

#### 7.1.3 窗口冻结

| 冻结窗口 | 时段 | 原因 |
|---------|------|------|
| Phase 2 核心拆分期（Week 3） | 2026-03-17 ~ 2026-03-21 | Coordinator 切换是唯一 breaking point，该周限制所有非重构 PR 进入 `lib/features/notes/` |
| Phase 3 收口期（Week 4 前半） | 2026-03-24 ~ 2026-03-26 | SectionRegistry 迁移涉及 EntryShellPage，限制 entry 目录并行改动 |

### 7.2 冻结例外审批流程

当必须在冻结模块中进行非计划变更时：

| 步骤 | 责任人 | 动作 |
|------|--------|------|
| 1. 提出例外申请 | 申请人 | 说明变更原因、影响范围、是否可推迟到重构窗口后 |
| 2. 评估冲突风险 | Agent（Owner） | 评估与当前重构 PR 的文件冲突、接口冲突 |
| 3. 审批决策 | TL | 批准/拒绝。批准条件：紧急 bugfix 或用户可见阻塞 |
| 4. 同步 TPM | TPM | 记录例外，更新风险台账 |
| 5. 执行约束 | 申请人 | 例外 PR 必须在重构 PR 之前或之后合并，不穿插 |

### 7.3 并行开发协作规则

| 规则 | 说明 |
|------|------|
| 新功能优先落在未冻结模块 | tasks、calendar、search、settings、diagnostics、reminders 不受限 |
| 冻结模块改动需 TL 审批 | 按 Section 7.2 流程执行 |
| 优先通过接口扩展降低冲突 | 如需扩展 notes 能力，通过 coordinator public API 暴露，不直接改 manager 内部 |
| 重构 PR 优先合并 | 冻结期间出现并行 PR 时，重构 PR 优先 merge，功能 PR rebase |
| 每日同步冲突风险 | 多人改同目录时，在每日同步中提前识别文件级冲突 |

### 7.4 FFI / Rust 接口变更控制

| 规则 | 说明 |
|------|------|
| 本轮不改 Rust 接口签名 | `crates/lazynote_ffi/src/api.rs` 中的 12 个 notes/workspace/tags 相关函数签名不变 |
| Flutter 侧仅做调用收口 | invoker 从 NotesController 下沉到 manager，调用点不变 |
| 如必须改（不预期） | 列为独立任务，需 TL 拍板 + 触发 `gen_bindings.ps1` + CI `rust_ubuntu` job 验证 |

---

## 8. 风险管理与止损机制

### 8.1 风险台账

以下为本轮执行期间的风险清单（不同于 0255A 的代码风险，这里聚焦执行风险）：

| 风险 ID | 风险描述 | 触发信号 | 概率 | 影响 | 缓解措施 | Owner | 状态 | 升级条件 |
|---------|---------|---------|------|------|---------|-------|------|---------|
| EX-1 | Coordinator 切换引入回归 | P2-3 合并后回归清单出现失败项 | 中 | 高 | S4 两阶段迁移 + P2-3/P2-4 同天合并 + 回滚预案（Section 6.6） | Agent + TL | 监控中 | 回归清单失败 ≥2 项，立即暂停拉 TL 决策 |
| EX-2 | NoteListManager 多孔域提取困难 | P2-2 实施超过预计人日 50%（即 >2.25d） | 中 | 高 | 等所有下游 manager 就位后再提取；行号已精确标注（0255B Section 6.2 C1） | Agent | 监控中 | 延期 >1 天，评估是否将 NoteListManager 简化为"仅列表加载"（标签联动推迟） |
| EX-3 | TL review 带宽不足 | PR 等待 review 超过 2 个工作日 | 中 | 中 | Phase 1 低风险 PR 可由 Agent 预审；高风险 PR（P0-5, P2-3, P3-5）TL 必须 review | TL | 监控中 | 连续 2 个 PR 等待 >2 天，TPM 协调 TL 带宽 |
| EX-4 | 异步时序变化导致 UI 闪烁 | manager 拆分后 `notifyListeners()` 触发顺序改变，消费者收到部分更新 | 中 | 中 | 保持原 controller 内的 notifyListeners 调用顺序；coordinator 编排方法按原有顺序调用各 manager | Agent | 监控中 | 用户可见 UI 回退（列表闪烁/Tab 状态不一致），暂停拆分排查时序 |
| EX-5 | 并行功能需求冲入冻结模块 | PM 要求在 `lib/features/notes/` 中加功能 | 低 | 中 | 冻结策略（Section 7）+ 例外审批流程 | PM + TL | 监控中 | 超过 2 次例外申请，TPM 重新评估冻结窗口 |
| EX-6 | 测试基线新增失败 | `flutter test` 出现新失败 | 低 | 高 | 每个 PR 合并前 CI 自动门禁（Section 6.3.1）；新增失败立即阻塞合并 | Agent | 监控中 | 新增失败 ≥1 个，暂停重构排查 |
| EX-7 | WorkspacePort 接口不足 | P1-1 WorkspaceTreeManager 实施时发现 port 缺少方法签名 | 低 | 低 | S5 最小化设计 + port 可在 Phase 1 内迭代补充 | Agent | 监控中 | 需要补充 >3 个方法签名，重新评估 port 设计 |

### 8.2 止损/降级策略

当出现以下情况时，触发复盘并可能缩范围：

| 触发条件 | 处置策略 | 决策人 |
|---------|---------|--------|
| 连续 2 个重构 PR 引入回归（回归清单失败） | 暂停后续拆分，先补回归覆盖和门禁，修复已引入问题 | TL |
| 核心阶段任务偏差超过预计 30%（如 Phase 2 超时 1.5 天以上） | 评估是否将 Phase 3 缩减为"仅收口文档"（SectionRegistry 推迟到下轮） | TL + TPM |
| 回归缺陷堆积 ≥3 个未修复 P0/P1 | 停止新拆分，全力修复回归缺陷 | TL |
| 并行需求 ≥3 次冲入冻结模块 | 重新评估冻结窗口是否可行；可能改为"仅 Phase 0–1 执行，Phase 2–3 推迟" | TPM + PM |
| TL review 堵塞导致 PR 积压 ≥4 个 | TPM 协调 TL 专项 review 时间或引入额外 reviewer | TPM |

### 8.3 降级方案（scope cut 优先级）

当需要缩减范围时，按以下优先级砍：

| 砍减顺序 | 砍减项 | 影响 | 剩余价值 |
|---------|--------|------|---------|
| 1（最先砍） | P3-1 SectionRegistry（EntryShellPage 解耦） | Rule E 违规保留（6 处跨 feature import），不影响 notes 内部拆分成果 | NotesController → Coordinator 拆分完成，核心目标达成 |
| 2 | P1-8 ExplorerTreeBuilder | NoteExplorer 仍含树渲染逻辑（~375 行），但 4 个对话框已独立 | 对话框可独立测试，Explorer 行数已降低 ~550 行 |
| 3 | P3-3 + P3-4 文档收口 | 边界图和复盘文档推迟，不影响代码产出 | 代码拆分完成但文档欠债 |
| 4（最后砍） | P2-2 NoteListManager 中的标签联动部分 | NoteListManager 仅保留"列表加载 + 详情缓存"，标签筛选联动保留在 coordinator | 降低多孔域复杂度，但 NoteListManager 职责不完整 |

> **底线：** 即使全部降级，Phase 0（止血 + 门禁） + Phase 1 前 4 项 manager 提取（WorkspaceTreeManager, NoteDraftManager, NoteTagManager, NoteSaveTracker）必须完成。这 4 个 manager 覆盖 NotesController 9 域中的 4 域，是本轮最低可接受产出。

---

## 9. 资源、角色与会议节奏

### 9.1 角色职责（执行期）

| 角色 | 人员 | 执行期职责 | 参与阶段 |
|------|------|-----------|---------|
| **前端 Owner** | AI Agent（Claude） | 拆分主导：编写全部重构 PR、执行自测、管理回归清单、风险上报、计划跟踪更新 | Phase 0–3 全程 |
| **TL** | WYI1223 | 技术 review：样板 PR 审核（P0-5）、高风险 PR 审核（P2-3）、架构争议拍板、阶段验收签字（P3-5） | 必须：P0-5, P2-3, P3-5；建议：全部 manager PR |
| **TPM** | 待指定 | 计划跟踪：依赖协调、冻结确认、例外审批协调、会议组织、风险升级、周报收集 | Phase 0–3 全程 |
| **PM** | 待指定 | 范围取舍：功能冻结确认（P4 前置条件）、并行需求取舍、scope cut 决策参与 | 启动前 + 需要范围调整时 |
| **QA（或 TL 兼任）** | 待指定 | 回归执行：Phase 1/2 结束时各执行 1 次阶段回归（回归清单 v1 + 阶段专项），里程碑全量回归 | Phase 1/2 结束时 + Phase 3 收口前 |

### 9.2 RACI 矩阵（关键动作）

| 动作 | Agent（Owner） | TL | TPM | PM | QA |
|------|--------------|----|----|----|----|
| 编写重构 PR | **R** | C | I | — | — |
| Review 重构 PR（低风险 Type A） | R | **A** | I | — | — |
| Review 高风险 PR（P0-5, P2-3） | R | **R+A** | I | — | — |
| 阶段回归执行 | R | C | I | — | **R** |
| 冻结例外审批 | C | **A** | R | C | — |
| Scope cut 决策 | C | **A** | R | **A** | I |
| 风险升级 | **R** | A | **R** | I | — |
| 计划跟踪与周报 | **R** | C | **R** | I | I |
| 阶段验收签字 | R | **A** | I | — | C |

> R = Responsible（执行），A = Accountable（拍板），C = Consulted（咨询），I = Informed（知会）

### 9.3 会议与同步机制

| 会议 | 频率 | 参与人 | 时长 | 议题 |
|------|------|--------|------|------|
| **每日同步** | 每工作日 | Agent + TL（异步文字即可） | 5–10 分钟 | 昨日完成 / 今日计划 / 阻塞项 / 冲突风险 |
| **周度检查** | 每周五 | Agent + TL + TPM | 15–30 分钟 | 阶段进度 / 风险变化 / 下周计划 / 需拍板事项 |
| **阶段验收会** | Phase 0/1/2/3 结束时各 1 次 | Agent + TL + QA + TPM | 30 分钟 | 对照 DoD 逐项确认 / 回归结果 / 风险台账更新 / 下阶段 go/no-go |

> **最小化原则：** 每日同步可异步（文字消息或 PR comment），不强制同步会议。周度检查和阶段验收需同步。

### 9.4 沟通渠道

| 渠道 | 用途 |
|------|------|
| PR comment | 技术 review 讨论、自测记录、回归结果 |
| 风险台账文档 | 风险状态更新（每阶段结束时同步） |
| 周报（Section 10.3 模板） | 正式进度汇报 |

---

## 10. 度量指标与汇报格式

### 10.1 执行期指标

| # | 指标 | 数据来源 | 观察频率 | 基线 / 目标 |
|---|------|---------|---------|------------|
| M1 | 阶段任务完成率 | Section 4.2 任务清单状态列 | 每阶段结束 | 100%（每阶段全部任务完成或有明确处置） |
| M2 | 重构任务完成数 | Section 4.2 任务清单状态列 | 每周 | Phase 0: 5, Phase 1: 8, Phase 2: 4, Phase 3: 5 = 总计 22（含代码 PR、文档确认、验收签字等全部任务类型） |
| M3 | 重构 PR 平均 review 时长 | PR 创建到合并时间 | 每周 | 目标 ≤2 个工作日（低风险）/ ≤3 个工作日（高风险） |
| M4 | CI 通过率 | CI workflow 记录 | 每个 PR | 100%（所有合并的 PR 必须 CI 全绿） |
| M5 | 回归通过率（阶段级） | 回归清单执行记录 | 每阶段结束 | REG-01~10 全通过 + 阶段专项无 blocker |
| M6 | 新增回归缺陷数（重构相关） | 回归执行发现的问题 | 每阶段结束 | 目标 0 个 P0/P1；≥1 个 P0 触发暂停 |
| M7 | 测试基线变化 | `flutter test` 输出 | 每个 PR | 313 pass / 0 known-fail（不变） |
| M8 | 冻结模块违规改动次数 | `rg` 检查 + PR review | 每周 | 目标 0 次；≥2 次触发冻结策略复审 |

### 10.2 结构治理效果指标（本轮结束时度量）

| # | 指标 | 度量方法 | 基线（重构前） | 目标（重构后） |
|---|------|---------|-------------|-------------|
| G1 | NotesController 最大文件行数 | `wc -l` | 3,160 行 | 删除（由 Coordinator <300 行 + 5 个 Manager 各自阈值 + WorkspaceTree <550 行替代） |
| G2 | NoteExplorer 最大文件行数 | `wc -l` | 2,280 行 | ~1,180 行（去除 4 对话框 549 行 + TreeBuilder ~375 行 + 提取后缩减） |
| G3 | 单文件最大方法数 | 代码阅读 | 73（NotesController） | <20（每个 manager） |
| G4 | 单文件状态字段数 | 代码阅读 | 60（NotesController） | <15（每个 manager） |
| G5 | `notifyListeners()` 最大调用数 | `rg -c "notifyListeners"` | 62（NotesController） | <10（每个 manager，按域精准通知） |
| G6 | 跨 feature import 数 | `rg -c "features/" entry_shell_page.dart` | 6（EntryShellPage） | 0（SectionRegistry 完成后） |
| G7 | Rule E 违规总数 | Lakos 依赖图分析 | 16 处 | ≤2 处（仅 notes_style D8 豁免 + search_results_view 保留） |
| G8 | 测试基线 | `flutter test` | 313 pass / 0 known-fail | 不变（313 pass / 0 known-fail） |

### 10.3 周报模板

每周五由 Agent（Owner）输出，发送至 TL + TPM：

```
# 重构周报 — Week N（YYYY-MM-DD ~ YYYY-MM-DD）

## 本周完成
- [ ] 任务 ID / PR 链接 / 合并状态
- [ ] ...

## 本周风险变化
- 新增：（描述 + 影响）
- 缓解：（描述 + 措施）
- 升级：（描述 + 需要决策）

## 下周计划
- 任务 ID / 预计产出
- 阻塞项（如有）

## 需要拍板事项
- （范围 / 时间 / 资源调整）

## 计划偏差
- 偏差描述 + 调整建议（如有）

## 指标快照
| 指标 | 本周值 | 趋势 |
|------|--------|------|
| 任务完成率 | X/Y | — |
| PR 合并数 | N | — |
| PR 平均 review 时长 | Xd | — |
| 新增回归缺陷 | N | — |
| 测试基线 | 312/1 | 不变 |
```

---

## 11. 阶段验收与计划收口

### 11.1 每阶段验收（必须）

每阶段完成时执行以下验收流程：

| 步骤 | 责任人 | 动作 | 产出 |
|------|--------|------|------|
| 1. 对照 DoD 逐项勾选 | Agent | 检查 Section 3 各阶段 DoD 每一项是否达成 | DoD checklist 记录 |
| 2. 回归结果记录 | Agent + QA | 执行回归清单 v1（REG-01~10）+ 阶段专项（HF-XX）+ 非功能观察（Section C） | 回归报告 |
| 3. 风险台账更新 | Agent | 更新 Section 8.1 风险状态（已缓解 / 新发现 / 升级） | 风险台账 |
| 4. 未完成项处理 | Agent + TL | 每个未完成项明确处置：转下阶段 / 取消 / 升级决策 | 处置记录 |
| 5. 阶段签字 | TL | 确认 DoD 全部达成或偏差已批准 | 签字记录 |

#### 各阶段验收清单

**Phase 0 验收：**

- [x] `workspace_port.dart` 已合并（P0-1）
- [x] NoteSaveTracker 样板 PR 已合并，测试基线不变（P0-4, P0-5）
- [x] 回归清单 v1 已确认（P0-2）
- [x] PR 门禁规则文档化（P0-3）
- [x] 回归清单 v1 走查通过（REG-04 记为非阻塞遗留）
- [x] 风险台账无新增 P0 项

**Phase 1 验收：**

- [x] WorkspaceTreeManager 已合并（P1-1），<550 行（物理行口径）
- [x] NoteDraftManager 已合并（P1-2），<300 行
- [x] NoteTagManager 已合并（P1-3），<350 行
- [ ] 4 个对话框已合并（P1-4~7），各 <200 行
- [ ] ExplorerTreeBuilder 已合并（P1-8），<400 行
- [ ] 测试基线不变（313 pass / 0 known-fail）
- [ ] 回归清单 v1 全通过 + HF-01~06 无 blocker
- [ ] NotesController facade 转发正常，原 public API 不变

**Phase 2 验收：**

- [ ] NoteTabManager 已合并（P2-1），<400 行
- [ ] NoteListManager 已合并（P2-2），<400 行
- [ ] NotesCoordinator 已合并（P2-3），<300 行
- [ ] 测试批量迁移完成（P2-4），313 pass / 0 known-fail
- [ ] 原 `notes_controller.dart` 已删除
- [ ] 6 个消费者文件全部使用 `_coordinator`
- [ ] 回归清单 v1 全通过 + HF-01~11 无 blocker
- [ ] 非功能验证无明显退化

**Phase 3 验收：**

- [ ] SectionRegistry 已合并（P3-1），EntryShellPage 零跨 feature import
- [ ] P3-2 验证通过
- [ ] 边界图更新完成（P3-3）
- [ ] 复盘文档输出（P3-4）
- [ ] 全部 DoD 达成（P3-5 TL 签字）
- [ ] 里程碑全量回归通过（REG-01~10 + HF-01~12 + 非功能）

### 11.2 本轮结束收口

Phase 3 验收通过后，输出以下收口产物：

#### 11.2.1 已完成拆分项清单

| # | 拆分项 | 原位置 | 新位置 | 行数 | PR 链接 | 状态 |
|---|--------|--------|--------|------|---------|------|
| 1 | WorkspacePort | — | `notes/workspace_port.dart` | <30 | — | 待执行 |
| 2 | NoteSaveTracker | `notes_controller.dart` | `notes/managers/note_save_tracker.dart` | <250 | — | 待执行 |
| 3 | WorkspaceTreeManager | `notes_controller.dart` | `notes/managers/workspace_tree_manager.dart` | <550（物理行口径） | — | 已完成（P1-1） |
| 4 | NoteDraftManager | `notes_controller.dart` | `notes/managers/note_draft_manager.dart` | <300 | — | 已完成（P1-2） |
| 5 | NoteTagManager | `notes_controller.dart` | `notes/managers/note_tag_manager.dart` | <350 | — | 已完成（P1-3） |
| 6 | NoteTabManager | `notes_controller.dart` + `note_tab_manager.dart` | `notes/managers/note_tab_manager.dart` | <400 | — | 待执行 |
| 7 | NoteListManager | `notes_controller.dart` | `notes/managers/note_list_manager.dart` | <400 | — | 待执行 |
| 8 | NotesCoordinator | `notes_controller.dart`（替代） | `notes/notes_coordinator.dart` | <300 | — | 待执行 |
| 9 | CreateFolderDialog | `note_explorer.dart` | `notes/dialogs/create_folder_dialog.dart` | ~130 | — | 待执行 |
| 10 | DeleteFolderDialog | `note_explorer.dart` | `notes/dialogs/delete_folder_dialog.dart` | ~150 | — | 待执行 |
| 11 | RenameNodeDialog | `note_explorer.dart` | `notes/dialogs/rename_node_dialog.dart` | ~130 | — | 待执行 |
| 12 | MoveNodeDialog | `note_explorer.dart` | `notes/dialogs/move_node_dialog.dart` | ~160 | — | 待执行 |
| 13 | ExplorerTreeBuilder | `note_explorer.dart` | `notes/explorer_tree_builder.dart` | <400 | — | 待执行 |
| 14 | SectionRegistry | `entry_shell_page.dart` | `app/section_registry.dart` | — | — | 待执行 |

#### 11.2.2 未完成项与原因（收口时填写）

| # | 未完成项 | 原因 | 处置 |
|---|---------|------|------|
| — | （收口时填写） | — | 转下轮 / 取消 / 已降级处理 |

#### 11.2.3 剩余技术债（进入 Debt Log）

以下为本轮已知但不处理的技术债：

| # | 技术债 | 来源 | 严重度 | 触发重评估条件 |
|---|--------|------|--------|--------------|
| D1 | `notes_style.dart` 跨 feature import（D8 豁免） | 0255B Section 3.3.2 | P2 | tags 模块超过 500 行或被第 3 个 feature 引用 |
| D2 | `search_results_view.dart` 跨 feature import | 0255A Section 4.3 | P2 | search 模块结构拆分时 |
| D3 | NotesPage / NoteContentArea 未独立拆分 | 0255B Section 6.3 | P1 | NotesPage 超过 1000 行或 v0.3 分屏增强 |
| D4 | WorkspaceProvider 未独立拆分 | 0255B Section 6.3 | P1 | 新增第 2 个 consumer（非 notes） |
| D5 | P2 模块未拆分（SingleEntryController, DebugLogsPanel 等） | 0255B Section 7.1 | P2 | 任一模块行数增长超过 50% |
| D6 | [已关闭 2026-02-24] `smoke_test.dart` CalendarPage L67 Row overflow known-fail | 0255A Section 0 | Closed | 已在主干修复，测试基线更新为 313 pass / 0 known-fail |

#### 11.2.4 收益评估（收口时填写）

| 维度 | 基线 | 实际 | 是否达到预期 |
|------|------|------|------------|
| NotesController 消除 | 3,160 行上帝对象 | （收口时填写） | — |
| NoteExplorer 瘦化 | 2,280 行 | （收口时填写） | — |
| EntryShellPage Rule E 合规 | 6 处违规 | （收口时填写） | — |
| 测试基线保持 | 312/1 | （收口时填写） | — |
| 单文件最大行数 | 3,160 行 | （收口时填写） | — |
| 跨 feature import 数 | 16 处 | （收口时填写） | — |

#### 11.2.5 下一轮建议（收口时填写）

收口时根据实际执行情况，给出以下建议：

- 是否继续下一轮拆分（P2 模块）
- 是否需要补充自动化回归测试
- 是否需要调整架构规则（如 Rule E 的 shared 层建设）
- v0.3 功能开发是否可安全叠加在新架构上

### 11.3 计划文档更新与归档

| 动作 | 时机 | 责任人 |
|------|------|--------|
| 更新 `03-phased-refactor-plan.md` 中所有任务状态列 | 每个 PR 合并后 | Agent |
| 更新 Section 11.2 收口表格 | Phase 3 验收后 | Agent |
| 更新 `docs/releases/v0.2.5/README.md` 进度标记 | 每阶段结束 | Agent |
| 同步 `PR-0252` 前置条件指向本计划 | Phase 3 收口后 | Agent |
| 归档本计划到 `docs/reports/v0.2.5/frontend-review/` | 已在位 | — |

### 11.4 向 PR-0252 交接

本计划（PR-0255C）的最终产出直接作为 `PR-0252-dart-modular-refactor-and-decoupling` 的执行输入：

| PR-0252 所需输入 | 本计划对应 |
|-----------------|----------|
| 拆分执行顺序 | Section 3（Phase 0–3）+ Section 4（任务清单 + 关键路径） |
| 每个 PR 的验收标准 | Section 4.2 各任务验收标准列 |
| 回归验证方式 | Section 5（回归清单 v1 + 高风险专项 + CI 门禁） |
| PR 合并规则 | Section 6（PR 分类 + 门禁 + 合并 checklist） |
| 冻结策略 | Section 7 |
| 风险与回滚 | Section 8 + Section 6.6 |
| 阶段验收清单 | Section 11.1 |

> PR-0252 执行时，以本计划 Section 4.2 的任务清单为"逐项可执行指令"，以 Section 5/6/7 为"执行约束"，以 Section 11.1 为"阶段检查点"。

---

> **注意：** 本计划基于 PR-0255A（体检报告）和 PR-0255B（拆分方案）输出，解决"谁在什么时候做、怎么验证、什么条件能合并和收口"。不含运行时代码变更。
