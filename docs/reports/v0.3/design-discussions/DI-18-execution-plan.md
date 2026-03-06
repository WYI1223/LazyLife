# DI-18: 执行方案 — PR 拆分、迁移顺序与测试策略

| 项目 | 值 |
|------|-----|
| **状态** | RESOLVED |
| **关联决策点** | DI-15（数据模型）、DI-16（Rust API）、DI-17（Flutter） |
| **影响范围** | 全代码库（Rust Core + FFI + Flutter） |
| **前置依赖** | DI-15/16/17 全部裁决完成 |
| **目标版本** | v0.4 |
| **输出物** | 可执行的 PR 拆分方案 + 迁移检查清单 |

---

## 背景

DI-15/16/17 分别定义了 Rust 数据模型、Rust API、Flutter 消费层的目标架构。本 DI 规划从当前代码库到目标状态的执行路径：如何拆分 PR、以什么顺序提交、如何保证迁移过程中代码库始终可编译可测试。

**边界原则**：本 DI 只讨论执行策略（"怎么安全地到达目标"），不重新讨论目标架构本身。

---

## 讨论边界

### In Scope

1. PR 拆分策略与依赖图。
2. 迁移顺序（跨 Rust/FFI/Flutter 的协调）。
3. 增量迁移 vs 一次性切换的选择。
4. FFI breaking change 协调策略。
5. 测试策略（迁移前后的验证矩阵）。
6. 代码文件搬迁与 git history 保留。
7. 回滚方案与风险缓解。

### Out of Scope

1. 目标架构设计 → DI-15/16/17。
2. 具体代码实现细节。

---

## 待裁决问题（Q1-Q5）

### Q1. PR 依赖图与提交顺序？

从 DI-15/16/17 的依赖链推导 PR 序列。

**草案 PR 序列**：

```
PR-1: Schema migration (DI-15)
  → 新增 0012_workspace_single_root.sql
  → 系统节点创建 + 回填
  → Core migration 测试

PR-2: TreeRepo/Service 新方法 (DI-16 Q1-Q2)
  → list_subtree_atom_refs, get_ancestor_path, list_atom_refs_for_atom
  → 系统节点保护
  → ensure_system_folders() 巡检

PR-3: CreationService 路由 (DI-16 Q3)
  → DI-12 Q6 优先级实现
  → 单元测试

PR-4: FFI 新增函数 (DI-16 Q6)
  → 新增 FFI 导出
  → FRB 绑定重生成
  → FFI 集成测试

PR-5: TaskService/CalendarService 改造 (DI-16 Q4)
  → 查询路径从直查 atoms 改为子树查询
  → 旧 FFI 处理（deprecated 或内部改造）

PR-6: Flutter core wrapper (DI-17 Q1-Q4)
  → WorkspaceTreeService 创建
  → 系统节点解析
  → 变更通知

PR-7: Flutter feature 适配 (DI-17 Q5-Q6)
  → Tasks/Calendar controller 适配
  → Synthetic uncategorized 移除
  → Explorer 对接 core service
```

**需要裁决**：

- 是否可以合并某些 PR？（如 PR-2 + PR-3）
- 每个 PR 是否应独立可编译可测试？
- PR-5 和 PR-6 是否有严格依赖？（Flutter 适配需要新 FFI 就绪）

#### Q1 裁决：Phase 0 治理 + 6 PR 重构，线性执行顺序

**依赖关系推导**：

从 DI-15/16/17/18 裁决产出按层分组：

| 层 | 工作项 | 来源 |
|----|--------|------|
| Layer 0a: 文本治理 | ADR 目录 + README + 首批 ADR + docs 更新 | DI-19 → DI-20（**以前置执行文档为准**） |
| Layer 0b: CI 治理 | `architecture_check.dart` 跨 feature 重复检测（新 Check）+ 现有 Check 输出补强（WHAT/WHY/HOW） | DI-21 |
| Layer 1: Schema | Migration 0012（单根树、workspace 元数据、designated folders、回填） + WorkspaceMetaRepository | DI-15 |
| Layer 2a: 查询 | ScopedAtomQuery + ScopedQueryRepository（CTE 管线、全套枚举） | DI-16 Q1 |
| Layer 2b: 写入 | TreeService 增强（ancestor_path 签名修复、list_atom_refs、保护规则、move 硬约束）+ CreationService（resolve_creation_role、跨 workspace 保护、`origin_workspace_id` 事务写入）+ `reassign_designated` repo/service 实现 | DI-16 Q2-Q4 |
| Layer 3: Guard+FFI | AccessGuard 体系 + Guarded*Service + FFI 全量（新增 + 重命名 + caller 参数，含 `workspace_reassign_designated`）+ FRB 重生成 | DI-16 Q5-Q6 |
| Layer 4a: Flutter core | WorkspaceTreeService B+ 改造 + TreeMutationDelta + loadSystemNodes + getSystemNodeId + `reassignDesignated` 后刷新本地映射 | DI-17 Q1-Q4 |
| Layer 4b: Flutter feature | Tasks/Calendar invoker 替换 + Notes/Tag Panel/Entry Search/Editor invoker 迁移 + query helper + synthetic uncategorized 全量删除 + Explorer 内部分层（DI-17 Q3 基础层/特化层拆分，禁止反向耦合） | DI-17 Q3/Q5-Q6 |

**依赖图**：

```
Phase 0                    Phase 1
PR-0a (文本治理) → 以前置执行文档为准
                           Layer 1         Layer 2              Layer 3            Layer 4
PR-0b (CI 治理) ─────────→ PR-1 (Schema) → PR-2 (Query)   ─┐
                                            PR-3 (Mutation) ─┤→ PR-4 (Guard+FFI) → PR-5 (Flutter core) → PR-6 (Flutter features)
```

- **PR-0a 以前置 kickoff 筹备文档为准**：DI-20 已定义治理序列（PR-GOV-01~06），PR-0a 内容当前由 `docs/reports/v0.3/governance-kickoff-prep/` 下的筹备文档承载，待 future `v0.4 kickoff` 组织正式 PR spec 时再迁入主线。
- **PR-0b 无阻塞**：CI 治理增强不依赖文本治理框架，可立即执行。
- **PR-0b → PR-1**：CI 增强应在代码 PR 之前就位，让 PR-1~6 在增强的 CI 框架下执行。
- PR-2 和 PR-3 互不依赖（查询 vs 写入），但都依赖 PR-1。
- PR-4 依赖 PR-2 + PR-3（需要所有 service 才能包装 + 导出 FFI）。
- 单人开发下线性链最简，无需管理并行分支合并冲突。

**最终序列**：

| PR | 范围 | 来源 | 预估改动量 | CI 要求 |
|----|------|------|-----------|---------|
| **PR-0a** | 文本治理（ADR 目录 + README + 首批 ADR + Ruling 评估 + docs 更新）。以前置 kickoff 筹备文档为准：`docs/reports/v0.3/governance-kickoff-prep/PR-GOV-*`，待 future `v0.4 kickoff` 时组织为正式 PR spec。 | DI-19 → DI-20 | 见 PR-GOV drafts | 见 PR-GOV drafts |
| **PR-0b** | `architecture_check.dart` 新增跨 feature 代码重复检测（Check N）+ 现有 Check 1-3 输出补强（WHAT/WHY/HOW 三层上下文，Check 4 已足够不补强）。检测范围、阈值、实现方式以 DI-21 最终裁决为准。 | DI-21 | ~200-400 行 Dart | `dart analyze` 全绿 + 自测通过 |
| **PR-1** | Migration 0012（`workspaces` 表 + `designated_folders` 表 + `atoms.origin_workspace_id` 字段）+ WorkspaceMetaRepository + 回填逻辑 + migration 测试 | DI-15 | ~400-600 行 Rust | `cargo test` 全绿 |
| **PR-2** | ScopedAtomQuery struct + 枚举 + ScopedQueryRepository（CTE 管线）+ TaskService/CalendarService 查询路径改造（DI-16 Q1.4：`list_today` 等委托到 ScopedAtomQuery）+ 查询测试 | DI-16 Q1 | ~600-800 行 Rust | `cargo test` 全绿 |
| **PR-3** | `get_ancestor_path` 签名修复 + `list_atom_refs_for_atom` + TreeService 保护规则 + move 硬约束 + CreationService（`resolve_creation_role` + `origin_workspace_id` 事务写入）+ `reassign_designated` repo/service 实现 + 测试 | DI-16 Q2-Q4 | ~500-700 行 Rust | `cargo test` 全绿 |
| **PR-4** | CallerContext + AccessGuard + NoopGuard + Guarded\*Service 全套 + FFI 新函数（`query_atoms`、`atom_create`、`workspace_resolve_designated`、`workspace_reassign_designated` 等）+ 旧 FFI 保留为薄 wrapper（expand-contract：先加新接口，旧接口暂保留以保证 Flutter 侧编译通过）+ FRB 重生成 + FFI 测试 | DI-16 Q5-Q6 | ~800-1200 行 Rust/Dart（含生成代码） | `cargo test` + `flutter analyze` 全绿 |
| **PR-5** | WorkspaceTreeService B+ 改造 + TreeMutationDelta + `loadSystemNodes` + `getSystemNodeId` + `reassignDesignated` 后刷新本地映射 + mock 测试 | DI-17 Q1-Q4 | ~300-500 行 Dart | 全 CI 绿 |
| **PR-6** | Tasks/Calendar invoker 替换 + Notes/Tag Panel invoker 迁移（`notes_list` → `query_atoms`）+ Entry Search 迁移（`entry_search` → `query_atoms`）+ Editor/Resolver 迁移（`note_get` → `atom_get`）+ QueryAtomsInvoker + query helper + Explorer 内部分层（DI-17 Q3：基础层/特化层拆分，禁止反向耦合）+ 删除 `workspace_tree_children_loader.dart` + 清理 8 文件 48 处 uncategorized 引用 + **移除旧 FFI 名称**（15 个，完整清单见附录 A）+ FRB 重生成 + 测试更新 | DI-17 Q3/Q5-Q6 + DI-16 Q6 旧 FFI 清理 | ~-300 行净减 Dart | 全 CI 绿（含 `architecture_check.dart`） |

**对草案问题的回答**：

1. **是否合并 PR？**：PR-2 + PR-3 可合并（都是 Rust core 层），但分开更利于 review——PR-2 是全新查询引擎（复杂度高），PR-3 是现有 service 增强。PR-5 + PR-6 不合并——PR-5 是基础设施，PR-6 是消费方，分开确保基础设施先稳定。
2. **独立可编译可测试？**：是。每个 PR 合入后 CI 全绿。但不要求每个 PR 后功能端到端完整（例如 PR-2 加了 ScopedQueryRepository 但 Flutter 还不能调用）。FFI 层使用 **expand-contract** 迁移：PR-4 新增新接口 + 旧接口保留为薄 wrapper（expand），PR-6 Flutter 完成迁移后移除旧接口（contract），避免中间状态编译失败。
3. **PR-5 和 PR-6 严格依赖？**：是。PR-6 的 Tasks/Calendar controller 需要 `getSystemNodeId()`（PR-5 提供），PR-6 的 synthetic 移除需要 PR-5 的 WorkspaceTreeService 已就位。

**草案 PR 序列（7 PR）与裁决序列（PR-0a/0b + 6 PR）的差异**：

| 草案 | 裁决 | 变化 |
|------|------|------|
| PR-2: TreeRepo/Service 新方法 | PR-2: ScopedQueryRepository | 查询引擎独立为 PR-2 |
| PR-3: CreationService | PR-3: TreeService 增强 + CreationService | 合并草案 PR-2 部分 + PR-3 |
| PR-4: FFI 新增 | PR-4: Guard + FFI | 合并草案 PR-4 + 新增 Guard 层 |
| PR-5: Task/Calendar 改造 | （并入 PR-2/PR-3） | 草案 PR-5 的 Rust 侧改造分散到 PR-2/PR-3 |
| PR-6/7: Flutter | PR-5/6: Flutter | 编号前移 |
| （无） | PR-0a: 文本治理 | 新增，以前置执行文档为准（`governance-kickoff-prep/PR-GOV-*`） |
| （无） | PR-0b: CI 治理增强 | 新增，DI-21 产出 |

---

### Q2. 增量迁移 vs 一次性切换？

- A. **增量迁移**：每个 PR 后代码库可正常运行，新旧路径可能短暂共存
  - 优点：风险分散，每步可验证
  - 缺点：过渡期可能需要兼容代码

- B. **一次性切换**：在 feature branch 上完成所有变更，一次合入 main
  - 优点：无过渡期兼容成本
  - 缺点：巨型 PR，review 困难，风险集中

**分析重点**：

- 项目当前是单人开发，分支管理灵活。
- 每个 PR 应独立可测试（CI 绿灯），但不要求每个 PR 后功能完整。

#### Q2 裁决：A+（增量迁移 + 严格死代码清理）

**选择 A（增量迁移）**，附加 **严格死代码清理执行规则**（A+ 变体）。

**核心机制：Expand-Contract 迁移**

Q1 已确定 6 PR 线性序列，天然支持增量迁移。关键协调点在 PR-4 → PR-5 → PR-6 的 FFI 层：

```
PR-4 (Expand)     PR-5 (Bridge)       PR-6 (Contract)
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ 新 FFI 函数    │   │ Flutter core │   │ Flutter 消费方  │
│ + 旧 FFI 保留  │ → │ 对接新 FFI    │ → │ 完成迁移       │
│   为薄 wrapper │   │              │   │ + 移除旧 FFI   │
└──────────────┘   └──────────────┘   └──────────────┘
```

- **Expand（PR-4）**：新增全套 Guarded*Service FFI + 旧 FFI 保留为内部委托薄 wrapper。两套接口共存，Flutter 编译不受影响。
- **Bridge（PR-5）**：WorkspaceTreeService 对接新 tree FFI（`workspace_resolve_designated`、`workspace_reassign_designated` 等树操作）。`query_atoms` 消费迁移在 PR-6 feature 层。此时新旧路径共存。
- **Contract（PR-6）**：Flutter 消费方（Tasks/Calendar controller）全部迁移到新接口后，移除全部旧 FFI wrapper + FRB 重生成。

**A+ 严格执行规则**：

| 规则 | 内容 | 验证方式 |
|------|------|----------|
| **R1: PR 级死代码清理** | 每个 PR 完成其迁移阶段后，必须在同一 PR 中删除该阶段产生的全部废弃代码。不允许遗留 `// deprecated` 注释占位或空 wrapper。 | PR review checklist |
| **R2: Contract PR 完整移除** | PR-6 作为 contract 阶段，必须移除全部旧 FFI 函数（15 个，完整清单见附录 A）。不允许"等后续版本清理"。 | `architecture_check.dart` + grep 旧函数名 |
| **R3: 无孤立 import** | 每个 PR 合入后，不允许存在未使用的 import、未调用的函数、未引用的类型定义。 | `flutter analyze`（unused_import lint）+ `cargo clippy`（dead_code warning） |
| **R4: 迁移完整性断言** | PR-6 合入后，运行以下验证：① grep 全部旧 FFI 函数名确认零匹配（排除 CHANGELOG/docs）；② `flutter analyze` 零 warning；③ `cargo clippy` 零 warning。 | CI gate |

**各 PR 的迁移-清理对照**：

| PR | 迁移动作 | 同步清理 |
|----|----------|----------|
| PR-1 | 新增 Migration 0012 | 无废弃代码产生 |
| PR-2 | 新增 ScopedQueryRepository | 无废弃代码产生（旧查询路径在 PR-6 才废弃） |
| PR-3 | TreeService 增强 + CreationService | 无废弃代码产生 |
| PR-4 | 新增 Guarded*Service FFI + 旧 FFI 改为薄 wrapper | 旧 FFI 函数体替换为委托调用（逻辑迁移完成），但函数签名保留（expand 阶段） |
| PR-5 | WorkspaceTreeService 对接新 FFI | 清理 WorkspaceTreeService 旧的直接 FFI 调用模式（如有） |
| PR-6 | Tasks/Calendar 迁移 + synthetic 移除 | **完整 contract**：移除 15 个旧 FFI 函数（见附录 A）+ 删除 `workspace_tree_children_loader.dart` + 清理 48 处 uncategorized 引用 + FRB 重生成 |

**为什么不选 B（一次性切换）**：

- 6 PR 涉及 Schema → Rust Service → FFI → Flutter 全栈，一次性切换意味着 ~2500-4000 行变更集中在单一 PR，review 和 debug 成本极高。
- 增量迁移的 expand-contract 机制已内建在 Q1 的 PR 序列中，兼容成本可控（仅 PR-4 中旧 FFI 保留为薄 wrapper，PR-6 统一移除）。
- A+ 的严格清理规则消除了增量迁移的主要缺点（遗留废弃代码），确保 PR-6 合入后代码库干净。

---

### Q3. FFI Breaking Change 协调？

新增 FFI 函数是 non-breaking（additive），但修改/废弃旧函数需要 Flutter 侧同步更新。

**需要裁决**：

1. ~~旧 Tasks/Calendar FFI（`tasks_list_inbox` 等）是否在同一 PR 中废弃，还是先 deprecated 后续移除？~~ → **已由 Q1+Q2 裁决**：PR-4 expand（旧 FFI 保留为薄 wrapper），PR-6 contract（统一移除 15 个旧函数，见附录 A）。
2. ~~FRB 绑定重生成是否在 FFI PR 中完成，还是单独 PR？~~ → **已由 Q1 裁决**：PR-4（新增 FFI 后重生成）和 PR-6（移除旧 FFI 后重生成），均在同 PR 内完成，不单独拆 PR。
3. `ffi-contracts.md` 和 `API_COMPATIBILITY.md` 在哪个 PR 更新？ → **裁决如下**。

#### Q3 裁决：技术文档跟随变更 PR + 决策线 ADR 交由 PR-GOV 序列

**Q3.1-Q3.2**：已由 Q1+Q2 裁决（见上方删除线标注）。

**Q3.3：API 文档更新分配**

| 文档 | 更新 PR | 内容 |
|------|---------|------|
| `docs/api/ffi-contracts.md` | **PR-4**（新增）+ **PR-6**（移除） | PR-4 新增 Guarded\*Service FFI 函数契约；PR-6 移除 15 个旧函数契约（附录 A） |
| `docs/governance/API_COMPATIBILITY.md` | **PR-4** | PR-4 是 breaking change 实际发生点（新增 caller 参数、新接口），在此记录兼容性说明 |
| `docs/api/error-codes.md` | **PR-4** | PR-4 新增 Guard 相关错误码（如 `access_denied`、`invalid_query_descriptor` 等），DI-16 要求注册到 error-codes.md |

**原则**：技术 API 文档跟随产生变更的 PR 同步更新，不单独拆 docs PR。

**Q3.3 附：决策线 ADR 归属**

DI-12→DI-14→DI-15→DI-16→DI-17→DI-18 构成完整的 Workspace Tree Architecture 决策线。按 DI-19/DI-20 治理框架（T2 Phase B），该决策线的 Retrospective Reconstruction ADR 由 PR-GOV 序列负责：

- **PR-GOV-01**：source corpus 盘点时将 DI-12~DI-18 识别为候选决策线
- **PR-GOV-03**：产出对应的历史补录 ADR

DI-18 本身作为 Exploration 层文档收口，不直接产出 ADR。

---

### Q4. 测试策略？

**需要裁决**：

1. **Migration 测试**：
   - 从空库建表 → 系统节点存在
   - 从旧版本升级 → 回填正确、系统节点存在
   - 迁移失败 → 回滚不破坏旧数据

2. **Service 测试**：
   - 新 repo/service 方法的单元测试
   - 系统节点保护测试
   - 创建路由优先级测试

3. **FFI 测试**：
   - 新函数集成测试
   - 旧函数行为不变（回归）

4. **Flutter 测试**：
   - WorkspaceTreeService mock 测试
   - Tasks/Calendar controller 适配后的 widget 测试
   - Synthetic uncategorized 移除后的 Explorer 测试

#### Q4 裁决：Per-PR 测试责任制 + 清理验证

**总体策略**：每个 PR 自带测试覆盖其变更，沿用现有模式（Rust in-memory SQLite 集成测试 + Flutter mock invoker 注入）。测试分五类，前四类为功能测试，第五类为清理验证测试。

**1. Migration 测试（PR-1）**

| 场景 | 验证点 | 实现方式 |
|------|--------|----------|
| 全新安装 | 空 DB → 跑全部 migration → `workspaces` 表存在、`designated_folders` 3 个系统节点存在、`atoms.origin_workspace_id` 字段存在 | `open_db_in_memory` + 断言查询 |
| 版本升级 | DB at version 11 → migration 12 → 旧 atom 回填正确（已有 note/task/event 的 atom_ref 存在）、系统节点存在 | 先插入 v11 测试数据，再跑 migration 12 |
| 触发器负测：designated folder soft-delete 拒绝 | raw SQL `UPDATE workspace_nodes SET is_deleted = 1 WHERE node_uuid = <designated_folder>` → `protect_designated_folder_soft_delete` 触发器拒绝 | 直接执行 SQL，断言返回错误 |
| 触发器负测：designated folder hard-delete 拒绝 | raw SQL `DELETE FROM workspace_nodes WHERE node_uuid = <designated_folder>` → `protect_designated_folder_hard_delete` 触发器拒绝 | 直接执行 SQL，断言返回错误 |
| 触发器负测：跨 workspace designated 写入拒绝 | raw SQL 向 `designated_folders` 插入 `workspace_id` 与 `node_uuid` 所属 workspace 不一致的记录 → `validate_designated_folder_workspace` 触发器拒绝 | 直接执行 SQL，断言返回错误 |
| 触发器负测：workspace root re-parent 拒绝 | raw SQL `UPDATE workspace_nodes SET parent_uuid = <some_node> WHERE kind = 'workspace'` → `protect_workspace_root_reparent` 触发器拒绝 | 直接执行 SQL，断言返回错误 |
| 触发器负测：workspace root kind 篡改拒绝 | raw SQL `UPDATE workspace_nodes SET kind = 'folder' WHERE kind = 'workspace'` → `protect_workspace_root_kind` 触发器拒绝 | 直接执行 SQL，断言返回错误 |

**不新增回滚测试**：SQLite migration 在事务内执行，失败即整个事务回滚，`user_version` 不变。这是 SQLite 保证，不需要应用层验证。当前 11 个 migration 也无回滚测试先例。

**触发器负测的设计依据**：DI-15 将 designated folder 保护（Q9.1：soft-delete / hard-delete / 跨 workspace 写入）和 workspace root 保护（Q12：re-parent / kind 篡改）设计为 DB 触发器兜底。注意："映射行不可删除"（`DELETE FROM designated_folders`）是 Service 层拒绝（DI-15 Q9.1），不属于 migration 触发器负测范围。只测 schema 不够，必须验证触发器实际拒绝旁路 SQL 违规操作。

**2. Service 测试（PR-2、PR-3）**

沿用现有模式（in-memory SQLite 集成测试）：

| PR | 测试重点 |
|----|----------|
| PR-2 | ScopedQueryRepository：time-matrix 四象限（T0/T1/T2/T3）正确过滤、overdue T1 补偿、scope 限定（只返回子树内 atom）、分页、去重。**契约真值表显式覆盖**：`ProjectionMode × include_path` 合法/非法组合、`include_overdue_deadlines × time_filter` 合法/非法组合（DI-16 Q1 定义），非法组合必须返回 `invalid_query_descriptor` 错误，不可留到 FFI 层才验证 |
| PR-3 | TreeService 保护规则（系统节点不可删除/移出）、move 硬约束（不可移入非本 workspace）、CreationService `resolve_creation_role` 优先级（指定 folder > designated > root） |

**3. FFI 测试（PR-4）**

| 策略 | 内容 |
|------|------|
| **新函数测试** | `query_atoms`、`atom_create`、`workspace_resolve_designated` 等正向测试 + 错误码测试 |
| **旧函数回归** | 保留旧语义覆盖，必要时因 caller/绑定变化调整 harness。旧 wrapper 内部委托到新 service，现有测试全绿即回归通过 |
| **Guard 边界测试** | 新增测试专用 `DenyGuard` 实现（拒绝所有请求），验证 Guarded\*Service 经由 FFI 能稳定映射拒绝类错误码（如 `access_denied`）。证明 Guard 架构层实际生效，而非仅 NoopGuard 通路成功 |

**不做新旧 FFI 对比测试**：旧函数语义可能与新函数有差异（如旧函数不传 caller），逐一对比输出的投入产出比低。

**4. Flutter 测试（PR-5、PR-6）**

沿用现有模式（mock invoker 注入）：

| PR | 测试重点 |
|----|----------|
| PR-5 | WorkspaceTreeService：`loadSystemNodes` 成功/失败、`getSystemNodeId` 正常返回/抛异常、`TreeMutationDelta` 通知触发 `notifyListeners`。**delta 载荷测试**：create/move/delete/reassign_designated 操作各至少断言一次 `affectedParentIds` 内容正确（DI-17 Q2 核心价值），不只断言 listener 被调用 |
| PR-6 | TasksController/CalendarController：mock `WorkspaceTreeService` + `QueryAtomsInvoker`，验证 section 数据加载正确；Explorer：synthetic uncategorized 逻辑不存在（负向测试——确认无 BFS 合成） |

**5. 清理验证 gate（Q2 A+ 规则的验收门禁化落地）**

清理验证本质是验收门禁（grep / analyze / clippy），与功能测试同等优先级，写进 PR 的验收标准，不依赖人工 review。

| PR | 清理验证项 | 验证方式 |
|----|-----------|----------|
| **PR-4** | 旧 FFI 函数体已替换为薄 wrapper（不残留原始逻辑） | Review checklist：旧函数内部只有一次 Guarded\*Service 委托调用 |
| **PR-6** | 15 个旧 FFI 函数名零匹配 | CI 脚本：grep 附录 A 全部旧函数名，代码文件（`.rs` + `.dart`）匹配数 == 0（排除 `docs/`、`CHANGELOG.md`） |
| **PR-6** | `workspace_tree_children_loader.dart` 已删除 | CI 脚本：断言文件不存在 |
| **PR-6** | uncategorized 引用清零 | CI 脚本：grep `uncategorized` / `synthetic` 相关标识符，代码文件中匹配数 == 0 |
| **每个 PR** | 无孤立 import / 无死代码 | `flutter analyze` 零 warning + `cargo clippy` 零 warning（CI gate，明确列为测试验收项） |

**PR-6 清理验证脚本参考**（与 Q2 R4 对齐）：

```bash
# 旧 FFI 函数名零匹配（附录 A 完整清单）
grep -rn "tasks_list_inbox\|tasks_list_today\|tasks_list_upcoming\|calendar_list_by_range\|notes_list\|entry_search\|atoms_list_timed\|entry_create_note\|entry_create_task\|entry_schedule\|note_create\|note_update\|note_set_tags\|calendar_update_event\|note_get" \
  crates/ apps/ --include="*.rs" --include="*.dart"
# 预期：零匹配

# 删除文件验证
test ! -f apps/lazynote_flutter/lib/core/workspace/workspace_tree_children_loader.dart

# uncategorized 清零
grep -rn "uncategorized\|synthetic" apps/ --include="*.dart" | grep -v "test" | grep -v "//"
# 预期：零匹配（排除测试文件和注释）
```

**设计决策摘要**：

| 决策 | 理由 |
|------|------|
| Per-PR 测试责任制 | 每个 PR 自包含，不依赖后续 PR 补测试 |
| 不新增 migration 回滚测试 | SQLite 事务保证，无先例，投入产出比低 |
| PR-1 触发器负测（5 项） | DI-15 将 designated folder 保护（Q9.1：soft-delete/hard-delete/跨 workspace）和 workspace root 保护（Q12：re-parent/kind 篡改）设计为 DB 触发器兜底，只测 schema 不够，必须验证不变量。注意"映射不可删除"是 Service 层拒绝，不在触发器负测范围 |
| PR-2 契约真值表显式覆盖 | DI-16 Q1 对 descriptor 组合合法性有严格定义，不可留到 FFI 层顺带验证 |
| PR-4 DenyGuard 测试 | 证明 Guard 架构层实际生效（拒绝路径 + 错误码映射），而非仅 NoopGuard 通路成功 |
| PR-5 delta 载荷断言 | DI-17 Q2 核心价值是 affectedParentIds 供定向刷新，不只是"有通知" |
| 不做新旧 FFI 对比测试 | 语义差异存在（caller 参数），旧测试全绿已足够 |
| 清理验证列为验收门禁 | Q2 A+ 的 R1-R4 规则需要可自动化验证，防止因复杂度降级处理 |
| 旧 FFI 测试保留语义覆盖 | 必要时因 caller/绑定变化调整 harness，不被"不修改不删除"字面约束 |
| 引用旧 FFI 的测试代码在 PR-6 同步迁移或删除 | Q2 R1 规则：不遗留废弃代码 |

---

### Q5. 代码文件搬迁策略？

Flutter 侧需要将部分文件从 `features/notes/` 搬迁到 `lib/core/workspace/`。注意：DI-17 Q3 裁决为 A+/B-（v0.4 不提取共享 UI 组件到 `lib/shared/`），因此搬迁目标仅限 `lib/core/workspace/`（数据/状态层），不涉及 `lib/shared/`。

**需要裁决**：

1. **Git history 保留**：
   - A. `git mv` 保留 rename tracking
   - B. 删除旧文件 + 创建新文件（history 断裂但更干净）

2. **搬迁文件范围**：
   - 哪些文件搬到 `lib/core/workspace/`（数据/状态层）
   - 哪些文件留在 `features/notes/`（Notes 专有 UI + 视图状态）
   - `lib/shared/` 不新增树 UI 组件（DI-17 Q3 裁决：提取触发条件未达标）

3. **搬迁时机**：
   - PR-5/PR-6 中搬迁？
   - 还是先搬迁再适配（两个 PR）？

#### Q5 裁决：无搬迁 + CI 强制化提取至 DI-21

**Q5.1 结论：v0.4 不需要文件搬迁**

PR-RB-05（S9 提取）已将 workspace 基础设施搬迁到 `lib/core/workspace/`。当前文件分布：

| 位置 | 文件 | v0.4 动作 | 理由 |
|------|------|-----------|------|
| `lib/core/workspace/` | `workspace_tree_service.dart` | 原地增强（PR-5） | 已在正确位置 |
| `lib/core/workspace/` | `workspace_tree_types.dart` | 原地扩展（加 TreeMutationDelta） | 已在正确位置 |
| `lib/core/workspace/` | `workspace_tree_error_utils.dart` | 保留或按需调整 | 已在正确位置 |
| `lib/core/workspace/` | `workspace_tree_children_loader.dart` | **删除**（PR-6，DI-17 Q6） | 全量删除，非搬迁 |
| `features/notes/` | `explorer_tree_state.dart` | 留原处 | DI-17 Q1 B+：feature 层保留自己的数据缓存 |
| `features/notes/` | Explorer UI 文件（7 个） | 留原处 | Notes 专有 UI |
| `features/notes/` | 树操作对话框（4 个） | 留原处 | DI-17 Q3：提取触发条件未达标（当前仅 1 消费者） |
| `features/notes/` | Notes 专有文件（12 个） | 留原处 | 与搬迁无关 |

**三个子问题的消解**：

- **Q5.1 Git history**：无搬迁发生，问题不成立。未来若需搬迁，使用 `git mv` 保留 rename tracking。
- **Q5.2 搬迁范围**：零文件搬迁。core 基础设施已就位，feature 文件按 DI-17 Q1/Q3 留在 features 层。
- **Q5.3 搬迁时机**：无搬迁。PR-5 原地增强 `lib/core/workspace/`，PR-6 删除 `workspace_tree_children_loader.dart` + 清理引用。

**Q5.2 提取触发条件的 CI 强制化 → 拆分至 [DI-21](DI-21-ci-duplication-detection.md)**

讨论过程中识别出 DI-17 Q3 的提取触发条件（>100 行重复 + 2 消费者）缺少自动化强制手段。Rule E 阻止跨 feature import，但不阻止在另一个 feature 下重建功能相同的代码绕过提取。现有缓解方案（PR spec、CLAUDE.md、文件名匹配）均存在失败模式，跨 feature 代码相似度检测（CI）是唯一可行的自动化强制方案。

该方案的完整设计（检测参数、实现方式、CI 输出格式、现有 Check 输出补强）已拆分至 **DI-21** 独立讨论。DI-21 是 DI-18 执行的前置条件（PR-0b）。

**设计决策摘要**：

| 决策 | 理由 |
|------|------|
| v0.4 无文件搬迁 | PR-RB-05 已完成 core 层提取，DI-17 Q1/Q3 裁决 feature 文件留原处 |
| 未来搬迁使用 `git mv` | 保留 rename tracking，`git log --follow` 可追溯 |
| CI 强制化提取拆分至 DI-21 | 方案独立性和内容量值得单独 DI，且是 PR-0b 的设计依据 |

---

## 附录 A：旧 FFI 移除清单（PR-6 contract 阶段）

PR-6 合入时必须移除以下 15 个旧 FFI 函数。来源：DI-16 Q6.1（查询）、Q6.2（创建）、Q6.3（重命名）。

| # | 旧函数名 | 类别 | 替代 | DI-16 来源 |
|---|----------|------|------|-----------|
| 1 | `tasks_list_inbox` | 查询 | `query_atoms` | Q6.1 |
| 2 | `tasks_list_today` | 查询 | `query_atoms` | Q6.1 |
| 3 | `tasks_list_upcoming` | 查询 | `query_atoms` | Q6.1 |
| 4 | `calendar_list_by_range` | 查询 | `query_atoms` | Q6.1 |
| 5 | `notes_list` | 查询 | `query_atoms` | Q6.1 |
| 6 | `entry_search` | 查询 | `query_atoms` | Q6.1 |
| 7 | `atoms_list_timed` | 查询 | `query_atoms` | Q6.1 |
| 8 | `entry_create_note` | 创建 | `atom_create` | Q6.2 |
| 9 | `entry_create_task` | 创建 | `atom_create` | Q6.2 |
| 10 | `entry_schedule` | 创建 | `atom_create` | Q6.2 |
| 11 | `note_create` | 创建 | `atom_create` | Q6.2 |
| 12 | `note_update` | 重命名 | `atom_update_content` | Q6.3 |
| 13 | `note_set_tags` | 重命名 | `atom_set_tags` | Q6.3 |
| 14 | `calendar_update_event` | 重命名 | `atom_update_time` | Q6.3 |
| 15 | `note_get` | 重命名 | `atom_get` | Q6.3 |

**验证命令**（R4 迁移完整性断言）：
```bash
# 在 crates/ 和 apps/ 下 grep 所有旧函数名，排除 docs/CHANGELOG
grep -rn "tasks_list_inbox\|tasks_list_today\|tasks_list_upcoming\|calendar_list_by_range\|notes_list\|entry_search\|atoms_list_timed\|entry_create_note\|entry_create_task\|entry_schedule\|note_create\|note_update\|note_set_tags\|calendar_update_event\|note_get" crates/ apps/ --include="*.rs" --include="*.dart"
# 预期结果：零匹配
```

---

## 关联

- ← DI-15（Rust 数据模型裁决）
- ← DI-16（Rust API 裁决）
- ← DI-17（Flutter 方案裁决）
- → DI-20（文本治理重构，PR-0a 前置条件）
- → DI-21（CI 重复检测，PR-0b 前置条件）
- → PR-GOV-01（source corpus 盘点：DI-12~DI-18 为候选 ADR 决策线）
- → 实际 PR 实现

---

*前序议题：[DI-17 Flutter 薄客户端](DI-17-flutter-thin-client.md)*
