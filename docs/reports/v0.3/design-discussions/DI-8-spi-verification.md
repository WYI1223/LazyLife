# DI-8: PR-0309 SPI 验证方式

| 项目 | 值 |
|------|-----|
| **状态** | **DEFERRED to v0.4** — PR-0309 整体延期，SPI trait 验证随之延期 |
| **关联决策点** | 无编号（§5.6 提出，对应风险 R6） |
| **影响 PR** | PR-0309 |
| **前置依赖** | 无（独立议题） |
| **来源** | 01-design-readiness-audit.md §5.6 |

---

## 问题提取

### 来源 §5.6 — PR-0309 SPI 验证缺失（R6）

> PR-0309 是 Provider SPI 的首个运行时实现。当前 SPI 是 declaration-only（`src/sync/` 中仅有 trait 定义和类型枚举）。
>
> spec 应要求在 PR-0309 **开始实现之前** 验证 SPI trait 的可实现性：
> - auth flow 是否完整？
> - pull/push 接口是否支持 Google Calendar 的 incremental sync？
> - conflict-map 抽象是否足够？
>
> 这可以通过一个 **mock provider 单元测试** 完成，验证 SPI trait 的接口完整性。建议作为 PR-0309 spec 的前置条件或首个 milestone。

### 来源 §3.5 — PR-0309 就绪度评估

> | PR | 方案确定性 | 接口定义 | 依赖清晰度 | 验证可测试性 | 就绪度 |
> |----|-----------|---------|-----------|------------|--------|
> | PR-0309 | ⚠️ SPI 首次实现 | ⚠️ SPI trait 可能需修改 | ✅ 依赖 0308 | ⚠️ R6 风险 | **有风险但可启动** |

### 风险 R6 说明（README）

R6 风险：Provider SPI trait 在首次运行时实现（PR-0309 Google Calendar）时可能发现设计缺陷，需要 trait 修改。

---

## 待讨论

1. SPI trait 验证应在什么时机执行？（spec 编写前 / PR-0309 M1 / 独立前置 PR）
2. 验证方式：mock provider 单测是否足够？还是需要真实 API 探测？
3. 如果 trait 需要修改，对 PR-0308 和 Phase 0 的影响范围？

---

## 关联

- 独立议题，与 DI-0 ~ DI-7 无直接依赖
- ← 01 审计报告 §5.6 + §3.5

---

*前序议题：[DI-7 Gate + 性能 + 测试](DI-7-gates-perf-testing.md)*
