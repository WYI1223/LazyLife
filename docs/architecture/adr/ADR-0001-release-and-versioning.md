# ADR-0001: Release And Versioning Strategy (Early Stage)

- Status: Accepted
- Date: 2026-02-12

## Context

LazyNote 当前处于架构初始化与 MVP 定义阶段。仓库虽为 Flutter + Rust 的多模块形态，但尚未进入高频、多包独立发布周期。  
现阶段目标是先稳定开发节奏、明确版本边界、降低流程复杂度。

## Decision

在当前阶段，采用以下方案：

- 提交规范：`Conventional Commits`
- 版本记录：手工维护 `CHANGELOG.md`
- 版本策略：`SemVer`，细则写入 `VERSIONING.md`
- 发布入口：`release.yml` 基于 Git tag（`vX.Y.Z`）触发

暂不引入 `.changeset/` 和 Changesets 自动汇总流程。

## Why

- 当前发布频率和协作规模不足以支撑 Changesets 的额外流程成本。
- `Conventional Commits + CHANGELOG` 已能覆盖 MVP 到 v1.0 的节奏管理。
- 可以先把 CI 稳定在“构建、测试、打包、发版”主链路，再引入自动化增量流程。

## CI/Release Flow (Current)

1. PR：执行 lint/test/build（Flutter + Rust）。
2. Merge to main：持续集成产物验证（可选 nightly artifacts）。
3. Release：创建 tag `vX.Y.Z`，同步更新 `CHANGELOG.md` 并触发 `release.yml`。

## Revisit Criteria

满足任一条件时，评估切换到 Changesets：

- 需要对多个包进行独立版本发布。
- 发布频率提升到手工维护 changelog 成本明显升高。
- 团队规模扩大，需更细粒度地在 PR 层管理变更片段与 release notes。

## Consequences

- 优点：流程简单、落地快、易于团队理解。
- 风险：随着规模增长，手工维护 changelog 的一致性成本会升高。
- 对策：按 `Revisit Criteria` 定期复盘，满足条件即切换到 Changesets。
