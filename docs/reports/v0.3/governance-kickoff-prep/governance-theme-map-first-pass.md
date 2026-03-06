# Governance Theme Map First Pass

> `PR-GOV-01` 产物。本文是 first-pass `decision line` 主题地图，
> 不是 `docs/architecture/adr/topic-map.md` 的替代品。
> 正式 `topic-map` 需在 `PR-GOV-02` 以后承载已批准主题。

---

## Theme ID Policy

1. 本文使用临时候选编号：`TH-001`, `TH-002`, `TH-003`, ...
2. `TH-xxx` 不得与 `DI-20` 的治理主题编号 `T1-T8` 混用。
3. `Current Status` 仅表示 first-pass 判断，不表示已发布 ADR。

当前使用的 first-pass 状态词：

- `candidate_first_batch`
- `later_batch_candidate`
- `split_pending`

---

## Index

| Theme ID | Decision Line Title | First Seen In Corpus | Current Status | Planned ADR | Owner |
|------|------|------|------|------|------|
| `TH-001` | Atom projection model evolution | `C01` | `candidate_first_batch` | `ADR-000X-atom-projection-model-evolution` | `PR-GOV-03` |
| `TH-002` | Tag × Workspace Tree orthogonality | `C01` | `later_batch_candidate` | `ADR-000X-tag-workspace-orthogonality` | `PR-GOV-03` |
| `TH-003` | Creation path unification and atom_ref pairing | `C01` | `later_batch_candidate` | `ADR-000X-creation-path-unification` | `PR-GOV-03` |
| `TH-004` | Reminders positioning and trigger semantics | `C01` | `later_batch_candidate` | `ADR-000X-reminders-positioning-and-trigger-semantics` | `PR-GOV-03` |
| `TH-005` | Atom list DTO unification (`NoteItem` -> `AtomListItem`) | `C01` | `split_pending` | `pending` | `PR-GOV-02` |
| `TH-006` | Release and versioning strategy lineage | `C06` | `candidate_first_batch` | `ADR-0001-release-and-versioning` | `PR-GOV-03` |
| `TH-007` | Governance carrier evolution (`ADR -> Ruling -> replay + activation`) | `C06` | `candidate_first_batch` | `ADR-000X-governance-carrier-evolution` | `PR-GOV-03` |

---

## Theme Records

### TH-001

| Field | Value |
|------|------|
| `Theme ID` | `TH-001` |
| `Decision Line Title` | `Atom projection model evolution` |
| `Stable Why-Question` | `Why should Atom projection be defined by unified atom semantics rather than legacy type-only hints, so that notes/tasks/calendar surfaces consume one truth consistently?` |
| `Decision Subject` | Atom projection semantics across note/task/calendar views |
| `Governing Tension` | 统一 Atom 真相 vs 视图层/旧字段启发式 |
| `Acceptance Semantics` | 当前文档链能够解释 S1 的投影语义与 v0.3 handoff，而不依赖互相冲突的 view-specific 解释 |
| `Primary Upstream` | `C02 (08b / S1)` |
| `Secondary Input Constraints` | `C01 (08a / S1)`, `C04 (08d / S1 映射)`, `C05 (09 / S1 处置矩阵)`, `C08 (v0.3 release evidence / Rulings S1)` |
| `Relation Types` | `inherited_context: TH-005` |
| `Supersedes / Redirected By` | `none in current corpus` |
| `First Seen In Corpus` | `C01 (08a / S1)` |
| `Current Status` | `candidate_first_batch` |
| `Planned ADR` | `ADR-000X-atom-projection-model-evolution` |
| `Published ADR` | `pending` |
| `Owner` | `PR-GOV-03` |
| `Notes` | `DI-19` 原始样例曾把 `S1` 与 `S8` 放入同一 Atom 投影旅程；first-pass 先拆开，保留显式关系。 |

### TH-002

| Field | Value |
|------|------|
| `Theme ID` | `TH-002` |
| `Decision Line Title` | `Tag × Workspace Tree orthogonality` |
| `Stable Why-Question` | `Why should tag filtering and workspace tree stay orthogonal, so that explorer semantics remain stable even when tag query capability evolves?` |
| `Decision Subject` | Tag filtering 与 workspace tree 的交互边界 |
| `Governing Tension` | 单一面板心智模型 vs 两套独立语义轴的正交性 |
| `Acceptance Semantics` | 文档链能够明确“tag 过滤不改写 tree 语义”，且后续实现只能验证该不变式，不能静默重定义它 |
| `Primary Upstream` | `C02 (08b / S3)` |
| `Secondary Input Constraints` | `C01 (08a / S3)`, `C04 (08d / S3 映射)`, `C05 (09 / S3 处置矩阵)` |
| `Relation Types` | `co-occurrence only: TH-003` |
| `Supersedes / Redirected By` | `none in current corpus` |
| `First Seen In Corpus` | `C01 (08a / S3)` |
| `Current Status` | `later_batch_candidate` |
| `Planned ADR` | `ADR-000X-tag-workspace-orthogonality` |
| `Published ADR` | `pending` |
| `Owner` | `PR-GOV-03` |
| `Notes` | `09` 明确当前行为已符合 S3 语义，v0.3 任务更偏向“不变式验证”，因此 first-pass 不强制进入首批。 |

### TH-003

| Field | Value |
|------|------|
| `Theme ID` | `TH-003` |
| `Decision Line Title` | `Creation path unification and atom_ref pairing` |
| `Stable Why-Question` | `Why should all creation paths converge on one storage invariant, so that head-create and tree-create no longer produce semantically divergent results?` |
| `Decision Subject` | 创建路径语义与 `atom_ref` / 指定路径配对约束 |
| `Governing Tension` | 多入口 UX 便利性 vs 存储层路径不变量 |
| `Acceptance Semantics` | 文档链能够明确所有创建路径最终收敛到同一语义结果，并能解释 `atom_ref` 强制配对为何是 handoff 的关键前提 |
| `Primary Upstream` | `C02 (08b / S4)` |
| `Secondary Input Constraints` | `C01 (08a / D8, S4)`, `C04 (08d / S4 映射)`, `C05 (09 / S4 处置矩阵)` |
| `Relation Types` | `inherited_context: TH-001` |
| `Supersedes / Redirected By` | `none in current corpus` |
| `First Seen In Corpus` | `C01 (08a / D8, S4)` |
| `Current Status` | `later_batch_candidate` |
| `Planned ADR` | `ADR-000X-creation-path-unification` |
| `Published ADR` | `pending` |
| `Owner` | `PR-GOV-03` |
| `Notes` | 当前 corpus 已能证明它是独立决策线，但首批是否进入 ADR 仍以后续 batch 选择为准。 |

### TH-004

| Field | Value |
|------|------|
| `Theme ID` | `TH-004` |
| `Decision Line Title` | `Reminders positioning and trigger semantics` |
| `Stable Why-Question` | `Why should reminders be treated as shared/core capability rather than feature-local code, so that Rule E and lifecycle-triggered scheduling stay consistent?` |
| `Decision Subject` | Reminders 的模块定位与触发语义 |
| `Governing Tension` | feature-local 实现便利 vs 基础设施一致性 |
| `Acceptance Semantics` | 文档链能够同时解释 reminders 的放置位置和其触发语义，不再依赖跨 feature import 例外来维持行为 |
| `Primary Upstream` | `C02 (08b / S7)` |
| `Secondary Input Constraints` | `C01 (08a / D10, S7)`, `C04 (08d / S7 映射)`, `C05 (09 / S7 处置矩阵)` |
| `Relation Types` | `none in current corpus` |
| `Supersedes / Redirected By` | `none in current corpus` |
| `First Seen In Corpus` | `C01 (08a / D10, S7)` |
| `Current Status` | `later_batch_candidate` |
| `Planned ADR` | `ADR-000X-reminders-positioning-and-trigger-semantics` |
| `Published ADR` | `pending` |
| `Owner` | `PR-GOV-03` |
| `Notes` | `09` 已记录 reminders 迁移至 `core/`，但 first-pass 仍将其保留为独立决策线，而不是并入一般 Rule E 修复。 |

### TH-005

| Field | Value |
|------|------|
| `Theme ID` | `TH-005` |
| `Decision Line Title` | `Atom list DTO unification (NoteItem -> AtomListItem)` |
| `Stable Why-Question` | `Why should list-oriented FFI DTOs converge on atom-oriented responses, so that projection consumers stop carrying a parallel NoteItem lineage?` |
| `Decision Subject` | FFI 列表 DTO 边界 |
| `Governing Tension` | 旧有 note-specific DTO 兼容性 vs 统一 atom-oriented API surface |
| `Acceptance Semantics` | 文档链能够明确 `NoteItem` 何时只是历史过渡物，以及统一后的列表面如何回到 `AtomListItem` / `AtomListResponse` |
| `Primary Upstream` | `C02 (08b / S8)` |
| `Secondary Input Constraints` | `C01 (08a / S8)`, `C04 (08d / S8 映射)`, `C05 (09 / S8 处置矩阵)` |
| `Relation Types` | `inherited_context: TH-001` |
| `Supersedes / Redirected By` | `split_pending against TH-001` |
| `First Seen In Corpus` | `C01 (08a / S8)` |
| `Current Status` | `split_pending` |
| `Planned ADR` | `pending` |
| `Published ADR` | `pending` |
| `Owner` | `PR-GOV-02` |
| `Notes` | first-pass 将它从 `TH-001` 中拆出，因为其 `Decision Subject` 是 FFI surface，不是投影语义本身；是否重新并入须在 `PR-GOV-02` 明确裁决。 |

### TH-006

| Field | Value |
|------|------|
| `Theme ID` | `TH-006` |
| `Decision Line Title` | `Release and versioning strategy lineage` |
| `Stable Why-Question` | `Why should release and versioning remain a stable engineering decision line even after ADR-0001 was migrated into E1?` |
| `Decision Subject` | 发布与版本策略的历史连续性 |
| `Governing Tension` | 历史连续性 vs 当前 Ruling 体系下的规范统一 |
| `Acceptance Semantics` | 文档链能够说明 `ADR-0001 -> E1` 的迁移关系，并明确当前规范以 `E1` 为准，而补录 ADR 只承担旅程层叙事职责 |
| `Primary Upstream` | `C07 (E1)` |
| `Secondary Input Constraints` | `C06 (PR-RB-00 / B2)`, `C08 (v0.3 release evidence)`, `C09 (DI-19 / ADR-0001 示例)` |
| `Relation Types` | `inherited_context: TH-007` |
| `Supersedes / Redirected By` | `ADR-0001 (deleted) -> E1 -> retrospective ADR pending` |
| `First Seen In Corpus` | `C06 (PR-RB-00 / B2)` |
| `Current Status` | `candidate_first_batch` |
| `Planned ADR` | `ADR-0001-release-and-versioning` |
| `Published ADR` | `pending` |
| `Owner` | `PR-GOV-03` |
| `Notes` | 该主题在 `DI-19` 的原始样例中已被明确识别，且当前 corpus 已具备 `迁移来源` 元数据。 |

### TH-007

| Field | Value |
|------|------|
| `Theme ID` | `TH-007` |
| `Decision Line Title` | `Governance carrier evolution (ADR -> Ruling -> replay + activation)` |
| `Stable Why-Question` | `Why should governance split journey-layer ADRs from normative Rulings, so that cross-version traceability can be restored without collapsing back into one-file authority?` |
| `Decision Subject` | 架构治理载体分层 |
| `Governing Tension` | 单载体治理便利性 vs 跨版本追溯与分层权威 |
| `Acceptance Semantics` | 文档链能够说明为什么 v0.3 曾废弃 ADR、为什么 DI-19 重新引入 ADR 作为旅程层、以及为什么治理激活与 backfill 必须后置 |
| `Primary Upstream` | `C09 (DI-19)` |
| `Secondary Input Constraints` | `C06 (PR-RB-00 / B2)`, `C07 (E1 / 迁移来源)`, `C08 (v0.3 boundary)`, `C10 (DI-20 / execution plan)` |
| `Relation Types` | `superseding_dependency over C06 carrier model`; `upstream dependency: TH-006` |
| `Supersedes / Redirected By` | `PR-RB-00 ADR-deprecation model -> DI-19/20 replay-and-activation model` |
| `First Seen In Corpus` | `C06 (PR-RB-00 / B2)` |
| `Current Status` | `candidate_first_batch` |
| `Planned ADR` | `ADR-000X-governance-carrier-evolution` |
| `Published ADR` | `pending` |
| `Owner` | `PR-GOV-03` |
| `Notes` | 当前治理执行的中心主题；其补录 ADR 与后续 Native ADR 模板不是同一事项。 |

---

## Explicit Scope Gap

以下候选主题暂未进入 first-pass 地图：

1. `DI-12 / DI-14 / DI-15 / DI-16 / DI-17 / DI-18` 对应的 workspace topology / thin-client 决策线；
2. 任何需要新增 source corpus 才能证明 `Primary Upstream` 的主题。

若后续需要把这些主题纳入补录 ADR 范围，应先扩充 `governance-source-corpus-inventory.md`，再扩充本图。

