## TODO: Link & Workspace Launcher (local paths + web links)

## Release/PR Mapping (2026-02-14)

* [x] `v0.2 / PR-0212-links-index-open-v1`:
  * [x] P0 syntax baseline (Markdown links + supported target types)
  * [x] P0 data model/index + query API
  * [x] P0 safe open baseline (`http/https/file`, Windows first)
  * [x] P1 partial UI baseline (link list/search/open entry)
* [x] `v0.3 / PR-0307-workspace-launcher-experience`:
  * [x] P1 Workspace Launcher + `Open All` + safety cap + ordering
  * [x] P1 Single Entry bridge (`> open`, `> workspace`)
* [ ] `v1.0 / PR-1006-links-launcher-cross-platform-and-whitelist`:
  * [ ] P2 cross-platform parity (`open`/`xdg-open`)
  * [ ] P2 optional scheme whitelist hardening

Notes:

* P2 link health checks and export/import linkage are backlog candidates by default, unless pulled into a later release scope.

### P0 — 需求与语法设计

* [ ] 定义支持的链接类型（v1）

  * [ ] `folder`：本地目录（Windows 路径 / `file://`）
  * [ ] `file`：本地文件（同上）
  * [ ] `url`：网页链接（http/https）
* [ ] 定义笔记内的引用语法（选一种并写进文档）

  * [ ] 方案 A：纯 Markdown 链接（推荐）`[label](file:///C:/Work)` / `[label](https://...)`
  * [ ] 方案 B：自动识别裸路径/裸 URL（增强）
  * [ ] 方案 C：自定义标记（可选）如 `@open(C:\Work)`（后续再做）
* [ ] 写一页设计说明（英文 canonical）：`docs/architecture/links-and-launcher.md`

  * [ ] 链接解析规则、支持范围
  * [ ] 安全/隐私边界：不执行命令，只“打开”资源

### P0 — 数据模型与索引（Rust core）

* [ ] 增加 `links` 表（或等价结构）

  * [ ] 字段建议：`id, atom_id, type, target, label, created_at, updated_at`
  * [ ] 对 `(atom_id)`、`(type, target)` 建索引
* [ ] 在笔记保存/更新时提取链接（解析器）

  * [ ] 解析 Markdown link 中的 `file:///` 与 `http(s)://`
  * [ ] （可选）识别裸 URL
  * [ ] （可选）识别裸 Windows 路径（注意空格/转义）
* [ ] 提供查询 API：`list_links(atom_id)` / `search_links(query)`

### P0 — 打开链接能力（Windows 优先）

* [ ] 在 Rust core 或 Flutter 侧定义“打开链接”的统一用例（推荐做成 use-case）

  * [ ] `open_link(link_id)` 或 `open_target(type, target)`
* [ ] Windows 实现：

  * [ ] 目录：用系统默认方式打开（Explorer）
  * [ ] 文件：交给系统默认程序打开
  * [ ] URL：默认浏览器打开
* [ ] 安全校验（必须做）

  * [ ] 只允许 `http/https/file`（拒绝 `cmd://`、`powershell:` 等危险 scheme）
  * [ ] `file://` 解析后必须是本地绝对路径（拒绝奇怪的相对/注入）
  * [ ] 失败时返回可读错误（路径不存在/权限不足/格式错误）

### P1 — Flutter UI 渲染与交互

* [ ] 笔记详情页：渲染“链接块/快捷入口块”

  * [ ] 展示 label + target（可折叠）
  * [ ] 单击打开
  * [ ] 右键菜单：复制路径/复制链接/在资源管理器中显示（文件）
* [ ] 统一入口命令（可选但很好用）

  * [ ] `> open <keyword>`：从链接索引里搜索并打开
  * [ ] `> reveal <file>`：在 Explorer 中定位

### P1 — “快速进入工作环境”（Workspace Launcher）

* [ ] 定义 Workspace：一条笔记/一个区块代表一个“工作环境”

  * [ ] 最小实现：同一条笔记内有一组 links，提供 “Open All” 按钮
* [ ] 打开策略（避免炸窗口）

  * [ ] 打开前确认：将打开 N 个资源
  * [ ] 限制最大数量（例如默认 10，可配置）
  * [ ] 打开顺序：先目录→再网页（可配置）
* [ ] 入口支持：在统一入口里 `> workspace <name>` 一键打开该组

### P2 — 跨平台与高级能力（后续）

* [ ] macOS/Linux：对齐 `open` / `xdg-open` 行为
* [ ] 支持更多 scheme（可选、谨慎）

  * [ ] `vscode://file/...`（打开工程）
  * [ ] `obsidian://`、`notion://` 等第三方（需白名单机制）
* [ ] 链接健康检查（可选）

  * [ ] 路径是否存在、URL 是否可访问（只提示，不自动访问私密资源）
* [ ] 导出/导入支持

  * [ ] 导出时保留链接（Markdown 原样即可）
  * [ ] 导入时重建 links 索引

### P0/P1 — 测试与日志（建议同时做）

* [ ] 单元测试：链接解析器（各种边界输入）
* [ ] 集成测试：保存笔记→links 表更新一致
* [ ] 日志：记录 “open_link” 事件（只记录类型、是否成功、耗时；不记录用户文本）

---

如果你愿意，我也可以顺手帮你把 **链接语法**拍板成一个最稳的 v1（我倾向“先用纯 Markdown + file:/// + http(s)”），并给你一份 `links` 表的最小 migration 草案，方便你后面直接开写。
