# v0.3 Design Discussions Index

> 01-design-readiness-audit.md 的后续拆解讨论。每个文档聚焦一个独立议题，逐个确认设计决策。

---

## 讨论规则

1. **拆分不做结论**：每个文档从 01 审计报告提取问题和选项，保留原始上下文
2. **讨论产出结论**：结论在逐个讨论后填入，不预设
3. **状态跟踪**：每个文档头部标注 `OPEN` → `RESOLVED` → `APPLIED`
4. **结论可追溯**：结论须标明影响哪些 PR spec
5. **讨论顺序**：按依赖关系排序，前序议题的结论可被后续议题引用

---

## 议题清单

| 编号 | 文件 | 议题 | 关联决策点 | 状态 |
|------|------|------|-----------|------|
| DI-0 | [DI-0-dual-tab-manager.md](DI-0-dual-tab-manager.md) | NoteTabManager 命名冲突澄清 | D4 | RESOLVED |
| DI-1 | [DI-1-editor-shell-service.md](DI-1-editor-shell-service.md) | EditorShellService 接口 + 状态归属 | D1+D2+D3 | RESOLVED |
| DI-2 | [DI-2-layout-tree-structure.md](DI-2-layout-tree-structure.md) | 递归布局树节点结构 + 约束传播 | D5+D6 | RESOLVED |
| DI-3 | [DI-3-layout-persistence.md](DI-3-layout-persistence.md) | 布局持久化、迁移、深度限制 | D7+D8+D9 | RESOLVED |
| DI-4 | [DI-4-buffer-sync-model.md](DI-4-buffer-sync-model.md) | Buffer 同步模型 + 粒度 | D10+D11 | OPEN |
| DI-5 | [DI-5-cursor-and-conflict.md](DI-5-cursor-and-conflict.md) | 光标独立性 + 冲突处理 | D12+D13 | OPEN |
| DI-6 | [DI-6-cross-track-dependencies.md](DI-6-cross-track-dependencies.md) | 跨 Track 隐藏依赖 + 增量交付 | §5.3+§5.4 | OPEN |
| DI-7 | [DI-7-gates-perf-testing.md](DI-7-gates-perf-testing.md) | Phase 1 Gate + 性能基线 + 测试策略 | §5.1+§5.2+§5.5 | OPEN |
| DI-8 | [DI-8-spi-verification.md](DI-8-spi-verification.md) | PR-0309 SPI 验证方式 | §5.6 | OPEN |
| DI-9 | — | Entry Search 查询语义重设计 | S1 R3 | OPEN |
| DI-10 | [DI-10-editor-resolver-shell.md](DI-10-editor-resolver-shell.md) | EditorResolver 壳设计 | S2 Phase 3 | RESOLVED |

---

## 推荐讨论顺序

```
DI-0 (事实澄清，无依赖)                    ✓ RESOLVED
  ↓
DI-1 (EditorShellService，v0.3 核心接口)    ✓ RESOLVED
  ↓
DI-2 → DI-3 (布局树结构 → 布局持久化)       DI-2 ✓ DI-3 ✓ RESOLVED
  ↓
DI-4 → DI-5 (Buffer 同步 → 光标冲突)
  ↓
DI-6 → DI-7 (工程依赖 → 验收标准)
  ↓
DI-8 (SPI，独立)

独立分支（可与主链并行）：
DI-9  (Entry Search 查询语义，依赖 S1 R3)
DI-10 (EditorResolver 壳，依赖 DI-1)    ✓ RESOLVED
```

---

## 来源

- 审计报告：`docs/reports/v0.3/01-design-readiness-audit.md`
- Kickoff：`docs/releases/v0.3/v0.3-kickoff.md` §9
- Release Plan：`docs/releases/v0.3/README.md`
