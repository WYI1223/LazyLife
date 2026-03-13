# PR-0412: Flutter Core — WorkspaceTreeService B+ 改造

- Proposed title: `feat(workspace): workspace tree service enhancement with mutation delta`
- Status: Draft

## Goal

改造 WorkspaceTreeService 对接新 tree FFI（`workspace_resolve_designated`、`workspace_reassign_designated` 等树操作），引入 TreeMutationDelta 变更通知机制，新增 `loadSystemNodes` / `getSystemNodeId` 系统节点接口。`query_atoms` 消费迁移属于 PR-0413（feature 层）。

前置条件：PR-0411（需要新 FFI 函数就绪）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-17-flutter-thin-client.md` Q1-Q4 | WorkspaceTreeService B+ 改造、TreeMutationDelta、系统节点解析 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` Q1（PR-0412 行）、Q4（Flutter 测试 + delta 载荷断言） | PR 定位、测试要求 |
| 现有实现 | `apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart` | 需改造的目标文件 |
| 现有实现 | `apps/lazynote_flutter/lib/core/workspace/workspace_tree_types.dart` | 需扩展（加 TreeMutationDelta） |
| Handoff workflow | `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md` | `DOC-023 / DI-15` + `DOC-024 / DI-16` + `DOC-025 / DI-17` + `DOC-026 / DI-18` 的交接合同；本 PR 负责更新 `flutter-core` ledger，同时更新 `execution-order` 与本 PR 负责的 `verification-gates` rows，并显式消费 `OI-035` / `OI-036` / `OI-038`、`OI-039` / `OI-040` / `OI-042` 的 core-consumer 部分，以及 `OI-045` / 本 PR 负责的 `OI-048` 部分，不得直接发布 ADR / ruling / topic-map carrier |

## Scope

In scope:
- WorkspaceTreeService 对接新 tree FFI（`workspace_resolve_designated`、`workspace_reassign_designated` 等树操作接口）
- TreeMutationDelta 通知机制（`affectedParentIds` 供定向刷新）
- `loadSystemNodes` / `getSystemNodeId` 系统节点接口
- `reassignDesignated` 成功后刷新本地系统节点映射（DI-17 Q2）
- Mock invoker 测试
- 更新 `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md` 中 `flutter-core`、`execution-order`、以及本 PR 负责的 `verification-gates` rows，显式对齐 `OI-035` / `OI-036` / `OI-038`、`OI-039` / `OI-040` / `OI-042`、以及 `OI-045` / `OI-048` 的 core-consumer 部分，写入 landed/partial 状态与证据路径

Out of scope:
- `query_atoms` 消费迁移 / QueryAtomsInvoker（PR-0413 feature 层）
- Tasks/Calendar/Notes/Entry controller 适配（PR-0413）
- 旧 FFI 移除（PR-0413）
- Explorer UI 变更 / 内部分层（PR-0413）
- 直接发布或改写 `DI-15` active bundle 的 ADR / ruling / `docs/architecture/adr/topic-map.md`

## Design

### TreeMutationDelta 结构（DI-17 Q2）

```dart
class TreeMutationDelta {
  final int revision;
  final TreeMutationType type;
  final Set<String?> affectedParentIds; // null = root level

  const TreeMutationDelta({
    required this.revision,
    required this.type,
    required this.affectedParentIds,
  });
}

enum TreeMutationType { create, rename, move, delete, reassign }
```

**affectedParentIds 映射规则：**

| 操作 | affectedParentIds | 说明 |
|------|-------------------|------|
| createFolder(parent) | `{parent}` | 新节点出现在 parent 子列表 |
| renameNode(node) | `{node.parent}` | parent 子列表中某项名称变化 |
| moveNode(old, new) | `{oldParent, newParent}` | Set 自动去重（同 parent 内移动 → 单元素） |
| deleteFolder(node) | `{node.parent}` | 节点从 parent 子列表消失 |
| reassignDesignated | `{oldFolder.parent, newFolder.parent}` | 两个 parent 受影响 |

### 系统节点解析 API

```dart
/// 启动时调用一次，缓存 designated role → node UUID 映射
Future<void> loadSystemNodes(String workspaceId);

/// 同步 getter，返回指定 role 的 node UUID
/// 抛出 DesignatedRoleNotFoundException（不返回 null）
String getSystemNodeId(String workspaceId, String role);
```

**缓存结构**：`Map<(String workspaceId, String role), String nodeUUID>`
**FFI 调用**：每个 role 调用 `workspace_resolve_designated(workspaceId, role)`（PR-0411 导出）
**幂等性**：同一 workspaceId 二次调用为 no-op（early return）

### FFI 适配模式

所有 FFI invoker 通过构造函数注入（现有模式），新增：

```dart
typedef WorkspaceResolveDesignatedInvoker =
    Future<WorkspaceNodeResponse> Function({
      required String workspaceId,
      required String role,
    });
```

PR-0412 不新增 FFI 函数——仅消费 PR-0411 已导出的函数。

### reassignDesignated 流程

1. Controller 调用 `reassignDesignated(workspaceId, role, newFolderId)`
2. FFI 调用 `workspace_reassign_designated` → Rust 更新 designated_folders
3. 本地缓存更新：`_systemNodeIds[(ws, role)] = newFolderId`
4. 构建 delta：`affectedParentIds = {oldFolder.parent, newFolder.parent}`
5. `notifyListeners()` → 消费者读 `lastMutation` 做定向刷新

### 通知策略

- WorkspaceTreeService extends `ChangeNotifier`
- 每次成功 mutation 后写入 `_lastMutation` + `notifyListeners()`
- 消费者通过 `lastMutation.affectedParentIds` 过滤已展开文件夹，只刷新受影响的
- Delta 是优化提示，非强保证——消费者可回退到全量刷新

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Dart | TreeMutationDelta 类型定义 | `apps/lazynote_flutter/lib/core/workspace/workspace_tree_types.dart` | TBD | — |
| T2 | Dart | `loadSystemNodes` / `getSystemNodeId` | `apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart` | TBD | — |
| T3 | Dart | WorkspaceTreeService 对接新 FFI | `apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart` | TBD | T1-T2 |
| T4 | Dart | `reassignDesignated` + 本地映射刷新 | `apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart` | TBD | T2-T3 |
| T5 | Dart | delta 载荷测试（create/move/delete/reassign affectedParentIds 断言） | `apps/lazynote_flutter/test/core/workspace/workspace_tree_service_test.dart` | TBD | T1-T4 |
| T6 | Dart | loadSystemNodes 成功/失败 + getSystemNodeId 正常/异常测试 | `apps/lazynote_flutter/test/core/workspace/workspace_tree_service_test.dart` | TBD | T2 |

## Planned File Changes

- `[edit]` apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart (对接新 FFI + 系统节点接口)
- `[edit]` apps/lazynote_flutter/lib/core/workspace/workspace_tree_types.dart (加 TreeMutationDelta + TreeMutationType + WorkspaceResolveDesignatedInvoker + 异常类)
- `[add]` apps/lazynote_flutter/test/core/workspace/workspace_tree_service_test.dart

## Verification

### CI gates

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

### Structural verification

```bash
# 验证 TreeMutationDelta 类定义
grep -rn "^class TreeMutationDelta" apps/lazynote_flutter/lib/ --include="*.dart"
# 预期：1 匹配

# 验证 TreeMutationType enum 定义
grep -rn "^enum TreeMutationType" apps/lazynote_flutter/lib/ --include="*.dart"
# 预期：1 匹配

# 验证 TreeMutationDelta 实例化（各 mutation 类型至少一次）
grep -rn "TreeMutationDelta(" apps/lazynote_flutter/lib/ --include="*.dart"
# 预期：至少 4 匹配（create/move/delete/reassign）

# 验证系统节点接口定义
grep -rn "loadSystemNodes\|getSystemNodeId" apps/lazynote_flutter/lib/ --include="*.dart"
# 预期：方法定义 + 至少一处调用

# 验证 delta 载荷测试覆盖
grep -rn "affectedParentIds" apps/lazynote_flutter/test/ --include="*.dart"
# 预期：至少 4 匹配（create/move/delete/reassign 各一）

# 验证异常类定义
grep -rn "DesignatedRoleNotFoundException\|WorkspaceInitException" apps/lazynote_flutter/lib/ --include="*.dart"
# 预期：至少 2 匹配（类定义）
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 新旧 FFI 路径共存期间状态不一致 | LOW | PR-0412 对接新 FFI，旧路径仍在但不被 WorkspaceTreeService 使用 |
| loadSystemNodes 在 FFI 失败时 UI 无法启动 | MEDIUM | 测试覆盖成功/失败路径，失败时有明确错误处理 |

## Acceptance Criteria

- [ ] WorkspaceTreeService 对接新 FFI 函数
- [ ] TreeMutationDelta 通知包含 `affectedParentIds`
- [ ] delta 载荷测试：create 操作断言 `affectedParentIds` 正确
- [ ] delta 载荷测试：move 操作断言 `affectedParentIds` 正确
- [ ] delta 载荷测试：delete 操作断言 `affectedParentIds` 正确
- [ ] delta 载荷测试：reassign_designated 操作断言 `affectedParentIds` 正确
- [ ] `loadSystemNodes` 成功返回系统节点信息
- [ ] `loadSystemNodes` 失败时抛出明确异常
- [ ] `getSystemNodeId` 正常返回指定 designated folder 的 node ID
- [ ] `reassignDesignated` 成功后本地系统节点映射已刷新
- [ ] `flutter analyze` 零 warning
- [ ] `flutter test` 全绿
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `flutter-core` row 已更新为本 PR 的实际落地状态并附证据路径，且已显式覆盖 `OI-039` / `OI-040` / `OI-042`
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `execution-order` row 已更新为本 PR 的实际顺序与依赖落地状态并附证据路径
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `verification-gates` row 已写明本 PR 覆盖的 Flutter core 测试部分与证据路径
- [ ] 本 PR 未直接发布或改写 `DI-15` active bundle 的 ADR / ruling / `topic-map.md`
- [ ] PR spec Status updated to Merged
