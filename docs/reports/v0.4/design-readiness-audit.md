# v0.4 设计就绪审计（Design Readiness Audit）

| 项目 | 值 |
|------|-----|
| **版本** | v0.4 |
| **审计日期** | 2026-03-10 |
| **依据** | `docs/releases/v0.4/20QA.MD`（20 个设计问题 Q&A） |
| **范围** | PR-0407~PR-0416（workspace execution + S1 能力落地）；PR-0417~PR-0419 延期至 v0.5 |

---

## 一、跨 PR 阻塞性决策（Cross-PR Blockers）

### X1：FFI 接口方向

| 项 | 状态 |
|----|------|
| 原始问题 | 旧 `note_create` / `entry_create_*` 路径是否在 PR-0414~PR-0416 中仍然使用？ |
| 裁决（X1A） | **已解决** — PR-0411 新增 `atom_create(caller, request)`（含 `content_type` 字段）、`atom_get`、`atom_update_content` 等统一接口；PR-0413 移除旧函数；PR-0414~PR-0416 直接消费新 FFI。 |
| 设计就绪状态 | ✅ 已解决 |

### X2：Migration 编号分配

| 项 | 状态 |
|----|------|
| 裁决（X2A） | **已解决** — 编号分配如下：PR-0408 → Migration 12，PR-0414 → 13，PR-0415 → 14，PR-0416 → 15，PR-0419 → 16（已延期）。PR-0417 和 PR-0418 不需要 schema 变更（Core 视 content 为 opaque string）。 |
| 设计就绪状态 | ✅ 已解决 |

---

## 二、PR 分组设计就绪状态

### 2.1 治理执行组（PR-0400~PR-0406）

此组 PR 处理 ADR 治理体系建设（来源：DI-19/DI-20），不涉及 20QA.MD 中的设计问题。

| PR | 标题 | 设计就绪 | 备注 |
|----|------|---------|------|
| PR-0400 | Legacy Rulings 归档 | ✅ 已就绪 | 无外部设计依赖 |
| PR-0401 | Source Corpus 提取与 DN 分类 | ✅ 已就绪 | 无外部设计依赖 |
| PR-0402 | ADR 基础设施与 Metadata Contract | ✅ 已就绪 | 无外部设计依赖 |
| PR-0403 | 按 ADR 串行执行 | ✅ 已就绪 | 无外部设计依赖 |
| PR-0404 | Theme Delta Contract 与一致性审计 | ✅ 已就绪 | 无外部设计依赖 |
| PR-0405 | 闭合审计与治理激活 | ✅ 已就绪 | 无外部设计依赖 |
| PR-0406 | Template Playbook 与 Lifecycle Backfill | ✅ 已就绪 | 无外部设计依赖 |

### 2.2 Workspace 执行组（PR-0407~PR-0413）

此组 PR 处理 workspace 单根树与 FFI 统一（来源：DI-15~DI-18），不涉及 20QA.MD 中的设计问题。

| PR | 标题 | 设计就绪 | 备注 |
|----|------|---------|------|
| PR-0407 | CI 跨 Feature 重复检测 + Check 输出补强 | ✅ 已就绪 | 依据 DI-21 Q1-Q3；无 20QA 依赖 |
| PR-0408 | Schema Migration 0012（单根树 + Workspace 元数据） | ✅ 已就绪 | 依据 DI-15；X2A 确认 Migration 12 编号 |
| PR-0409 | Scoped Query Repository | ✅ 已就绪 | 依据 DI-15/DI-16 |
| PR-0410 | Tree Service + Creation Service | ✅ 已就绪 | 依据 DI-16/DI-18 |
| PR-0411 | Guard + FFI 统一 | ✅ 已就绪 | X1A 确认新 FFI 接口方向 |
| PR-0412 | Flutter Core 收敛 | ✅ 已就绪 | 依据 DI-17；X1A 确认 FFI 消费路径 |
| PR-0413 | Flutter Features 收敛 | ✅ 已就绪 | 依据 DI-17；X1A 确认旧接口移除 |

### 2.3 S1 能力落地组（PR-0414~PR-0416）

| PR | 标题 | 设计就绪 | 未解决项 |
|----|------|---------|---------|
| PR-0414 | icon + cover_image（S1 R9/R10） | ✅ 已就绪 | 无 |
| PR-0415 | atom_comments（S1 R11） | ✅ 已就绪 | 无 |
| PR-0416 | atom_overlays + ViewMode（S1 R14 + S2） | ✅ 已就绪 | 无 |

**PR-0414 设计裁决摘要：**
- Q1A：`icon` 字段 — Core 视为 opaque string，长度上限 64 字符；Flutter 层负责 emoji 渲染与 Material Icons 查表。
- Q2A：`cover_image` 字段 — 方案 C（Core opaque + 分阶段）：v0.4 Flutter 层使用绝对路径；v0.5 引入 sync 时迁移为托管附件体系。变更需走 playbook 流程更新文档。
- Q3A：setter API — 新增统一 `atom_update_metadata(atom_id, icon?, cover_image?)` 函数，返回 `AtomItemResponse`。
- Q4A：`AtomListItem` 同时携带 `icon` + `cover_image` 字段。

**PR-0415 设计裁决摘要：**
- Q5A：Comments 为 append-only；通过 `is_deleted` 软删除字段支持删除。
- Q6A：删除策略 — 软删除（保留历史记录）。
- Q7A：宿主 Atom 软删除时，关联 comments 级联软删除。
- Q8A：`AtomListItem` 不需要 `comment_count` 字段。

**PR-0416 设计裁决摘要：**
- Q9A：Reconciliation 算法宿主 — Rust 端实现，新增 markdown AST 解析能力。
- Q10A：`ViewMode` enum 成员：`source` / `block` / `preview`（v0.4 落地）+ `inline`（预留枚举值，v0.5 实现）。
- Q11A：`content_rev` 同步策略 — Flutter 不跟踪；mode 切换时调 `atom_get_overlay(atom_id)` → Core 返回 `{ block_meta, is_stale, overlay_rev }`；`atom_update_content` 响应不变。

### 2.4 延期组（PR-0417~PR-0419）

以下 PR 工作量评估后延期至 v0.5，设计问题（Q12~Q20）在此版本**跳过**，不作为 v0.4 阻塞项。

| PR | 标题 | 状态 | 关联问题 |
|----|------|------|---------|
| PR-0417 | Canvas Editor（S1 R12-A）| 延期至 v0.5 | Q12/Q13/Q14 |
| PR-0418 | Conversation MVP（S1 R13） | 延期至 v0.5 | Q15/Q16/Q17 |
| PR-0419 | Spatial Workspace + Explorer 三视图（S1 R12-B + S3） | 延期至 v0.5 | Q18/Q19/Q20 |

v0.4 对 PR-0417~PR-0419 的规划变更：
- PR-0417（Canvas）：v0.4 仅做技术选型与设计讨论，不落地实现。
- PR-0418（Conversation）：v0.4 仅做简单 Claude Code SDK 集成，验证对话功能基本可行性。
- PR-0419（Spatial）：整体延期至 v0.5。

### 2.5 Issue 修复与优化组（PR-0421~PR-0424）

此组 PR 处理已知 issue 修复（#44~#50）与 UI/UX 优化，不涉及 20QA.MD 中的设计问题。

| PR | 标题 | 设计就绪 | 备注 |
|----|------|---------|------|
| PR-0421 | Editor 修复（Issue #44~#46 相关） | ✅ 已就绪 | 无新设计决策 |
| PR-0422 | FFI 测试隔离（Issue #46） | ✅ 已就绪 | 无新设计决策 |
| PR-0423 | 跨 Feature Refresh 修复（Issue #47~#50 相关） | ✅ 已就绪 | 无新设计决策 |
| PR-0424 | UI/UX 优化（TBD） | ⚠️ 部分就绪 | 范围待定；不阻塞其他 PR |

---

## 三、20 个设计问题汇总表

| # | 问题摘要 | 关联 PR | 解决状态 | 裁决要点 |
|---|---------|---------|---------|---------|
| X1 | FFI 接口方向（旧入口是否废弃） | PR-0411/PR-0413 | ✅ 已解决 | 新统一接口取代旧入口 |
| X2 | Migration 编号分配 | PR-0408/PR-0414~PR-0416 | ✅ 已解决 | 12→13→14→15 顺序固定 |
| Q1 | icon 值格式 | PR-0414 | ✅ 已解决 | Core opaque string，64 字符上限 |
| Q2 | cover_image 值格式与文件管理机制 | PR-0414 | ✅ 已解决 | 方案 C：v0.4 绝对路径，v0.5 迁移 |
| Q3 | setter API 模式（统一 patch vs 独立函数） | PR-0414 | ✅ 已解决 | 统一 `atom_update_metadata` |
| Q4 | AtomListItem 是否携带 icon + cover_image | PR-0414 | ✅ 已解决 | 携带 |
| Q5 | Comments 可编辑还是 append-only | PR-0415 | ✅ 已解决 | Append-only + is_deleted 软删除 |
| Q6 | Comments 删除策略（软/硬删除） | PR-0415 | ✅ 已解决 | 软删除 |
| Q7 | 宿主 Atom 软删除后 comments 处理 | PR-0415 | ✅ 已解决 | 级联软删除 |
| Q8 | AtomListItem 是否需要 comment_count | PR-0415 | ✅ 已解决 | 不需要 |
| Q9 | Reconciliation 算法宿主（Rust vs Dart） | PR-0416 | ✅ 已解决 | Rust 端实现 |
| Q10 | ViewMode enum 成员集合 | PR-0416 | ✅ 已解决 | source/block/preview + inline 预留 |
| Q11 | content_rev 同步策略 | PR-0416 | ✅ 已解决 | Flutter 不跟踪，按需查询 |
| Q12 | Canvas 渲染引擎技术选型 | PR-0417（延期） | ⏭ 跳过（v0.5） | v0.4 仅技术选型讨论 |
| Q13 | Viewport 状态持久化 | PR-0417（延期） | ⏭ 跳过（v0.5） | 裁决持久化，v0.5 实现 |
| Q14 | Canvas preview_image 生成 | PR-0417（延期） | ⏭ 跳过（v0.5） | v0.4 跳过 |
| Q15 | Conversation MVP LLM 接入边界 | PR-0418（延期） | ⏭ 跳过（v0.5） | v0.4 仅 SDK 验证 |
| Q16 | EditBuffer 对 conversation 的适用性 | PR-0418（延期） | ⏭ 跳过（v0.5） | — |
| Q17 | Conversation title/preview_text 推导责任归属 | PR-0418（延期） | ⏭ 跳过（v0.5） | — |
| Q18 | 三视图模式状态归属 | PR-0419（延期） | ⏭ 跳过（v0.5） | — |
| Q19 | Tag × Spatial 并发切换优先级 | PR-0419（延期） | ⏭ 跳过（v0.5） | — |
| Q20 | 自动布局算法（NULL 坐标时的 fallback） | PR-0419（延期） | ⏭ 跳过（v0.5） | — |

**汇总：**
- ✅ 已解决：13 项（X1、X2、Q1~Q11）
- ⏭ 跳过（延期至 v0.5）：9 项（Q12~Q20）
- ⚠️ 未解决阻塞项：0 项

---

## 四、结论

v0.4 在范围内的所有 PR（PR-0400~PR-0416，PR-0421~PR-0423）的设计决策均已通过 20QA.MD Q&A 解决，无设计层面的阻塞项。PR-0417~PR-0419 已正式延期至 v0.5，其关联设计问题（Q12~Q20）随 PR 一并延期，不影响 v0.4 执行。

PR-0424（UI/UX 优化）范围待定，处于部分就绪状态，但不阻塞其他 PR 的进行。
