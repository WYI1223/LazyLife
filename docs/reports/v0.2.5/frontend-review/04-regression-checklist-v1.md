# 回归清单 v1（PR-0252 P0-2）

## 0. 文档信息

| 项目 | 值 |
|------|-----|
| 文档路径 | `docs/reports/v0.2.5/frontend-review/04-regression-checklist-v1.md` |
| 关联任务 | `PR-0252 / P0-2` |
| 基线来源 | `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 5.2A |
| 适用范围 | `PR-0252` Phase 0–3 阶段级手工回归 |
| 测试基线 | `flutter test` 313 pass / 0 known-fail |
| 版本 | v1 |
| 更新日期 | 2026-02-24 |

## 1. 执行规则

- 阶段级回归必须覆盖 REG-01 ~ REG-10 全量用例。
- 执行时机：Phase 0/1/2/3 各阶段结束时。
- 记录要求：每个用例必须落地 `通过/失败` 结果，失败项必须绑定缺陷链接。
- 专项增量（HF-XX）不在本清单内，按 `03-phased-refactor-plan.md` Section 5.2B 叠加执行。

## 2. 核心回归用例（REG-01 ~ REG-10）

| 用例 ID | 用例名称 | 关联模块 | 操作步骤 | 通过标准 |
|---------|---------|---------|---------|---------|
| REG-01 | 创建笔记并自动选中 | NotesController/Coordinator | 1. 点击创建按钮 2. 观察笔记列表 3. 观察编辑器 | 新笔记出现在列表顶部；编辑器自动聚焦；Tab 栏新增条目 |
| REG-02 | 编辑笔记内容触发自动保存 | NoteDraftManager | 1. 选中一条笔记 2. 输入内容 3. 等待自动保存 | 保存状态依次经过 dirty → saving → saved；badge 短暂显示后消失 |
| REG-03 | 手动切换笔记触发保存守卫 | NoteTabManager + NoteDraftManager | 1. 编辑笔记 A 2. 切换到笔记 B 3. 观察保存状态 | 笔记 A 内容已保存后才切换到 B；B 的内容正确加载 |
| REG-04 | 标签创建与筛选 | NoteTagManager | 1. 为笔记添加标签 2. 激活标签筛选 3. 清除筛选 | 标签正确显示；筛选后列表仅含匹配项；清除后恢复全列表 |
| REG-05 | 工作区创建文件夹 | WorkspaceTreeManager | 1. 在 Explorer 中右键 2. 创建文件夹 3. 观察树更新 | 文件夹出现在树中正确位置；Explorer 自动刷新 |
| REG-06 | 工作区拖拽移动笔记 | WorkspaceTreeManager | 1. 拖拽笔记到文件夹 2. 观察树更新 | 笔记移入目标文件夹；原位置消失；树结构正确 |
| REG-07 | 工作区删除文件夹（dissolve） | WorkspaceTreeManager | 1. 右键删除文件夹 2. 选择 dissolve 模式 | 文件夹消失；子项上移到父级；Tab 中打开的笔记不受影响 |
| REG-08 | 搜索笔记并打开 | SingleEntryController | 1. 在搜索栏输入关键词 2. 点击搜索结果 | 搜索结果正确展示；点击后在编辑器中打开对应笔记 |
| REG-09 | 窗口关闭保存守卫 | NotesPage + NoteDraftManager | 1. 编辑未保存笔记 2. 尝试关闭窗口 | 弹出保存确认对话框；确认后保存并关闭；取消后留在编辑器 |
| REG-10 | Section 导航往返 | EntryShellPage | 1. 从 Home 进入 Notes 2. 切换到 Tasks 3. 返回 Notes | 各 section 正确渲染；返回 Notes 后状态保持（Tab、列表、编辑器） |

## 3. 阶段执行记录

| 阶段 | 执行日期 | 执行人 | 结果汇总 | 缺陷链接 |
|------|---------|--------|---------|---------|
| Phase 0 | 待执行 | 待填写 | 待填写 | - |
| Phase 1 | 待执行 | 待填写 | 待填写 | - |
| Phase 2 | 待执行 | 待填写 | 待填写 | - |
| Phase 3 | 待执行 | 待填写 | 待填写 | - |

## 4. 用例结果记录模板

| 用例 ID | 结果（通过/失败） | 备注 | 缺陷链接 |
|---------|------------------|------|---------|
| REG-01 | 待执行 | - | - |
| REG-02 | 待执行 | - | - |
| REG-03 | 待执行 | - | - |
| REG-04 | 待执行 | - | - |
| REG-05 | 待执行 | - | - |
| REG-06 | 待执行 | - | - |
| REG-07 | 待执行 | - | - |
| REG-08 | 待执行 | - | - |
| REG-09 | 待执行 | - | - |
| REG-10 | 待执行 | - | - |

## 5. 关联自动化检查

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```
