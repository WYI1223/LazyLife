# Rulings Registry

> 项目结构、语义与工程决策的权威裁决记录。所有 PR 规划与执行必须遵守本目录中的裁决。
>
> 每条裁决是自包含文档，包含完整的决策、规则、理由与实施状态。
> - **S 系列**（Semantic）：领域语义与结构裁决
> - **E 系列**（Engineering）：工程流程与基础设施决策

| 字段 | 值 |
|------|-----|
| 建立时间 | 2026-02-27 |
| 基线版本 | v0.2.5 (commit `372bf18`) |
| 历史来源 | `docs/reports/v0.2.5/frontend-review/08b-semantic-decisions.md`（冻结快照） |

---

## 裁决索引

### S 系列（Semantic — 领域语义与结构裁决）

| ID | 标题 | 状态 | 关联 v0.3 PR |
|----|------|------|-------------|
| [S1](S1-atom-projection.md) | Atom 投影语义 | Landed — v0.3 基线 + v0.4 addendum(DI-11/12, planning) | PR-RB-02, PR-RB-03 |
| [S2](S2-tab-draft-save-ownership.md) | Tab/Draft/Save 状态归属 | Accepted — Phase 1 Landed, Phase 2/3 v0.3 | PR-RB-06 |
| [S3](S3-tag-workspace-orthogonality.md) | Tag × Workspace Tree 正交性 | Accepted — v0.3 | PR-RB-10 |
| [S4](S4-creation-path-unification.md) | Note 创建入口统一 | Accepted — v0.3 基线 + v0.4 addendum(DI-11/12) | PR-RB-03 |
| [S5](S5-extension-kernel-boundary.md) | Extension Kernel → Flutter 命令系统边界 | Landed | — |
| [S6](S6-provider-spi-interaction.md) | Provider SPI → external_mappings 交互 | Accepted — v0.3 | PR-RB-12 (Conditional) |
| [S7](S7-reminders-infrastructure.md) | Reminders 模块定位 | Landed | — |
| [S8](S8-noteitem-unification.md) | NoteItem → AtomListItem 类型统一 | Landed | PR-RB-01 |
| [S9](S9-cross-feature-infrastructure-placement.md) | 跨 feature 基础设施模块归属 | Accepted — v0.3 | PR-RB-05 |

### E 系列（Engineering — 工程/基础设施决策）

| ID | 标题 | 状态 | 关联 v0.3 PR |
|----|------|------|-------------|
| [E1](E1-release-and-versioning.md) | Release and Versioning Strategy | Landed | — |

## 状态定义

| 状态 | 含义 |
|------|------|
| **Proposed** | 提议中，未裁决 |
| **Accepted** | 已裁决，待实现或已实现 |
| **Landed** | 已裁决且已实现（代码已合入或语义已生效） |
| **Deprecated** | 已废弃，由其他 ruling 取代 |

## 维护规则

1. **单一信息源**：每条裁决的权威内容仅存在于本目录对应文件中
2. **修订追踪**：任何裁决变更必须在文件内记录修订历史
3. **架构文档同步**：裁决变更后，必须同步更新引用该裁决的架构文档
4. **PR 合规**：所有 PR 设计必须检查本目录中相关裁决的约束
