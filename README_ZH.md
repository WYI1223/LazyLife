# LazyNote

> 一个极简、本地优先的个人效率系统。
> 笔记、任务与日程，收敛到同一个入口。

**[English →](README.md)**

文档入口：**[docs/index.md](docs/index.md)**

---

## 项目定位

LazyNote 聚焦三个核心价值：

- **单一入口（Single Entry）** — 统一搜索框 + 命令面板，所有核心动作可直达。
- **强联动（Strong Linkage）** — 笔记、任务、事件是同一数据图谱的不同视图。
- **低负担（Low Friction）** — 默认简单，按需增强。避免功能膨胀与认知负担。

这不是"功能最多"的生产力工具，而是"摩擦最小"的个人第二大脑。

---

## 设计原则

| 原则 | 说明 |
|------|------|
| **Local-First** | 数据默认保存在本地，离线可用，同步是可选能力 |
| **Privacy-First** | 最小权限，默认零遥测，无强制账号 |
| **One Input** | 统一入口优先于多页面跳转 |
| **Default Simple** | 复杂能力（图谱视图、语义检索等）按需启用，不作为默认 |
| **Cross-Platform by Design** | 架构从一开始面向 Windows / macOS / iOS / Android |

---

## 技术架构

```
┌───────────────────────────────────────────────┐
│               Flutter UI 层                    │
│  单一入口 · 笔记 · 任务 · 日历                  │
│  工作区树 · 诊断面板 · 设置                      │
└──────────────────────┬────────────────────────┘
                       │  Flutter-Rust Bridge（FRB / FFI）
┌──────────────────────▼────────────────────────┐
│               Rust Core 层                     │
│  领域模型 · 服务 · 数据仓库                      │
│  FTS5 全文搜索 · 迁移管理 · 日志                 │
│  扩展内核 · 同步 SPI（契约层）                    │
└──────────────────────┬────────────────────────┘
                       │
┌──────────────────────▼────────────────────────┐
│              本地数据层                         │
│  SQLite（atoms、tags、workspace tree、           │
│         external mappings）                     │
│  FTS5（全文检索虚拟表）                          │
└───────────────────────────────────────────────┘
```

Rust Core 是所有业务逻辑的单一数据源。Flutter 只负责 UI，全部数据操作通过 FFI 边界调用 Rust。FFI 层（`lazynote_ffi`）仅暴露用例级 API，绝不直接暴露数据库操作。

---

## 包结构

```
apps/
  lazynote_flutter/                  # Flutter 客户端（Windows 优先，多平台目标）
    lib/
      app/                           # 路由、Shell 编排、语言控制器、UI 插槽
      core/                          # RustBridge、FFI 绑定（自动生成）、设置、路径
      features/
        entry/                       # 单一入口搜索 + 命令面板
        notes/                       # 笔记列表、编辑器、资源管理器树、标签管理器
        tags/                        # 标签过滤组件
        search/                      # 搜索结果视图
        tasks/                       # 任务面板：Inbox / Today / Upcoming
        calendar/                    # 周历：侧边栏、周网格、事件块
        workspace/                   # 工作区树 Provider + 模型
        reminders/                   # 本地通知调度
        settings/                    # 扩展能力设置
        diagnostics/                 # Rust 健康检查面板 + 实时日志查看器
      l10n/                          # 本地化（英文 + 中文）

crates/
  lazynote_core/                     # 全部业务逻辑（Rust）
    src/
      model/atom.rs                  # 规范 Atom 实体、AtomType、TaskStatus
      db/                            # SQLite 启动 + 9 个版本化迁移
      repo/                          # 持久化 Trait + SQLite 实现
        atom_repo.rs                 # Atom CRUD、区段查询、状态更新
        note_repo.rs                 # 笔记 CRUD、标签归一化
        tree_repo.rs                 # 工作区树 CRUD
      service/                       # 用例编排
        atom_service.rs              # Atom 创建门面
        note_service.rs              # 笔记生命周期 + Markdown 预览
        task_service.rs              # 区段查询 + 状态管理
        tree_service.rs              # 工作区树（含环检测）
      search/fts.rs                  # FTS5 全文检索
      logging.rs                     # 结构化滚动日志
      extension/                     # 扩展内核契约（仅声明）
      sync/                          # 同步提供者 SPI 契约（仅声明）

  lazynote_ffi/                      # FFI 边界（薄包装层，不含逻辑）
    src/api.rs                       # 导出 FFI 函数 — 在此编辑
    src/frb_generated.rs             # 自动生成 — 禁止手动编辑

  lazynote_cli/                      # CLI 链接探针（极简）

docs/                                # 架构文档、API 契约、版本计划
scripts/                             # doctor.ps1、gen_bindings.ps1、format.ps1
tools/                               # CI 辅助、架构分析、Docker
server/relay/                        # 计划中的同步中继（骨架）
```

---

## 统一数据模型（Atom）

LazyNote 将笔记、任务、事件统一为同一个规范实体：**Atom**。

同一条记录可投影为 Note / Task / Event。`kind` 字段仅决定 UI 渲染形状；列表区块归属（Inbox / Today / Upcoming）由 `start_at`/`end_at` 的可空性决定，与 `kind` 无关。无需数据复制或迁移。

| 字段 | 类型 | 说明 |
|------|------|------|
| `uuid` | UUIDv4 | 全局稳定标识，绝不复用 |
| `kind` | `note \| task \| event` | 仅为渲染提示 — 不决定区块分类 |
| `content` | String | Markdown 正文 |
| `preview_text` | String? | 从 content 派生（首段纯文本，最长 100 字符） |
| `preview_image` | String? | 首个 Markdown 图片路径 |
| `task_status` | Enum? | `todo \| in_progress \| done \| cancelled`；NULL = 无状态 |
| `start_at` | i64? | 毫秒级 Epoch 时间戳 — 时间矩阵锚点 |
| `end_at` | i64? | 毫秒级 Epoch 时间戳；始终 >= `start_at` |
| `recurrence_rule` | String? | 保留字段：RFC 5545 RRULE 字符串 — 实现前为 NULL |
| `is_deleted` | bool | 软删除标记 — 对可见性具有权威性 |
| `hlc_timestamp` | String? | 为 CRDT 同步预留（暂未启用） |

**时间矩阵区段分类：**

| start_at | end_at | 区段 |
|----------|--------|------|
| NULL | NULL | Inbox |
| NULL | 有值 | Today（若已过期/当天）或 Upcoming |
| 有值 | NULL | Today（若已开始）或 Upcoming |
| 有值 | 有值 | Today（若与今天重叠）或 Upcoming |

`task_status` 为 `done` 或 `cancelled` 的 Atom 会从活跃区段中隐藏。

**工作区树：**

笔记通过层级树形结构组织，包含文件夹和笔记引用。每个 `WorkspaceNode` 有类型（Folder / NoteRef）、可选父节点和排序序号。树操作包括创建、重命名、移动（带环检测）和删除（子节点溶解到父级，或递归删除）。

**代码层强制执行的不变量：**
- `uuid` 永不为空
- 当 `start_at` 与 `end_at` 均存在时，`end_at >= start_at`
- 所有默认查询过滤 `WHERE is_deleted = 0`
- 仅允许软删除 — 禁止在功能代码中对 `atoms` 执行 `DELETE` 语句
- 标签始终小写化并去重

---

## 当前实现状态

| 功能 | 状态 |
|------|------|
| Atom 数据模型 + SQLite Schema（9 个迁移） | 已实现 |
| FTS5 全文检索 | 已实现 |
| 笔记 CRUD（通过 FFI） | 已实现 |
| 标签管理（创建、分配、过滤） | 已实现 |
| 单一入口搜索 + 命令面板 | 已实现 |
| 笔记编辑器（Markdown）+ 标签管理器 | 已实现 |
| 工作区树（文件夹、笔记引用、拖拽） | 已实现 |
| 任务引擎（Inbox/Today/Upcoming、状态切换） | 已实现 |
| 日历（周视图、创建/编辑事件） | 已实现 |
| 提醒（本地通知） | 已实现 |
| 本地化（英文 + 中文） | 已实现 |
| UI 扩展插槽系统 | 已实现 |
| 结构化日志 + 诊断面板 | 已实现 |
| Windows 构建 | 已实现 |
| 扩展内核（契约已定义） | 仅声明 |
| 同步提供者 SPI（契约已定义） | 仅声明 |
| Google Calendar 同步 | 计划中 |
| 导入 / 导出 | 计划中 |
| 移动端（iOS / Android） | 计划中 |
| CRDT / 多端同步 | 计划中 |

---

## 开发环境搭建

### 前置依赖

- Rust stable 工具链（见 `rust-toolchain.toml`）
- Flutter SDK（Dart >= 3.11）
- Windows SDK（Windows 构建所需）

### 快速验证

```powershell
# 在仓库根目录执行
./scripts/doctor.ps1
```

### 构建

```bash
# Rust（在 crates/ 目录下）
cargo build --all

# Flutter（在 apps/lazynote_flutter/ 目录下）
flutter pub get
flutter build windows --debug
```

### 测试

```bash
# Rust（在 crates/ 目录下）
cargo test --all

# Flutter（在 apps/lazynote_flutter/ 目录下）
flutter test
```

### 代码质量

```bash
# Rust
cargo fmt --all -- --check
cargo clippy --all -- -D warnings

# Flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
```

### 代码生成

修改 `crates/lazynote_ffi/src/api.rs` 后，必须重新生成 FFI 绑定：

```powershell
./scripts/gen_bindings.ps1
```

Windows 详细开发说明见 [docs/development/windows-quickstart.md](docs/development/windows-quickstart.md)。

---

## 运行时文件布局

Windows 下，LazyNote 的所有运行时文件存储在 `%APPDATA%\LazyLife\`：

```
%APPDATA%\LazyLife\
  settings.json               — 应用设置（日志级别、数据库路径、UI 语言）
  logs/                        — 滚动日志文件（7 天保留）
  data/
    lazynote_entry.sqlite3     — SQLite 数据库
```

macOS/iOS 下：`<app_support>/LazyLife/`，结构相同。

---

## 技术栈

| 层 | 技术 | 版本 |
|----|------|------|
| UI | Flutter | SDK |
| FFI 桥接 | Flutter-Rust Bridge | 2.11.1 |
| 核心逻辑 | Rust | stable |
| 数据库 | SQLite（rusqlite bundled） | 0.32 |
| 全文检索 | FTS5 | 内置于 SQLite |
| 日志 | flexi_logger | 0.29 |
| 通知 | flutter_local_notifications | 20.1.0 |
| 日历组件 | table_calendar | 3.1.0 |
| 窗口管理 | window_manager | 0.5.1 |

---

## 版本路线图

| 阶段 | 重点 |
|------|------|
| **v0.1** | 笔记 + 标签 + 全文检索 + 单一入口面板 |
| **v0.1.5** | Atom 时间矩阵 — Inbox/Today/Upcoming 任务视图 + 日历极简版 |
| **v0.2** | 工作区树、笔记资源管理器、扩展内核契约、同步 SPI 契约 |
| **v0.2.5** | 架构基线、代码健康分析 |
| **v0.3** | 高级布局、拖拽分屏、跨面板实时同步 |
| **v1.0** | 插件沙箱、iOS 发布、API 兼容性 CI 门控 |

v0.2 之后：Google Calendar 同步、导入/导出、移动端、CRDT 多端同步。

---

## 关键文档索引

| 文档 | 说明 |
|------|------|
| [docs/index.md](docs/index.md) | 文档总入口与导航索引 |
| [docs/architecture/engineering-standards.md](docs/architecture/engineering-standards.md) | 6 条强制架构规则 |
| [docs/architecture/data-model.md](docs/architecture/data-model.md) | Atom 实体规范与数据库 Schema |
| [docs/architecture/overview.md](docs/architecture/overview.md) | 架构概览 |
| [docs/api/ffi-contracts.md](docs/api/ffi-contracts.md) | FFI API 契约 |
| [docs/api/error-codes.md](docs/api/error-codes.md) | 稳定错误码注册表 |
| [docs/governance/API_COMPATIBILITY.md](docs/governance/API_COMPATIBILITY.md) | API 破坏性变更策略 |
| [docs/product/vision.md](docs/product/vision.md) | 产品愿景与长期方向 |
| [docs/product/roadmap.md](docs/product/roadmap.md) | 产品路线图 |
| [docs/development/windows-quickstart.md](docs/development/windows-quickstart.md) | Windows 开发环境快速上手 |
| [CLAUDE.md](CLAUDE.md) | AI Agent 开发指南 |

---

## 贡献指南

请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 和 [docs/governance/CONTRIBUTING.md](docs/governance/CONTRIBUTING.md)。

提交信息遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：
`feat(scope):`、`fix(scope):`、`chore(scope):`、`docs(scope):`、`test(scope):`、`refactor(scope):`

每个 PR 只处理一件事，不允许将功能开发与无关重构混入同一 PR。

---

## 许可证

[MIT License](LICENSE)
