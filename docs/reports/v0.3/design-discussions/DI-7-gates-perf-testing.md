# DI-7: Phase 1 Gate + 性能基线 + 测试策略

| 项目 | 值 |
|------|-----|
| **状态** | OPEN |
| **关联决策点** | 无编号（§5.1 + §5.2 + §5.5 提出的工程问题） |
| **影响 PR** | Phase 1 Gate、PR-0305、所有 v0.3 PR 的测试 |
| **前置依赖** | DI-1/DI-2/DI-4 的结论（Gate 精确化依赖设计决策） |
| **来源** | 01-design-readiness-audit.md §5.1 + §5.2 + §5.5 |

---

## 问题提取

### 来源 §5.1 — Phase 1 Gate 验证标准不够精确

> 当前 Phase 1 Gate 包含模糊条件：
>
> | 当前表述 | 问题 | 建议精确化 |
> |---------|------|-----------|
> | "Same-note multi-pane editing content-coherent" | "content-coherent" 不是可自动化验证的条件 | 定义具体测试场景：在 pane A 编辑 → pane B 在 N ms 内反映变更 |
> | "Recursive split stable" | "stable" 含义不明确 | 定义：N 次 split/close 循环后状态一致，无内存泄漏 |
> | "Preview/pinned tab deterministic" | "deterministic" 需操作序列定义 | 定义：给定操作序列 → 预期 tab 状态映射表 |

### 来源 §5.2 — 性能目标未量化

> PR-0305 的 "≥ 60 FPS" 目标缺少：
>
> | 缺失维度 | 需要定义 |
> |---------|---------|
> | 数据集 | 多长的 Markdown？（1K 行？10K 行？100K 行？） |
> | 窗格数 | 1 pane？2 pane 同笔记？4 pane？ |
> | 硬件基线 | 哪种 CPU/GPU？最低配置？ |
> | 测量方法 | Flutter DevTools Timeline？profile mode 自动化？ |
> | 基线对比 | 与 v0.2 相比改善还是不退化？ |

### 来源 §5.5 — 测试策略缺失

> v0.3 引入多个全新交互模型（多窗格编辑、drag-to-split、buffer 同步、递归布局树），但当前规划中 **没有任何地方定义测试方法论**。
>
> 需要回答的问题：
>
> | 新能力 | 测试问题 | 现有测试能力 |
> |--------|---------|------------|
> | 多窗格编辑 | Widget test 能模拟多 pane 场景吗？需要自定义 test harness？ | 当前 widget test 均为单 pane |
> | Drag-to-split | 如何模拟 drag gesture 在 layout tree 上的交互？ | Flutter `WidgetTester` 支持 `drag()`，但 overlay 交互可能需要额外 setup |
> | Buffer 同步 | 同步一致性如何在测试中验证？需要时序控制？ | 无现有参考 |
> | 递归布局树 | 树操作（split/close/resize）的状态正确性如何验证？ | 当前布局测试基于扁平模型 |
> | EditorShellService | Service 提取后，现有 333 个测试是否需要迁移？ | 现有测试直接 mock coordinator |
>
> **建议**：每个 DI 的输出中应包含 "验证方法" 节，定义该设计的可测试性方案。PR-0301B spec 特别需要定义：提取后现有测试的迁移策略。

---

## 待讨论

1. Phase 1 Gate 的三个模糊条件如何精确化为可自动化验证的标准？
2. PR-0305 性能基准的各维度定义
3. v0.3 新能力的测试方法论 — 是否需要新的 test harness？
4. 现有 333 个测试在 EditorShellService 提取后的迁移策略

---

## 关联

- ← DI-1/DI-2/DI-4（设计决策影响 Gate 和测试方式）
- ← DI-6（Phase 1 是整体交付门禁）
- ← 01 审计报告 §5.1 + §5.2 + §5.5

---

*前序议题：[DI-6 跨 Track 依赖](DI-6-cross-track-dependencies.md)*
*下一个议题：[DI-8 SPI 验证](DI-8-spi-verification.md)*
