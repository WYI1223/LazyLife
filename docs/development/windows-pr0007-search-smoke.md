# Windows PR-0007 Search Smoke

目标：在 Windows 上快速验证 `PR-0007`（FTS5 搜索）可用，面向新克隆仓库的开发者。

## 前置条件

- 已安装 Rust toolchain（含 `cargo`）
- 已克隆仓库，并在仓库根目录打开 PowerShell

## 4 条命令

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/doctor.ps1 -SkipFlutterDoctor
cd crates
cargo test -p lazynote_core --test search_fts
cargo test -p lazynote_core
```

## 预期结果

- `search_fts` 集成测试通过（当前应显示 `10 passed`）。
- `migration_bootstrap_indexes_existing_v3_atoms` 用例通过，说明 v3 -> v4 迁移后旧数据可检索。
- 不应出现 `no such table: atoms_fts` 这类迁移缺失错误。

## 失败排查

- 终端提示找不到 `cargo`：先安装 Rust（`rustup`），再重开终端。
- 如果只想快速定位 PR-0007 问题：先只跑 `cargo test -p lazynote_core --test search_fts`。
- 需要全仓回归时：执行 `cd crates; cargo test --all`。
