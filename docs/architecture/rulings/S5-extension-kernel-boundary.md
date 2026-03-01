# S5: Extension Kernel → Flutter 命令系统边界

| 字段 | 值 |
|------|-----|
| 状态 | **Landed** — 语义定义，无代码变更 (PR-0256) |
| 引入版本 | v0.2.5 (PR-0256) |
| 废弃者 | — |
| 裁决日期 | 2026-02-26 |
| 关联 PR | PR-0310（命令插件化，v0.3） |

---

## 决策

**First-party 与 Extension Kernel 分离。** Extension Kernel 定位为 third-party 安全合约，first-party 功能直接使用 Flutter 命令系统，不经过 Extension Kernel 的 manifest 验证或 capability guard。

---

## 规则

1. **First-party 直接访问**：Notes/Tasks/Calendar 等产品功能直接调用 FFI，不经过 Extension Kernel
2. **Extension Kernel = third-party 合约**：`ExtensionManifest`、`RuntimeCapability`、`ExtensionRegistry` 为未来 third-party 插件准备
3. **Declaration-only 是正确状态**：Extension Kernel 保持 declaration-only 直到第一个真实 third-party 插件需求出现
4. **S1-S4 影响在命令执行层**：atom_ref 强制伴随、指定文件夹路由等变化作用在 FFI/CommandRegistry 层，不经过 Extension Kernel

---

## 两套系统服务不同对象

| | First-party（Notes/Tasks/Calendar） | Third-party（未来插件） |
|---|---|---|
| 信任级别 | 完全信任 — 直接 FFI，全 DB 访问 | 沙箱化 — capability-gated API |
| 注册路径 | 编译时确定（hardcoded parsers/slots） | 运行时动态加载（manifest 驱动） |
| 安全需求 | 无 — 产品核心功能 | `RuntimeCapability` 守卫 |
| 迭代约束 | 直接改代码，无 API 稳定性负担 | 必须通过稳定 extension API |

### Flutter 命令系统 = first-party 运行时

- 3 个 first-party parser（`new_note`、`task`、`schedule`）直接注册在 `EntryParserChain`
- 命令执行通过 `EntryCommandRegistry` 直接调用 FFI
- UI Slots 通过 `UiSlotRegistry` 直接注册 first-party contributions
- 以上均不经过 manifest 验证或 capability guard

### Extension Kernel = third-party 安全合约

- Manifest 验证确保第三方声明合法的 capabilities
- `assert_invocation_allowed()` 在第三方调用时做权限守卫
- `FirstPartyExtensionAdapter` 存在是为了 baseline 测试，不意味着 first-party 需要走 extension 路径

---

## 桥接构建时机

Extension Kernel → Flutter 运行时的桥接在**第一个真实 third-party 插件需求出现时**构建（预计 v0.4+）：

1. FFI 暴露 extension 注册接口（`list_extensions()`、`assert_capability()`）
2. Flutter 端动态注册路径（manifest → parser/command/slot 注册）
3. 沙箱化执行环境（third-party 代码不直接访问 FFI/DB）

---

## 理由

1. **阶段适配**：v0.2.5 没有 third-party 插件，强制 first-party 走 Extension Kernel 是为了架构一致性牺牲迭代速度
2. **本质差异**：first-party 和 third-party 在信任、注册、安全三个维度上根本不同
3. **Extension Kernel 完备性**：declaration-only 是正确状态，manifest 验证和 capability guard 已有充分测试（17 个单元测试）
4. **命令系统独立性**：Flutter 命令系统已 production-ready，不需要 Extension Kernel 的间接层

---

## 实施状态

| 项目 | 状态 |
|------|------|
| 语义定义 | **已完成** — first-party / Extension Kernel 边界明确 |
| Extension Kernel 保持 declaration-only | ✓ 当前状态正确 |
| Third-party 桥接构建 | v0.4+（需求驱动） |

---

## 开放设计项

- First-party extension manifest 格式（是否需要声明式描述 first-party 的 capabilities 以供文档/调试使用）
- Third-party 沙箱化执行环境的技术选型（isolate / process / WASM）
