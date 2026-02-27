# 08d — PR 再规划

> 替代/扩展原 PR-0251 和 PR-0253 的新执行计划。
> 本文为 [08-reassessment-and-replanning.md](08-reassessment-and-replanning.md) 的第四部分。
> 具体任务分解待 08b 语义裁决完成后细化。

| 字段 | 值 |
|------|-----|
| 日期 | 2026-02-26 |
| 前提 | [08b-semantic-decisions.md](08b-semantic-decisions.md) + [08c-solution-proposals.md](08c-solution-proposals.md) |
| 状态 | **草稿 — 待裁决后细化** |

---

## 4.1 原 PR 状态与处置

| 原 PR | 原定范围 | 处置建议 |
|-------|---------|---------|
| PR-0251（语义冻结） | 5 个语义歧义区域的冻结 + v0.3 依赖措辞更新 | **扩展并重新定义** — 原范围不足以覆盖 S1–S8 全部议题。合并语义裁决（S1–S8）+ 文档同步（3.3）为新的 PR scope |
| PR-0253（收尾交接） | 6 维闭合检查 + 全质量门禁回放 + v0.3 交接 | **保留但后置** — 在所有结构性解耦和语义裁决完成后执行 |

---

## 4.2 建议的新 PR 结构

> `[草案]` — 待语义裁决完成后确定最终拆分。

| PR | 名称 | 范围 | 依赖 | 预估规模 |
|----|------|------|------|---------|
| **PR-0256** | 语义裁决与文档对齐 | S1–S8 语义裁决文档化 + 3.3 文档同步全部项 + CLAUDE.md 对齐 | 本文档讨论完成 | 纯文档 PR |
| **PR-0257** | notes↔workspace 结构性解耦 | 3.1.1（WP bridge 删除 + UI 消费者迁移 + shared types 提取）+ 3.1.3（coordinator 瘦身） | PR-0256（S2 裁决） | 代码 PR，高风险 |
| **PR-0258** | Rule E 违规消减与 CI 防线 | 3.1.2（notes↔tags 循环打破）+ 3.1.4（低优先级解耦）+ 3.2（CI rule_e_check）+ S7 执行 | PR-0257 | 代码 + CI PR |
| **PR-0253** | v0.2.5 收尾与 v0.3 交接 | 原定 6 维闭合 + 全质量门禁回放 + v0.3 交接文档 + CHANGELOG 补齐 | PR-0256, PR-0257, PR-0258 | 文档 + 验证 PR |

---

## 4.3 执行顺序

```
本文档讨论（语义裁决） ─► PR-0256（文档化裁决）
                           │
                           ▼
                      PR-0257（结构解耦）
                           │
                           ▼
                      PR-0258（Rule E + CI）
                           │
                           ▼
                      PR-0253（收尾交接）
                           │
                           ▼
                      v0.2.5 正式关闭 → v0.3 启动
```

---

## 4.4 v0.3 就绪度检查清单

v0.2.5 关闭前需满足的 v0.3 就绪条件：

- [ ] S1–S8 全部裁决完成且文档化
- [ ] notes→workspace import 降至 0
- [ ] notes↔tags 循环依赖消除
- [ ] Coordinator impl <1,500 行
- [ ] WP bridge 删除，状态源唯一化
- [ ] CI rule_e_check 上线
- [ ] Rule E 违规降至 ≤4（仅保留已豁免项）
- [ ] `architecture/overview.md` 更新至 v0.2.5
- [ ] `ffi-contracts.md` 按域重组
- [ ] CLAUDE.md 与 ffi-contracts.md 对齐
- [ ] 测试基线 333 pass / 0 fail 保持
- [ ] 全质量门禁回放通过
