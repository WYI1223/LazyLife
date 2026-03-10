# v0.4 设计讨论（Design Discussions）索引

| 项目 | 值 |
|------|-----|
| **版本** | v0.4 |
| **日期** | 2026-03-10 |

---

## 说明

v0.4 的设计问题采用了与 v0.3 不同的处理方式。v0.3 为每个重要设计议题单独创建了 DI 文档（DI-0 至 DI-21），而 **v0.4 的全部设计问题集中在 kickoff Q&A 会话中完成裁决**，不单独产出 DI 文档。

规范性来源（canonical design input）：

- **`docs/releases/v0.4/20QA.MD`** — v0.4 kickoff 的 20 个设计问题及完整 Q&A 裁决，是 v0.4 PR-0414~PR-0416 设计层面的权威依据。
- **`docs/reports/v0.4/design-readiness-audit.md`** — 基于 20QA.MD 形成的设计就绪审计，汇总各 PR 的设计状态与裁决摘要。

因此，本目录（`design-discussions/`）在 v0.4 中不包含独立的 DI 文档。

---

## v0.3 DI 文档作为 v0.4 执行输入

v0.3 中编写的以下 DI 文档对 v0.4 workspace 执行组（PR-0407~PR-0413）具有直接约束力，是这些 PR 的 canonical design input：

| DI 文档 | 路径 | 对应 v0.4 PR |
|---------|------|-------------|
| DI-15：Rust 数据模型单根化 | `docs/reports/v0.3/design-discussions/DI-15-rust-data-model-single-root.md` | PR-0408、PR-0409 |
| DI-16：Rust Service + FFI 契约 | `docs/reports/v0.3/design-discussions/DI-16-rust-service-ffi-contract.md` | PR-0409、PR-0410、PR-0411 |
| DI-17：Flutter 瘦客户端收敛 | `docs/reports/v0.3/design-discussions/DI-17-flutter-thin-client.md` | PR-0412、PR-0413 |
| DI-18：执行计划 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` | PR-0407~PR-0413（所有 workspace 执行 PR） |
| DI-19：ADR 治理体系设计 | `docs/reports/v0.3/design-discussions/DI-19-adr-governance.md` | PR-0400~PR-0406（治理执行 PR） |
| DI-20：治理执行计划 | `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md` | PR-0400~PR-0406（治理执行 PR） |
| DI-21：CI 重复检测 | `docs/reports/v0.3/design-discussions/DI-21-ci-duplication-detection.md` | PR-0407 |

---

## 相关文档导航

| 文档 | 路径 | 说明 |
|------|------|------|
| v0.4 kickoff Q&A | `docs/releases/v0.4/20QA.MD` | 20 个设计问题裁决原文 |
| 设计就绪审计 | `docs/reports/v0.4/design-readiness-audit.md` | 各 PR 设计就绪状态与裁决摘要 |
| PR Spec Rebaseline | `docs/releases/v0.4/v0.4-pr-spec-rebaseline.md` | 原始 PR 编号到新编号的映射 |
| v0.4 PR Spec（原始） | `docs/releases/v0.4/v0.4-pr-spec-2026-03-01.md` | 原始 v0.4 规划文档 |
| v0.4 README | `docs/releases/v0.4/README.md` | v0.4 发布计划概览 |
