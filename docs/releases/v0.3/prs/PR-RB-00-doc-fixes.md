# PR-RB-00: 文档前置修复与基础设施

- Proposed title: `docs(v0.3): PR-RB-00 doc fixes, orphan cleanup, docs linter, ruling lifecycle headers`
- Status: Merged

## Goal

v0.3 执行前的文档治理 PR。五项职责：

1. **路径与状态修复**：修复 CLAUDE.md / overview.md 中因 v0.2.5 后期 PR 遗留的过时描述
2. **文档基础设施**：给 Rulings 加标准化生命周期 header；扩展 `architecture_check.dart` 增加 docs 交叉引用检查（Check 4）
3. **产品与导航文档刷新**：`index.md`、`milestones.md`、`product/roadmap.md` 对齐到 v0.3 rebaseline 后的真实状态
4. **孤儿文件清理**：归档或删除 v0.1/v0.2 时代遗留在 docs 根目录的过期文件
5. **流程模板**：创建版本生命周期模板 + PR Spec 模板，固化 v0.3 kickoff 中验证有效的流程

前置条件：`v0.3-pre-execution-git-hygiene.md` 已执行（.docx + artifacts 历史清洗 + .gitignore 修复）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| Acceptance Report | `docs/reports/v0.2.5/frontend-review/09-acceptance-report.md` §7.4 | 列出 3 项前置文档修复 |
| Acceptance Report | 同上 §5.1 | 完整过时引用清单（5 项） |
| Rebaseline | `docs/releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md` §4 PR-RB-00 | 定义原始 scope |
| Spec Review | `docs/reports/v0.3/pr-spec-review-resolution.md` | R1/R2 review 中发现的文件名引用问题（Issue 3/4/5）证实了 docs linter 的必要性 |

## Scope

In scope:

- §7.4 未修复项 + §5.1 范围内的 CLAUDE.md / overview.md 过时描述（Lane A）
- Ruling 生命周期 header 标准化（Lane B）
- Docs 交叉引用 linter — `architecture_check.dart` Check 4（Lane B）
- `index.md`、`milestones.md`、`product/roadmap.md` 刷新（Lane C）
- 根目录孤儿文件归档/删除（Lane D）
- 版本生命周期模板 + PR Spec 模板（Lane E）

Out of scope:

- `data-model.md` S1 R1-R4 字段补充（属 PR-RB-02 前置）
- overview.md 中 v0.3 前瞻性描述（L104 "v0.3: tab/draft/save..."）——正确的规划标注，不是过时描述
- Gate 验证脚本提取（属 PR-RB-11 scope）
- mdBook / Sphinx 等文档构建工具

---

## Lane A: 路径与状态修复

### §7.4 原始清单 vs 当前状态

| §7.4 项目 | 当前状态 | PR-RB-00 动作 |
|-----------|---------|---------------|
| CLAUDE.md `features/reminders/` → `core/reminders/` | **已修复** | 无需操作 |
| CLAUDE.md `features/tags/` → `shared/` | **未修复**（L99 仍为 `lib/features/tags/`） | T1 |
| overview.md L77 移除 "currently `features/reminders/`" | **已修复** | 无需操作 |
| overview.md L138 PR-0258 改为已完成时态 | **已修复** | 无需操作 |

### §7.4 之外发现的过时项

| 发现 | 文件:行 | 问题 | 动作 |
|------|---------|------|------|
| 版本状态过时 | `CLAUDE.md:13` | "Post-v0.2 baseline"，应为 Post-v0.2.5 | T2 |
| 双状态描述未过去时 | `CLAUDE.md:370` | "is targeted for elimination in PR-0258"，已完成 | T3 |
| Rulings 计数过时 | `CLAUDE.md:429` | "S1-S8"，S9 已存在 | T4 |
| Tags 路径过时 | `overview.md:105` | `lib/features/tags/`，已迁移至 `lib/shared/` | T5 |

---

## Lane B: 文档基础设施

### B1: Ruling 生命周期 Header 标准化

当前 9 个 Ruling 文件已有 `状态` 字段，但存在以下问题：

1. **状态词汇不统一**：Deferred / Landed / Documented / Phase 1 Landed —— 无标准化生命周期
2. **缺少引入版本**：无法追溯何时创建
3. **缺少废弃指针**：未来 Ruling 被覆盖时无法标记

**标准化方案**：每个 Ruling 文件的 header 表统一为：

```markdown
| 字段 | 值 |
|------|-----|
| 状态 | **Accepted** — v0.3 PR-RB-XX 实现 |
| 引入版本 | v0.2.5 (PR-0256) |
| 废弃者 | — |
```

**状态词汇表**（标准化）：

| 状态值 | 含义 |
|--------|------|
| **Proposed** | 提议中，未裁决 |
| **Accepted** | 已裁决，待实现或已实现 |
| **Landed** | 已裁决且已实现（代码已合入） |
| **Deprecated** | 已废弃，由其他 ruling 取代 |

当前 Ruling 的状态映射：

| Ruling | 当前状态文本 | 标准化后 |
|--------|------------|---------|
| S1 | Deferred — v0.3 实现 | Accepted — v0.3 PR-RB-02/03 实现 |
| S2 | Phase 1 Landed — Phase 2/3 Deferred | Accepted — Phase 1 Landed (PR-0258), Phase 2/3 v0.3 PR-RB-06 |
| S3 | Deferred — v0.3 实现 | Accepted — v0.3 PR-RB-10 实现 |
| S4 | Deferred — v0.3 实现 | Accepted — v0.3 PR-RB-03 实现 |
| S5 | Landed — 语义定义 | Landed — 语义定义，无代码变更 (PR-0256) |
| S6 | Documented — v0.3 实现 | Accepted — v0.3 scope (Google Calendar) |
| S7 | Landed — PR-0259 已执行 | Landed — PR-0259 模块迁移 |
| S8 | Deferred — v0.3 实现 | Accepted — v0.3 PR-RB-01 实现 |
| S9 | Deferred — v0.3 实施 | Accepted — v0.3 PR-RB-05 实现 |

### B2: ADR 废弃，职责并入 Ruling 体系

**现状**：`docs/architecture/adr/` 仅含 ADR-0001（release/versioning），内容停留在 v0.1 时代。所有真实架构决策都记录在 Rulings (S1-S9) 和 DIs 中。ADR 系统名存实亡。

**变更**：

1. **Ruling 体系扩展**：新增 E 系列（Engineering）管理工程/基础设施决策，与现有 S 系列（Semantic）并列
   - `E1-release-and-versioning.md` — 从 ADR-0001 迁移并更新到当前状态
   - 未来 Rule A-F 变更、CI 策略变更等记录为 E 系列

2. **删除 `docs/architecture/adr/` 目录**

3. **全仓库 ADR 引用替换**（12 处，7 个文件）：

| 文件 | 行 | 当前 | 改为 |
|------|----|------|------|
| `CLAUDE.md` | 157 | "requires an ADR filed in `docs/architecture/adr/`" | "requires a Ruling filed in `docs/architecture/rulings/`" |
| `CLAUDE.md` | 163 | "may hard-delete with an ADR" | "may hard-delete with a Ruling" |
| `CLAUDE.md` | 447 | "with an ADR" | "with a Ruling" |
| `AGENTS.md` | 163 | "requires an ADR in `docs/architecture/adr/`" | "requires a Ruling in `docs/architecture/rulings/`" |
| `engineering-standards.md` | 23 | "需有 ADR 记录原因" | "需有 Ruling 记录原因" |
| `engineering-standards.md` | 96 | "关联一个 ADR 或 Issue" | "关联一个 Ruling 或 Issue" |
| `data-model.md` | 319 | "requires an ADR" | "requires a Ruling" |
| `GOVERNANCE.md` | 12 | "Issue/PR/ADR" | "Issue/PR/Ruling" |
| `GOVERNANCE.md` | 46 | "必要时补 ADR" | "必要时补 Ruling" |
| `CONTRIBUTING.md` | 11 | "同步更新 `docs/architecture/adr/`" | "同步更新 `docs/architecture/rulings/`" |
| `S1-atom-projection.md` | 60 | "通过 ruling 或 ADR 注册" | "通过 Ruling 注册" |
| `research/todo_*.md` | 36 | "architecture decisions (ADR)" | "architecture decisions (Ruling)" |

**不改的文件**（历史记录，保留原文）：
- `docs/product/vision.md` — 项目 vision 文档中的目录树引用，属于历史快照
- `docs/releases/v0.1/prs/PR-0014-*` / `v0.3/prs/PR-0308-*` — 旧 PR spec，历史记录

4. **Ruling README 更新**：增加 E 系列说明和索引

### B3: Docs 交叉引用 Linter（Check 4）

扩展 `tools/ci/architecture_check.dart`，新增 Check 4：

**检查范围**：`docs/**/*.md` 中的 markdown 链接 `[text](path)`

**检查逻辑**：
1. 递归扫描 `docs/` 下所有 `.md` 文件
2. 提取所有 markdown 链接：`\[([^\]]*)\]\(([^)#]+)` （忽略锚点部分）
3. 过滤：跳过 `http://`、`https://`、`mailto:` 外部链接
4. 对每个相对路径，基于当前文件所在目录解析为绝对路径
5. 检查目标文件是否存在于文件树中
6. 报告所有断链为 violation

**配置**：
- `docs_link_allowlist.yaml`（初始条目：`docs/reports/**/artifacts/` 路径——git hygiene 清洗后 artifacts 不再被追踪，但 baseline report .md 中仍引用这些路径）
- 对 `releases/` 下的 PR spec 中引用的 `apps/` 或 `lib/` 代码路径，只做 warning 不做 failure（代码文件可能尚未创建）

**集成**：复用现有 CI 步骤 `dart run ../../tools/ci/architecture_check.dart`，无需额外配置。

**预期代码量**：~100-120 行 Dart，新增到 `architecture_check.dart`。

---

## Lane C: 产品与导航文档刷新

### C1: `docs/index.md`

当前问题：
- "Start Here" 指向 `v0.2.5/README.md` 作为 "current baseline"，应更新为 v0.3
- Architecture 部分缺少 `modules/README.md` 链接
- 缺少 reports 和 design discussions 的入口
- Product 部分仍指向 `v0.2/README.md`

更新内容：
- "Start Here" 指向 `v0.3/README.md` 作为 current release
- Architecture 增加 modules、rulings（已有）链接
- 新增 Reports 部分（v0.2.5 baseline + frontend review + v0.3 DI）
- Product 部分指向 `v0.3/README.md`

### C2: `docs/product/milestones.md`

当前问题：M3.5 仍标 "Planned"，M5 仍标 "Planned"，不知道 v0.2.5 的存在。

更新内容：
- M3.5 → Completed
- M4 → 说明已分散到 v0.2/v0.3
- M5 → Completed (v0.2)
- 新增 M5.5 (v0.2.5) → Completed
- M6 → In Progress (v0.3)，更新 PR 编号为 PR-RB-XX

### C3: `docs/product/roadmap.md`

当前问题：v0.3 scope 描述仍用旧 PR-030X 编号，未反映 rebaseline。

更新内容：
- v0.2.5 条目：状态更新为 completed
- v0.3 条目：更新 scope 描述 + PR 编号改为 PR-RB-00~11 + 引用 rebaseline 文档
- 清理 "Deferred from v0.1" 部分（大部分已在 v0.2/v0.3 完成）

---

## Lane D: 孤儿文件清理

| 文件 | 问题 | 动作 |
|------|------|------|
| `docs/roadmap.md` | 停在 v0.1.5 时代，与 `docs/product/roadmap.md` 完全重复 | **删除** |
| `docs/FunctionImplementSynReport.md` | v0.2 时代功能同步报告，提到的缺口早已修复 | **移入** `docs/reports/v0.2/` |
| `docs/review-01-architecture.md` | 2026-02-14 审查报告，引用旧 NotesController | **移入** `docs/reports/v0.2.5/` |
| `docs/review-02-engineering.md` | 2026-02-14 审查报告，引用旧 NotesController | **移入** `docs/reports/v0.2.5/` |
| `docs/api/ffi-contract-v0.1.md` | v0.1 时代 FFI 合同，已被 `ffi-contracts.md` 取代 | **保留但在 API README 中标注为 historical** |
| `docs/product/mvp-scope.md` | 纯 v0.1 历史文档 | **保留**（有追溯价值，无歧义风险） |
| `docs/development/windows.md` | 内容稀疏，与 `windows-quickstart.md` 重复 | **合并内容到 quickstart，删除** |
| `docs/init/`（5 个 .docx） | 项目创世纪文档，14 MB 二进制 | **已由 pre-execution git hygiene 从历史中清除**，`.gitignore` 隔离 |
| `docs/development/windows-pr0007-search-smoke.md` | PR-0007 专属冒烟测试，v0.1 产物，已被通用 CI 覆盖 | **删除** |
| `docs/product/idea_temp/` | DI 讨论产出的未来版本设计 idea，`temp` 命名暗示临时性 | **重命名**为 `docs/product/ideas/` |
| `docs/api/workspace-tree-contract.md` | v0.2 时代 workspace tree FFI 合同，已被 `ffi-contracts.md` 覆盖 | **保留但在 API README 中标注为 historical**（与 T19 合并） |

---

## Lane E: 流程模板

### E1: 版本生命周期模板

文件：`docs/development/release-lifecycle-template.md`（~120 行）

基于 v0.3 kickoff 实战经验，固化三阶段流程 + 交付物清单 + 质量关卡。

**阶段结构**：

```
Phase 1: Kickoff
├── 1.1 Kickoff Audit — 旧版本 PR spec vs 当前代码库对账
├── 1.2 Design Readiness Audit — 设计缺口识别
├── 1.3 Design Discussions (DI) — 设计问题裁决
│   ├── DI 拆分标准：一个 DI 只解决一个设计问题
│   ├── DI 依赖声明：每个 DI 标明前置/后置 DI
│   └── Cross-DI consistency checkpoint：每批裁决后交叉验证
├── 1.4 Rulings / Modules 回填 — 新裁决产出后扫描已有 spec
├── 1.5 PR Spec Rebaseline — 旧 spec 重写（如有）
├── 1.6 PR Spec Writing
└── 1.7 Spec Review (R1/R2) — 交叉审查 + 修复

Phase 2: Execution
├── 2.1 分支策略：trunk-based，短命分支 squash merge
├── 2.2 PR-00 Doc fixes + infra（每版本首个 PR）
├── 2.3 PRs 按依赖序执行，每个合入后 CI green
└── 2.4 中期检查点（可选，>6 PR 时建议设置）

Phase 3: Closure
├── 3.1 Dead code cleanup
├── 3.2 Regression test gap fill
├── 3.3 Doc sync（CLAUDE.md / overview / data-model / ffi-contracts / rulings）
├── 3.4 Gate verification（scripted, SSOT）
├── 3.5 Release evidence collection
├── 3.6 Coverage matrix sign-off
└── 3.7 Lifecycle template retrospective — 回填实战经验
```

**关键流程协议**：

| 协议 | 内容 |
|------|------|
| **DI 拆分标准** | 一个 DI 解决一个设计问题，产出一个裁决。如果 DI 讨论中发现第二个独立问题，拆出新 DI |
| **Cross-DI 一致性检查** | 每完成一批 DI（≥3 个）后，对这批 DI 的裁决做依赖矩阵交叉验证：检查是否有隐含冲突 |
| **Ruling/Module 回填** | 新 ruling 产出后，扫描所有已写 PR spec 的 Execution Contract 表和 Verification 命令，更新引用 |
| **Spec Review 轮次** | R1 全量审查 → 修复 → R2 增量审查（只看 R1 修复是否引入新问题）→ 签核 |

**交付物清单**（每版本必须产出）：

```
docs/releases/vN.M/
├── README.md                              — 版本概述
├── vN.M-kickoff.md                        — Kickoff 审计
├── vN.M-pr-spec-rebaseline-DATE.md        — Rebaseline（如有旧 spec）
├── prs/PR-RB-XX-*.md                      — PR Specs
├── vN.M-release-evidence.md               — Release 证据
docs/reports/vN.M/
├── NN-design-readiness-audit.md           — 设计就绪审计
├── design-discussions/DI-*.md             — DI 系列
├── design-discussions/README.md           — DI 索引
└── pr-spec-review-resolution.md           — Spec Review 报告
```

### E2: PR Spec 模板

文件：`docs/development/pr-spec-template.md`（~80 行）

固化 PR-RB-00~11 中自然收敛的统一结构。

**模板结构**：

```markdown
# PR-RB-XX: 标题

- Proposed title: `type(scope): description`
- Status: Draft | In Progress | Merged

## Goal
[1-2 句话说明这个 PR 要解决什么问题]

前置条件：[列出依赖的前序 PR]

## Execution Contract (Canonical Inputs)
| 类型 | 引用 | 与本 PR 的关系 |
[必须引用实际文件名，不允许语义别名]

## Scope
In scope: [明确列出]
Out of scope: [明确列出，解释为什么不在本 PR]

## 设计方案
[技术设计，代码示例，开放决策表]

## Task Breakdown
| Task | 内容 | 文件 | 估算 | 依赖 |
[每个 Task 对应一个可独立验证的变更单元]

## Planned File Changes
- `[add]` / `[edit]` / `[delete]` / `[move]` 每个文件

## Verification
### CI gates — 必须可执行
### Structural verification — grep/test 命令，期望值明确

## Risk
| 风险 | 严重度 | 缓解 |

## Acceptance Criteria
- [ ] 每条可 binary 判定（是/否），不含模糊表述
```

**填写规则**：

1. **Execution Contract 文件名必须与仓库实际文件名完全匹配**——不允许使用语义别名（v0.3 Spec Review Issue 4 教训）
2. **Verification 命令必须可执行**——粘贴到终端直接跑，不需要人工解释
3. **Acceptance Criteria 必须 binary**——每条只能判定"通过"或"未通过"，不含"基本完成""大致符合"等模糊表述
4. **Planned File Changes 路径必须具体到文件**——不允许 "相关文件" 等模糊描述
5. **Task Breakdown 中每个 Task 对应一个 git commit 粒度**——可以合并但不能再拆

---

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| **Lane A: 路径与状态修复** | | | | | |
| T1 | A | `features/tags/` → `shared/`：TagFilter + ui_tokens | `CLAUDE.md:99` | 改 1 行 | — |
| T2 | A | "Post-v0.2 baseline" → "Post-v0.2.5 baseline" | `CLAUDE.md:13` | 改 1 行 | — |
| T3 | A | 双状态描述改为已完成时态 | `CLAUDE.md:370` | 改 1 行 | — |
| T4 | A | "S1-S8" → "S1-S9" | `CLAUDE.md:429` | 改 1 行 | — |
| T5 | A | `features/tags/` → `shared/` | `overview.md:105` | 改 1 行 | — |
| **Lane B: 文档基础设施** | | | | | |
| T6 | B | 标准化 9 个 Ruling 文件的 header（状态词汇 + 引入版本 + 废弃者） | `docs/architecture/rulings/S*.md` | 编辑 9 文件 × ~3 行 | — |
| T7 | B | ADR→Ruling 迁移：创建 `E1-release-and-versioning.md`（从 ADR-0001 迁移+更新） | `docs/architecture/rulings/E1-release-and-versioning.md` | 新文件 ~50 行 | — |
| T8 | B | ADR 引用替换：12 处 ADR→Ruling（CLAUDE.md/AGENTS.md/engineering-standards/data-model/GOVERNANCE/CONTRIBUTING/S1/research） | 7 个文件 | 每处改 1 行 | — |
| T9 | B | 更新 Ruling README：增加 E 系列说明 + E1 索引 | `docs/architecture/rulings/README.md` | 编辑 ~+10 行 | T7 |
| T10 | B | `architecture_check.dart` 新增 Check 4：docs 交叉引用完整性检查 | `tools/ci/architecture_check.dart` | ~+120 行 | — |
| T11 | B | 创建 `tools/ci/docs_link_allowlist.yaml`（含 artifacts/ 路径豁免） | 新文件 | ~10 行 | T10 |
| **Lane C: 产品与导航文档刷新** | | | | | |
| T12 | C | 更新 `docs/index.md`：v0.3 入口 + modules/reports 链接 | `docs/index.md` | 编辑 ~+15 行 ~-5 行 | — |
| T13 | C | 更新 `docs/product/milestones.md`：M3.5~M6 状态 + v0.2.5 补充 | `docs/product/milestones.md` | 编辑 ~+10 行 | — |
| T14 | C | 更新 `docs/product/roadmap.md`：v0.3 rebaseline 编号 + scope | `docs/product/roadmap.md` | 编辑 ~+10 行 ~-5 行 | — |
| **Lane D: 孤儿文件清理** | | | | | |
| T15 | D | 删除 `docs/roadmap.md`（重复） | 删除 1 文件 | — | — |
| T16 | D | 移动 `docs/FunctionImplementSynReport.md` → `docs/reports/v0.2/` | 移动 1 文件 | — | — |
| T17 | D | 移动 `docs/review-01-architecture.md` + `review-02-engineering.md` → `docs/reports/v0.2.5/` | 移动 2 文件 | — | — |
| T18 | D | 合并 `docs/development/windows.md` 内容到 `windows-quickstart.md`，删除原文件 | 编辑 1 + 删除 1 | — | — |
| T19 | D | 更新 `docs/api/README.md`：`ffi-contract-v0.1.md` + `workspace-tree-contract.md` 标注 historical | `docs/api/README.md` | 编辑 ~2 行 | — |
| T20 | D | 删除 `docs/architecture/adr/` 目录（ADR-0001 已迁移为 E1 ruling） | 删除目录 | — | T7 |
| T23 | D | 删除 `docs/development/windows-pr0007-search-smoke.md` | 删除 1 文件 | — | — |
| T24 | D | 重命名 `docs/product/idea_temp/` → `docs/product/ideas/` | 重命名目录 | — | — |
| **Lane E: 流程模板** | | | | | |
| T21 | E | 创建版本生命周期模板（三阶段 + 交付物 + DI/ruling 协议） | `docs/development/release-lifecycle-template.md` | 新文件 ~120 行 | — |
| T22 | E | 创建 PR Spec 模板（结构 + 填写规则） | `docs/development/pr-spec-template.md` | 新文件 ~80 行 | — |

Lane A~E 之间无依赖，可任意交叉执行。Lane 内部：T9 依赖 T7，T11 依赖 T10，T20 依赖 T7。T23~T24 无内部依赖。

## Planned File Changes

**Lane A（路径修复）：**
- `[edit]` `CLAUDE.md`（4 处单行修改）
- `[edit]` `docs/architecture/overview.md`（1 处单行修改）

**Lane B（文档基础设施）：**
- `[edit]` `docs/architecture/rulings/S1-atom-projection.md` ~ `S9-cross-feature-infrastructure-placement.md`（9 文件 header 标准化）
- `[add]` `docs/architecture/rulings/E1-release-and-versioning.md`（从 ADR-0001 迁移 ~50 行）
- `[edit]` `docs/architecture/rulings/README.md`（+E 系列说明）
- `[edit]` `CLAUDE.md`、`AGENTS.md`、`engineering-standards.md`、`data-model.md`、`GOVERNANCE.md`、`CONTRIBUTING.md`、`S1-atom-projection.md`、`research/todo_*.md`（12 处 ADR→Ruling 替换）
- `[edit]` `tools/ci/architecture_check.dart`（+~120 行 Check 4）
- `[add]` `tools/ci/docs_link_allowlist.yaml`（~5 行）

**Lane C（产品导航）：**
- `[edit]` `docs/index.md`
- `[edit]` `docs/product/milestones.md`
- `[edit]` `docs/product/roadmap.md`

**Lane D（孤儿清理）：**
- `[delete]` `docs/architecture/adr/`（目录及 ADR-0001，内容已迁移为 E1）
- `[delete]` `docs/roadmap.md`
- `[delete]` `docs/development/windows-pr0007-search-smoke.md`
- `[move]` `docs/FunctionImplementSynReport.md` → `docs/reports/v0.2/FunctionImplementSynReport.md`
- `[move]` `docs/review-01-architecture.md` → `docs/reports/v0.2.5/review-01-architecture.md`
- `[move]` `docs/review-02-engineering.md` → `docs/reports/v0.2.5/review-02-engineering.md`
- `[rename]` `docs/product/idea_temp/` → `docs/product/ideas/`
- `[edit+delete]` `docs/development/windows.md` 内容合并到 `windows-quickstart.md` 后删除
- `[edit]` `docs/api/README.md`（`ffi-contract-v0.1.md` + `workspace-tree-contract.md` 标注 historical）

**Lane E（流程模板）：**
- `[add]` `docs/development/release-lifecycle-template.md` (~120 行)
- `[add]` `docs/development/pr-spec-template.md` (~80 行)

## Verification

### CI gates

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
# Check 4 (docs link check) 应报告 0 violations
```

### Structural verification

```bash
# Lane A: 路径修复验证
rg "features/tags/" CLAUDE.md
# Expected: zero matches

rg "Post-v0\.2 baseline" CLAUDE.md
# Expected: zero matches

rg "targeted for elimination" CLAUDE.md
# Expected: zero matches

rg "S1-S8" CLAUDE.md
# Expected: zero matches

rg "features/tags/" docs/architecture/overview.md
# Expected: zero matches

# Lane B: Ruling header 验证
# 所有 Ruling 文件包含 "引入版本" 和 "废弃者" 字段
for f in docs/architecture/rulings/S*.md; do
  rg "引入版本" "$f" || echo "MISSING: $f"
done
# Expected: 9 matches, 0 MISSING

# Lane B: ADR 废弃验证
# adr/ 目录不存在
test ! -d docs/architecture/adr

# E1 ruling 已创建
test -f docs/architecture/rulings/E1-release-and-versioning.md

# 活跃文档中不再引用 "docs/architecture/adr/"（历史 PR spec 除外）
rg "docs/architecture/adr/" CLAUDE.md AGENTS.md docs/architecture/ docs/governance/ docs/development/
# Expected: zero matches

# Lane D: 孤儿文件验证
test ! -f docs/roadmap.md                          # 已删除
test ! -f docs/FunctionImplementSynReport.md       # 已移动
test ! -f docs/review-01-architecture.md           # 已移动
test ! -f docs/review-02-engineering.md             # 已移动
test ! -f docs/development/windows.md               # 已删除
test -f docs/reports/v0.2/FunctionImplementSynReport.md  # 移动目标存在
test -f docs/reports/v0.2.5/review-01-architecture.md    # 移动目标存在

# Lane D: 新增散落文件验证
test ! -f docs/development/windows-pr0007-search-smoke.md # PR-0007 冒烟已删除
test ! -d docs/product/idea_temp                          # idea_temp 已重命名
test -d docs/product/ideas                                # ideas/ 目录存在

# Pre-execution git hygiene 前置验证（PR-RB-00 开始前应已完成）
git log --all --full-history -- 'docs/init/*.docx' | head -1
# Expected: empty（.docx 已从历史中清除）
git ls-files -- 'docs/reports/**/artifacts/' | wc -l
# Expected: 0（artifacts 已从追踪中移除）
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| Docs linter 误报（PR spec 引用尚未存在的代码路径） | MEDIUM | 对 `releases/` 下引用 `apps/` `lib/` 路径只 warn 不 fail；allowlist 预留 |
| Ruling header 标准化影响下游 PR spec 引用格式 | LOW | 仅增加字段，不改变现有内容结构 |
| 孤儿文件移动后断链 | LOW | Check 4 linter 会在同一 PR 中捕获断链 |

## Acceptance Criteria

- [ ] `CLAUDE.md` 中 `features/tags/` 替换为 `shared/`
- [ ] `CLAUDE.md` 项目状态为 "Post-v0.2.5 baseline"
- [ ] `CLAUDE.md` 双状态描述为已完成时态
- [ ] `CLAUDE.md` 语义裁决引用为 "S1-S9"
- [ ] `overview.md` 中 tags 路径为 `lib/shared/`
- [ ] 9 个 S 系列 Ruling 文件均包含标准化 header（状态/引入版本/废弃者）
- [ ] `E1-release-and-versioning.md` 已创建（从 ADR-0001 迁移）
- [ ] `docs/architecture/adr/` 目录已删除
- [ ] 全仓库 ADR 引用替换为 Ruling（12 处，零残留）
- [ ] `architecture_check.dart` Check 4 已实现且 CI 通过（docs 零断链）
- [ ] `docs/index.md` 入口指向 v0.3 + 包含 modules/reports 链接
- [ ] `docs/product/milestones.md` 反映 v0.2/v0.2.5 已完成 + v0.3 进行中
- [ ] `docs/product/roadmap.md` 使用 PR-RB-XX 编号
- [ ] 根目录孤儿文件已清理（删除/移动/归档）——含 `windows-pr0007` 删除、`idea_temp` 重命名
- [ ] Pre-execution git hygiene 已完成（.docx + artifacts 从历史清除，.gitignore 已更新）
- [ ] `release-lifecycle-template.md` 已创建，包含三阶段流程 + DI 拆分/一致性/回填协议 + 交付物清单
- [ ] `pr-spec-template.md` 已创建，包含统一结构 + 5 条填写规则
- [ ] Structural verification 全部通过
