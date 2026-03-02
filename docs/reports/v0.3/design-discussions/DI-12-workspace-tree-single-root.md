# DI-12: Workspace Tree 单根化与系统语义锚点

| 项目 | 值 |
|------|-----|
| **状态** | **RESOLVED** |
| **关联裁决** | S1 R5/R6, S3, S4 |
| **影响范围** | Core Tree/Creation Service、FFI 创建/树接口、Flutter Explorer/Tasks/Calendar |
| **前置输入** | DI-11（Atom-first 入口方向）、08b（指定默认路径语义） |
| **目标版本** | v0.4 规划（不回改 v0.3 已收口范围） |

---

## 背景

当前 workspace tree 已完成 `note_ref -> atom_ref` 升级，但仍存在以下结构性张力：

1. 组织树是通用节点模型（folder/atom_ref），但 Tasks/Calendar 的系统语义锚点未作为一等结构约束落地。
2. `designated folder` 语义部分依赖上层约定，导致删除保护、pending 数据口径、创建路由的认知不稳定。
3. 根级别（`parent_uuid = NULL`）与“未分类/系统入口”混用，容易造成产品心智和实现口径分叉。

本议题用于单独讨论“是否将树收敛为单根整树 + 固化系统语义节点”，并形成可执行方案。

---

## 讨论边界

### In Scope

1. Workspace tree 结构模型（单根 vs 现有 root-level null 模型）。
2. Tasks/Calendar 系统文件夹的存在性、生命周期和保护规则。
3. 创建路径路由与 pending 池数据源的结构化定义。
4. 迁移策略（DB + 服务层 + API 兼容）。
5. 验收和回归标准。

### Out of Scope

1. `AtomType -> ViewHint` 命名收敛（已在 DI-11 处理）。
2. Canvas / Conversation 内容模型（S1 R12+）。
3. 视图组件视觉细节（仅讨论语义和契约）。

---

## 待裁决问题（Q1-Q12）

### Q1. 树模型是否改为单根整树？（RESOLVED）

- A. 维持 `parent_uuid = NULL` 作为根级
- B. 引入隐藏系统根节点 `ROOT`，所有节点必须有父（除 `ROOT`）

**裁决（2026-03-01）**：选择 **B（隐藏系统根的单根整树）**。

**裁决理由**：

1. 结构语义统一：从 forest/root-null 收敛为单根树，便于约束和推导。
2. 系统锚点稳定：Tasks/Calendar 可作为 `ROOT` 下固定系统节点承载路由语义。
3. 查询口径清晰：pending/scope 均可基于“子树”定义，减少 synthetic 补丁。
4. 兼容成本可控：FFI 入参可保持 `parent_node_id: Option<String>`，在 service 层将 `None` 映射到 `ROOT`。

**实施约束（Q1 派生）**：

1. 数据层允许一个逻辑根节点（系统保留，不向用户暴露删除入口）。
2. 所有现存 `parent_uuid IS NULL` 节点在迁移中回填到 `ROOT`。
3. UI 可继续隐藏根展示；“是否显示根”属于展示策略，不影响数据模型。

### Q2. 根级“未分类”如何表达？（RESOLVED）

- A. 保留 synthetic uncategorized 展示层
- B. 使用真实结构节点（例如 `Inbox/Unclassified`）承接
- C. 两者并存（过渡期）

**裁决（2026-03-01）**：选择 **B（真实系统节点 Inbox）**，并淘汰 synthetic uncategorized。

**语义定义**：

1. `Inbox` 是系统“默认收件/待整理区”，不是 `Trash`。
2. `Inbox` 承接“无明确归档目标”的创建与恢复流量，保证不丢数据。
3. `Inbox` 是真实树节点（可查询、可迁移、可审计），不是 UI 合成层。
4. 用户可弱感知（可折叠/可低强调），但系统层必须存在。

**实施约束（Q2 派生）**：

1. 旧 `parent_uuid IS NULL` 的“散落项”在单根迁移中进入 `Inbox`（或按规则归档后剩余进入 `Inbox`）。
2. Explorer 不再注入 `__uncategorized__` synthetic 节点。
3. `Inbox` 与 `Trash` 生命周期严格分离：前者 active，后者 deleted/recover 流程。

### Q3. Tasks/Calendar 系统文件夹是否必须存在？（RESOLVED）

- A. 可为空（未配置合法）
- B. 必须存在（缺失自动修复/创建）

**裁决（2026-03-01）**：选择 **B（必须存在）**。

**裁决理由**：

1. 消除重分配歧义：缺失后再恢复会出现“应绑定哪个文件夹”的选择分叉。
2. 稳定创建路由：task/calendar 创建入口必须有确定结构落点。
3. 保持查询口径一致：pending/inbox 的子树边界依赖稳定系统节点。

**实施约束（Q3 派生）**：

1. 启动与迁移阶段执行 `ensure_system_folders()`：确保 `Tasks` 与 `Calendar` 存在且唯一。
2. 若系统节点缺失（被异常数据破坏），系统自动重建并记录诊断日志。
3. 创建路由禁止回退到“未配置”分支（与 Q1/Q2 保持一致）。

### Q4. 系统文件夹可执行哪些操作？（RESOLVED）

- Profile Soft: 可重命名、可移动、不可删除
- Profile Strict: 可移动、不可重命名、不可删除
- Profile Locked: 全部不可变（仅系统维护）

**裁决（2026-03-01）**：选择 **Profile Soft**。

**语义定义**：

1. 系统语义绑定 `role + uuid`，不绑定显示名。
2. 用户可重命名系统文件夹，重命名只影响展示文案，不改变路由与角色。
3. 用户可移动系统文件夹（改变 parent），不改变系统角色。
4. 系统文件夹不可删除、不可去系统化（不可转普通文件夹）。

**用户知情约束**：

1. 首次重命名系统文件夹需确认提示：
   - “仅修改显示名，不改变系统角色与创建路由”。
2. 系统文件夹在 UI 中应显示稳定 role 标识（如 `TASKS`/`CALENDAR` badge）。
3. 提供“一键恢复默认名称”。

### Q5. 是否保留“重新指定映射”能力？（RESOLVED）

- A. 保留 `view -> folder` 可重指定映射
- B. 取消映射重指定，改为“移动同一系统文件夹节点”

**裁决（2026-03-01）**：选择 **B**。

**语义定义**：

1. 不再提供 `view -> folder_uuid` 的运行时重绑定。
2. “重新指定”在产品语义上改为“移动系统文件夹到目标父目录（可选重命名）”。
3. 系统角色（`tasks`/`calendar`）绑定固定节点 `uuid`，不因移动或改名改变。

**提前预演（Tree/Spatial 一致性）**：

1. 场景：用户在 Tree 中执行“重新指定 Tasks 到 Work/Planning”。
2. 旧模型 A 的结果：仅映射改绑，原 `Tasks` 节点与 Spatial 布局可能保持旧位置，出现“Tree 改了、Spatial 没改”的感知分叉。
3. 新模型 B 的结果：执行同一节点移动（`parent_uuid` 变更，`uuid` 不变），Tree 与 Spatial 读取同一结构数据，结果一致。

**实施约束（Q5 派生）**：

1. 服务层禁止“映射重绑定”接口进入主流程。
2. `reassign`/`designate` 类 UI 文案统一替换为“移动系统文件夹”。
3. 移动后刷新 Tree/Spatial 缓存；跨父移动时可将该节点下空间坐标标记为待重排（`spatial_x/y = NULL`）以避免布局残影。

### Q6. 创建路由如何定义为结构事实？（RESOLVED）

- 关注点从“映射 vs 固定节点”改为“路由优先级与可预期性”。

**裁决（2026-03-01）**：采用**固定系统节点 + 明确优先级路由**。

**用户语义**：

1. 用户体感可保留“重新指定/调整默认位置”表达。
2. 实际实现始终是“移动同一系统文件夹节点（`uuid` 不变）”，不是替换映射目标。

**路由优先级（高 -> 低）**：

1. 显式目标优先：用户明确选择父文件夹（右键文件夹新建、拖拽落点新建）时，落该目标。
2. 意图上下文次之：`task`/`calendar` 语义创建分别落对应系统文件夹（按 role+uuid）。
3. 无上下文兜底：落 `Inbox` 系统节点。

**一致性约束**：

1. 路由解析必须基于系统角色与固定 `uuid`，不依赖可变 mapping 配置。
2. Tree 与 Spatial 共用同一结构源（`workspace_nodes.parent_uuid`），移动系统节点后两视图结果一致。

### Q7. Calendar Pending 数据源口径？（RESOLVED）

> 本题不仅是“从哪查”，还要定义“按什么单位展示、何时进出池子、如何排序”。

**裁决（2026-03-01）**：

1. Calendar 面板基础数据源 = `Calendar` 系统文件夹子树内全部 active `atom_ref`（与 Explorer 同源）。
2. 数据层不做“pending 专用过滤”；过滤/分组由 UI 视图层承担。
3. “Pending”降级为 Calendar 面板的一个 UI 视图（例如 unscheduled 分组），不是独立数据池。
4. 保留统一的域谓词函数（如 `is_unscheduled`）供 UI 调用，避免多页面规则漂移。

**Q7 口径拆解（已定）**：

1. 候选集合（scope）：`Calendar` 系统节点子树内引用集合（非全局 atoms）。
2. 展示单位：以 `atom_ref` 为基础单位；UI 可按 `atom_id` 聚合展示，但不改变底层语义。
3. 字段标注：`start_at/end_at` 用于 UI 分组标注（unscheduled/scheduled/anomaly），不是数据源入口过滤条件。
4. 排序：由 UI 视图定义默认排序并保持可重复（建议 `updated_at DESC` + `atom_id ASC` 兜底）。

### Q8. Tasks Pending/Inbox 数据源口径？（RESOLVED）

- A. Tasks 系统文件夹子树内 + task 条件
- B. 全局 task 条件，不绑定结构子树

**裁决（2026-03-01）**：选择 **A（结构约束）**，并将“task 条件”定义为视图分组规则，而非数据源入口过滤。

**语义定义**：

1. Tasks 面板基础数据源 = `Tasks` 系统文件夹子树内全部 active `atom_ref`（与 Explorer 同源）。
2. 数据层不做“仅 task”硬过滤；`task_status` 与时间字段用于 UI 分组标注。
3. `Tasks Inbox/Pending` 是 Tasks 面板内的一个视图分组，不是独立数据池。

**建议分组（可演进）**：

1. `All in Tasks`：子树全量。
2. `Inbox/Pending`：`task_status` 进行态且无时间字段。
3. `Scheduled`：`task_status` 进行态且有时间字段。
4. `Done`：`task_status IN ('done','cancelled')`。

**UI 边界约束**：

1. 本裁决只冻结数据口径与分组规则，不冻结具体 UI 布局形式。
2. 现有 UI 若不适配，可在后续 UI 议题中重做编排；不得改变本节数据契约。

### Q9. “active”判定是否作为全局可见性约束？（RESOLVED）

- A. 仅判 atom `is_deleted=0`
- B. atom + atom_ref + ancestor chain 全部 active

**裁决（2026-03-01）**：选择 **B**。

**语义定义**：

1. 可见性判定单位是“引用路径”，不是 atom 本体单独状态。
2. 仅当以下条件同时满足时，`atom_ref` 才进入任何可见性候选集（Explorer / Tasks / Calendar / Search / Spatial）：
   - `atom.is_deleted = 0`
   - `atom_ref.is_deleted = 0`
   - 该 `atom_ref` 在结构上可达 `ROOT`（祖先链 active、无断链）
3. `ancestor_chain` 是全局可达性不变式，但默认由写路径维护，不要求每次读查询都做递归追溯。

**为什么不选 A**：

1. A 会产生“幽灵可见性”：atom 还活着，但其引用或父链已失活，UI 仍可能误显示。
2. A 与单根结构语义冲突：单根树强调“路径即归属”，路径失活应视为不可见。
3. A 会放大 Tree/Spatial 不一致风险。

**实施约束（Q9 派生）**：

1. 写路径强约束：删除/移动/重挂操作必须在事务内保持子树一致性，避免产生“父失活但子仍 active”的悬挂路径。
2. 读路径轻约束：常规查询以 `atom.is_deleted=0 + atom_ref.is_deleted=0` 为主，不做全量 ancestor 递归。
3. 巡检修复：后台一致性检查负责发现断链/悬挂引用并修复；发现问题需记录诊断日志。

### Q10. API 兼容策略（FFI）？（RESOLVED）

- A. 保持 `parent_node_id: Option<String>`，`None` 在 service 层映射到系统根/默认入口
- B. 改为显式 `target_scope` 枚举（breaking）

**裁决（2026-03-01）**：选择 **A（兼容优先）**。

**语义定义**：

1. 保留现有 `parent_node_id` 契约，作为“显式目标父节点”。
2. 当 `parent_node_id=None` 时，由 service 层按 Q6 路由优先级解析默认落点（意图上下文 -> 系统节点 -> Inbox）。
3. API 行为文档更新：`parent_node_id` 不再等价于“唯一路由来源”，而是显式覆盖入口。

**扩展策略（非 breaking）**：

1. 未来如需更显式语义，可新增可选 `target_scope` hint 字段（additive），不替换 `parent_node_id`。
2. 解析优先级固定为：`parent_node_id`（显式） > `target_scope`（语义 hint） > 默认路由。

**为什么不选 B（当前阶段）**：

1. 会触发 FFI + Flutter + 调用方全面改签名，迁移成本与风险过高。
2. 当前阶段核心目标是先完成单根树与系统锚点语义收敛，避免并行引入接口破坏。

**前瞻兼容收益**：

1. 保留 `parent_node_id` 有利于未来多子树工作区扩展（同一大树下多分区）。
2. 共享文档场景可继续依赖 `atom_ref` 多挂载语义，不受接口破坏影响。

### Q11. 数据迁移策略？（RESOLVED）

- A. 一次性迁移（新增系统节点 + 回填 parent）
- B. 双轨过渡（兼容旧结构一段时间）

**裁决（2026-03-01）**：选择 **A（一次性迁移）**，采用 A+ 执行策略（迁移 + 启动巡检修复）。

**裁决理由**：

1. Workspace tree 是上层视图与创建路由的基石，不应长期双语义并存。
2. 双轨过渡会放大实现分支与排障成本，与本次“语义收敛”目标冲突。
3. 本项目为本地 SQLite 单机模型，一次切换成本可控，收益更高。

**A+ 执行步骤（规范）**：

1. 迁移中创建系统节点：`ROOT`、`Inbox`、`Tasks`、`Calendar`（稳定 `uuid`）。
2. 回填旧结构：
   - 旧 `folder` 且 `parent_uuid IS NULL` -> 挂到 `ROOT`
   - 旧 `atom_ref` 且 `parent_uuid IS NULL` -> 挂到 `Inbox`
3. 写入系统角色绑定（建议独立绑定表，避免按名称识别角色）。
4. 启用系统节点保护约束（禁止删除、禁止去系统化）。
5. 下线旧 root-null 语义路径与 synthetic uncategorized 依赖。
6. 启动后执行一致性巡检（断链/悬挂 ref/缺失系统节点），必要时自愈并写诊断日志。

**失败与回滚要求**：

1. 迁移必须事务化，失败即回滚，不允许半迁移状态。
2. 启动巡检仅做幂等修复，不修改用户业务字段语义（仅结构自愈）。
3. 迁移后版本门禁要求：旧读写路径不得再写入 `parent_uuid IS NULL` 作为业务常态。

### Q12. 删除策略与安全网？（RESOLVED）

- A. 继续支持 `dissolve/delete_all`，但对系统节点加硬保护
- B. 收敛为单一删除语义，减少分支

**裁决（2026-03-01）**：选择 **A**。

**语义定义**：

1. 保留双模式删除：
   - `dissolve`：删除文件夹节点，子节点重挂到上级结构（不直接删除 atom）。
   - `delete_all`：删除文件夹子树引用；无其他 active 引用的 atom 执行 soft-delete。
2. 系统节点（`ROOT` / `Inbox` / `Tasks` / `Calendar`）禁止删除（两种模式均不可用）。

**安全网约束**：

1. 删除操作必须事务化执行，禁止半完成状态。
2. 删除后触发一致性巡检，修复潜在悬挂引用并记录诊断日志。
3. UI 必须明确双模式差异，并将 `dissolve` 设为默认安全选项。

**为什么不选 B（当前阶段）**：

1. 单一删除语义会损失有效操作表达（“只删壳”与“连内容清理”场景确实不同）。
2. 在 Q1-Q11 已有大幅语义迁移时，再收敛删除语义会叠加迁移复杂度与用户心智负担。

---

## 执行清单（v0.4 落地）

### E1. Core：单根树与系统节点落地

1. 新增迁移（建议 `0012_workspace_single_root.sql`）：
   - 创建系统节点：`ROOT`、`Inbox`、`Tasks`、`Calendar`
   - 回填旧 `parent_uuid IS NULL`（folder -> ROOT，atom_ref -> Inbox）
   - 建立系统角色绑定表（建议 `workspace_system_nodes(role,node_uuid)`）
   - 增加系统节点保护约束（禁止删除/去系统化）
2. `tree_repo`/`tree_service` 更新：
   - 删除路径增加系统节点保护分支
   - 移动系统节点允许（保持 role+uuid 不变）
   - 删除后一致性巡检 hook
3. 创建路由服务更新：
   - 实现 Q6 优先级（显式 parent > 意图上下文 > Inbox）
   - 禁止旧“未配置 designated 回退”分支

### E2. FFI：兼容优先收敛

1. 保持现有 `parent_node_id: Option<String>` 契约（不 breaking）。
2. 更新 FFI doc 注释：
   - `parent_node_id` 是显式覆盖，不是唯一路由来源。
3. 预留未来扩展位（可选）：
   - additive `target_scope` hint（不替换现有字段）。

### E3. Flutter：Explorer/Tasks/Calendar 同源化

1. 移除 synthetic uncategorized 注入路径（`__uncategorized__`）。
2. 引入系统节点可视化约束：
   - role badge（TASKS/CALENDAR）
   - 首次重命名确认提示
   - “恢复默认名称”
3. Calendar 面板按 Q7 改为同源全量 + UI 分组。
4. Tasks 面板按 Q8 改为同源全量 + UI 分组。
5. 删除弹窗默认 `dissolve`，系统节点隐藏删除入口。

### E4. 一致性与巡检

1. 启动时执行 `ensure_system_folders()`（缺失自动自愈）。
2. 后台巡检任务：
   - 断链路径检测
   - 悬挂引用检测
   - 系统角色唯一性检测
3. 巡检异常写诊断日志，不静默吞错。

### E5. 测试清单（最小）

1. Core migration tests：
   - 旧库升级后系统节点存在且唯一
   - root-null 数据回填正确
2. Core service tests：
   - 创建路由优先级正确
   - 系统节点删除被拒绝
   - 双模式删除行为符合 Q12
3. FFI tests：
   - 旧参数调用不破坏
   - `parent_node_id=None` 按新语义路由
4. Flutter integration tests：
   - Explorer 无 synthetic uncategorized
   - Calendar/Tasks 面板同源分组稳定
   - Tree/Spatial 移动系统节点后结果一致

### E6. 文档同步

1. 更新 `S1`：R6 迁移到单根树+系统节点语义。
2. 更新 `S4`：创建路径统一叠加“固定系统节点 + 路由优先级”。
3. 更新 `ffi-contracts`：`parent_node_id` 的新语义说明。
4. 在 v0.4 PR spec 中增加执行条目与验收门禁。

---

## 方案输出要求（本 DI 最终产物）

1. **语义裁决**：Q1-Q12 每项给出唯一结论（可含阶段性结论）。
2. **结构契约**：`workspace_nodes` 约束与系统节点定义。
3. **服务契约**：Creation/Tree Service 路由与保护规则。
4. **FFI 契约**：入参/出参兼容策略与弃用计划。
5. **迁移方案**：SQL 迁移步骤、失败回滚、幂等保障。
6. **验收基线**：最小测试矩阵（Core/FFI/Flutter）。

---

## 讨论顺序建议

1. 先定 Q1-Q5（结构与生命周期）。
2. 再定 Q6-Q9（路由与查询语义）。
3. 最后定 Q10-Q12（迁移与发布策略）。

---

## 备注

本文件已完成 Q1-Q12 全量裁决，作为 v0.4 规划输入使用。
