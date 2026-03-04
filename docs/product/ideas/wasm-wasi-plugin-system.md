# Idea: WASM + WASI 插件系统（基于 wasmtime 的安全沙箱扩展架构）

| 项目 | 值 |
|------|-----|
| **来源** | 插件系统架构探讨 |
| **优先级** | v0.4+ 规划参考 |
| **关联** | Extension Kernel（`docs/architecture/extension-kernel.md`）、S5 ruling（Extension SPI 冻结） |

---

## 背景

LazyNote 当前的 Extension Kernel 是声明式合约（`ExtensionManifest` + `RuntimeCapability` + `ExtensionRegistry` trait），尚无运行时加载能力。现有设计预留了能力声明和权限模型，但未定义插件的**执行沙箱**。

本文档探讨一种「神级插件系统」方案：将 **WASM + WASI** 通过 **wasmtime** 嵌入 Rust Core，使 LazyNote 获得市面上绝大多数笔记软件不具备的扩展能力。

---

## 1. 核心优势

### 1.1 多语言通吃

插件作者不需要学 Dart 或 Rust，可以用任何能编译到 WASM 的语言编写插件：

| 语言 | 工具链 | 成熟度 |
|------|--------|--------|
| Rust | `wasm32-wasi` target (官方支持) | 生产就绪 |
| C/C++ | Emscripten / wasi-sdk | 生产就绪 |
| Go | TinyGo (`-target=wasi`) | 可用 |
| Python | Componentize-py / CPython WASI build | 实验性 |
| JavaScript/TypeScript | Javy (Bytecode Alliance) / ComponentizeJS | 可用 |
| Zig | 原生 WASM target | 可用 |
| AssemblyScript | 原生 WASM 输出 | 生产就绪 |
| Kotlin | Kotlin/Wasm (WASI preview) | 实验性 |

```
┌─────────────────────────────────────────────────┐
│            插件开发者 (任意语言)                    │
│   Rust / Go / Python / JS / C++ / Zig / ...     │
└────────────────────┬────────────────────────────┘
                     │ 编译
                     ▼
              ┌──────────────┐
              │  .wasm 模块   │
              └──────┬───────┘
                     │ 加载
                     ▼
┌─────────────────────────────────────────────────┐
│           LazyNote Rust Core                     │
│  ┌───────────────────────────────────────────┐  │
│  │         wasmtime Runtime                   │  │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐    │  │
│  │  │Plugin A │ │Plugin B │ │Plugin C │    │  │
│  │  │(Rust)   │ │(Python) │ │(JS)     │    │  │
│  │  └─────────┘ └─────────┘ └─────────┘    │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### 1.2 绝对的安全感 — 细粒度能力授权

WASI 的核心设计哲学是 **Capability-based Security**（基于能力的安全模型）。插件默认没有任何权限，每一项能力都需要宿主显式授予。

**用户体验示例：**

```
┌──────────────────────────────────────────────┐
│  插件权限请求                                  │
│                                              │
│  「自动整理桌面文件夹」 请求以下权限：            │
│                                              │
│  [x] 读取笔记内容         (lazynote:note:read)│
│  [x] 修改笔记标签         (lazynote:tag:write)│
│  [ ] 访问文件系统                              │
│    └─ 仅限: C:\Users\Me\Desktop\             │
│  [ ] 网络访问             (无)                │
│                                              │
│  [允许选中项]  [拒绝全部]  [查看源码]            │
└──────────────────────────────────────────────┘
```

**能力模型设计：**

```rust
/// 插件可请求的能力集合
enum PluginCapability {
    // LazyNote 数据能力
    NoteRead,                    // 读取笔记内容
    NoteWrite,                   // 创建/修改笔记
    TagRead,                     // 读取标签
    TagWrite,                    // 修改标签
    WorkspaceTreeRead,           // 读取工作区结构
    WorkspaceTreeWrite,          // 修改工作区结构
    AtomStatusWrite,             // 修改任务状态
    SearchExecute,               // 执行搜索

    // 系统能力 (WASI 层)
    FileSystemRead(PathBuf),     // 读取指定路径
    FileSystemWrite(PathBuf),    // 写入指定路径
    NetworkAccess(String),       // 访问指定域名
    ClockRead,                   // 读取系统时间

    // UI 能力
    UiSlotRender(String),        // 在指定 UI slot 渲染内容
    NotificationSend,            // 发送通知
}
```

**与现有 Extension Kernel 的映射：**

现有的 `RuntimeCapability` 枚举（`src/extension/mod.rs`）已经声明了能力类型（DataRead/DataWrite/SystemAccess/UiRender/NetworkAccess）。WASM 方案将这些抽象能力映射为具体的 WASI 权限配置：

```
RuntimeCapability::DataRead     → WASI: 无文件系统权限, Host Function: note_read / tag_read
RuntimeCapability::DataWrite    → WASI: 无文件系统权限, Host Function: note_write / tag_write
RuntimeCapability::SystemAccess → WASI: 按路径授权的文件系统访问
RuntimeCapability::NetworkAccess→ WASI: 按域名授权的网络访问
RuntimeCapability::UiRender     → Host Function: ui_slot_render (返回渲染描述)
```

### 1.3 极速启动

| 指标 | WASM (wasmtime) | Docker 容器 | Node.js 进程 | Lua VM |
|------|-----------------|-------------|--------------|--------|
| 冷启动 | ~1-5 ms | ~500-2000 ms | ~50-200 ms | ~1-5 ms |
| 预编译后启动 | **~100-500 us** | N/A | N/A | N/A |
| 内存开销/实例 | ~1-10 MB | ~50-200 MB | ~30-80 MB | ~1-5 MB |
| 安全隔离 | 沙箱 (内存安全) | 容器级 | 无 (需要 VM) | 弱 |
| 多语言支持 | 30+ 种 | 任意 | JS/TS only | Lua only |

**wasmtime 预编译 (AOT) 优化：**

```rust
// 首次安装时预编译，后续加载直接反序列化
let engine = Engine::new(&config)?;
let module = Module::from_file(&engine, "plugin.wasm")?;

// 序列化预编译产物
let serialized = module.serialize()?;
std::fs::write("plugin.cwasm", &serialized)?;

// 后续启动：微秒级加载
unsafe {
    let module = Module::deserialize_file(&engine, "plugin.cwasm")?;
    // ~100-500us, 跳过编译阶段
}
```

---

## 2. 架构设计

### 2.1 整体分层

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter UI Layer                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────────┐  │
│  │ 插件商店  │  │ 权限管理  │  │ UI Slot Host (插件渲染)  │  │
│  └──────────┘  └──────────┘  └──────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                    FFI Boundary                              │
├─────────────────────────────────────────────────────────────┤
│                    Rust Core                                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Plugin Host (新模块)                      │   │
│  │  ┌────────────────┐  ┌─────────────────────────┐    │   │
│  │  │ PluginRegistry │  │ PluginPermissionManager  │    │   │
│  │  │ (清单+生命周期) │  │ (能力授权+审计日志)       │    │   │
│  │  └────────────────┘  └─────────────────────────┘    │   │
│  │  ┌────────────────┐  ┌─────────────────────────┐    │   │
│  │  │ WasmRuntime    │  │ HostFunctionBridge      │    │   │
│  │  │ (wasmtime 封装) │  │ (WASM <-> Core API 桥接) │    │   │
│  │  └────────────────┘  └─────────────────────────┘    │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │            Existing Core Services                     │   │
│  │  NoteService / AtomService / TreeService / ...        │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Plugin Host 模块结构

```
crates/lazynote_core/src/plugin/
├── mod.rs                  # 模块入口
├── manifest.rs             # 插件清单 (扩展现有 ExtensionManifest)
├── runtime.rs              # wasmtime Engine + Store 封装
├── host_functions.rs       # 暴露给 WASM 的宿主函数
├── permission.rs           # 能力授权管理器
├── lifecycle.rs            # 插件生命周期 (install/enable/disable/uninstall)
└── registry.rs             # 插件注册表 (扩展现有 ExtensionRegistry)
```

### 2.3 Host Function 桥接

插件通过 Host Function 与 LazyNote 交互，而非直接访问数据库：

```rust
/// Host functions 暴露给 WASM 插件的 API
/// 每个函数都会检查调用者的能力授权
impl HostFunctionBridge {
    // 笔记操作
    fn host_note_list(&self, caller: &PluginId, tag: Option<&str>) -> Result<Vec<NoteDto>>;
    fn host_note_get(&self, caller: &PluginId, atom_id: &str) -> Result<NoteDto>;
    fn host_note_create(&self, caller: &PluginId, content: &str) -> Result<NoteDto>;
    fn host_note_update(&self, caller: &PluginId, atom_id: &str, content: &str) -> Result<NoteDto>;

    // 标签操作
    fn host_tag_list(&self, caller: &PluginId) -> Result<Vec<String>>;
    fn host_tag_set(&self, caller: &PluginId, atom_id: &str, tags: &[String]) -> Result<()>;

    // 工作区操作
    fn host_workspace_list(&self, caller: &PluginId, parent: Option<&str>) -> Result<Vec<NodeDto>>;

    // 搜索
    fn host_search(&self, caller: &PluginId, query: &str) -> Result<Vec<SearchHitDto>>;
}
```

**权限检查流程：**

```
Plugin 调用 host_note_create()
    |
    v
HostFunctionBridge 检查 PluginId 的能力集
    |
    |-- 有 NoteWrite 能力 -> 调用 NoteService::create() -> 返回结果
    |
    └-- 无 NoteWrite 能力 -> 返回 PermissionDenied 错误
```

### 2.4 WASM Component Model (未来方向)

当前 wasmtime 已支持 **WASM Component Model** (WIT 接口定义)，这是比 raw WASM 更高级的抽象：

```wit
// lazynote-plugin.wit -- 插件接口定义
package lazynote:plugin@0.1.0;

interface note-api {
    record note {
        id: string,
        title: string,
        content: string,
        tags: list<string>,
    }

    list-notes: func(tag: option<string>) -> result<list<note>, string>;
    get-note: func(id: string) -> result<note, string>;
    create-note: func(content: string) -> result<note, string>;
    update-note: func(id: string, content: string) -> result<note, string>;
}

interface tag-api {
    list-tags: func() -> result<list<string>, string>;
    set-tags: func(atom-id: string, tags: list<string>) -> result<_, string>;
}

world lazynote-plugin {
    import note-api;
    import tag-api;

    export on-note-created: func(note-id: string);
    export on-note-updated: func(note-id: string);
    export on-startup: func();
    export on-command: func(command: string, args: string) -> option<string>;
}
```

优势：自动生成多语言绑定（Rust、JS、Python、Go 等），类型安全，版本化接口演进。

---

## 3. 插件生命周期

```
                    ┌──────────┐
                    │  发现     │  用户从插件商店/本地安装 .wasm
                    └────┬─────┘
                         │
                    ┌────v─────┐
                    │  验证     │  检查清单、签名、兼容性
                    └────┬─────┘
                         │
                    ┌────v─────┐
                    │  安装     │  预编译 AOT (.cwasm)、存储清单
                    └────┬─────┘
                         │
                    ┌────v─────┐
                    │  授权     │  弹出权限对话框，用户选择授权
                    └────┬─────┘
                         │
              ┌──────────v──────────┐
              │       已启用         │ <── 正常运行状态
              │  (on_startup 调用)   │
              └──────────┬──────────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
     ┌────v────┐   ┌────v────┐   ┌────v────┐
     │  禁用   │   │  更新   │   │  卸载   │
     │(保留数据)│   │(重新编译)│   │(清理)   │
     └─────────┘   └─────────┘   └─────────┘
```

---

## 4. 事件系统

插件可以订阅 LazyNote 的事件流：

```rust
/// 插件可订阅的事件类型
enum PluginEvent {
    NoteCreated { atom_id: AtomId },
    NoteUpdated { atom_id: AtomId },
    NoteDeleted { atom_id: AtomId },
    TagsChanged { atom_id: AtomId, old_tags: Vec<String>, new_tags: Vec<String> },
    StatusChanged { atom_id: AtomId, old_status: Option<TaskStatus>, new_status: Option<TaskStatus> },
    WorkspaceNodeMoved { node_id: WorkspaceNodeId },
    AppStartup,
    AppShutdown,
    ScheduledTick { interval_id: String },  // 定时触发
}
```

**事件分发流程：**

```
Core Service 完成操作 (e.g., note_create)
    |
    v
EventBus 广播 NoteCreated 事件
    |
    |---> Plugin A (订阅了 NoteCreated) -> 调用 on_note_created()
    |---> Plugin B (未订阅) -> 跳过
    └---> Plugin C (订阅了 NoteCreated) -> 调用 on_note_created()
```

---

## 5. 示例插件场景

### 5.1 自动标签插件

```
触发：NoteCreated / NoteUpdated 事件
能力：NoteRead + TagWrite
逻辑：分析笔记内容 -> 自动建议/添加标签
```

### 5.2 每日摘要生成器

```
触发：ScheduledTick (每天 22:00)
能力：NoteRead + NoteWrite + AtomStatusWrite
逻辑：汇总今日完成任务 -> 生成摘要笔记
```

### 5.3 文件夹自动整理

```
触发：on_command("organize", folder_path)
能力：FileSystemRead(指定路径) + NoteWrite + WorkspaceTreeWrite
逻辑：扫描文件夹 -> 为每个文件创建笔记引用 -> 按类型分组到工作区文件夹
```

### 5.4 Markdown 导出器

```
触发：on_command("export", format)
能力：NoteRead + WorkspaceTreeRead + FileSystemWrite(导出路径)
逻辑：遍历工作区结构 -> 导出为 HTML/PDF/Docx
```

### 5.5 AI 内容增强

```
触发：on_command("summarize", note_id)
能力：NoteRead + NoteWrite + NetworkAccess("api.openai.com")
逻辑：读取笔记 -> 调用 AI API -> 追加摘要到笔记末尾
```

---

## 6. 与现有架构的兼容性分析

### 6.1 与 Extension Kernel 的关系

| 现有组件 | WASM 方案中的角色 |
|---------|-----------------|
| `ExtensionManifest` | 扩展为包含 WASM 模块路径、能力声明、事件订阅 |
| `ExtensionRegistry` trait | 实现为 `WasmPluginRegistry`，管理 wasmtime 实例 |
| `RuntimeCapability` enum | 映射为具体的 Host Function 访问控制 |
| `FirstPartyExtensionAdapter` | 第一方插件可以选择继续用 native Rust，或迁移到 WASM |

### 6.2 与 Architecture Rules 的兼容

| 规则 | 影响 | 兼容性 |
|------|------|--------|
| Rule A (逻辑在 Core) | Plugin Host 在 `lazynote_core` 中实现 | 完全兼容 |
| Rule B (FFI 暴露用例) | 新增 `plugin_install`/`plugin_enable` 等 FFI 函数 | 兼容 |
| Rule C (软删除) | 插件操作通过 Host Function 调用 Core Service，遵循软删除 | 兼容 |
| Rule E (Feature 隔离) | 插件 UI 通过 UI Slot 系统渲染，不违反 Feature 隔离 | 兼容 |
| Rule F (运行时路径) | 插件存储在 `%APPDATA%/LazyLife/plugins/` | 兼容 |

### 6.3 依赖影响

```toml
# Cargo.toml 新增依赖
[dependencies]
wasmtime = "29"        # ~10-15 MB 编译产物增量
wasmtime-wasi = "29"   # WASI 支持
wit-bindgen = "0.36"   # WIT 绑定生成 (可选, Component Model)
```

**二进制体积影响：** wasmtime 会增加约 10-15 MB 的发布体积。对桌面应用可接受，但需评估对未来移动端的影响。

---

## 7. 风险与挑战

| 风险 | 严重度 | 缓解策略 |
|------|--------|---------|
| wasmtime 编译产物体积 (~15 MB) | 中 | 桌面端可接受；移动端可能需要裁剪或延迟加载 |
| WASI Preview 2 尚未完全稳定 | 中 | 锁定 wasmtime 版本，仅使用稳定 API |
| Component Model 生态仍在成熟 | 低 | 初期用 raw Host Function，后续迁移到 WIT |
| 插件 API 向后兼容压力 | 高 | 版本化 WIT 接口，SemVer 约束 |
| 调试体验 | 中 | wasmtime 支持 DWARF 调试信息，可集成 |
| 异步 I/O | 中 | WASI Preview 2 支持 async，或用 Host Function 代理 |

---

## 8. 实施路线建议

### Phase 1: 基础运行时 (v0.5?)

- 集成 wasmtime，实现基本 WASM 模块加载
- 实现 3-5 个核心 Host Function (note_read, note_list, tag_list, etc.)
- 权限模型 MVP（全部允许/全部拒绝）
- 第一个示例插件（Rust 编写的自动标签插件）

### Phase 2: 能力授权 + 事件系统 (v0.6?)

- 细粒度能力授权 UI
- 事件订阅与分发
- WASI 文件系统/网络按路径授权
- 插件生命周期管理（安装/启用/禁用/卸载）

### Phase 3: Component Model + 生态 (v0.7+)

- 迁移到 WIT 接口定义
- 多语言 SDK（Rust/JS/Python 插件模板）
- 插件商店基础设施
- 插件签名与安全审计

---

## 9. 竞品对比

| 特性 | LazyNote (WASM) | Obsidian | Logseq | Notion |
|------|----------------|----------|--------|--------|
| 插件沙箱 | WASM 隔离 | 无 (Node.js) | 无 (JS) | 无 (API only) |
| 多语言插件 | 30+ 种 | JS/TS only | JS/TS only | N/A |
| 细粒度权限 | 能力级授权 | 无 | 无 | OAuth scope |
| 启动性能 | us 级 | ms 级 | ms 级 | N/A |
| 离线运行 | 完全离线 | 完全离线 | 完全离线 | 需网络 |
| 类型安全 API | WIT 强类型 | 弱类型 | 弱类型 | REST |

---

## 10. 结论

WASM + WASI 方案与 LazyNote 现有架构高度兼容：

1. **Rust Core 天然适配** — wasmtime 是 Rust 原生库，集成成本低
2. **现有 Extension Kernel 可平滑演进** — `ExtensionManifest` / `RuntimeCapability` / `ExtensionRegistry` 直接映射为 WASM 运行时概念
3. **安全模型领先** — 基于能力的授权远优于无沙箱的 JS 插件
4. **性能无忧** — us 级启动 + MB 级内存，挂载十几个插件也不会成为资源瓶颈
5. **生态潜力** — 多语言支持降低插件开发门槛，WASM Component Model 提供类型安全演进路径

建议在 v0.3 稳定后将此方案纳入 v0.5+ 路线规划，优先实现 Phase 1 基础运行时。
