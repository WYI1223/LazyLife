# S6: Provider SPI → external_mappings 交互

| 字段 | 值 |
|------|-----|
| 状态 | **Documented** — v0.3 实现 |
| 裁决日期 | 2026-02-26 |
| 关联 PR | PR-0309（Google Calendar Provider，v0.3） |

---

## 决策

**external_mappings 由 Core 的 sync orchestrator 管理，ProviderSpi 实现不直接接触映射表。** 三层职责分离：Provider（翻译官）、Orchestrator（调度员）、Mapping Persistence（存储层）。

---

## 规则

1. **Provider = 翻译官**：ProviderSpi 实现只负责远端 API 格式转换，不知道 LazyNote 内部如何存储映射
2. **Orchestrator = 调度员**：SyncOrchestratorService 是 external_mappings 的唯一读写者，编排完整同步流程
3. **Mapping 层级正确**：external_mappings 是 Atom 级别（非 atom_ref 级别），与 S1 R5 多引用模型正交
4. **S1 创建语义统一**：sync pull 创建的 Atom 走与手动创建相同的路径（Atom + atom_ref + view_hint 推导 + 指定文件夹路由）

---

## 三层职责分离

| 层 | 组件 | 职责 | 接触 external_mappings? |
|----|------|------|----------------------|
| Provider adapter | `ProviderSpi` 实现 | 远端 API 交互：auth、拉取、推送、冲突策略 | **否** |
| Sync orchestrator | `SyncOrchestratorService`（待建） | 编排同步流程、管理映射、遵循创建语义 | **是** — 唯一读写者 |
| Mapping persistence | `ExternalMappingRepository`（待建） | external_mappings 表的 CRUD | **是** — 被 orchestrator 调用 |

### 同步流程

```
1. provider.auth()           → 确认认证状态
2. provider.pull(cursor)     → 拿到远端变更
3. mapping_repo.find(...)    → 查找已有映射
   - 有映射 → 更新本地 Atom
   - 无映射 → 创建 Atom + atom_ref + 创建映射
4. 收集本地变更
5. mapping_repo.get(...)     → 获取 external_id
6. provider.push(changes)    → 推送到远端
7. mapping_repo.update(...)  → 更新 version/last_synced_at
8. 如有冲突 → provider.conflict_map() → 按策略执行
```

### S1 裁决对同步的影响

| S1 裁决 | 对 sync orchestrator 的要求 |
|---------|---------------------------|
| R5 atom_ref 强制伴随 | pull 创建新 Atom 时必须同时创建 atom_ref |
| R6 指定默认路径路由 | Google Calendar pull 的 Atom → atom_ref 落入 Calendar 指定文件夹 |
| R4 view_hint 自动推导 | pull 的 Atom 有 start_at/end_at → Core 自动推导 view_hint = event |

---

## external_mappings 表约束

两个 UNIQUE 约束在 S1 语义下仍然成立：

- `UNIQUE(provider, external_id)` — 一个远端记录只映射到一个 Atom
- `UNIQUE(provider, atom_uuid)` — 一个 Atom 在一个 provider 中只有一个映射

atom_ref 多引用不影响映射（映射关系是 Atom 级别，不是 atom_ref 级别）。

---

## 理由

1. **关注点分离**：Provider 只做翻译，Orchestrator 管流程和映射，每层可独立测试
2. **Provider 可替换性**：Google Calendar、Outlook、CalDAV 只需实现同一个 trait，不需了解 mappings schema
3. **S1 创建语义统一**：sync pull 创建的 Atom 走与手动创建相同路径，无边界特例
4. **映射层级正确**：Atom 级别映射与 atom_ref 多引用正交
5. **当前状态合理**：ProviderSpi declaration-only + schema-only = 两块拼图各自就位，等待 orchestrator 在 v0.3 连接

---

## 实施状态

| 项目 | 状态 |
|------|------|
| 语义定义 | v0.2.5 已完成 |
| ProviderSpi trait | 已存在（declaration-only） |
| external_mappings schema | 已存在（Migration 3） |
| SyncOrchestratorService | v0.3 PR-0309 待建 |
| ExternalMappingRepository | v0.3 PR-0309 待建 |

---

## 开放设计项

- Cursor 增量同步策略（full sync vs delta sync vs change token）
- 冲突解决 UI（ManualMerge 场景的用户交互流程）
