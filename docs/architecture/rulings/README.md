# Semantic Rulings Registry

> 项目结构与语义的权威裁决记录。所有 PR 规划与执行必须遵守本目录中的裁决。
>
> 每条裁决是自包含文档，包含完整的决策、规则、理由与实施状态。

| 字段 | 值 |
|------|-----|
| 建立时间 | 2026-02-27 |
| 基线版本 | v0.2.5 (commit `372bf18`) |
| 历史来源 | `docs/reports/v0.2.5/frontend-review/08b-semantic-decisions.md`（冻结快照） |

---

## 裁决索引

| ID | 标题 | 状态 | 关联 v0.3 PR |
|----|------|------|-------------|
| [S1](S1-atom-projection.md) | Atom 投影语义 | Deferred — v0.3 | PR-0301, PR-0308 |
| [S2](S2-tab-draft-save-ownership.md) | Tab/Draft/Save 状态归属 | Phase 1 Landed — Phase 2/3 Deferred | PR-0301, PR-0303, PR-0304 |
| [S3](S3-tag-workspace-orthogonality.md) | Tag × Workspace Tree 正交性 | Deferred — v0.3 | PR-0304, PR-0307 |
| [S4](S4-creation-path-unification.md) | Note 创建入口统一 | Deferred — v0.3 | PR-0301 前置 |
| [S5](S5-extension-kernel-boundary.md) | Extension Kernel → Flutter 命令系统边界 | Landed — 语义定义 | PR-0310 |
| [S6](S6-provider-spi-interaction.md) | Provider SPI → external_mappings 交互 | Documented — v0.3 实现 | PR-0309 |
| [S7](S7-reminders-infrastructure.md) | Reminders 模块定位 | Landed — v0.2.5 PR-0259 | — |
| [S8](S8-noteitem-unification.md) | NoteItem → AtomListItem 类型统一 | Deferred — v0.3 | 新 PR |

## 状态定义

| 状态 | 含义 |
|------|------|
| **Landed** | 裁决已落地执行（代码变更或语义定义已生效） |
| **Documented** | 语义已定义，代码实现在后续版本 |
| **Deferred** | 裁决确认，执行推迟到指定版本 |

## 维护规则

1. **单一信息源**：每条裁决的权威内容仅存在于本目录对应文件中
2. **修订追踪**：任何裁决变更必须在文件内记录修订历史
3. **架构文档同步**：裁决变更后，必须同步更新引用该裁决的架构文档
4. **PR 合规**：所有 PR 设计必须检查本目录中相关裁决的约束
