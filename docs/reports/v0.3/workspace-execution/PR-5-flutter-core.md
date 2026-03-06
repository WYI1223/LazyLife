# PR-5: Flutter Core — WorkspaceTreeService B+ 改造

- Proposed title: `feat(workspace): workspace tree service enhancement with mutation delta`
- Status: Draft

## Goal

改造 WorkspaceTreeService 对接新 tree FFI（`workspace_resolve_designated`、`workspace_reassign_designated` 等树操作），引入 TreeMutationDelta 变更通知机制，新增 `loadSystemNodes` / `getSystemNodeId` 系统节点接口。`query_atoms` 消费迁移属于 PR-6（feature 层）。

前置条件：PR-4（需要新 FFI 函数就绪）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-17-flutter-thin-client.md` Q1-Q4 | WorkspaceTreeService B+ 改造、TreeMutationDelta、系统节点解析 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` Q1（PR-5 行）、Q4（Flutter 测试 + delta 载荷断言） | PR 定位、测试要求 |
| 现有实现 | `apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart` | 需改造的目标文件 |
| 现有实现 | `apps/lazynote_flutter/lib/core/workspace/workspace_tree_types.dart` | 需扩展（加 TreeMutationDelta） |

## Scope

In scope:
- WorkspaceTreeService 对接新 tree FFI（`workspace_resolve_designated`、`workspace_reassign_designated` 等树操作接口）
- TreeMutationDelta 通知机制（`affectedParentIds` 供定向刷新）
- `loadSystemNodes` / `getSystemNodeId` 系统节点接口
- `reassignDesignated` 成功后刷新本地系统节点映射（DI-17 Q2）
- Mock invoker 测试

Out of scope:
- `query_atoms` 消费迁移 / QueryAtomsInvoker（PR-6 feature 层）
- Tasks/Calendar/Notes/Entry controller 适配（PR-6）
- 旧 FFI 移除（PR-6）
- Explorer UI 变更 / 内部分层（PR-6）

## Design

TBD — kickoff 阶段细化。参考 DI-17 Q1-Q4。

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Dart | TreeMutationDelta 类型定义 | `apps/lazynote_flutter/lib/core/workspace/workspace_tree_types.dart` | TBD | — |
| T2 | Dart | `loadSystemNodes` / `getSystemNodeId` | `apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart` | TBD | — |
| T3 | Dart | WorkspaceTreeService 对接新 FFI | `apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart` | TBD | T1-T2 |
| T4 | Dart | `reassignDesignated` + 本地映射刷新 | `apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart` | TBD | T2-T3 |
| T5 | Dart | delta 载荷测试（affectedParentIds 断言） | `apps/lazynote_flutter/test/` | TBD | T1-T4 |
| T6 | Dart | loadSystemNodes 成功/失败测试 | `apps/lazynote_flutter/test/` | TBD | T2 |

## Planned File Changes

- `[edit]` apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart (对接新 FFI + 系统节点接口)
- `[edit]` apps/lazynote_flutter/lib/core/workspace/workspace_tree_types.dart (加 TreeMutationDelta)
- `[add]` apps/lazynote_flutter/test/core/workspace/workspace_tree_service_test.dart (或合入现有测试文件)

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
# 验证 TreeMutationDelta 类型存在
grep -rn "TreeMutationDelta" apps/lazynote_flutter/lib/ --include="*.dart"
# 预期：类定义 + 至少一处使用

# 验证系统节点接口
grep -rn "loadSystemNodes\|getSystemNodeId" apps/lazynote_flutter/lib/ --include="*.dart"
# 预期：方法定义 + 至少一处调用

# 验证 delta 载荷测试
grep -rn "affectedParentIds" apps/lazynote_flutter/test/ --include="*.dart"
# 预期：至少 4 匹配（create/move/delete/reassign 各一）
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 新旧 FFI 路径共存期间状态不一致 | LOW | PR-5 对接新 FFI，旧路径仍在但不被 WorkspaceTreeService 使用 |
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
- [ ] PR spec Status updated to Merged
