# Idea: Tab 与 Explorer 名称一致性 UX 优化

| 项目 | 值 |
|------|-----|
| **来源** | DI-1 Q4 细化1 讨论（Tab 标题机制） |
| **优先级** | 未定 |
| **关联** | S1 R8（title 字段）、S1 R9（icon 字段）、DI-1 EditorShellService |

---

## 背景

S1 R8 裁决 Tab 显示 `atom.title`（Atom 身份层），Explorer atom_ref 显示 `display_name`（节点层别名，用户手动设置）> `atom.title`。

大多数情况下 `display_name` 未设置，两者自然一致。但当用户为 atom_ref 设置了 display_name 后，可能出现：

- Explorer 显示 "Q1会议纪要"（display_name）
- 点击后 Tab 显示 "Meeting Notes"（atom.title）
- 用户困惑："我打开对了吗？"

## 为什么 Tab 不能跟 display_name 同步

Tab 是 per-atom 的（一个 Atom 只有一个 Tab），display_name 是 per-ref 的（同一 Atom 可有多个 atom_ref，各有不同 display_name）。维度不匹配，强行同步在多引用场景下无法自洽：

```
Explorer
├── 📁 Work/
│   └── 📄 "Q1会议纪要"     ← atom_ref_1.display_name
└── 📁 Personal/
    └── 📄 "Meeting Notes"   ← atom_ref_2 无 display_name → 显示 atom.title

Tab: 只有一个 → 跟谁的 display_name？
```

## UI 层缓解方案（未来实现）

### 方案 1: Tab tooltip 显示来源路径

hover Tab 时显示面包屑路径，连接 Explorer 别名和 Atom 本名：

```
Tab: [Meeting Notes]
Tooltip: 📁 Work / Q1会议纪要 → Meeting Notes
```

用户可以通过 tooltip 确认"这就是我从 Explorer 点击的那个"。

### 方案 2: Tab icon 辅助识别（依赖 S1 R9）

S1 R9 为 Atom 新增 `icon` 字段（emoji 或图标标识符）。即使名称不完全匹配，一致的 icon 也能帮助用户快速识别。

### 方案 3: Explorer → Tab 的视觉关联动画

用户从 Explorer 点击条目时，Tab strip 中对应 tab 短暂高亮（如 0.3s 闪烁或滑入动画），建立视觉上的"就是这个"关联。

### 方案 4: Tab 副标题显示 display_name（如有）

如果打开的 Atom 的某个 atom_ref 设置了 display_name，Tab 可以以副标题形式显示：

```
┌─────────────────┐
│ Meeting Notes    │  ← atom.title（主标题）
│ Q1会议纪要       │  ← display_name（副标题，灰色小字，仅当存在时显示）
└─────────────────┘
```

但多引用场景下仍需决定显示哪个 display_name（最近点击的？第一个？），复杂度较高。

## 备注

以上为 UX 层面的优化思路，不影响数据模型和架构设计。当前 S1 R8 的 `atom.title` + `display_name` 分层设计是正确的，UX 缓解方案可在功能稳定后按需实现。
