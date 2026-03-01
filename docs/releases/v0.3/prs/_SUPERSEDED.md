# v0.3 旧 PR Spec 失效声明

> 自 `v0.3-pr-spec-rebaseline-2026-03-01.md` 起，本目录下以 `PR-03XX` 编号的 spec 文件**不再作为执行依据**。

## 原因

DI-0 至 DI-7 的设计讨论裁决从根本上改变了 v0.3 的架构结构：

- DI-1 裁决 EditorShellService 统一布局和编辑器状态 → 原 Track A/B 不可分离
- DI-6 裁决三 Track 并行模型失效 → 替换为 PR-RB-XX 重排序列

原六个核心 PR（PR-0301 ~ PR-0305）坍缩为 PR-RB-06 + PR-RB-07 + PR-RB-08 + PR-RB-09，并新增语义阶段（PR-RB-00 ~ PR-RB-05）和收口阶段（PR-RB-10 ~ PR-RB-11）。

## 失效文件

| 旧 PR | 旧目标 | 替代 |
|-------|--------|------|
| PR-0301 | 递归布局树 | PR-RB-06（GroupLayout 是 EditorShellService 内部组件） |
| PR-0302 | drag-to-split | PR-RB-06（splitGroup 是 Service API） |
| PR-0303 | 跨 pane buffer 同步 | PR-RB-08（EditBuffer 状态机） |
| PR-0304 | tab 模型 | PR-RB-06（EditorGroupModel 是 Service 内部组件） |
| PR-0305 | 渲染性能 | PR-RB-08（DI-4 SLA 验证） |
| PR-0306 | workspace 可靠性 | 部分覆盖于 PR-RB-05（core-workspace） |
| PR-0306A | 链接索引 | 延期评估 |
| PR-0307 | launcher | 延期评估 |
| PR-0308 | 本地投影 | 部分覆盖于 PR-RB-03/04 |
| PR-0309 | Google Calendar | 延期到 v0.4（DI-8 DEFERRED） |
| PR-0310 | 命令解析插件 | 延期评估 |
| PR-0311 | 全局热键 | 延期评估 |

## 权威执行方案

- **PR 序列**：[v0.3-pr-spec-rebaseline-2026-03-01.md](../../v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md)
- **新 PR specs**：本目录下 `PR-RB-XX-*.md` 文件

## 保留原因

旧文件保留以维护设计推演的历史链条。不删除，但不执行。
