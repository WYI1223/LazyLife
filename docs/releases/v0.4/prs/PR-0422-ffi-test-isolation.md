# PR-0422: FFI 测试数据库隔离（每次运行独立 DB）

- Proposed title: `fix(ffi): isolate FFI test database per run to prevent flaky failures`
- Status: Draft

## Goal

修复 Issue #46：FFI 测试共用持久化的 `%TEMP%/lazynote_entry.sqlite3`，多次运行后数据累积，导致依赖 LIMIT 边界的测试出现不稳定失败；同时消除单次 panic 通过 mutex 毒化传导到所有 FFI 测试的级联故障。

前置条件：无（独立 bugfix，不依赖 v0.4 序列中其他 PR）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| 现有实现 | `crates/lazynote_ffi/src/api.rs` | 唯一修改目标文件：`mod tests` 内的 DB 设置逻辑 |
| 对照参考 | `crates/lazynote_core/tests/atom_crud.rs` | Core 集成测试使用 `open_db_in_memory()` 的正确示范 |
| Bug 记录 | Issue #46 | 问题现象、复现条件、已知影响范围 |

## Scope

In scope:
- 在测试 `mod tests` 内新增 `setup_test_db()` 辅助函数，为每次测试运行分配 UUID 命名的临时 DB 文件
- 通过 `LAZYNOTE_DB_PATH` 环境变量将测试 DB 路径注入 `resolve_entry_db_path()`，复用现有机制，零侵入产品代码
- 将 `acquire_test_db_lock()` 替换为 `setup_test_db()`，每个 DB 路径唯一，消除全局串行锁依赖
- 对 mutex 毒化问题的缓解：各测试使用独立 DB，单次 panic 不再通过共享状态传播
- 测试运行后的临时 DB 文件清理（测试结束时删除，失败时保留以供调试）

Out of scope:
- 修改产品路径的任何逻辑（`resolve_entry_db_path`、`ENTRY_DB_PATH_OVERRIDE`、`ENTRY_DB_FILE_NAME` 不变）
- 引入 `open_db_in_memory()` 到 FFI 测试（FFI 层本身不持有 `Connection`，无法改为内存模式而不重构帮助函数签名；UUID 临时文件方案等效且侵入性更小）
- 将 FFI 测试改为并行执行（测试之间仍串行以避免 FRB 全局状态竞争，但串行化通过各自 DB 独立实现，而非全局锁）
- 修改 Core 集成测试（已正确使用 `open_db_in_memory()`）

## Design

### 问题根因

`resolve_entry_db_path()` 在没有配置覆盖时回退到：

```rust
std::env::temp_dir().join(ENTRY_DB_FILE_NAME)
// → %TEMP%\lazynote_entry.sqlite3
```

此文件在测试运行之间持久存在，每次 `cargo test` 只追加数据，从不清空。

测试内部使用 `unique_token`（纳秒时间戳前缀）保证单次创建的 atom 可以按内容定位，但 `notes_list`、`workspace_list_children` 等全量列表查询对总行数敏感——LIMIT 边界在数据量超过阈值后会截断新创建的条目，导致断言失败。

全局 `TEST_DB_LOCK: Mutex<()>` 确保测试串行，但一旦持锁测试 panic，mutex 进入毒化状态，后续所有测试在 `acquire_test_db_lock()` 处以 `expect` 崩溃，产生级联失败。

### 方案选择

| 方案 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| **A. UUID 命名临时文件（本 PR 选择）** | 侵入性最小；完全复用现有 `LAZYNOTE_DB_PATH` 注入机制；DB 可在失败时保留检查 | 留下少量临时文件（正常结束时删除） | 采用 |
| B. 测试开始时 DELETE all rows | 不新增文件 | 需要枚举所有表；迁移演进后容易遗漏 | 弃用 |
| C. 将帮助函数签名改为接收 `Connection` | 与 Core 测试模式一致 | 需重构所有 with_*_service 类型签名，范围超出 bugfix | 弃用 |

### 实现

在 `mod tests` 内新增 `TestDb` 结构体，使用 `Drop` 自动清理：

```rust
struct TestDb {
    path: std::path::PathBuf,
}

impl TestDb {
    fn new() -> Self {
        let id = uuid::Uuid::new_v4();
        let path = std::env::temp_dir()
            .join(format!("lazynote_test_{id}.sqlite3"));
        // 注入路径，resolve_entry_db_path() 优先读取此环境变量
        std::env::set_var("LAZYNOTE_DB_PATH", path.to_str().expect("valid utf-8 path"));
        // 预先建库 + 跑迁移，确保后续 with_*_service 可直接使用
        lazynote_core::db::open_db(&path).expect("test db init");
        TestDb { path }
    }
}

impl Drop for TestDb {
    fn drop(&mut self) {
        // 清理：测试正常结束（包括 panic 被 catch 的情况）时删除临时文件
        // 若测试进程 abort，文件留存供调试（OS 临时目录最终会回收）
        let _ = std::fs::remove_file(&self.path);
        // WAL 文件
        let _ = std::fs::remove_file(self.path.with_extension("sqlite3-wal"));
        let _ = std::fs::remove_file(self.path.with_extension("sqlite3-shm"));
    }
}
```

每个 DB 密集测试将 `acquire_test_db_lock()` 替换为 `TestDb::new()`：

```rust
// Before
#[test]
fn note_create_and_get_returns_typed_payload() {
    let _guard = acquire_test_db_lock();
    // ...
}

// After
#[test]
fn note_create_and_get_returns_typed_payload() {
    let _db = TestDb::new();
    // ...
}
```

不依赖 DB 的纯逻辑测试（`ping_returns_pong`、`version_is_not_empty`、`map_*` 系列、`init_logging_*`、`configure_entry_db_path_*`、`log_dart_event_*`）不需要 `TestDb`，直接移除 `acquire_test_db_lock()` 调用即可。

### mutex 毒化缓解

`TestDb::new()` 不使用任何共享 Mutex，因此 panic 在测试之间不传播。保留 `TEST_DB_LOCK` 和 `acquire_test_db_lock()` 以兼容过渡期，最终在同一 PR 内全量替换后可删除。

### 环境变量线程安全注意

Rust 测试框架默认多线程运行，`std::env::set_var` 不是线程安全的。本方案利用 `cargo test -- --test-threads=1`（或通过测试文件顶层 `#[serial_test]`）确保环境变量设置串行化。由于 FFI 测试已经因 FRB 全局状态而实际串行（所有测试在同一 OS 线程顺序执行），当前 `cargo test -p lazynote_ffi` 单线程行为与此兼容。

如需显式保证，在 `Cargo.toml` 中添加：

```toml
[dev-dependencies]
# 若将来需要显式串行标注
# serial_test = "3"
```

或在测试顶层文件添加 `// cargo test -- --test-threads=1` 注释作为文档。

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Rust | 新增 `TestDb` 结构体 + `Drop` 清理 | `crates/lazynote_ffi/src/api.rs`（`mod tests` 内部） | 30 min | — |
| T2 | Rust | 将所有 DB 密集测试的 `acquire_test_db_lock()` 替换为 `TestDb::new()` | `crates/lazynote_ffi/src/api.rs`（`mod tests` 内部） | 30 min | T1 |
| T3 | Rust | 移除不需要 DB 的纯逻辑测试中的 `acquire_test_db_lock()` 调用；移除 `TEST_DB_LOCK` 和 `acquire_test_db_lock` | `crates/lazynote_ffi/src/api.rs`（`mod tests` 内部） | 15 min | T2 |
| T4 | Verify | 运行 `cargo test -p lazynote_ffi` 连续三次，确认无累积数据导致的失败 | — | 15 min | T3 |

## Planned File Changes

- `[edit]` crates/lazynote_ffi/src/api.rs (新增 `TestDb` struct；替换所有 `acquire_test_db_lock()` 调用；删除 `TEST_DB_LOCK` 和 `acquire_test_db_lock()`)

## Verification

### CI gates

```bash
cd crates/
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all

cd ../apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

### Structural verification

```bash
# 验证 TEST_DB_LOCK 和 acquire_test_db_lock 已从 api.rs 删除
grep -n "TEST_DB_LOCK\|acquire_test_db_lock" crates/lazynote_ffi/src/api.rs
# 预期：无匹配（零输出）

# 验证 TestDb 已引入
grep -n "struct TestDb\|TestDb::new" crates/lazynote_ffi/src/api.rs
# 预期：至少 2 匹配（struct 定义 + 至少一处调用）

# 验证无测试直接引用旧共享 DB 常量（产品代码不受影响）
grep -n "lazynote_entry.sqlite3" crates/lazynote_ffi/src/api.rs
# 预期：1 匹配（ENTRY_DB_FILE_NAME 常量定义本身），测试内无引用

# 连续三次运行 FFI 测试，确认无累积数据导致失败
cargo test -p lazynote_ffi && cargo test -p lazynote_ffi && cargo test -p lazynote_ffi
# 预期：三次全绿
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| `set_var` 在多线程测试运行器中竞争 | LOW | FFI 测试因 FRB 全局状态已实际串行；必要时加 `-- --test-threads=1` 显式保证 |
| `Drop` 未能删除 WAL/SHM 文件（Windows 文件锁） | LOW | `remove_file` 失败静默忽略（`let _ = ...`）；OS 临时目录最终回收；不影响正确性 |
| 临时 DB 文件在 CI 磁盘上累积（进程 abort 时 Drop 不运行） | LOW | UUID 命名文件体积极小（< 1 MB），CI 环境 `%TEMP%` 定期清理；可接受 |
| 产品代码路径被误改 | LOW | 仅修改 `mod tests` 内部；`ENTRY_DB_FILE_NAME` 常量和 `resolve_entry_db_path` 函数不变；clippy + CI 全量测试兜底 |

## Acceptance Criteria

- [ ] `crates/lazynote_ffi/src/api.rs` 中 `TEST_DB_LOCK` 静态变量和 `acquire_test_db_lock()` 函数已删除
- [ ] `TestDb` 结构体已在 `mod tests` 内定义，包含 `Drop` 实现（删除临时 DB 文件及 WAL/SHM）
- [ ] 所有 DB 密集型测试使用 `TestDb::new()` 而非共享锁
- [ ] 纯逻辑测试（ping、version、map_*、init_logging_*、configure_entry_db_path_*、log_dart_event_*）不含任何 DB 设置调用
- [ ] `ENTRY_DB_FILE_NAME` 常量、`resolve_entry_db_path()` 函数、`ENTRY_DB_PATH_OVERRIDE` 全局变量均未变更
- [ ] `cargo test -p lazynote_ffi` 连续运行三次，三次全绿（验证无累积数据故障）
- [ ] `cargo test --all` 全绿
- [ ] `cargo clippy --all -- -D warnings` 零 warning
- [ ] PR spec Status updated to Merged
