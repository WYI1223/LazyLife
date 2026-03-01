# DI-7: Gate 验证标准 + 性能基线 + 测试策略

| 项目 | 值 |
|------|-----|
| **状态** | **RESOLVED** — Gate 精确化、性能 SLA、测试方法论、迁移策略全部裁决 |
| **关联决策点** | 无编号（§5.1 + §5.2 + §5.5 提出的工程问题） |
| **影响 PR** | 所有 v0.3 PR 的测试要求 + Gate A / Gate B 验收标准 |
| **前置依赖** | DI-1/DI-2/DI-4 的结论（Gate 精确化依赖设计决策）、DI-6（重排后的 Gate 结构） |
| **来源** | 01-design-readiness-audit.md §5.1 + §5.2 + §5.5 |
| **权威执行方案** | [v0.3-pr-spec-rebaseline-2026-03-01.md](../../../releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md) |

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

## Q1 裁决：Gate 验证标准精确化

DI-6 重排后，原单一 Phase 1 Gate 替换为 Gate A + Gate B + Release Gate 三级结构（[rebaseline §5](../../../releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md)）。以下将每个 Gate 项转化为可自动化验证的手段。

### Gate A — 语义与契约（PR-RB-05 后）

| 验证项 | 精确化定义 | 验证手段 | 自动化 |
|--------|----------|---------|--------|
| NoteItem 消除 | 手写 `.dart` 文件中零 `NoteItem` 引用（`lib/core/bindings/` 除外） | 扩展 `architecture_check.dart`：扫描 `lib/` 排除 `bindings/`，grep `NoteItem`，命中即 failure | CI 自动 |
| atom_ref 伴随 | 每个创建 API 返回值包含有效 `atom_ref`（非空且对应有效 workspace node） | Rust 集成测试：调用 `entry_create_note` / `entry_create_task` / `entry_schedule` / `workspace_create_note_ref` → assert 返回的 `atom_ref` 非空 | CI 自动 |
| 提醒调度解耦 | `TasksController` 和 `CalendarController` 不再直接调用 `ReminderScheduler.schedule/cancel` | 扩展 `architecture_check.dart`：扫描 `features/tasks/` 和 `features/calendar/` 中不存在 `reminder_scheduler` 导入 | CI 自动 |

**实施方式**：三项均扩展进 `architecture_check.dart`（静态分析 + Rust 测试），在 CI 中自动执行。

### Gate B — 编辑器基础设施（PR-RB-09 后）

| 验证项 | 精确化定义 | 验证手段 | 自动化 |
|--------|----------|---------|--------|
| M1 多 pane | `splitGroup()` → `groups.length == 2` + `layout.leafCount == 2`；`closeGroup()` → 恢复单 pane | EditorShellService 单元测试 | CI 自动 |
| M2 跨 pane 编辑 | 同一 EditBuffer 挂两个 listener → `edit()` → 两个 listener 均被通知且 `content` 一致 | EditBuffer 单元测试 | CI 自动 |
| DI-0 命名 | 代码中不存在旧名 `NoteTabManager`（widget 层已重命名为 `NoteTabStrip`） | `architecture_check.dart` 扩展 | CI 自动 |
| DI-1/2 不变式 | DI-2 七条不变式（I1-I7）：二叉、叶 ID 唯一、fraction ∈ (0,1)、最小 200×200、非空、groups 双射、无重复兄弟 | GroupLayout 单元测试：每次 split/close/resize 后 assert 七条不变式 | CI 自动 |
| DI-3 恢复 | 损坏 JSON / `{schema_version: 999}` / 空文件 → 均恢复为单 LeafNode 默认布局 | LayoutPersistence 单元测试 | CI 自动 |
| DI-4/5 同步 | `_rev` 单调递增；跨 pane content 一致；光标不在 buffer 层管理（由各 pane 独立 TextEditingController 持有） | EditBuffer 单元测试 | CI 自动 |

**所有 Gate B 验证项通过各 PR 新增的单元测试覆盖，PR-RB-11（收口）做回归确认。**

### Release Gate（v0.3）

```bash
cd crates/
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all

cd apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart  # 含 Gate A 扩展检查
```

### 审计报告 §5.1 三个模糊条件的精确化对照

| 原始模糊表述 | 精确化后 | 验证方式 |
|------------|---------|---------|
| "Same-note multi-pane editing content-coherent" | 同一 EditBuffer 挂 N 个 listener → `edit()` → 所有 listener 同步收到一致 content；buffer sync 延迟 < 8ms（100KB 文档，Stopwatch 断言） | 单元测试 + 性能测试（Q2 层 1） |
| "Recursive split stable" | 连续 split/close 10 次循环后 → 树满足 I1-I7 不变式 + groups 映射一致 + 无悬挂引用 | GroupLayout 单元测试 |
| "Preview/pinned tab deterministic" | 给定操作序列（open A → open B → open C → close B）→ 预期 tab list 状态映射表 | EditorGroupModel 单元测试 |

---

## Q2 裁决：性能基准定义

### 已有 SLA（来自 DI-4）

| 同步路径 | 延迟目标 | 来源 |
|---------|---------|------|
| 文本→文本（跨 pane） | 实时（每次击键） | DI-4 Q1 |
| Block→文本（跨 pane） | 50-150ms | DI-4 Q2 SLA 表 |
| 文本→Block（跨 pane） | 300-500ms 节流 | DI-4 Q2 SLA 表 |
| 字符串操作（100KB 文档） | < 1ms（帧预算 6%） | DI-4 Q2 性能估算 |

### 审计报告 §5.2 五个缺失维度的补充

| 维度 | 定义 | 理由 |
|------|------|------|
| **数据集** | 标准测试文档：小（1KB）、中（10KB）、大（100KB）；100KB 为 v0.3 性能边界 | DI-4 明确 100KB 内无感知，500KB 为边界 |
| **窗格数** | 1 pane（基线）、2 pane 同笔记（核心场景）、4 pane（压力测试） | 2 pane 同笔记是 M2 核心交付场景 |
| **硬件基线** | 不定义最低配置；以开发机（i5/Ryzen 5 + 16GB + 集显）为参考 | pre-1.0 阶段，Windows-first，用户群体为开发者 |
| **测量方法** | 两层验证（见下） | 兼顾自动化精度与 CI 稳定性 |
| **基线对比** | v0.2 单 pane 不退化（tab 切换、编辑输入延迟） | v0.2 功能兜底，新架构不应使已有场景变慢 |

### 性能 SLA 总表（v0.3 标准）

| 操作 | SLA 目标 | CI 回归守卫（5x） | 测试条件 | 验证方式 |
|------|---------|-----------------|---------|---------|
| Tab 切换 | < 16ms（单帧） | — | 10KB 文档，2 pane | 层 2 integration_test |
| Split/Close | < 50ms | < 250ms | 2→4 pane | 层 1 Stopwatch |
| 跨 pane 文本同步 | < 8ms（buffer 层） | < 40ms | 100KB 文档，2 pane 同笔记 | 层 1 Stopwatch |
| 编辑击键延迟 | < 16ms（维持 60 FPS） | — | 100KB 文档，2 pane | 层 2 integration_test |
| 布局持久化写入 | < 50ms | < 250ms | 8 pane（上限） | 层 1 Stopwatch |
| 启动恢复（布局+tab） | < 200ms | < 1000ms | 4 pane，每 pane 3 tab | 层 1 Stopwatch |

**SLA 目标 vs CI 回归守卫的区分**：SLA 目标是 Gate B 本地验证的严格标准。CI 回归守卫使用 5x 宽松阈值，仅捕捉数量级退化（防止"8ms 变 80ms"的回归），不做精确 SLA 合规——因为 CI VM 负载波动可能导致绝对毫秒断言不可重复。

### 两层验证方法

#### 层 1：Service 层 — Stopwatch 回归守卫（CI 自动执行）

不涉及 UI 渲染的纯 Dart 操作，在单元测试中用 `Stopwatch` 计时。**CI 中使用 5x 宽松阈值**作为回归守卫，Gate B 本地验证时使用严格 SLA 目标值：

```dart
test('buffer sync regression guard', () async {
  final buffer = EditBuffer(atomId: 'test', loadContentFn: ...);
  await buffer.initialize();

  final sw = Stopwatch()..start();
  buffer.edit(content: largeContent100KB);
  sw.stop();

  // CI 回归守卫（5x SLA）— 捕捉数量级退化
  expect(sw.elapsedMilliseconds, lessThan(40));
  // Gate B 本地验证时手动检查 SLA: < 8ms
});
```

适用操作：跨 pane buffer 同步、Split/Close 树操作、布局持久化写入、启动恢复。

在现有 CI `flutter test` 中自动执行，零额外基础设施成本。CI 断言使用宽松阈值避免因 VM 负载波动导致 flaky。

#### 层 2：UI 帧率 — Flutter integration_test（Gate B 本地手动触发）

涉及 widget 渲染的操作，用 `binding.traceAction()` 做帧级计时：

```dart
testWidgets('tab switch within frame budget', (tester) async {
  // setup multi-pane editor...
  final timeline = await tester.binding.traceAction(() async {
    await tester.tap(find.text('Tab 2'));
    await tester.pumpAndSettle();
  });
  // timeline 包含精确帧耗时
});
```

适用操作：Tab 切换、编辑击键 FPS。

测试代码随 PR-RB-06/08 提交，但 CI 中**不设 timing 断言**（CI VM 帧率不稳定，避免 flaky）。Gate B 检查点时在本地 `flutter test --profile` 手动执行确认。

### 裁决：不引入自动化性能 CI

理由：
1. 当前无任何性能测试基础设施（无 benchmark、无 criterion）
2. Flutter widget 性能测试在 CI VM 环境中不稳定
3. v0.3 核心目标是架构正确性，不是性能优化
4. 层 1 Stopwatch 断言已覆盖 service 层热路径；层 2 在 Gate B 手动确认足以发现退化

---

## Q3 裁决：测试方法论

### 核心结论：不需要自定义 test harness

v0.3 新能力的核心组件（GroupLayout、EditBuffer、EditorShellService）都是纯 Dart 类，可用标准 Flutter 测试模式覆盖。

| 新能力 | 测试类别 | 测试方法 | 需要新 harness |
|--------|---------|---------|--------------|
| GroupLayout 树操作 | 纯单元测试 | 输入→输出函数：`split(tree, groupId, axis)` → assert 新树满足 I1-I7 | 否 — 纯数据结构 |
| EditorShellService | 单元测试 + listener 验证 | ChangeNotifier 标准模式：调用 API → assert 状态变更 + listener 通知 | 否 — 现有 Flutter 测试模式 |
| EditBuffer 状态机 | 单元测试 | 状态转换全路径覆盖：`loading→ready→dirty→saving→clean` | 否 — 标准状态机测试 |
| 跨 pane 同步 | 单元测试 | 同一 EditBuffer 挂多个 listener → `edit()` → assert 所有 listener 收到一致 content | 否 — ChangeNotifier 原生支持 |
| Drag-to-split | Widget 测试 | `WidgetTester.drag()` 模拟拖拽 → assert split 生效 | 少量 overlay setup，不需要独立 harness |
| 布局持久化 | 单元测试 | JSON roundtrip + 损坏恢复 | 否 |
| 启动恢复 | 集成测试 | Mock file system + mock FFI → `restore()` → assert 恢复正确 | 可能需要 file system mock |

### 每个 PR 的测试期望

以"覆盖场景"为准，不设硬性测试数量要求。

| PR | 新增测试覆盖范围 |
|----|---------------|
| PR-RB-01 | AtomListItem DTO 替换后的 FFI 契约测试 |
| PR-RB-02 | S1 字段 migration + 自动推导逻辑 Rust 测试 |
| PR-RB-03 | 创建路径统一 + atom_ref 路由 |
| PR-RB-04 | 提醒生命周期触发 + 启动恢复 |
| PR-RB-05 | WorkspaceTreeService 独立单元测试 |
| PR-RB-06 | **重点**：EditorShellService + EditorGroupModel + GroupLayout 不变式（I1-I7）+ 层 1 性能断言 |
| PR-RB-07 | 持久化 JSON roundtrip + 损坏恢复 + debounce + atomic write |
| PR-RB-08 | **重点**：EditBuffer 状态机 + 跨 pane 同步 + `_rev` 防陈旧 + 层 1 性能断言 |
| PR-RB-09 | EditorResolver 路由 + 未知 content_type 占位 |
| PR-RB-10 | S3 tag 面板 + atom_ref 面包屑 |
| PR-RB-11 | 回归测试补齐 + 旧 manager 测试清理 |

---

## Q4 裁决：现有测试迁移策略

### 影响分析

当前测试基线：53 Flutter 测试文件，~340 用例。受 EditorShellService 提取影响的主要是 Notes 相关测试。

| 测试类别 | 受影响文件 | 迁移策略 |
|---------|----------|---------|
| Tab 操作测试 | `notes_controller_tabs_test.dart` | **重写** → EditorShellService 单元测试（tab 逻辑从 coordinator 移出） |
| Draft/Save 测试 | `note_save_tracker_test.dart`、draft 相关测试 | **重写** → EditBuffer 状态机测试（draft/save 统一为 buffer 状态） |
| Workspace split 测试 | `workspace_split_v1_test.dart` | **更新**：mock 对象从 WorkspaceProvider 改为 EditorShellService |
| Coordinator 集成测试 | `notes_controller_*_test.dart` | **更新**：coordinator 测试范围缩小到 wiring（FFI 调用中转），不再测 tab/draft/save |
| UI 渲染测试 | `notes_page_c*_test.dart` | **最小改动**：widget props 不变，仅 provider 注入方式可能调整 |
| 非 Notes 测试 | Tasks、Calendar、Entry 等 | **不受影响** |

### 迁移原则

1. **渐进式**：每个 PR 只迁移自己影响的测试，不做一次性大规模迁移
2. **先增后减**：PR-RB-06 先为新组件写测试，确认功能正确后再删除旧测试中的冗余覆盖
3. **测试数不减**：每个 PR 合并后总测试数 ≥ 合并前（允许替换，不允许净减少）
4. **PR-RB-11 扫尾**：收口 PR 清理所有残留的旧 manager 测试引用

---

## 裁决汇总

> 注：以下编号为 DI-7 内部裁决编号（Q1-Q4 对应四个待讨论问题，R1 为补充裁决），与审计报告 D1-D13 无关。

| 编号 | 决策点 | 裁决 |
|------|--------|------|
| Q1 | Gate A 检查是否扩展进 `architecture_check.dart` CI 自动执行？ | **是** — 静态检查成本低，自动化防回归 |
| Q2 | v0.3 是否引入自动化性能 CI？ | **否（整体）** — 采用两层方案：层 1 Stopwatch 回归守卫（CI 自动，5x 宽松阈值），层 2 integration_test（Gate B 本地手动，严格 SLA） |
| Q2-SLA | 性能 SLA 数值 | 见上方性能 SLA 总表（含 SLA 目标值 + CI 回归守卫阈值） |
| Q3 | 每个 PR 的测试期望 | 以"覆盖场景"为准，不设硬性数字 |
| Q4 | 测试迁移原则 | 渐进式 + 先增后减 + 总数不减 + PR-RB-11 扫尾 |

---

## 关联

- ← DI-1/DI-2/DI-4（设计决策定义了 Gate B 验证项和性能 SLA）
- ← DI-5（光标独立性 → Gate B DI-4/5 验证项）
- ← DI-6（重排后 Gate A + Gate B 两级结构）
- ← 01 审计报告 §5.1 + §5.2 + §5.5
- → 各 PR spec（测试期望表定义每个 PR 的测试覆盖范围）
- → [v0.3-pr-spec-rebaseline-2026-03-01.md](../../../releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md)（Gate 定义源头）

---

*前序议题：[DI-6 跨 Track 依赖](DI-6-cross-track-dependencies.md)*
*下一个议题：[DI-8 SPI 验证](DI-8-spi-verification.md)*
