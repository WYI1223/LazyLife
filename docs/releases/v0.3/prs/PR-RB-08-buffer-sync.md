# PR-RB-08: DI-4/5 Buffer 同步

- Proposed title: `feat(editor): PR-RB-08 cross-pane buffer sync with manual listener pattern`
- Status: Draft

## Goal

实现 `EditBuffer` 跨 pane 实时同步：同一 Atom 在多个 pane 中编辑时内容实时一致。实现 manual listener + string guard bridging 模式。实现 P1/P2 加载策略（active tab eager / non-active lazy）。确立光标独立语义。**交付里程碑 M2：同一 Atom 跨 pane 编辑可用。**

前置条件：PR-RB-06（EditBuffer 基础状态机已落地）+ PR-RB-07（layout persistence Phase 1 恢复提供 tabs in loading 状态）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI-4 | `DI-4-buffer-sync-model.md` Q1(D10)/Q2(D11)/Q3(D12)/Q4 | sync 模型 / save 语义 / listener pattern / 加载策略 |
| DI-5 | `DI-5-cursor-and-conflict.md` D12/D13 | 光标独立 / 无冲突机制 |
| Module Spec | `modules/core-editor/edit-buffer.md` | EditBuffer 详细规格 + 性能边界 |
| DI-7 | `DI-7-gates-perf-testing.md` Q2-SLA | buffer sync <8ms（CI guard <40ms） |
| Rebaseline | `v0.3-pr-spec-rebaseline-2026-03-01.md` §4 PR-RB-08 | M2 milestone |

## 核心机制

### 跨 Pane 同步（DI-4 D10）

```
Pane A (editing)                EditBuffer (shared)              Pane B (observing)
─────────────────              ─────────────────               ─────────────────
user types "x"
  → TextField.onChanged
  → buffer.edit("...x")
       _content = "...x"
       _rev++
       notifyListeners()  ───→ _onBufferChanged()           _onBufferChanged()
                                Pane A: content == controller   Pane B: content != controller
                                → NO-OP (cursor preserved)     → controller.value = new content
```

**同步粒度**：per-keystroke real-time。string assignment + comparison 在 100KB 内 <1ms。

### Manual Listener Pattern（DI-4 D12）

```dart
class _EditorPaneState extends State<EditorPane> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.buffer.content);
    widget.buffer.addListener(_onBufferChanged);
  }

  void _onBufferChanged() {
    if (widget.buffer.content != _controller.text) {
      // Remote edit → update controller (no cursor jump for local edits)
      _controller.value = TextEditingValue(text: widget.buffer.content);
    }
  }

  void _onTextChanged(String newText) {
    widget.buffer.edit(newText);  // Direct to buffer, not through coordinator
  }

  @override
  void didUpdateWidget(EditorPane old) {
    super.didUpdateWidget(old);
    if (widget.buffer != old.buffer) {
      old.buffer.removeListener(_onBufferChanged);
      widget.buffer.addListener(_onBufferChanged);
      _controller.value = TextEditingValue(text: widget.buffer.content);
    }
  }

  @override
  void dispose() {
    widget.buffer.removeListener(_onBufferChanged);
    _controller.dispose();
    super.dispose();
  }
}
```

三点生命周期：`initState` add → `didUpdateWidget` swap → `dispose` remove。

### String Guard（DI-4 D12 + DI-5 D13）

- **Level 1（loop prevention）**：编辑 pane 在 `_onBufferChanged` 中比较 `buffer.content == controller.text` → 相等则 NO-OP → cursor 不跳。
- **Level 2（stale save）**：`_rev` 单调递增，debounce timer 触发时检查 `currentRev == scheduledRev`。
- Flutter 保证 programmatic `controller.value = ...` 不触发 `onChanged`，无循环风险。

### P1/P2 加载策略（DI-4 Q4）

| 策略 | 目标 | 触发 | 并发 |
|------|------|------|------|
| P1 Eager | 全部 active tabs | Phase 2 启动后 fire-and-forget parallel | 最多 8（pane 限制） |
| P2 Lazy | non-active tabs | `switchTab()` 时按需 | 单个 |

加载失败处理：
- `AtomNotFoundException` → 从所有 group 移除该 tab
- Generic FFI exception → `buffer.markError(e)` → UI 显示 error + retry
- Buffer 已 disposed → `?.initialize()` safe no-op

### 光标独立（DI-5 D12）

每个 pane 独立的 `TextEditingController` → 独立 cursor position + selection + scroll position。仅 focused pane 显示 cursor（Flutter 默认行为）。

### 无冲突机制（DI-5 D13）

单线程 Dart event loop + exclusive keyboard focus → 物理上不可能并发写入。无需 OT/CRDT。

### Save 语义（DI-4 D11）

- 1.5s idle debounce + 30s force periodic
- Save 对象是 `buffer.content`（当前 draft），不是 DB 版本
- `_rev` 防止 stale save
- Save 成功后：`_lastSavedContent = content` → `isDirty` 变为 false → UI 更新 dirty dot

## Task Breakdown

### Phase 1: EditBuffer 跨 pane 能力

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T1 | EditBuffer 完善 save 语义：1.5s debounce + 30s force + `_rev` stale guard | `edit_buffer.dart` | 编辑 ~50 行 | — |
| T2 | EditorShellService：同一 atomId 多 pane 打开时共享 EditBuffer 实例（buffer ref-counting） | `editor_shell_service.dart` | 编辑 ~30 行 | — |

### Phase 2: Editor Widget Bridging

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T3 | 实现 manual listener pattern（initState/didUpdateWidget/dispose 三点） | editor pane widget | 编辑 ~50 行 | T1 |
| T4 | String guard：`_onBufferChanged` 中 string comparison + NO-OP | 同上 | 含在 T3 内 | T1 |

### Phase 3: P1/P2 Loading

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T5 | P1 Eager：Phase 2 启动后 collect active tabs → fire-and-forget parallel `_loadSingleBuffer()` | `editor_shell_service.dart` | 新增 ~25 行 | T2 |
| T6 | P2 Lazy：`switchTab()` 触发按需 load if buffer.phase == loading | `editor_shell_service.dart` | 编辑 ~10 行 | T2 |
| T7 | Loading failure handling（AtomNotFound → remove tab / FFI error → markError） | `editor_shell_service.dart` | 新增 ~20 行 | T5 |

### Phase 4: Tests

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T8 | EditBuffer 跨 pane sync 测试：两个 listener，edit from one → other receives | `test/edit_buffer_test.dart` | 新增 ~100 行 | T1 |
| T9 | Save 语义测试：debounce + `_rev` stale guard + force periodic | `test/edit_buffer_test.dart` | 新增 ~80 行 | T1 |
| T10 | P1/P2 loading 测试：eager parallel + lazy on-demand + failure handling | `test/editor_shell_service_test.dart` | 新增 ~100 行 | T5, T6, T7 |
| T11 | 性能回归守卫：100KB buffer sync <40ms (CI 5x) | `test/edit_buffer_test.dart` | 新增 ~15 行 | T1 |
| T12 | Manual listener widget 测试 | `test/editor_pane_test.dart` | 新文件 ~80 行 | T3 |

### Phase 5: Docs

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T13 | 文档更新 + DI-4/5 标注验证完成 | docs | 编辑 | T7 |

## Planned File Changes

- `[edit]` `apps/lazynote_flutter/lib/core/editor/edit_buffer.dart`（save 语义完善）
- `[edit]` `apps/lazynote_flutter/lib/core/editor/editor_shell_service.dart`（buffer sharing + P1/P2）
- `[edit]` editor pane widget（manual listener pattern 集成）
- `[add]` `apps/lazynote_flutter/test/editor_pane_test.dart`

## Verification

```bash
cd apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

### M2 Milestone 验证

| 验证项 | 标准 |
|--------|------|
| 跨 pane 实时同步 | Pane A 输入 → Pane B 立即更新 |
| 光标独立 | Pane B 更新时 Pane A cursor 不跳 |
| Save 一致性 | 任一 pane 触发的 save 对另一 pane 可见 |
| P1 eager | 启动后 active tabs 自动加载 |
| P2 lazy | 切换到非 active tab 时按需加载 |
| Buffer sync SLA | <8ms per-keystroke overhead（100KB） |
| `_rev` 防陈旧 | debounce 期间新编辑不丢失 |

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| String comparison 在 >500KB 文档上超过帧预算 | MEDIUM | DI-4 定义 500KB 为边界；>1MB 需 evolution path（v0.4） |
| Manual listener 生命周期泄漏 | MEDIUM | T12 widget 测试覆盖 dispose + didUpdateWidget |
| P1 并行 load 与 tab close 竞态 | LOW | `?.initialize()` safe no-op + buffer disposed check |

## Acceptance Criteria

- [ ] 同一 Atom 跨 2+ pane 编辑实时同步
- [ ] 光标独立：非编辑 pane 更新不影响编辑 pane cursor
- [ ] Manual listener 三点生命周期正确（initState/didUpdateWidget/dispose）
- [ ] String guard 防止编辑 pane 自身 loop
- [ ] `_rev` 防止 stale save
- [ ] P1 eager loading + P2 lazy loading 正常
- [ ] Loading failure gracefully handled
- [ ] Buffer sync 100KB <40ms（CI guard）
- [ ] CI green
