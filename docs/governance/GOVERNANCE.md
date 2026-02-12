# Governance

## Goal

本文件定义 LazyNote 在当前阶段（早期开源）的治理模型，确保决策清晰、责任明确、协作可持续。

## Governance Model

当前采用轻量治理（Minimum Viable Governance）：

- 先保证交付效率与工程质量。
- 重要决策可追踪（Issue/PR/ADR）。
- 随项目规模增长再升级治理复杂度。

## Roles

### Owner

- 对项目方向、发布策略、最终争议裁决负责。
- 管理仓库关键权限（分支保护、发布权限、维护者任命）。

### Maintainer

- 评审与合并 PR。
- 维护 CI、版本计划、文档一致性。
- 处理社区协作与行为问题。

### Contributor

- 提交 Issue、PR、文档改进。
- 遵守 `CONTRIBUTING.md` 与 `CODE_OF_CONDUCT.md`。

## Decision Process

### Small changes

普通修复、文档更新、小范围优化：

- 通过 PR 评审达成共识后合并。

### Medium/Large changes

涉及架构边界、跨模块影响、版本计划变更：

1. 先开 Issue 讨论方案。
2. 必要时补 ADR（`docs/architecture/adr/`）。
3. Maintainer 达成共识后执行；无法达成时由 Owner 决策。

## Merge And Review Policy

- 至少 1 位 Maintainer 审核通过后可合并。
- 需满足 CI 通过与文档同步要求。
- 禁止直接向受保护主分支提交（紧急修复除外）。

## Release Governance

- 版本计划由 `docs/releases/` 维护。
- 版本策略由 `VERSIONING.md` 定义。
- 版本变更由 `CHANGELOG.md` 记录。
- 发布动作由 Maintainer 执行，Owner 保留最终发布控制权。

## Conflict Resolution

- 先在 PR/Issue 中基于事实与数据讨论。
- 无法达成一致时，升级到 Maintainer 会议（异步即可）。
- 仍无结论时，Owner 作最终裁决。

## Security And Compliance Escalation

安全与合规问题优先级高于普通功能讨论：

- 可临时冻结相关 PR 或发布。
- Maintainer 可要求补充风险评估与修复计划。

## Evolution

本治理文件会按阶段迭代。出现以下情况时应升级治理机制：

- 维护者数量增加、协作规模扩大。
- 发布频率明显提高。
- 多平台/多模块并行开发导致决策冲突上升。
