# E1: Release and Versioning Strategy

| 字段 | 值 |
|------|-----|
| 状态 | **Landed** — 流程已生效 |
| 引入版本 | v0.1 (ADR-0001) |
| 废弃者 | — |
| 裁决日期 | 2026-02-12 |
| 迁移来源 | `docs/architecture/adr/ADR-0001-release-and-versioning.md`（已删除） |

---

## 决策

在当前阶段（pre-v1.0），采用以下发布策略：

- **提交规范**：Conventional Commits（`feat:`, `fix:`, `docs:`, `chore:`, etc.）
- **版本记录**：手工维护 `CHANGELOG.md`
- **版本策略**：SemVer，细则写入 `VERSIONING.md`
- **发布入口**：`release.yml` 基于 Git tag（`vX.Y.Z`）触发

暂不引入 `.changeset/` 和 Changesets 自动汇总流程。

---

## 规则

1. **Conventional Commits 强制**：所有 commit message 必须符合 Conventional Commits 规范
2. **手工 CHANGELOG**：每个版本发布前手工更新 `CHANGELOG.md`，按 feature/fix/breaking 分类
3. **SemVer 合规**：版本号遵循 `VERSIONING.md` 中定义的 SemVer 策略
4. **Tag 触发发布**：创建 `vX.Y.Z` tag 触发 `release.yml` CI 流程

---

## CI/Release Flow

1. **PR**：执行 lint/test/build（Flutter + Rust）
2. **Merge to main**：持续集成产物验证
3. **Release**：创建 tag `vX.Y.Z`，同步更新 `CHANGELOG.md` 并触发 `release.yml`

---

## 升级条件

满足任一条件时，评估切换到 Changesets：

- 需要对多个包进行独立版本发布
- 发布频率提升到手工维护 changelog 成本明显升高
- 团队规模扩大，需更细粒度地在 PR 层管理变更片段与 release notes

---

## 修订历史

| 日期 | 变更 |
|------|------|
| 2026-02-12 | 初始版本（ADR-0001） |
| 2026-03-01 | 迁移至 Ruling 体系（E1），ADR 目录废弃 |
