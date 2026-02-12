## PR 0～2：先把仓库“能跑、能测、能生成”

这些 PR 合并后，你就能在本仓库里 `flutter run -d windows`，并能从 Flutter 调到 Rust（替换 smoke test）。

### PR0 — `chore(repo): scaffold monorepo skeleton`

**目标**：按 README 的“计划目录”把骨架建好（apps/crates/docs/server/workflows）。
**交付**：

* `apps/lazynote_flutter/`（用 `flutter create --platforms=windows`）
* `crates/{lazynote_core,lazynote_ffi,lazynote_cli}/`（Cargo workspace）
* `docs/{architecture,product,compliance}/`
* `.github/workflows/ci.yml`（先留空也行）

### PR1 — `chore(devex): add Windows dev docs + doctor scripts`

**目标**：把你刚验证通过的环境写成“新人一键自检”。
**交付**：

* `docs/development/windows.md`（写明：Flutter 3.41 / Rust 1.93 / FRB 2.11.1；Android 可选）
* `scripts/doctor.ps1`：输出 `flutter --version / doctor / rustc -V / cargo -V / frb_codegen --version`
* `.gitattributes`（建议强制 `*.rs text eol=lf`，减少 CRLF 踩坑）

### PR2 — `chore(ci): add CI for flutter+rusta (windows + ubuntu)`

**目标**：保证每个 PR 都不会把 Windows 端编译打坏。
**交付（最小）**：

* Windows job：`flutter pub get` + `flutter test` + `flutter build windows --debug`
* Rust job：`cargo fmt --check` + `cargo clippy -- -D warnings` + `cargo test`

---

## PR 3～5：把 FRB “真正接入 Lazynote”

### PR3 — `chore(frb): wire lazynote_core <-> lazynote_flutter`

**目标**：把 smoke test 的成功迁移到 monorepo：Flutter 能调用 Rust，Rust 能返回数据。
**交付**：

* `crates/lazynote_ffi`：FRB bridge + codegen 脚本（`scripts/gen_bindings.ps1`）
* Flutter 端集成生成的 Dart bindings
* 最小 API：`core.ping()` / `core.version()`（用于自检）

### PR4 — `core(model): define Atom model + IDs + soft delete`

**目标**：把 README 的统一 Atom 模型落到 Rust 代码里：Note/Task/Event 同源投影。
**交付**：

* `Atom { uuid, type, content, task_status, event_start/end, hlc_timestamp?, is_deleted }`
* 先不必做 CRDT/HLC（字段预留即可），v0.1 先跑通 CRUD

### PR5 — `core(db): sqlite schema + migrations + open_db()`

**目标**：SQLite 成为权威存储 + 可迁移。
**交付（建议最小表）**：

* `atoms`（核心）
* `tags` / `atom_tags`（标签）
* `external_mappings`（给 GCal 用：eventId ↔ atomId，或 extendedProperties 反查缓存）
* migration 机制（哪怕是手写 SQL 文件 + 版本号也行）

---

## PR 6～10：先把 Windows 端“能记、能搜、能改”跑通（v0.1 主闭环）

### PR6 — `core(repo): Atom CRUD + basic queries`

**目标**：Rust core 提供稳定的增删改查（含软删除）。
**交付**：

* `create_atom / update_atom / get_atom / list_atoms / soft_delete_atom`

### PR7 — `core(search): FTS5 full-text index + search_all()`

**目标**：实现“即输即得”的全文检索（v0.1 的核心体验）。
**交付**：

* `atoms_fts`（FTS5）+ 触发器/手动更新策略（二选一）
* `search(query) -> [AtomSummary]`

### PR8 — `ui(shell): Windows app shell + window behavior`

**目标**：Windows 端先跑顺 + 为后续“统一入口窗口”打底。
**交付**：

* 基础壳：启动页 + 顶部单输入框占位
* Windows 侧窗口配置（最小尺寸、记忆位置可后置）

### PR9 — `ui(entry): single entry (search + command router)`

**目标**：统一入口：同一输入框既能搜索也能执行命令。
**交付**（最小命令集，来自 README 示例）：

* `> new note ...`
* `> task ... #tag`
* `> schedule ...`（先只解析“明确时间”就行）
* 普通输入：走 `search_all`

### PR10 — `ui(notes+tags): markdown editor + tag filter`

**目标**：笔记 v0.1：Markdown 编辑、标签/层级、全文检索。
**交付**：

* 笔记列表 + 详情编辑（Markdown 文本框先够用）
* 标签筛选（层级可先用“文件夹=tag”简化）

---

## PR 11～14：任务/日历/提醒（Windows 先做最小）

### PR11 — `ui(tasks): Inbox/Today/Upcoming + complete toggle`

**目标**：任务三视图 + 完成切换。

### PR12 — `ui(calendar): day/week view (minimal) + schedule task`

**目标**：最小日历视图（先周或日其一），并支持把任务写入 `event_start/end`。

### PR13 — `feat(reminders): local notifications on Windows`

**目标**：本地提醒（Windows 也要能弹通知）。
**建议实现**：直接用 `flutter_local_notifications`（它有 Windows 实现包）。([Dart packages][1])
（v0.1 先支持“一次性提醒”，重复规则可后置。）

### PR14 — `feat(windows): global hotkey + quick entry window`

**目标**：Windows 端无边框悬浮窗口 + 全局热键唤醒（文档第一阶段交付物）。

> 系统托盘、多窗口弹出是很好的增强项，可以放

---

## PR 15～16：v0.1 的“合规gcal): OAuth + incremental syncToken + extendedProperties mapping`

**目标**：Google Calendar 事件级双向同步（v0.1 必做）。
**Windows 上建议路线**（先不拍死一种推荐的 `googleapis` + `googleapis_auth`（更偏“Google API 访问”而非“登录态 UI”）。([Flutter Docs][2])

* 或使用能覆盖桌面端的 Google Sign-In 方案（例如 `google_sign_in_all_platforms`）。([Dart packages][3])
  同时要按你文档写的要点做：`syncToken` 增量同步 + `extended properties` 存内部 ID。 

### PR16 — `feat(export): export/import Markdown + JSON + ICS`

**目标**：避免锁定，支持整库备份与恢复（v0.1 必做）。？顺序做 **PR0 → PR1 → PR3**：

* PR0/1 把仓库和 DevEx 固化；
* PR3 把“能调 Rust”嵌入 Lazynote（之后所有 core 工作都能直接3` 或截图）贴一下，我可以把上面的清单进一步**落到“每个 PR 要新增/修改哪些具体文件路径”**，保证你按单施工不会走歪。

[1]: https://pub.dev/packages/flutter_local_notifications?utm_source=chatgpt.com "flutter_local_notifications | Flutter package"
[2]: https://docs.flutter.dev/data-and-backend/google-apis?utm_source=chatgpt.com "Google APIs"
[3]: https://pub.dev/packages/google_sign_in_all_platforms?utm_source=chatgpt.com "google_sign_in_all_platforms | Flutter package"
