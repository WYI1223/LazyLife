# v0.2.5 Frontend Review Reports

## Input Templates

- `docs/development/report-templates/code-health-report-template.zh-CN.md`
- `docs/development/report-templates/module-split-blueprint-template.zh-CN.md`
- `docs/development/report-templates/phased-refactor-plan-template.zh-CN.md`

## Baseline Artifact Inputs

- root: `docs/reports/v0.2.5/architecture-baseline/artifacts/`
- status entry: `docs/reports/v0.2.5/architecture-baseline/artifacts/RUN_SUMMARY.md`
- frontend graph: `docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/lakos/lakos.svg`
- frontend size data:
  - `docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/size/snapshot.windows-x64.json`
  - `docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/size/trace.windows-x64.json`

## Outputs

1. `01-code-health-report.md` — 代码体检报告
2. `02-module-split-blueprint.md` — 模块拆分方案
3. `03-phased-refactor-plan.md` — 分阶段重构计划
4. `04-regression-checklist-v1.md` — 回归测试清单 v1
5. `05-refactor-retrospective.md` — PR-0252 重构复盘
6. `06-remaining-split-analysis.md` — 残余大模块分析
7. `07-wp-wpbridge-analysis.md` — WorkspaceProvider / WP Bridge 分析
8. `08-reassessment-and-replanning.md` — v0.2.5 重新审视与再规划（索引）
   - `08a-audit-findings.md` — 审计发现（事实基础）
   - `08b-semantic-decisions.md` — 语义裁决记录
   - `08c-solution-proposals.md` — 解决方案
   - `08d-pr-replanning.md` — PR 再规划
