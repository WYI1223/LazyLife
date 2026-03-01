> Translation of `docs/releases/v0.3/README.md` at commit `5d833fb`.
> This translation may lag behind the canonical English source.

# v0.3 版本计划

> 2026-03-01 重排基线：执行口径已由
> `docs/releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md` 取代。
> 本文件保留为历史规划上下文。

## 定位

v0.3 在 v0.2.5 语义与架构基线之上，交付 IDE 级工作区交互模型。

主题：

- 统一数据模型基础（S1/S4/S8 裁决落地）
- 递归分屏架构 + EditorShellService（S2 Phase 2）
- 拖拽分屏交互
- 跨窗格编辑器一致性
- 长 Markdown 文档性能守护
- 链接索引/打开基础设施（launcher 前置）
- 工作区 Launcher 用户流程
- 本地任务-日历投影 + Google Calendar provider
- Windows 全局快捷键快速录入

> **启动审计**：`docs/releases/v0.3/v0.3-kickoff.md` 记录了完整的基线变迁分析、
> PR spec 审计及 Phase 0/1/2 结构的决策依据。
> **结构重审**：kickoff §9 记录了自上而下的能力推导过程，
> 产出了当前的 Phase 结构（三 Track Phase 1 + 独立 Lane Phase 2）。

## 用户可感知的成果

v0.3 结束时，用户应能：

1. 创建笔记/任务/事件时保证在工作区树中有位置（无孤儿 Atom）
2. 递归分屏工作区（不限于预设分屏模式）
3. 拖拽标签页到边缘区域自然创建新分屏
4. 在不同窗格中打开同一笔记，内容实时同步
5. 使用类 IDE 的预览/固定标签页语义
6. 安全地批量打开工作区链接集（`Open All` + 确认/上限）
7. 使用本地任务-日历投影（无需外部 provider 登录）
8. 通过 provider 插件流程连接 Google Calendar（可选集成）
9. 在 Windows 上通过全局快捷键切换/聚焦快速录入

## 架构成果

v0.3 结束时，工程层面应具备：

1. 所有 FFI 列表端点统一使用 `AtomListItem` DTO（S8 落地）
2. Atom 模型新增 `view_hint`/`title`/`content_type` 字段（S1 落地）
3. 所有创建路径产出 `Atom` + `atom_ref`（S4 落地）
4. `EditorShellService` 作为 workbench 级 tab/draft/save 所有者（S2 Phase 2）
5. 递归布局树模型（`Internal` + `Leaf` 节点）
6. 几何和安全规则（`≥ 200px`）在布局引擎中强制执行
7. 多窗格编辑的 buffer 同步模型
8. 长 Markdown 渲染策略，有可衡量的性能目标
9. Workspace Launcher 编排，关联链接索引和活跃窗格规则
10. 本地任务-日历投影规则作为核心能力
11. Google Calendar provider 基于 Provider SPI + S6 三层模型实现
12. 链接索引/打开管道作为 launcher 就绪基础
13. 全局快捷键快速录入路由，对齐 tab/entry 语义（Windows）

## 范围

纳入范围：

**Phase 0 — 基础设施前置：**

- FFI 类型统一：NoteItem → AtomListItem（`PR-0300A`）
- 数据模型 v2：view_hint/title/content_type 字段（`PR-0300B`）
- 创建路径统一：atom_ref 强制伴随（`PR-0300C`）
- Coordinator 瘦身：typedef/invoker 提取（`PR-0300D`）

**Phase 1 — 基础设施与交互（三条并行 Track）：**

- Track A — 布局引擎：递归布局树（`PR-0301`）+ 拖拽分屏交互（`PR-0302`）
- Track B — 编辑器状态：EditorShellService 提取（`PR-0301B`）+ 跨窗格 buffer 同步（`PR-0303`）+ 预览/固定标签页（`PR-0304`）
- Track C — 索引管道：链接索引/打开基础设施（`PR-0306A`）

**Phase 2 — 功能与收尾（独立 Lane）：**

- Workspace Launcher 体验（`PR-0307`）
- 本地任务-日历投影（`PR-0308`）
- Google Calendar Provider 插件（`PR-0309`）
- Windows 全局快捷键快速录入（`PR-0311`）
- Markdown 分段渲染 + 性能门禁（`PR-0305`）
- 可靠性加固 + v0.3 收尾（`PR-0306`）

不纳入范围：

- 协作多用户编辑
- CRDT 合并运行时
- Provider 同步冲突 UI 重设计
- First-party 命令/解析器插件化（S5 裁决：推迟到 v0.4+，见 kickoff §2.2）

## v0.2 / v0.2.5 依赖

v0.2 基线要求：

- 树 schema + 树 FFI
- WorkspaceProvider 状态提升
- Explorer 递归懒加载渲染 + tab open-intent 迁移（`PR-0205B` M2 已落地）
- 分屏布局 v1
- Extension Kernel + Provider SPI + Capability 模型

v0.2.5 基线要求（2026-02-27 已完成）：

- 语义裁决 S1-S8 文档化（`PR-0256`，见 `docs/architecture/rulings/`）
- Dart god-object 分解 — NotesCoordinator + 6 managers（`PR-0252`）
- Pane-aware NoteTabStateManager + per-pane tab 隔离（`PR-0257`）
- Notes-workspace 解耦 — coordinator 为唯一状态源，
  WorkspaceProvider 仅管 pane 布局（166 行）（`PR-0258`）
- Rule E CI 守护 `architecture_check.dart`（`PR-0259`）
- 闭合回放与 v0.3 交接证据（`PR-0253`）

## 执行顺序与状态追踪

### 规划阶段 — 设计研讨 + Spec 就绪

> 目标：解决关键设计空白，再将所有 PR spec 更新到可执行状态。
> 设计就绪度审计：`docs/reports/v0.3/01-design-readiness-audit.md`。
> 结构重审：`docs/releases/v0.3/v0.3-kickoff.md` §9。

**阶段 1 — 设计研讨（可与 Phase 0 spec 创建并行）：**

| # | 任务 | 目标 | 阻塞 | 状态 |
|---|------|------|------|------|
| DI-1 | EditorShellService 接口设计 | D1-D4 决策 | PR-0301B、PR-0303、PR-0304、PR-0311 spec | Planned |
| DI-2 | 递归布局树数据模型 | D5-D9 决策 | PR-0301、PR-0302 spec | Planned |
| DI-3 | Buffer 同步架构 | D10-D13 决策（依赖 DI-1） | PR-0303、PR-0305 spec | Planned |

> DI 交付物：`docs/releases/v0.3/design/DI-{1,2,3}-*.md`

**阶段 2 — Spec 编写（DI 结论产出后）：**

| # | 任务 | 目标 Spec | Kickoff 引用 | 状态 |
|---|------|----------|-------------|------|
| P1 | 创建 Phase 0 spec | `PR-0300A`、`PR-0300B`、`PR-0300C`、`PR-0300D` | §3 | Planned |
| P2 | 创建 PR-0301B spec | `PR-0301B` | §9.5 + DI-1 | Planned |
| P3 | 重写 3 个 spec | `PR-0301`、`PR-0302`、`PR-0304` | §9.7.3 + DI-1/DI-2 | Planned |
| P4 | 更新 5 个受影响的 spec | `PR-0303`、`PR-0307`、`PR-0308`、`PR-0309`、`PR-0311` | §2 + §9 + DI-1/DI-3 | Planned |
| P5 | 标记 PR-0310 为已移除 | `PR-0310` | §2（DROP 判定，S5） | Planned |

**规划阶段通过条件：**

- [ ] DI-1/DI-2/DI-3 设计文档完成，决策已记录
- [ ] 4 个 Phase 0 spec 已创建并审核
- [ ] PR-0301B（EditorShellService）spec 已创建，含 DI-1 接口定义
- [ ] PR-0301、PR-0302、PR-0304 按 §9 重构方案 + DI 结论完成重写
- [ ] 5 个更新的 spec 已对齐 S1-S8 裁决、coordinator 模式及 §9 依赖变更
- [ ] PR-0310 已标记移除并记录原因
- [ ] 本 README 中列出的所有 spec 文件路径与实际文件一致
- [ ] 每个活跃风险（R1、R3、R6）的缓解方案已写入对应 PR spec（见 kickoff §6）
- [ ] Phase 1 Gate 验证标准可测试（非模糊表述）

### Phase 0 — 基础设施前置

> 目标：清除架构阻塞。建立统一的数据模型和 FFI 合约。

| # | PR | 标题 | 裁决来源 | 状态 |
|---|-----|------|---------|------|
| 1 | `PR-0300D` | Coordinator typedef/invoker 提取 | 09 §7.1 | Planned |
| 2 | `PR-0300A` | FFI 类型统一（NoteItem → AtomListItem） | S8 | Planned |
| 3 | `PR-0300B` | 数据模型 v2（view_hint/title/content_type） | S1 | Planned |
| 4 | `PR-0300C` | 创建路径统一（atom_ref 强制伴随） | S4 | Planned |

**Phase 0 通过条件：**

- [ ] `cargo test --all` PASS
- [ ] `flutter test` PASS（≥333，0 fail）
- [ ] `architecture_check.dart` PASS（coordinator warning 清除）
- [ ] 所有创建路径产出 Atom + atom_ref
- [ ] NoteItem 不再被任何 Flutter 代码引用

### Phase 1 — 基础设施与交互（三条并行 Track）

> 目标：构建核心基础设施（布局引擎、编辑器服务、索引管道）和交互模型
> （拖拽分屏、buffer 同步、tab 预览/固定）。
> Phase 0 Gate 通过后三条 Track 同时启动（见 kickoff §9.5）。

**Track A — 布局引擎（L1a → L2 drag）：**

| # | PR | 标题 | Spec 状态 | 状态 |
|---|-----|------|----------|------|
| 5 | `PR-0301` | 递归布局树引擎 | **需重写** | Planned |
| 6 | `PR-0302` | 拖拽分屏交互（布局树层面） | **需重写** | Planned |

**Track B — 编辑器状态（L1b → L2 buffer/tab）：**

| # | PR | 标题 | Spec 状态 | 状态 |
|---|-----|------|----------|------|
| 7 | `PR-0301B` | EditorShellService 提取（S2 Phase 2） | **新增 — 需创建** | Planned |
| 8 | `PR-0303` | 跨窗格实时 buffer 同步 | 需更新 | Planned |
| 9 | `PR-0304` | EditorGroupModel + 预览/固定标签页 | **需重写** | Planned |

> PR-0303 和 PR-0304 都依赖 PR-0301B，但二者之间无依赖关系 — 可并行执行。

**Track C — 索引管道（L1c）：**

| # | PR | 标题 | Spec 状态 | 状态 |
|---|-----|------|----------|------|
| 10 | `PR-0306A` | 链接索引/打开基础设施 | 有效 | Planned |

**Phase 1 通过条件：**

- [ ] 递归分屏稳定，min-size 约束强制执行
- [ ] 拖拽分屏在布局树层面运行（不在 NoteExplorer 中）
- [ ] EditorShellService 在 workbench 级拥有 tab/draft/save
- [ ] 同一笔记多窗格编辑内容一致
- [ ] 预览/固定标签页行为确定性，有测试覆盖
- [ ] 链接索引/打开管道可用
- [ ] 所有 v0.2.5 测试无回归

### Phase 2 — 功能与收尾（独立 Lane）

> 目标：功能集成与质量收尾。
> 各 Lane 在其特定依赖满足后即可启动 — 无需等待整个 Phase 1 完成。
> Lane A 和 Lane B 可在 Phase 0 完成后启动（不依赖 Phase 1）。

| Lane | # | PR | 标题 | 启动条件 | Spec 状态 | 状态 |
|------|---|-----|------|---------|----------|------|
| A | 11 | `PR-0307` | Workspace Launcher 体验 | Track C (0306A) 完成 | 需更新 | Planned |
| B | 12 | `PR-0308` | 本地任务-日历投影 | Phase 0 完成 | 需更新 | Planned |
| B | 13 | `PR-0309` | Google Calendar Provider 插件 | PR-0308 完成 | 需更新 | Planned |
| C | 14 | `PR-0311` | Windows 全局快捷键快速录入 | Track B 0304 完成 | 需更新 | Planned |
| D | 15 | `PR-0305` | Markdown 分段渲染 + 性能门禁 | Track B 0303 完成 | 有效 | Planned |
| — | 16 | `PR-0306` | 可靠性加固 + v0.3 收尾 | 所有 PR 完成 | 有效 | Planned |

**Phase 2 / v0.3 发布通过条件：**

- [ ] `cargo test --all` PASS
- [ ] `flutter test` PASS（0 fail）
- [ ] `architecture_check.dart` PASS（0 violations）
- [ ] Launcher flow 有安全上限和确认机制
- [ ] 本地日历投影独立于外部 provider
- [ ] Google Calendar 通过 Provider SPI 运行（S6 三层模型）
- [ ] 全局快捷键非破坏性，失败可诊断
- [ ] 长 Markdown 场景 ≥ 60 FPS
- [ ] Profile 模式性能检查：长 Markdown 多窗格场景

## 已移除的 PR

| 原 PR | 原因 | 替代 |
|-------|------|------|
| `PR-0310`（first-party 命令/解析器插件化） | S5 裁决：first-party 不走 Extension Kernel。Extension Kernel 是 third-party 安全合约。 | 推迟到 v0.4+，第一个真实 third-party 插件需求出现时构建。 |

## 依赖图

> 源自 kickoff §9.3–§9.6 的能力分层推导。

```
Phase 0 (L0)               Phase 1 (L1+L2)                       Phase 2 (L3+L4)
─────────────               ─────────────────                     ─────────────────
0300D (瘦身)                Track A:          Track C:
                            0301 (布局树)     0306A (链接索引)────► Lane A: 0307 (launcher)
0300A (FFI 统一)               ↓
  ↓                         0302 (拖拽分屏)
0300B (数据模型 v2)
  ↓                         Track B:                              Lane B: 0308 (日历投影)
0300C (创建路径)════►        0301B (EditorShell)                       ↓
                              ↓       ↓                           0309 (Google Cal)
                            0303    0304
                           (buffer) (tab)────────────────────────► Lane C: 0311 (快捷键)
                              ↓
                            ·····························────────► Lane D: 0305 (性能)

                                                                  0306 (加固 + 收尾)
```

## 质量门禁（全 Phase 通用）

```bash
# Rust
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all

# Flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart

# 性能（Phase 1+）
# profile 模式基准测试，含文档化数据集
```

## 已知风险与缓解方案

> 完整分析及 v0.3 解决方案见 `docs/releases/v0.3/v0.3-kickoff.md` §6。
> 所有风险必须在 v0.3 内闭环，不推迟到 v0.4。
> §9 结构重审已从设计层面消除 R2 和 R5（见 §9.7.2）。

| 风险 | 描述 | 归属 PR | v0.3 解决方案 |
|------|------|---------|--------------|
| R1 | `coordinator_impl.dart` 1,514 行 — v0.3 新增可能触发 2,000 行 CI failure | `PR-0300D` + `PR-0301B` + `PR-0306` | PR-0300D 瘦身至 ~1,320 行；PR-0301B 提取 tab/draft/save（进一步缩减）；PR-0306 兜底二次拆分 |
| R3 | PR-0300A FFI 破坏性变更，Flutter 端消费者多 | `PR-0300A` | spec 必须包含完整消费者审计 + 机械替换策略；一次性批量迁移，不使用兼容 shim |
| R6 | PR-0309 是首个 Provider SPI 运行时实现，可能暴露 SPI 设计缺陷 | `PR-0309` | spec 必须包含 SPI 验证步骤（mock provider 集成测试）；SPI trait 修改在 PR-0309 内完成 |

**已消除的风险（§9 结构重审）：**

- ~~R2~~（`note_explorer.dart` 膨胀）— drag 逻辑现在在布局树层面运行（PR-0302 重写），不再加入 NoteExplorer。根因消除。
- ~~R5~~（EditorShellService 膨胀 PR-0301）— EditorShellService 现为独立 PR（PR-0301B）。单一职责，根因消除。

**已解决的风险**：R4（PR-0205B M2 不确定性）— 已验证在 commit `f9d911a` 合入。PR-0304 重写基于已有基线扩展。

## 验收标准（发布级）

v0.3 完成条件：

1. 所有创建路径产出 Atom + atom_ref（S4）
2. 所有 FFI 列表端点统一使用 AtomListItem DTO（S8）
3. 递归分屏和拖拽分屏稳定且约束安全
4. EditorShellService 在 workbench 级拥有 tab/draft/save（S2 Phase 2）
5. 多窗格同笔记编辑保持内容一致且可恢复
6. 预览/固定标签页行为确定性，有测试覆盖
7. 长 Markdown 渲染满足约定的性能基线目标
8. Workspace Launcher flow 安全、有约束、有测试覆盖
9. 本地任务-日历投影稳定，独立于外部 provider
10. Google Calendar 集成通过 Provider SPI + S6 三层模型运行
11. Windows 全局快捷键快速录入稳定且非破坏性

## Spec 状态总览

> 审计详情见 `docs/releases/v0.3/v0.3-kickoff.md` §2；结构重审见 §9。

| Spec | 审计判定 | 行动 |
|------|---------|------|
| PR-0300A/B/C/D | — | **创建**（新 Phase 0 spec） |
| PR-0301 | **REWRITE** | 收窄为纯布局树引擎；移除 EditorShellService 整合（§9.4 问题 1） |
| **PR-0301B** | — | **创建**（新增：EditorShellService 提取，S2 Phase 2；§9.5 Track B） |
| PR-0302 | **REWRITE** | 改为布局树层面交互；drag 逻辑不在 NoteExplorer 中（§9.4 问题 2） |
| PR-0303 | UPDATE | 依赖变更：依赖 PR-0301B（非 PR-0302）；buffer 在 EditorShellService 中 |
| PR-0304 | **REWRITE** | 基于 EditorGroupModel 重新设计；依赖 PR-0301B（非 PR-0303）；PR-0205B M2 基线已确认 |
| PR-0305 | VALID | 移至 Phase 2 Lane D（依赖 PR-0303 完成） |
| PR-0306 | VALID | 移至 Phase 2 收尾（依赖所有 PR） |
| PR-0306A | VALID | 移至 Phase 1 Track C（L1c 基础设施，非 Phase 2 功能） |
| PR-0307 | UPDATE | 追加 S3 正交性 AC（必选）；追加 S4 创建路径合规 |
| PR-0308 | UPDATE | 对齐 S1 view_hint、S7 触发语义 |
| PR-0309 | UPDATE | 对齐 S6 三层模型，修复过时依赖引用 |
| PR-0310 | **DROP** | S5 裁决矛盾 |
| PR-0311 | UPDATE | 移除 PR-0310 依赖，补充 pane targeting spec；依赖 PR-0304 |

## PR Spec 文件

**Phase 0（新增）：**

- `docs/releases/v0.3/prs/PR-0300A-ffi-type-unification.md`
- `docs/releases/v0.3/prs/PR-0300B-data-model-v2.md`
- `docs/releases/v0.3/prs/PR-0300C-creation-path-unification.md`
- `docs/releases/v0.3/prs/PR-0300D-coordinator-thinning.md`

**Phase 1 — Track A（布局）：**

- `docs/releases/v0.3/prs/PR-0301-recursive-layout-tree.md`
- `docs/releases/v0.3/prs/PR-0302-drag-to-split-edge-zones.md`

**Phase 1 — Track B（编辑器状态）：**

- `docs/releases/v0.3/prs/PR-0301B-editor-shell-service.md`
- `docs/releases/v0.3/prs/PR-0303-cross-pane-live-buffer-sync.md`
- `docs/releases/v0.3/prs/PR-0304-tab-preview-pinned-model.md`

**Phase 1 — Track C（索引）：**

- `docs/releases/v0.3/prs/PR-0306A-links-index-open-foundation.md`

**Phase 2（功能与收尾）：**

- `docs/releases/v0.3/prs/PR-0307-workspace-launcher-experience.md`
- `docs/releases/v0.3/prs/PR-0308-local-task-calendar-projection.md`
- `docs/releases/v0.3/prs/PR-0309-google-calendar-provider-plugin.md`
- `docs/releases/v0.3/prs/PR-0311-windows-global-hotkey-quick-entry.md`
- `docs/releases/v0.3/prs/PR-0305-markdown-segment-rendering-performance-gate.md`
- `docs/releases/v0.3/prs/PR-0306-recursive-workspace-reliability-hardening.md`

**已移除：**

- ~~`docs/releases/v0.3/prs/PR-0310-first-party-command-parser-plugins.md`~~（S5 裁决，见 kickoff §2.2）
