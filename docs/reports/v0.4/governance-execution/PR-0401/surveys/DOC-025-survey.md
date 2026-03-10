# DOC-025 Survey

- Source: `docs/reports/v0.3/design-discussions/DI-17-flutter-thin-client.md`
- Title: `DI-17: Flutter 薄客户端与 Feature 消费适配`
- Doc Class: Design discussion
- Corpus Role: Design discussion source

## Structure Snapshot

- The document is `RESOLVED`, but it is still a historical design-discussion source rather than a current-effective ruling carrier.
- There are three anchor layers in this source:
  - framing anchors (`背景`, `输入约束`, `讨论边界`)
  - parent question anchors (`Q1-Q6`)
  - lower execution anchors carried by `Q* 裁决`, numbered execution rules, and stable bold labels such as `WorkspaceTreeService 职责边界`, `TreeMutationDelta 结构`, and `Q6.1 workspace_tree_children_loader.dart`
- The parent `Q*` headings still matter because they preserve option space and problem framing; extraction should not collapse straight to the lower rule bullets only.
- `DI-17` is the downstream landing zone for `DI-14` and `DI-16`, so the survey should preserve both the handoff boundaries and the Flutter-side implementation constraints.

## Candidate DN Anchors

- `## 背景`
- `### 输入约束`
- `## 讨论边界 / ### In Scope`
- `## 讨论边界 / ### Out of Scope`
- `## 待裁决问题（Q1-Q6） / ### Q1. WorkspaceTreeService 的设计形态？`
- `## 待裁决问题（Q1-Q6） / #### Q1 裁决：B+（FFI 薄包装 + ChangeNotifier + revision，不含缓存）`
- `## 待裁决问题（Q1-Q6） / #### Q1 裁决：B+（FFI 薄包装 + ChangeNotifier + revision，不含缓存） / **WorkspaceTreeService 职责边界**`
- `## 待裁决问题（Q1-Q6） / #### Q1 裁决：B+（FFI 薄包装 + ChangeNotifier + revision，不含缓存） / **Feature 侧缓存规则**`
- `## 待裁决问题（Q1-Q6） / #### Q1 裁决：B+（FFI 薄包装 + ChangeNotifier + revision，不含缓存） / **升级口**`
- `## 待裁决问题（Q1-Q6） / ### Q2. 变更通知策略？（继承自 DI-14 Q3）`
- `## 待裁决问题（Q1-Q6） / #### Q2 裁决：A+delta（全局 ChangeNotifier + TreeMutationDelta 变更提示）`
- `## 待裁决问题（Q1-Q6） / #### Q2 裁决：A+delta（全局 ChangeNotifier + TreeMutationDelta 变更提示） / **TreeMutationDelta 结构**`
- `## 待裁决问题（Q1-Q6） / #### Q2 裁决：A+delta（全局 ChangeNotifier + TreeMutationDelta 变更提示） / **各 mutation 的 affectedParentIds**`
- `## 待裁决问题（Q1-Q6） / #### Q2 裁决：A+delta（全局 ChangeNotifier + TreeMutationDelta 变更提示） / **消费侧模式**`
- `## 待裁决问题（Q1-Q6） / ### Q3. 树 UI 组件的共享层级？（继承自 DI-14 Q4）`
- `## 待裁决问题（Q1-Q6） / #### Q3 裁决：A+/B-（不提取，但内部分层 + 量化触发条件）`
- `## 待裁决问题（Q1-Q6） / #### Q3 裁决：A+/B-（不提取，但内部分层 + 量化触发条件） / 1. 内部分层`
- `## 待裁决问题（Q1-Q6） / #### Q3 裁决：A+/B-（不提取，但内部分层 + 量化触发条件） / 2. 反向耦合禁止`
- `## 待裁决问题（Q1-Q6） / #### Q3 裁决：A+/B-（不提取，但内部分层 + 量化触发条件） / 3. 提取触发条件`
- `## 待裁决问题（Q1-Q6） / #### Q3 裁决：A+/B-（不提取，但内部分层 + 量化触发条件） / **Rule E 兼容**`
- `## 待裁决问题（Q1-Q6） / ### Q4. 系统节点解析的 Flutter 侧归属？（继承自 DI-14 Q5）`
- `## 待裁决问题（Q1-Q6） / #### Q4 裁决：A（WorkspaceTreeService 内部解析，同步 getter）`
- `## 待裁决问题（Q1-Q6） / #### Q4 裁决：A（WorkspaceTreeService 内部解析，同步 getter） / 1. 缓存键 = workspace_id + role`
- `## 待裁决问题（Q1-Q6） / #### Q4 裁决：A（WorkspaceTreeService 内部解析，同步 getter） / 2. reassign_designated 后必须刷新映射`
- `## 待裁决问题（Q1-Q6） / #### Q4 裁决：A（WorkspaceTreeService 内部解析，同步 getter） / 3. 失败返回明确错误`
- `## 待裁决问题（Q1-Q6） / #### Q4 裁决：A（WorkspaceTreeService 内部解析，同步 getter） / **具体设计**`
- `## 待裁决问题（Q1-Q6） / #### Q4 裁决：A（WorkspaceTreeService 内部解析，同步 getter） / **加载时机**`
- `## 待裁决问题（Q1-Q6） / #### Q4 裁决：A（WorkspaceTreeService 内部解析，同步 getter） / **消费侧**`
- `## 待裁决问题（Q1-Q6） / ### Q5. Tasks/Calendar controller 适配？`
- `## 待裁决问题（Q1-Q6） / #### Q5 裁决：A+（Controller 内部替换数据源 + 共享 query helper）`
- `## 待裁决问题（Q1-Q6） / #### Q5 裁决：A+（Controller 内部替换数据源 + 共享 query helper） / 1. 保留 Controller 结构，只替换数据源`
- `## 待裁决问题（Q1-Q6） / #### Q5 裁决：A+（Controller 内部替换数据源 + 共享 query helper） / 2. ScopedAtomQuery 参数模板放共享 helper`
- `## 待裁决问题（Q1-Q6） / #### Q5 裁决：A+（Controller 内部替换数据源 + 共享 query helper） / 3. Controller 持有 WorkspaceTreeService 引用，每次查询前取 folder_id`
- `## 待裁决问题（Q1-Q6） / #### Q5 裁决：A+（Controller 内部替换数据源 + 共享 query helper） / 4. 一次性迁移，不维护旧 FFI 双轨`
- `## 待裁决问题（Q1-Q6） / #### Q5 裁决：A+（Controller 内部替换数据源 + 共享 query helper） / **Invoker 改造明细 / TasksController**`
- `## 待裁决问题（Q1-Q6） / #### Q5 裁决：A+（Controller 内部替换数据源 + 共享 query helper） / **Invoker 改造明细 / CalendarController**`
- `## 待裁决问题（Q1-Q6） / #### Q5 裁决：A+（Controller 内部替换数据源 + 共享 query helper） / **folder_id 获取方式**`
- `## 待裁决问题（Q1-Q6） / #### Q5 裁决：A+（Controller 内部替换数据源 + 共享 query helper） / **分组逻辑位置确认**`
- `## 待裁决问题（Q1-Q6） / ### Q6. Synthetic uncategorized 移除？`
- `## 待裁决问题（Q1-Q6） / #### Q6 裁决：全量删除 synthetic 逻辑，无运行时迁移提示`
- `## 待裁决问题（Q1-Q6） / #### Q6 裁决：全量删除 synthetic 逻辑，无运行时迁移提示 / **Q6.1 workspace_tree_children_loader.dart -> 删除整个文件**`
- `## 待裁决问题（Q1-Q6） / #### Q6 裁决：全量删除 synthetic 逻辑，无运行时迁移提示 / **Q6.2 其他文件清理**`
- `## 待裁决问题（Q1-Q6） / #### Q6 裁决：全量删除 synthetic 逻辑，无运行时迁移提示 / **Q6.3 数据迁移提示 -> 不需要运行时 UI**`
- `## 待裁决问题（Q1-Q6） / #### Q6 裁决：全量删除 synthetic 逻辑，无运行时迁移提示 / **测试策略**`

## Notes

- `Q3` is especially important for later governance because it connects UI extraction policy to DI-21 CI enforcement.
- `Q4-Q6` contain several execution-grade subcontracts that are not markdown headings but are still stable enough to be first-pass DN anchors.
- The header status and the design-discussions index disagree on this document; survey follows the actual file header and clause surface inside the source file.
