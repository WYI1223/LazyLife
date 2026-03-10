# PR-GOV-00: Legacy Rulings 归档

> Historical prep material. Mainline execution was renumbered during `v0.4 kickoff`:
> `PR-GOV-00` corresponds to `PR-0400`, and execution artifacts belong under
> `docs/reports/v0.4/governance-execution/PR-0400/`.

| 项目 | 值 |
|------|-----|
| **状态** | PREP READY |
| **主题覆盖** | `T0` |
| **依赖** | 无 |
| **关联** | governance-rulings-migration-and-rebuild.md (planned, not yet created) |

---

## Purpose

把 `docs/architecture/rulings/` 中的全部现有文件整体归档为 `legacy normative snapshot`，
清空 canonical `rulings/` 作为 per-ADR workflow 重建的空集起点，消除后续所有治理阶段的
规范锚点歧义。

---

## Scope

### In Scope

1. 创建 `docs/architecture/rulings-legacy/` 目录
2. 移动 `docs/architecture/rulings/` 全部现有文件至 `rulings-legacy/`
3. 在 `docs/architecture/rulings/` 创建新 README：
   - 说明初始为空集
   - 说明只承载 per-ADR workflow 重建出的 current-effective 规则
   - 说明 legacy rulings 已归档至 `rulings-legacy/`
4. 所有对具体 ruling 文件的引用统一改指 `rulings-legacy/`
5. 创建 `docs/reports/v0.4/governance-execution/` 目录结构：
   - `v0.4/README.md`
   - `governance-execution/README.md`（执行总索引）
   - `PR-0400/` ~ `PR-0406/` 子目录骨架
6. 验证 Gate A 通过 + CI 通过（`architecture_check.dart` 无悬挂链接）

### Out of Scope

1. 创建任何新 ruling
2. 进入 source corpus 盘点或 DN extraction
3. 判断哪些 ruling 将被重建或重建优先级
4. 修改治理 workflow 文档

---

## Exit Gate

- [ ] `docs/architecture/rulings-legacy/` 包含全部原始 ruling 文件
- [ ] `docs/architecture/rulings/` 仅含新建 README
- [ ] 全部对具体 ruling 文件的引用已更新为指向 `rulings-legacy/`
- [ ] `docs/reports/v0.4/governance-execution/` 目录结构已创建（含 README 与 PR-GOV-00~06 子目录）
- [ ] `architecture_check.dart` 无悬挂链接
- [ ] `governance-rulings-migration-and-rebuild.md` Gate A（Archive Ready）条件满足：
  - 归档路径和命名规则已确定
  - legacy / rebuilt 的职责边界已写清
  - 历史 replay 不再消费 current rulings

---

## Reference

- governance-rulings-migration-and-rebuild.md（迁移原则，planned, not yet created）
- [DI-20-governance-execution-plan.md](../design-discussions/DI-20-governance-execution-plan.md)（T0 定义与 PR-GOV-00 gate）
