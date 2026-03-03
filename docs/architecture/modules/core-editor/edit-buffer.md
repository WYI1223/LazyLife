# Module Spec: EditBuffer

> `lib/core/editor/edit_buffer.dart`
>
> 设计来源：[DI-1 Q3](../../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md) · [DI-4 D10/D11/D12](../../../reports/v0.3/design-discussions/DI-4-buffer-sync-model.md) · [S2 EditBuffer 节](../../rulings/S2-tab-draft-save-ownership.md)

---

## 职责

Per-atom 自包含状态机，统一原 `NoteDraftManager` + `NoteSaveTracker`，消除状态双写。管理内容、脏状态检测、保存编排。跨 pane 共享 — 同一 atom 在多个 pane 中打开时共用同一个 EditBuffer 实例。

---

## 四状态状态机

```
loading ──┬──→ ready ──→ disposing
          │                  ↑
          └──→ error ────────┘
                │
                └── retry() → loading
```

| 状态 | 允许操作 | UI 显示 | 出口 |
|------|---------|---------|------|
| `loading` | `initialize(content)`, `markError(error)` | Loading 占位，不可编辑 | → `ready` 或 → `error` |
| `ready` | `edit(content)`, `flush()`, `dispose()` | 正常可编辑 | → `disposing` |
| `error` | `retry()`, `dispose()` | Error 占位 + 重试按钮 | → `loading` 或 → `disposing` |
| `disposing` | 无 | 终态 | — |

**异常处理规则**：
- FFI 通用异常 → `markError()` 进入 error 状态，支持 retry
- `AtomNotFoundException` → 不进入 error 状态，直接移除 tab（atom 已被删除）

---

## 状态字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `atomId` | `String` | 身份标识（不可变） |
| `_phase` | `BufferPhase` | 生命周期状态门 |
| `content` | `String` | 当前编辑内容 |
| `lastSavedContent` | `String` | 上次成功持久化的内容 |
| `_rev` | `int` | 单调递增版本号（统一 DI-1 的 `_editVersion`） |
| `_lastOp` | `EditOp?` | 最后一次编辑的操作提示（v0.3 不使用） |
| `_debounceTimer` | `Timer?` | 自动保存延迟（per-buffer） |
| `_saveFuture` | `Future<bool>?` | 进行中的保存 promise |
| `_saveQueued` | `bool` | 保存完成后是否需要重新保存 |
| `_errorMessage` | `String?` | 保存失败原因 |
| `_persistFn` | 闭包 | 如何持久化（注入） |
| `_onSaved` | 闭包? | 保存成功回调（注入） |

---

## 派生属性（getter，不存储）

```dart
bool get isDirty => content != lastSavedContent;

SaveState get saveState {
  if (_phase == BufferPhase.loading) return SaveState.loading;
  if (_errorMessage != null) return SaveState.error;
  if (_saveFuture != null) return SaveState.saving;
  if (isDirty) return SaveState.dirty;
  return SaveState.clean;
}
```

**`saveState` 是 getter**，不存储 — 从字段派生（DI-1 规则）。

---

## 公共 API

```dart
// 构造
EditBuffer(String atomId, Future<bool> Function(String, String) persistFn, {void Function(String, String)? onSaved})

// 状态转换
void initialize(String loadedContent)   // loading → ready
void markError(String message)          // loading → error
void retry()                            // error → loading（重新触发 load）
void dispose()                          // → disposing

// 编辑（仅 ready 状态有效，否则 no-op）
void edit(String newContent, {EditOp? op})

// 保存
Future<void> flush()                    // 立即保存 + 等待完成
```

---

## `_rev` 用途

单调递增版本号，每次 `edit()` 时自增。三个用途：

1. **防陈旧保存**：debounce timer 触发时检查 rev 是否匹配
2. **同步协议版本**：`EditOp.baseRev` 基于此判断是否需要降级
3. **Overlay stale 判定**：`content_rev > overlay.content_rev_at_sync` → 需要 reconciliation

---

## 编辑-保存时序

```
User keystroke → buffer.edit(newContent)
  ├── _phase != ready → no-op
  ├── content = newContent
  ├── _rev++
  ├── _lastOp = op (v0.3: null)
  ├── isDirty → true (computed)
  ├── notifyListeners()
  └── restart debounce timer (1.5s idle)
        └── _executeSave()
              ├── _saveFuture != null → _saveQueued = true, return
              ├── _saveFuture = _persistFn(atomId, content)
              ├── await _saveFuture
              ├── Success → lastSavedContent = content, _onSaved()
              └── Failure → _errorMessage = error
              └── if _saveQueued → _saveQueued = false → _executeSave()
```

**Debounce 参数**：1.5s idle + 30s force（活跃输入时也定期保存）。

---

## 实时同步模型（D10）

EditBuffer extends `ChangeNotifier`。每次 `edit()` 调用 `notifyListeners()` — 其他 pane 实时收到更新。

**消费者分层策略**：

| 消费者 | 更新成本 | 策略 |
|--------|---------|------|
| 文本编辑器 pane | 低 | 同步响应 |
| 状态指示器（dirty dot、字数） | 低 | 同步响应 |
| Markdown 预览 | 高 | 内部 debounce 300ms |
| 大纲/TOC | 中 | 内部 debounce 500ms |

EditBuffer 不关心 content_type — 统一 `notifyListeners()`，消费者自行决定响应策略。

---

## EditOp 协议（D11）

**两层模型**：

| 层 | 字段 | 角色 |
|----|------|------|
| Source of Truth | `_content: String` | 完整权威文本 |
| Advisory Hint | `_lastOp: EditOp?` | 可选优化提示 |

```dart
sealed class EditOp {
  final int baseRev;
}
class SnapshotReplace extends EditOp { final String content; }
class TextDelta extends EditOp { final int offset, deleteCount; final String insertText; }
class StructuredOp extends EditOp { final String opType; final Map<String, dynamic> payload; }
```

**v0.3 实现**：`edit(content)` 不传 op（等效 SnapshotReplace）。类已定义，不实例化。

**降级规则**：TextDelta baseRev ≠ currentRev → 降级为 SnapshotReplace。StructuredOp 消费者不理解 → 降级为 SnapshotReplace。

---

## 桥接模式（D12）

EditorPane 与 EditBuffer 的连接模式：Manual listener + string comparison guard。

```dart
// MarkdownEditorPane 关键流程
void initState() {
  _controller = TextEditingController(text: widget.buffer.content);
  widget.buffer.addListener(_onBufferChanged);
}

void _onBufferChanged() {
  if (widget.buffer.content != _controller.text) {
    _controller.value = TextEditingValue(text: widget.buffer.content, ...);
  }
  // 若相等 → 本地编辑，NO-OP（保护光标）
}

void _onTextChanged(String newText) {
  widget.buffer.edit(newText);  // 直接写入，不经过 coordinator
}
```

**didUpdateWidget**：buffer 引用变化（tab 切换） → removeListener 旧 buffer + addListener 新 buffer + 同步 controller。

**v0.4+ 泛化**：提取 `EditorBufferBridge` mixin（当第二个 EditorPane 出现时）。

---

## 性能边界（D11）

| 文档大小 | 全量字符串替换 | 判定 |
|---------|--------------|------|
| < 100KB | 不可感知 | 正常 |
| 100–500KB | < 0.5ms/keystroke | 可接受 |
| 500KB+ | 需要降级路径 | Transclusion / Rope / DocumentSession |

---

## 关联模块

- ← [EditorShellService](editor-shell-service.md) — 拥有 buffers Map
- → [EditorResolver](editor-resolver.md) — EditorPane 通过 buffer 参数获取内容
- → [S1 R14](../../rulings/S1-atom-projection.md) — atom_overlays sidecar（_rev 用于 stale 判定）
