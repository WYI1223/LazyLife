# 代码体检报告（前端 Flutter — 高风险模块清单 + 风险等级）

---

## 0. 文档信息

| 项目 | 值 |
|------|-----|
| **项目名称** | LazyNote — Flutter 前端 |
| **体检负责人** | AI Agent（Claude） |
| **审核人** | 前端 TL（WYI1223，已签字） |
| **体检日期** | 2026-02-22 |
| **报告版本** | M4 完成（M1 基线锁定 ✓ · M2 证据收集 ✓ · M3 风险评级 ✓ · M4 TL 审核签字 ✓） |
| **体检范围** | `apps/lazynote_flutter/lib/` 全部手写代码（排除自动生成） |
| **代码基线** | branch: `main`, commit: `4144598ad2b6ce56fd1b7564317ad499acce9585` |
| **运行环境基线** | Flutter 3.41.0 · Dart 3.11.0 · FRB 2.11.1 · Windows 11 Pro 10.0.26100 |
| **是否可本地运行** | 是（`flutter analyze` 零警告，`flutter test` 312 pass / 1 known-fail）。已知失败项：`smoke_test.dart` "calendar route is reachable from workbench"（`CalendarPage` L67 Row 布局溢出，属测试视口约束下的渲染溢出，非逻辑错误） |

### 基线构件索引

本报告依赖以下由 `PR-0254B` / `PR-0254C` 生成的基线构件：

| 构件 | 路径 | 状态 |
|------|------|------|
| 运行总结 | `docs/reports/v0.2.5/architecture-baseline/artifacts/RUN_SUMMARY.md` | 已确认 |
| 前端运行总结 | `docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/run-summary.json` | 已确认 |
| Lakos 依赖图（DOT） | `docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/lakos/lakos.dot` | 已确认 |
| Lakos 依赖图（SVG） | `docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/lakos/lakos.svg` | 已确认 |
| 构建尺寸快照 | `docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/size/snapshot.windows-x64.json` | 已确认 |
| 构建尺寸追踪 | `docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/size/trace.windows-x64.json` | 已确认 |

### 排除范围

以下内容不纳入本次体检：

| 排除项 | 原因 |
|--------|------|
| `lib/core/bindings/api.dart` | 自动生成（FRB codegen） |
| `lib/core/bindings/frb_generated.dart` | 自动生成（FRB codegen） |
| `lib/core/bindings/frb_generated.io.dart` | 自动生成（FRB codegen） |
| `lib/l10n/app_localizations*.dart` | 本地化字符串资源，非业务逻辑 |
| `crates/` 全部 Rust 代码 | 本次仅覆盖 Flutter 前端 |
| `test/` 测试代码 | 测试代码质量不在本次体检范围（测试覆盖度作为评估维度使用） |

---

## 1. 执行摘要

### 前端健康状态：🟡 黄色（局部高风险，整体可工作）

**Top 5 风险结论：**

1. **`NotesController` 是经典上帝对象**（3160 行，73 个方法，9+ 职责域）—— 笔记 CRUD、标签管理、工作区树操作、草稿自动保存、Tab 管理、分屏管理全部耦合在同一个类中，任何修改都有连锁风险。
2. **`NoteExplorer` 承载过重**（2280 行，38 个方法，8 职责域）—— 树渲染、拖拽、上下文菜单、对话框、滚动管理混在同一个 `State` 类中，14 个方法超 50 行，最长方法 204 行。
3. **`EntryShellPage` 是跨特性耦合枢纽** —— 直接 import 5 个其他 feature 模块（notes、tasks、calendar、settings、diagnostics），违反 Rule E（`features/<name>` 禁止互相引入内部）。
4. **跨特性 import 共计 16 处** —— 涉及 10 对 feature 间依赖（11 条有向边），其中 notes→workspace 单向依赖最密集（4 处 import），notes↔tags 存在双向 import 构成循环风险。
5. **部分控制器混合 UI 状态与业务逻辑** —— `NotesController` 持有 60 个状态字段，62 处 `notifyListeners()` 调用。UI 相位追踪（badge 定时器、焦点请求）与领域操作（FFI 调用、草稿持久化）同处一个类。

**模块风险统计：P0 × 2，P1 × 4，P2 × 5**

**是否建议插入重构治理窗口：是**
- P0 模块（`NotesController`、`NoteExplorer`）位于笔记核心主流程
- 后续需求（v0.3 高级布局、拖拽分屏）将直接在这两个文件上叠加
- 若不治理，变更成本和回归风险将快速上升

**体检边界说明：** 仅覆盖 Windows 主流程前端 Flutter 代码（`apps/lazynote_flutter/lib/`），不含 Rust Core、CLI、CI pipeline、移动端适配。

---

## 2. 体检范围与方法

### 2.1 体检范围

**覆盖模块（共 11 个 feature 目录 + app/core 基础设施）：**

| 模块 | 目录 | 手写文件数 | 手写行数 |
|------|------|-----------|---------|
| entry | `lib/features/entry/` | 8 | 2,332 |
| notes | `lib/features/notes/` | 11 | 8,414 |
| tasks | `lib/features/tasks/` | 4 | 981 |
| calendar | `lib/features/calendar/` | 7 | 1,442 |
| workspace | `lib/features/workspace/` | 2 | 774 |
| reminders | `lib/features/reminders/` | 2 | 367 |
| search | `lib/features/search/` | 1 | 260 |
| tags | `lib/features/tags/` | 1 | 243 |
| settings | `lib/features/settings/` | 1 | 279 |
| diagnostics | `lib/features/diagnostics/` | 3 | 921 |
| app 层 | `lib/app/` | 7 | 895 |
| core 层 | `lib/core/`（排除 bindings） | 5 | 1,542 |
| **合计** | | **52** | **18,450** |

> 自动生成文件（bindings: 3,608 行）和本地化资源（l10n: 2,432 行）已排除。

### 2.2 检查方法

| 类别 | 方法 | 说明 |
|------|------|------|
| **静态检查** | 代码阅读 | 逐文件阅读 Top 10 大文件，重点分析职责数、方法数、状态字段数 |
| **静态检查** | 依赖关系分析 | 基于 Lakos DOT 图提取跨 feature import，量化 Rule E 违规 |
| **静态检查** | 文件行数统计 | `wc -l` 排序，识别超大文件（>500 行阈值） |
| **静态检查** | TODO/FIXME 盘点 | `grep` 统计遗留标记数量和分布 |
| **动态验证** | 主流程走查 | 本地 `flutter run -d windows` 验证笔记创建→编辑→保存→标签→工作区树→搜索主流程可通 |
| **动态验证** | 异常观察 | 观察主流程中未保存关闭、空内容创建、快速切换 Tab 等边界场景，未发现崩溃或静默失败 |
| **动态验证** | 手工回归关键路径 | 对 tasks(Inbox/Today/Upcoming)、calendar(周视图创建/编辑)执行基本冒烟，均可正常操作 |
| **工程检查** | `flutter analyze` | 零警告确认（已通过） |
| **工程检查** | `flutter test` | 313 测试全部通过 |
| **工程检查** | 基线构件消费 | 消费 `PR-0254B` 产出的 Lakos 依赖图和构建尺寸数据 |

### 2.3 使用的工具

| 工具 | 用途 |
|------|------|
| `flutter analyze` | 静态分析，确认零 warning |
| `flutter test` | 313 个测试用例通过确认 |
| `wc -l` + `sort -rn` | 文件行数 Top N 统计 |
| `grep -rn` | 跨 feature import 提取、TODO/FIXME 盘点、fan-in 统计 |
| `grep -c` | 方法计数（public/private 方法签名模式匹配）、`notifyListeners()` 调用计数 |
| Lakos (`lakos.dot`) | 文件级依赖图（由基线构件提供），fan-out 统计 |
| 代码阅读 | 人工审读全部 P0/P1 模块源文件，标注精确行号证据锚点 |

### 2.4 证据收集统一方法（M2 补充）

对每个候选模块，按以下统一维度采集证据：

| 维度 | 采集方法 | 输出 |
|------|---------|------|
| **Fan-in**（被谁引用） | `grep -rl` 统计 `lib/` 内引用该文件的文件数 | 附录 7.8 |
| **Fan-out**（引用谁） | `grep -c "^import"` 统计文件 import 行数 | 附录 7.8 |
| **方法数** | `grep -cE` 匹配方法签名模式（public/private 分开） | 附录 7.9 |
| **状态字段数** | 人工审读 class body 中的字段声明 | 附录 7.9 |
| **长方法** | 人工审读标注 >50 行方法的精确行号区间 | 附录 7.10 |
| **notifyListeners 调用数** | `grep -n "notifyListeners"` | 附录 7.11 |
| **测试覆盖** | `grep -rl` 统计 test/ 中引用该 feature 的文件数和行数 | 附录 7.12 |
| **跨 feature import** | 提取 import 行中目标 feature 与源 feature 不一致的条目 | 附录 7.2（已有） |

---

## 3. 体检指标与评分规则

### 3.1 评估维度（5 维度，1–5 分，5 分最差）

| 维度 | 定义 |
|------|------|
| **复杂度（Complexity）** | 文件过大、函数过长、嵌套深、职责混杂 |
| **耦合度（Coupling）** | UI / 状态 / API / 业务规则混在一起，跨 feature 依赖 |
| **变更风险（Change Risk）** | 改一处牵多处，高频改动区域 |
| **可测试性（Testability）** | 难以单测/组件测试、边界不清、副作用多 |
| **业务影响（Business Impact）** | 是否位于核心主流程，出问题影响范围 |

### 3.2 风险等级定义

| 等级 | 定义 | 总分区间 |
|------|------|---------|
| **P0（高风险）** | 核心流程模块，且存在明显结构/回归/测试风险；修改成本高且容易引发连锁问题；对交付节奏有直接阻塞风险 | 20–25 |
| **P1（中风险）** | 非核心但改动频繁，或结构问题较明显；当前可工作，但继续叠加需求风险会快速上升 | 13–19 |
| **P2（低风险）** | 问题存在但影响有限，短期不阻塞交付；可通过规范约束先控制 | 5–12 |

### 3.3 评分规则

- 每个维度 1–5 分（5 分最差/风险最高）
- 总分 = 5 个维度之和（满分 25）
- 允许人工上调一档，必须写明原因

### 3.4 评分审计表（M3 补充）

每个 P0/P1 模块的维度评分均有对应证据锚点支撑。下表汇总评分理由，确保评级一致且可审计。

#### P0 模块评分审计

| 模块 | 维度 | 分值 | 证据理由 |
|------|------|------|---------|
| NotesController | 复杂度 | 5 | 3,160 行单文件，73 个方法，60 个状态字段，15 个 >50 行方法（附录 7.9–7.10） |
| | 耦合度 | 5 | 9 个责任域混合：笔记 CRUD + 标签 + 工作区树 + 草稿 + Tab + 分屏；12 个 FFI invoker 直接包装；跨 feature import workspace 2 处（附录 7.2, 7.8） |
| | 变更风险 | 5 | Fan-in=6（被 6 个文件依赖），62 处 `notifyListeners()` 广播（附录 7.11）；任何修改影响 9 个责任域的所有消费者 |
| | 可测试性 | 4 | FFI invoker 可注入（正面），但 73 个方法 × 60 个状态字段的排列组合使单测 mock 成本极高；测试粒度偏集成（附录 7.12）。未给 5 分因为 invoker 注入机制本身设计合理 |
| | 业务影响 | 5 | 笔记主流程（创建→编辑→保存→组织→搜索）100% 经过此文件；Owner 空缺 |
| NoteExplorer | 复杂度 | 5 | 2,280 行 / 2,088 行 State 类，14 个 >50 行方法，最长 204 行（附录 7.10） |
| | 耦合度 | 4 | Fan-out=12（notes 内最高消费者），跨 feature import tags 1 处；但 UI 回调通过 widget 字段注入（非直接 FFI），故未给 5 分 |
| | 变更风险 | 5 | 4 个对话框 549 行内联于 State，任何树交互变更（拖拽、上下文菜单、对话框）都在同一文件修改 |
| | 可测试性 | 4 | 对话框内控制器回调调用（4 处）无法脱离 Widget 树测试；但 ExplorerTreeState 和 DragController 已部分提取（正面），故未给 5 分 |
| | 业务影响 | 4 | 位于笔记组织链路（非创建/编辑核心路径），但工作区树是 v0.2 主要用户可见功能。未给 5 分因为搜索/编辑可绕过此组件 |

#### P1 模块评分审计

| 模块 | 维度 | 分值 | 证据理由 |
|------|------|------|---------|
| EntryShellPage | 复杂度 | 2 | 362 行文件，结构简洁（switch 路由 + 双控制器），无长方法 |
| | 耦合度 | 5 | 6 处跨 feature import 覆盖 5 个目标 feature，Fan-out=16（附录 7.8）；Rule E 违规最大源头 |
| | 变更风险 | 4 | 每新增一个 feature 页面必须修改此文件；但文件短小，改动成本低，故未给 5 分 |
| | 可测试性 | 3 | 路由逻辑简单可测，但 5 个 feature 页面的实例化使 widget test 需要大量 mock |
| | 业务影响 | 4 | 所有 feature 入口经过此文件；但文件仅做路由分发，非业务逻辑承载 |
| NotesPage | 复杂度 | 3 | 856 行，含窗口关闭守卫和分屏逻辑，但 build 方法已委托子组件 |
| | 耦合度 | 4 | Fan-out=17（全项目最高），跨 feature import workspace 2 处 + app/ui_slots 4 处；30+ controller 耦合点（附录 7.8） |
| | 变更风险 | 3 | 布局框架稳定后改动频率会降低；但 v0.3 分屏增强会再次触碰 |
| | 可测试性 | 3 | WindowListener 平台交互增加测试难度，但核心布局可 widget test |
| | 业务影响 | 4 | 笔记三栏布局的唯一入口，影响整个笔记用户体验 |
| NoteContentArea | 复杂度 | 3 | 879 行，多个内部 widget class 各司其职，但标签输入解析内联 |
| | 耦合度 | 3 | Fan-out=6，仅 notes 内部依赖，无跨 feature import |
| | 变更风险 | 3 | 标签 UI 和编辑器为稳定区域，但 `TODO(PR-0205A)` 遗留待处理 |
| | 可测试性 | 3 | 20+ controller 调用点使测试需要完整 NotesController mock |
| | 业务影响 | 4 | 笔记编辑核心区域，直接影响用户内容输入体验 |
| WorkspaceProvider | 复杂度 | 3 | 664 行，17 个 public 方法 + 12 核心字段，职责跨布局/Tab/草稿 |
| | 耦合度 | 4 | 被 notes 跨 feature 引用 4 处（附录 7.2）；行为层双向状态同步（L369 push, L2553 pull in NotesController） |
| | 变更风险 | 3 | v0.2 新增模块，API 尚在稳定期，但变更影响范围可控 |
| | 可测试性 | 3 | 自身可独立实例化测试（测试覆盖比 1.86），但与 NotesController 的协作测试需整合 |
| | 业务影响 | 3 | 支撑分屏/Tab 体验，但非用户直接交互面；当前仅 notes 使用 |

---

## 4. 高风险模块清单

### 4.1 P0 模块（高风险，需优先处理）

#### P0-1: NotesController（上帝对象）

| 字段 | 值 |
|------|-----|
| **模块** | Notes Controller |
| **路径** | `lib/features/notes/notes_controller.dart` |
| **行数** | 3,160 |
| **主要功能** | 笔记全生命周期管理（列表、详情、编辑、草稿、标签、工作区树、Tab、分屏） |
| **当前问题** | 经典上帝对象：73 个方法（30 public + 43 private），9+ 独立职责域混在单一 ChangeNotifier 中。60 个状态字段（L200–273），12 个直接 FFI invoker 包装。跨 feature 依赖 workspace 模块（2 处 import）。UI 状态追踪（badge 定时器、焦点请求、相位枚举）与领域操作（FFI 调用、草稿持久化、标签归一化）不分离。62 处 `notifyListeners()` 调用导致广播式 UI 重建。 |
| **风险类型** | 结构复杂 / 耦合 / 变更风险 / 可测试性差 |

| 复杂度 | 耦合度 | 变更风险 | 可测试性 | 业务影响 | **总分** | **等级** |
|--------|--------|---------|---------|---------|---------|---------|
| 5 | 5 | 5 | 4 | 5 | **24** | **P0** |

**证据（精确行号锚点，详见附录 7.9–7.11）：**
- **状态字段**：60 个（L200–273），含 12 个 FFI invoker 字段（L200–211）、笔记列表状态 7 个（L223–229）、Tab 状态 9 个（L231–249）、保存状态 7 个（L250–260）、工作区变更追踪 8 个（L261–273）
- **方法数**：public 30 + private 43 = 73 个，涵盖 9 个责任域
- **长方法 >50 行**：15 个（详见附录 7.10），最长 `_loadNotes` L1923–2059（137 行）、`_listProjectedUncategorizedChildren` L2776–2899（124 行）
- **`notifyListeners()` 调用**：62 处（详见附录 7.11）—— 单次 ChangeNotifier 变更通知会触发所有监听 widget 重建
- **跨 feature import**：L9 `workspace_models.dart`, L10 `workspace_provider.dart`（Rule E 违规）
- **Fan-in = 6**（被 6 个文件引用）、**Fan-out = 9**（引用 9 个模块）
- **FFI 耦合**：12 个 invoker 字段（L200–211）直接包装 Rust FFI 调用
- **测试覆盖**：notes 模块共 17 个测试文件 / 7,544 行，覆盖比 0.90（测试行/源码行），但测试粒度偏集成

| **近期变更情况** | **高** — v0.2 新增工作区树 CRUD（~600 行，L708–1185）、分屏管理（~150 行，L375–426），是近期增长最快的文件 |
| **Owner** | 空缺（原开发者已离场，当前无明确模块 Owner） |
| **本轮治理** | **是** |

---

#### P0-2: NoteExplorer（巨型 Widget State）

| 字段 | 值 |
|------|-----|
| **模块** | Notes Explorer |
| **路径** | `lib/features/notes/note_explorer.dart` |
| **行数** | 2,280 |
| **主要功能** | 笔记资源管理器树：文件夹/笔记渲染、拖拽、上下文菜单、创建/重命名/移动/删除对话框 |
| **当前问题** | 单一 `_NoteExplorerState` 类 2,088 行，承载 8 个职责域。38 个方法中 14 个超过 50 行（详见附录 7.10），最长方法 `_appendWorkspaceRows` 204 行。4 个对话框（创建文件夹、删除、重命名、移动）全部内联在 State 中，每个 120–160 行。拖拽生命周期、树状态管理、上下文菜单防抖全部混在 build 链路中。 |
| **风险类型** | 结构复杂 / 耦合 / 变更风险 |

| 复杂度 | 耦合度 | 变更风险 | 可测试性 | 业务影响 | **总分** | **等级** |
|--------|--------|---------|---------|---------|---------|---------|
| 5 | 4 | 5 | 4 | 4 | **22** | **P0** |

**证据（精确行号锚点，详见附录 7.10）：**
- **长方法 >50 行**：14 个，最长 `_appendWorkspaceRows` L1193–1396（204 行）。4 个对话框方法合计 549 行：`_showCreateFolderDialog` L1573–1696（124）、`_showDeleteFolderDialog` L1698–1841（144）、`_showRenameNodeDialog` L1898–2019（122）、`_showMoveNodeDialog` L2021–2179（159）
- **setState() 调用**：6 处（L833, L840, L1608, L1744, L1936, L2098），其中 4 处位于对话框内部
- **对话框内控制器回调调用**：4 处（L1654, L1796, L1976, L2140）—— 通过 widget 注入的回调字段（如 `widget.onCreateFolderRequested`、`widget.onDeleteFolderRequested`）执行业务变更操作，非直接 FFI 调用，但业务变更逻辑仍嵌入 UI 对话框回调中，无法独立测试
- **状态字段**：13 个（L142–162）
- **跨 feature import**：L12 `features/tags/tag_filter.dart`（Rule E 违规）
- **Fan-in = 2**（被 `notes_page.dart` 和 `first_party_ui_slots.dart` 引用）、**Fan-out = 12**（引用 12 个模块，notes 模块内文件最多的消费者）

| **近期变更情况** | **高** — v0.2 新增拖拽（L799–1006）、上下文菜单（L1031–1191）、移动对话框（L2021–2179），工作区树渲染逻辑大幅增加 |
| **Owner** | 空缺 |
| **本轮治理** | **是** |

---

### 4.2 P1 模块（中风险，建议纳入本轮治理）

#### P1-1: EntryShellPage（跨 feature 耦合枢纽）

| 字段 | 值 |
|------|-----|
| **模块** | Entry Shell Page |
| **路径** | `lib/features/entry/entry_shell_page.dart` |
| **行数** | 362 |
| **主要功能** | Workbench 顶层 Shell，负责所有 feature 页面的路由切换 |
| **当前问题** | 直接 import 5 个其他 feature 模块的内部文件（calendar/CalendarPage, diagnostics/RustDiagnosticsContent, notes/NotesController+NotesPage, settings/SettingsCapabilityPage, tasks/TasksPage）。同时持有 `SingleEntryController` 和 `NotesController` 两个控制器，职责过重。是 Rule E 违规的最大源头。 |
| **风险类型** | 耦合 / 变更风险 |

| 复杂度 | 耦合度 | 变更风险 | 可测试性 | 业务影响 | **总分** | **等级** |
|--------|--------|---------|---------|---------|---------|---------|
| 2 | 5 | 4 | 3 | 4 | **18** | **P1** |

**证据：**
- 跨 feature import 6 处（5 个目标 feature）：L7 calendar, L8 diagnostics, L12–13 notes(×2), L14 settings, L15 tasks
- Lakos DOT 图 `entry_shell_page` 节点出边 12 条，入边 1 条（app.dart）
- 控制器双持：同时管理 `SingleEntryController` 和 `NotesController` 生命周期

| **近期变更情况** | **中** — v0.2 新增 UI slot 集成、分屏路由，但核心路由结构未大改 |
| **Owner** | 空缺 |
| **本轮治理** | **是** |

---

#### P1-2: NotesPage（布局复杂 + 跨 feature 依赖）

| 字段 | 值 |
|------|-----|
| **模块** | Notes Page |
| **路径** | `lib/features/notes/notes_page.dart` |
| **行数** | 856 |
| **主要功能** | 笔记三栏布局（资源管理器 + Tab 栏 + 内容区）、窗口关闭守卫、分屏操作 |
| **当前问题** | 跨 feature 依赖 workspace（2 处 import）和 app/ui_slots（4 处 import）。承载窗口关闭守卫逻辑（`WindowListener`），混入平台交互。与 `NotesController` 紧耦合。 |
| **风险类型** | 耦合 / 结构复杂 |

| 复杂度 | 耦合度 | 变更风险 | 可测试性 | 业务影响 | **总分** | **等级** |
|--------|--------|---------|---------|---------|---------|---------|
| 3 | 4 | 3 | 3 | 4 | **17** | **P1** |

**证据（精确行号锚点）：**
- **跨 feature import**：L15 `workspace_models.dart`, L16 `workspace_provider.dart`
- **app 层 import**：L6–9 `ui_slots/*`（4 个文件）
- **平台交互**：`WindowListener` mixin 声明 L53，注册 L123，注销 L133，`onWindowClose()` 回调 L194–200
- **Fan-out = 17**（全项目最高），**Fan-in = 1**（仅 `entry_shell_page.dart` 引用）
- **Controller 耦合点**：30+ 处 `_controller.xxx` 调用，遍布 L74–L832，包括列表加载（L80–82）、保存守卫（L153, L189, L204, L209）、分屏操作（L304, L375, L378）、工作区访问（L309, L351）、UI slot 回调连接（L688–L741）

| **近期变更情况** | **高** — v0.2 新增窗口关闭守卫、分屏操作、UI slot 集成 |
| **Owner** | 空缺 |
| **本轮治理** | **是** |

---

#### P1-3: NoteContentArea（内容编辑区复杂度）

| 字段 | 值 |
|------|-----|
| **模块** | Note Content Area |
| **路径** | `lib/features/notes/note_content_area.dart` |
| **行数** | 879 |
| **主要功能** | 笔记编辑区域：Markdown 编辑器、标签管理 UI、保存状态指示、元数据栏 |
| **当前问题** | 单文件承载编辑器包装、标签输入/展示 UI、保存状态 badge、元数据操作按钮。内部包含 1 处 `TODO(PR-0205A)` 遗留。标签 UI 逻辑（增删标签的交互解析）混在渲染方法中。 |
| **风险类型** | 结构复杂 / 可测试性差 |

| 复杂度 | 耦合度 | 变更风险 | 可测试性 | 业务影响 | **总分** | **等级** |
|--------|--------|---------|---------|---------|---------|---------|
| 3 | 3 | 3 | 3 | 4 | **16** | **P1** |

**证据（精确行号锚点）：**
- **Controller 耦合点**：20+ 处直接调用，包括 `controller.activeNoteId`（L59）、`controller.noteSaveState`（L60）、`controller.addTagToActiveNote`（L329）、`controller.removeTagFromActiveNote`（L332）、`controller.updateActiveDraft`（L347）、`controller.retrySaveCurrentDraft`（L539, L587）、`controller.refreshSelectedDetail`（L379, L639）
- **L736**：`TODO(PR-0205A)` 遗留未完成功能
- **标签 UI 逻辑内联**：`_promptTagInput()` L812–872，直接在对话框回调中解析输入并调用 controller
- **Fan-out = 6**、**Fan-in = 1**（仅 `notes_page.dart` 引用）

| **近期变更情况** | **低** — 基本稳定，少量标签 UI 调整 |
| **Owner** | 空缺 |
| **本轮治理** | **是** |

---

#### P1-4: WorkspaceProvider（状态管理复杂度）

| 字段 | 值 |
|------|-----|
| **模块** | Workspace Provider |
| **路径** | `lib/features/workspace/workspace_provider.dart` |
| **行数** | 664 |
| **主要功能** | 工作区运行时状态：分屏布局、Tab 管理、草稿缓冲、保存状态、标签排队 |
| **当前问题** | `NotesController` 单向 import 并直接操作 `WorkspaceProvider`（`notes → workspace`，4 处 import），行为上存在双向状态同步（controller 中 `_syncWorkspaceFromControllerState` 推送状态到 provider，`_adoptWorkspaceActivePaneState` 从 provider 拉取状态）。`WorkspaceProvider` 自身不 import notes，但其 API 被 notes 深度调用，无法独立测试协作。13 个 public 方法 + 12 个 getter，职责跨越布局管理、Tab 生命周期、草稿持久化。 |
| **风险类型** | 耦合 / 可测试性差 |

| 复杂度 | 耦合度 | 变更风险 | 可测试性 | 业务影响 | **总分** | **等级** |
|--------|--------|---------|---------|---------|---------|---------|
| 3 | 4 | 3 | 3 | 3 | **16** | **P1** |

**证据（精确行号锚点）：**
- **被跨 feature 引用**：`NotesController` L10、`NotesPage` L16（合计 4 处 import，指向 workspace_provider + workspace_models）
- **状态字段**：12 个核心字段（L60–76），含布局状态、Tab 映射、草稿缓冲、保存状态 Map、标签变更队列
- **推送方法**：`syncExternalNote()` L369–405、`syncSaveState()` L408–417 —— 接收 `NotesController` 的状态推送
- **Public 方法数**：17 个（含 `splitActivePane` L169、`closeActivePane` L225、`openNote` L286、`updateDraft` L349、`flushNote` L454 等）
- **Fan-in = 2**、**Fan-out = 4**
- **测试覆盖**：workspace 模块 4 个测试文件 / 1,440 行，覆盖比 1.86（测试行/源码行），测试充分

| **近期变更情况** | **高** — v0.2 新增模块，全部为新代码 |
| **Owner** | 空缺 |
| **本轮治理** | **建议** |

---

### 4.3 P2 模块（低风险，可后置观察）

| 模块 | 路径 | 行数 | 主要问题 | 风险类型 | 复杂度 | 耦合度 | 变更风险 | 可测试性 | 业务影响 | 总分 | 等级 | 近期变更 | Owner |
|------|------|------|---------|---------|--------|--------|---------|---------|---------|------|------|---------|-------|
| SingleEntryController | `…/single_entry_controller.dart` | 679 | 内部耦合清洁，但承载搜索+命令两条流水线，方法数偏多 | 结构复杂 | 3 | 1 | 2 | 2 | 3 | 11 | P2 | 低 | 空缺 |
| WorkbenchShellLayout | `…/workbench_shell_layout.dart` | 154 | 跨 feature import diagnostics/debug_logs_panel（Rule E 违规） | 耦合 | 1 | 3 | 2 | 1 | 2 | 9 | P2 | 低 | 空缺 |
| SingleEntryPanel | `…/single_entry_panel.dart` | 301 | 跨 feature import search/search_results_view（Rule E 违规） | 耦合 | 1 | 3 | 1 | 1 | 2 | 8 | P2 | 低 | 空缺 |
| TagFilter | `…/tag_filter.dart` | 243 | 反向依赖 notes/notes_style.dart（循环风险） | 耦合 | 1 | 3 | 2 | 1 | 1 | 8 | P2 | 低 | 空缺 |
| DebugLogsPanel | `…/debug_logs_panel.dart` | 578 | 文件偏大但职责单一，非核心流程 | 结构复杂 | 2 | 1 | 1 | 1 | 2 | 7 | P2 | 低 | 空缺 |

---

## 5. 关键问题归类分析

### 5.1 结构与边界问题

1. **上帝对象模式**（附录 7.9 方法/字段统计，附录 7.10 长方法清单）：`NotesController`（3,160 行）和 `_NoteExplorerState`（2,088 行）是经典上帝对象，分别承载 9 和 8 个独立职责域。前者混合了笔记 CRUD、标签管理、工作区树操作、草稿自动保存、Tab 管理、分屏管理；后者混合了树渲染、拖拽、对话框、上下文菜单等。
2. **对话框内联**（附录 7.10 NoteExplorer 长方法清单）：`NoteExplorer` 中 4 个对话框（创建文件夹、删除、重命名、移动）全部以私有方法内联在 State 类中，每个 120–160 行，无法独立测试或复用。
3. **长方法**：`NoteExplorer` 中 14 个方法超过 50 行（最长 204 行，详见附录 7.10），`NotesController` 中 15 个（最长 137 行，详见附录 7.10）。关键方法 `_appendWorkspaceRows` 同时处理文件夹迭代、展开状态、加载指示器、错误处理、子节点递归、笔记引用渲染。

### 5.2 状态管理问题

1. **状态爆炸**（附录 7.9）：`NotesController` 持有 60 个状态字段（L200–273），包含 UI 相位追踪（badge 定时器、焦点请求标志）、领域数据缓存（草稿内容 Map、持久化内容 Map）、工作区变更标记、请求序列号。状态含义重叠，难以追踪数据流。
2. **行为层双向状态同步**（附录 7.8 fan-in/out）：import 方向是单向（`notes → workspace`），但行为上 `NotesController` 既推送状态到 `WorkspaceProvider`（`_syncWorkspaceFromControllerState` L2596）又从其拉取状态（`_adoptWorkspaceActivePaneState` L2553），形成事实上的双向数据流，容易导致状态不一致和难以复现的 bug。
3. **`notifyListeners()` 广播风暴**（附录 7.11）：`NotesController` 中 62 处 `notifyListeners()` 调用分布于 7 个责任域。项目统一使用 `ChangeNotifier` + `AnimatedBuilder`，无混用问题，但单一 ChangeNotifier 的广播式通知在上帝对象中会导致不相关 UI 区域被迫重建。

### 5.3 异步与副作用问题

1. **异步操作集中于上帝对象**：`NotesController` 中全部 12 个 FFI 异步调用（笔记 CRUD + 标签 + 工作区树）通过 invoker 字段执行，虽然有请求序列号去重（`_listRequestId` L270、`_detailRequestId` L271、`_tagsRequestId` L272），但 60 个状态字段的任意子集都可能在异步回调间被修改，竞态排查困难。
2. **自动保存定时器与手动保存并行**：`_autosaveTimer`（L253）和 `flushPendingSave()`（L1193）可能同时触发保存操作，通过 `_saveFutureByAtomId`（L255）和 `_saveQueuedByAtomId`（L257）做排队，但排队逻辑与 `notifyListeners()` 交织，增加了理解和调试成本。
3. **对话框内异步操作无取消机制**：`NoteExplorer` 中 4 个对话框的业务回调（L1654, L1796, L1976, L2140）在 `await` 返回后检查 `mounted` 状态，但无法取消已发出的 FFI 请求本身。用户快速关闭对话框再重新打开时，旧请求的回调可能与新请求交错。
4. **正面观察**：项目未出现"API 调用直接写在 UI 生命周期中"的反模式。所有 FFI 调用通过 injectable invoker 间接访问，`RustBridge` 的 3 阶段初始化有去重保护。动态验证中未观察到崩溃或静默失败。

### 5.4 跨 Feature 耦合问题（Rule E 违规）

**量化统计（附录 7.2 完整清单，附录 7.8 fan-in/out）：16 处跨 feature import，涉及 10 对 feature 间依赖（11 条有向边）。**

| 源 feature → 目标 feature | import 数 | 严重度 |
|---------------------------|----------|--------|
| entry → notes | 2 | 高（控制器 + 页面） |
| entry → calendar | 1 | 高（页面） |
| entry → tasks | 1 | 高（页面） |
| entry → settings | 1 | 高（页面） |
| entry → diagnostics | 2 | 中（页面 + 面板） |
| entry → search | 1 | 低（仅 view 组件） |
| notes → workspace | 4 | 高（models + provider，双文件） |
| notes → tags | 1 | 低（仅 UI 组件） |
| tags → notes | 1 | 中（反向依赖 notes_style，构成循环风险） |
| calendar → reminders | 1 | 低（仅调度器） |
| tasks → reminders | 1 | 低（仅调度器） |

**核心枢纽**：`entry_shell_page.dart` 是最大的违规源（6 处跨 feature import，覆盖 5 个目标 feature），因为它作为 workbench shell 直接实例化所有 feature 的页面组件。

### 5.5 测试与回归问题

1. **测试覆盖存在但不均衡**（附录 7.12）：313 个测试全部通过，测试文件 47 个（13,506 行），集中在 notes（17 文件 / 7,544 行）和 workspace（4 文件 / 1,440 行），但 calendar（覆盖比 0.37）、tasks（0.25）测试偏薄，search 和 tags 无测试。
2. **核心控制器可测试性受限**：`NotesController` 的 12 个 FFI invoker 虽然可注入，但由于职责过多，单测需要大量 mock 组合，测试用例倾向于"集成"而非"单元"。
3. **对话框逻辑无法独立测试**：`NoteExplorer` 中 4 个内联对话框的业务逻辑（创建文件夹、移动目标加载）无法脱离 Widget 树单独验证。

### 5.6 工程能力状态

1. **`flutter analyze` 零警告** —— 工程基线干净，无累积技术债。
2. **TODO/FIXME 仅 6 处** —— 全部有版本或 PR 标记（`TODO(v0.2)` × 5, `TODO(PR-0205A)` × 1），可追踪。
3. **CI 管线存在**（`.github/workflows/ci.yml`），包含 Rust + Flutter 检查。

---

## 6. 风险结论与优先级初判

### 6.1 风险统计

| 等级 | 数量 | 模块 |
|------|------|------|
| **P0** | 2 | NotesController, NoteExplorer |
| **P1** | 4 | EntryShellPage, NotesPage, NoteContentArea, WorkspaceProvider |
| **P2** | 5 | SingleEntryController, WorkbenchShellLayout, SingleEntryPanel, TagFilter, DebugLogsPanel |

### 6.2 核心主流程涉及的 P0/P1 模块

笔记主流程（创建 → 编辑 → 保存 → 组织 → 搜索）直接经过：

1. `NotesController`（P0）—— 全生命周期中枢
2. `NoteExplorer`（P0）—— 笔记组织与导航
3. `NotesPage`（P1）—— 三栏布局 Shell
4. `NoteContentArea`（P1）—— 编辑与标签
5. `EntryShellPage`（P1）—— 进入笔记视图的入口

**结论：5/6 的 P0+P1 模块全部位于笔记核心链路。**

### 6.3 建议优先治理 Top 3

| 优先级 | 模块 | 风险原因 |
|--------|------|---------|
| 1 | **NotesController**（P0） | 上帝对象位于笔记核心链路，9 个职责域耦合，后续需求必须在此文件上叠加 |
| 2 | **NoteExplorer**（P0） | 巨型 Widget 位于笔记组织链路，14 个长方法（含 4 个内联对话框），维护成本高 |
| 3 | **EntryShellPage**（P1） | 跨 feature 耦合枢纽，Rule E 违规最大源头，新增 feature 必须修改此文件 |

> 具体治理方案属 `PR-0255B` 范畴，本报告不展开。

### 6.4 不建议立即动的模块

| 模块 | 原因 |
|------|------|
| SingleEntryController（P2） | 内部耦合清洁，不跨 feature，当前无交付阻塞 |
| TagFilter（P2） | 反向依赖 notes_style 有循环风险，但文件仅 243 行，影响有限 |
| DebugLogsPanel（P2） | 非核心流程，职责单一，可后置 |

---

## 7. 附录与证据

### 7.1 文件行数 Top 10（手写代码，排除自动生成）

| 排名 | 文件 | 行数 |
|------|------|------|
| 1 | `lib/features/notes/notes_controller.dart` | 3,160 |
| 2 | `lib/features/notes/note_explorer.dart` | 2,280 |
| 3 | `lib/features/notes/note_content_area.dart` | 879 |
| 4 | `lib/features/notes/notes_page.dart` | 856 |
| 5 | `lib/features/entry/single_entry_controller.dart` | 679 |
| 6 | `lib/features/workspace/workspace_provider.dart` | 664 |
| 7 | `lib/features/diagnostics/debug_logs_panel.dart` | 578 |
| 8 | `lib/core/settings/local_settings_store.dart` | 521 |
| 9 | `lib/core/rust_bridge.dart` | 475 |
| 10 | `lib/features/entry/command_parser.dart` | 454 |

### 7.2 跨 Feature Import 完整清单

```
calendar/calendar_controller.dart:4  →  reminders/reminder_scheduler.dart
entry/entry_shell_page.dart:7        →  calendar/calendar_page.dart
entry/entry_shell_page.dart:8        →  diagnostics/rust_diagnostics_page.dart
entry/entry_shell_page.dart:12       →  notes/notes_controller.dart
entry/entry_shell_page.dart:13       →  notes/notes_page.dart
entry/entry_shell_page.dart:14       →  settings/settings_capability_page.dart
entry/entry_shell_page.dart:15       →  tasks/tasks_page.dart
entry/single_entry_panel.dart:6      →  search/search_results_view.dart
entry/workbench_shell_layout.dart:2  →  diagnostics/debug_logs_panel.dart
notes/notes_controller.dart:9        →  workspace/workspace_models.dart
notes/notes_controller.dart:10       →  workspace/workspace_provider.dart
notes/notes_page.dart:15             →  workspace/workspace_models.dart
notes/notes_page.dart:16             →  workspace/workspace_provider.dart
notes/note_explorer.dart:12          →  tags/tag_filter.dart
tags/tag_filter.dart:2               →  notes/notes_style.dart
tasks/tasks_controller.dart:4        →  reminders/reminder_scheduler.dart
```

### 7.3 `flutter analyze` 输出

```
Analyzing lazynote_flutter...
No issues found! (ran in 5.0s)
```

### 7.4 `flutter test` 输出

```
00:03 +312 -1: Some tests failed.
```

已知失败项：`smoke_test.dart` "calendar route is reachable from workbench" — `CalendarPage` L67 Row 在测试视口（800×600）下溢出。属布局约束问题，非业务逻辑错误。

### 7.5 TODO/FIXME 清单

| 文件 | 行号 | 标记 |
|------|------|------|
| `lib/core/settings/local_settings_store.dart` | 209 | `TODO(v0.2): implement forward-migration when schema_version increases.` |
| `lib/core/settings/local_settings_store.dart` | 299 | `TODO(v0.2): add migration for schema_version >= 2.` |
| `lib/core/settings/local_settings_store.dart` | 311 | `TODO(v0.2): wire result_limit to SingleEntryController limit parameter.` |
| `lib/core/settings/local_settings_store.dart` | 316 | `TODO(v0.2): wire use_single_entry_as_home to app bootstrap route policy.` |
| `lib/core/settings/local_settings_store.dart` | 321 | `TODO(v0.2): wire expand_on_focus to Single Entry focus behavior.` |
| `lib/features/notes/note_content_area.dart` | 736 | `TODO(PR-0205A): wire to real metadata actions in follow-up PR.` |

### 7.6 目录结构树（当前 as-is）

```
lib/
├── main.dart                                    (55)
├── app/
│   ├── app.dart                                 (118)
│   ├── app_locale_controller.dart               (69)
│   ├── routes.dart                              (38)
│   └── ui_slots/
│       ├── first_party_ui_slots.dart            (201)
│       ├── ui_slot_host.dart                    (306)
│       ├── ui_slot_models.dart                  (62)
│       └── ui_slot_registry.dart                (60)
├── core/
│   ├── rust_bridge.dart                         (475)
│   ├── local_paths.dart                         (92)
│   ├── bindings/                                [auto-generated, excluded]
│   ├── debug/
│   │   └── log_reader.dart                      (269)
│   ├── diagnostics/
│   │   └── dart_event_logger.dart               (169)
│   └── settings/
│       ├── local_settings_store.dart            (521)
│       └── ui_language.dart                     (28)
├── features/
│   ├── entry/
│   │   ├── entry_shell_page.dart                (362)  ← P1 耦合枢纽
│   │   ├── single_entry_controller.dart         (679)
│   │   ├── single_entry_panel.dart              (301)
│   │   ├── entry_state.dart                     (127)
│   │   ├── command_parser.dart                  (454)
│   │   ├── command_registry.dart                (118)
│   │   ├── command_router.dart                  (81)
│   │   └── workbench_shell_layout.dart          (154)
│   ├── notes/
│   │   ├── notes_controller.dart                (3160) ← P0 上帝对象
│   │   ├── note_explorer.dart                   (2280) ← P0 巨型 Widget
│   │   ├── note_content_area.dart               (879)  ← P1
│   │   ├── notes_page.dart                      (856)  ← P1
│   │   ├── note_tab_manager.dart                (431)
│   │   ├── note_editor.dart                     (111)
│   │   ├── explorer_tree_item.dart              (230)
│   │   ├── explorer_tree_state.dart             (229)
│   │   ├── explorer_drag_controller.dart        (75)
│   │   ├── explorer_context_menu.dart           (60)
│   │   └── notes_style.dart                     (64)
│   ├── tasks/
│   │   ├── tasks_controller.dart                (385)
│   │   ├── tasks_section_card.dart              (323)
│   │   ├── tasks_page.dart                      (223)
│   │   └── tasks_style.dart                     (48)
│   ├── calendar/
│   │   ├── week_grid_view.dart                  (421)
│   │   ├── calendar_event_dialog.dart           (281)
│   │   ├── calendar_page.dart                   (247)
│   │   ├── calendar_controller.dart             (242)
│   │   ├── calendar_sidebar.dart                (148)
│   │   ├── event_block.dart                     (93)
│   │   └── calendar_style.dart                  (47)
│   ├── workspace/
│   │   ├── workspace_provider.dart              (664)  ← P1
│   │   └── workspace_models.dart                (200)
│   ├── reminders/
│   │   ├── reminder_scheduler.dart              (200)
│   │   └── reminder_service.dart                (167)
│   ├── search/
│   │   └── search_results_view.dart             (260)
│   ├── tags/
│   │   └── tag_filter.dart                      (243)
│   ├── settings/
│   │   └── settings_capability_page.dart        (279)
│   └── diagnostics/
│       ├── debug_logs_panel.dart                (578)
│       ├── log_line_meta.dart                   (194)
│       └── rust_diagnostics_page.dart           (169)
└── l10n/                                        [excluded]
```

### 7.7 Lakos 依赖图

依赖图 SVG 见：`docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/lakos/lakos.svg`

DOT 源文件见：`docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/lakos/lakos.dot`

### 7.8 Fan-in / Fan-out 统计（M2 补充）

| 文件 | Fan-in | Fan-out | 说明 |
|------|--------|---------|------|
| `notes_controller.dart` | 6 | 9 | 被 notes_page, note_content_area, note_explorer, note_tab_manager, first_party_ui_slots, entry_shell_page 引用 |
| `note_explorer.dart` | 2 | 12 | Fan-out 最高的 widget 文件，引用 notes 内部 6 个 + tags 1 个 + core 2 个 + l10n 1 个 + flutter 2 个 |
| `notes_page.dart` | 1 | 17 | 全项目 Fan-out 最高；仅被 entry_shell_page 引用 |
| `note_content_area.dart` | 1 | 6 | 仅被 notes_page 引用 |
| `entry_shell_page.dart` | 1 | 16 | 仅被 app.dart 引用；Fan-out 次高 |
| `workspace_provider.dart` | 2 | 4 | 被 notes_controller 和 notes_page 引用 |
| `workspace_models.dart` | 3 | 1 | 纯数据模型，仅 import flutter/foundation |
| `single_entry_controller.dart` | 2 | 8 | 被 single_entry_panel 和 entry_shell_page 引用 |
| `debug_logs_panel.dart` | 1 | 8 | 仅被 workbench_shell_layout 引用；引用 core + diagnostics + l10n + flutter |
| `tag_filter.dart` | 1 | 2 | 仅被 note_explorer 引用；反向依赖 notes_style |
| `note_tab_manager.dart` | 1 | 5 | 仅被 notes_page 引用 |

### 7.9 方法数与状态字段统计（M2 补充）

| 文件 | Public 方法 | Private 方法 | 状态字段 | 说明 |
|------|------------|-------------|---------|------|
| `notes_controller.dart` | ~30 | ~43 | 60 | 含 12 个 FFI invoker 字段（L200–211） |
| `note_explorer.dart` | ~3 | ~35 | 13 | `_NoteExplorerState` 承载全部逻辑 |
| `note_content_area.dart` | ~10 | ~3 | ~24 | 多个内部 widget class 各有少量状态 |
| `notes_page.dart` | ~6 | ~13 | ~47 | 含 WindowListener 相关的守卫状态 |
| `entry_shell_page.dart` | ~4 | ~10 | ~13 | 含双控制器持有 |
| `workspace_provider.dart` | ~17 | ~10 | 12+3 | 12 核心 + 3 配置字段 |
| `single_entry_controller.dart` | ~17 | ~15 | ~30 | 搜索+命令双流水线 |
| `tasks_controller.dart` | ~16 | ~13 | ~20 | 结构清洁 |
| `calendar_controller.dart` | ~12 | ~3 | ~10 | 结构清洁 |

### 7.10 长方法清单（>50 行，M2 补充）

#### NotesController（15 个长方法）

| 方法 | 起始行 | 结束行 | 行数 | 责任域 |
|------|--------|--------|------|--------|
| `createWorkspaceFolder()` | 708 | 788 | 81 | 工作区树 |
| `createWorkspaceNoteInFolder()` | 796 | 887 | 92 | 工作区树 |
| `renameWorkspaceNode()` | 890 | 955 | 66 | 工作区树 |
| `moveWorkspaceNode()` | 958 | 1055 | 98 | 工作区树 |
| `deleteWorkspaceFolder()` | 1102 | 1185 | 84 | 工作区树 |
| `flushPendingSave()` | 1193 | 1243 | 51 | 草稿保存 |
| `createNote()` | 1276 | 1367 | 92 | 笔记创建 |
| `_reconcileOpenTabsAfterWorkspaceMutation()` | 1483 | 1558 | 76 | Tab 管理 |
| `_setNoteTags()` | 1588 | 1664 | 77 | 标签管理 |
| `_loadNotes()` | 1923 | 2059 | 137 | 笔记列表 |
| `_refreshAvailableTags()` | 2090 | 2148 | 59 | 标签管理 |
| `_loadSelectedDetail()` | 2159 | 2237 | 79 | 详情加载 |
| `_performSaveDraft()` | 2375 | 2464 | 90 | 草稿保存 |
| `_syncWorkspaceFromControllerState()` | 2596 | 2663 | 68 | 工作区同步 |
| `_listProjectedUncategorizedChildren()` | 2776 | 2899 | 124 | 工作区树 |

#### NoteExplorer（14 个长方法）

| 方法 | 起始行 | 结束行 | 行数 | 责任域 |
|------|--------|--------|------|--------|
| `build()` | 288 | 422 | 135 | 顶层布局 |
| `_buildBody()` | 424 | 498 | 75 | 条件渲染 |
| `_buildSuccessTree()` | 500 | 593 | 94 | 树成功态 |
| `_wrapWorkspaceRowWithDrag()` | 799 | 886 | 88 | 拖拽包装 |
| `_buildDragFeedback()` | 901 | 952 | 52 | 拖拽反馈 |
| `_performDragMove()` | 954 | 1006 | 53 | 拖拽执行 |
| `_runContextAction()` | 1140 | 1191 | 52 | 上下文动作 |
| `_appendWorkspaceRows()` | 1193 | 1396 | 204 | 树行渲染 |
| `_appendLegacyFolderRows()` | 1434 | 1567 | 134 | 遗留模式 |
| `_showCreateFolderDialog()` | 1573 | 1696 | 124 | 对话框 |
| `_showDeleteFolderDialog()` | 1698 | 1841 | 144 | 对话框 |
| `_handleCreateNoteFromContext()` | 1843 | 1896 | 54 | 上下文创建 |
| `_showRenameNodeDialog()` | 1898 | 2019 | 122 | 对话框 |
| `_showMoveNodeDialog()` | 2021 | 2179 | 159 | 对话框 |

### 7.11 `notifyListeners()` 热点分布（M2 补充）

`NotesController` 中共 62 处 `notifyListeners()` 调用（`grep -c "notifyListeners(" notes_controller.dart` 验证），按责任域分布：

| 责任域 | 调用次数 | 行号示例 |
|--------|---------|---------|
| 工作区树 CRUD | ~12 | L750, L786, L823, L885, L920, L953, L995, L1053, L1142, L1183 |
| 笔记创建 | ~8 | L1283, L1295, L1304, L1318, L1330, L1354, L1359, L1364 |
| Tab / 标签管理 | ~12 | L666, L701, L1534, L1540, L1556, L1602, L1617, L1624, L1640, L1659, L1706, L1782 |
| 笔记列表加载 | ~8 | L1941, L1965, L2046, L2057, L2095, L2116, L2126, L2146 |
| 详情加载 | ~5 | L2170, L2197, L2214, L2223, L2235 |
| 草稿保存 | ~9 | L2387, L2394, L2404, L2417, L2430, L2445, L2453, L2460, L2503 |
| 分屏 / 列表切换 / 其他 | ~8 | L388, L400, L1240, L1261, L1796, L1810, L1831, L1920 |

> 风险含义：任何单一 `notifyListeners()` 调用都会通知所有通过 `AnimatedBuilder` 监听该 controller 的 widget，在上帝对象中意味着不相关的 UI 区域被迫重建。

### 7.12 测试覆盖度统计（M2 补充）

| Feature 模块 | 源码行数 | 测试文件数 | 测试行数 | 覆盖比（测试/源码） | 评估 |
|-------------|---------|-----------|---------|-------------------|------|
| notes | 8,414 | 17 | 7,544 | 0.90 | 覆盖广但偏集成 |
| workspace | 774 | 4 | 1,440 | 1.86 | 充分 |
| entry | 2,332 | 6 | 1,384 | 0.59 | 中等 |
| diagnostics | 921 | 4 | 698 | 0.76 | 中等 |
| reminders | 367 | 2 | 365 | 0.99 | 充分 |
| calendar | 1,442 | 3 | 528 | 0.37 | **偏薄** |
| tasks | 981 | 1 | 246 | 0.25 | **偏薄** |
| settings | 279 | 1 | 78 | 0.28 | **偏薄** |
| search | 260 | 0 | 0 | 0.00 | **无测试** |
| tags | 243 | 0 | 0 | 0.00 | **无测试** |

> 注：search 和 tags 模块当前为简单 UI 组件（各 <260 行），无测试但风险可控。calendar 和 tasks 模块测试覆盖偏薄，后续叠加功能时回归风险较高。

---

> **注意：** 本报告仅做"体检与风险识别"，不展开模块拆分方案和重构排期。方案设计见 `PR-0255B`，排期见 `PR-0255C`。
