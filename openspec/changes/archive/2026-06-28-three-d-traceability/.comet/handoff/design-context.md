# Comet Design Handoff

- Change: three-d-traceability
- Phase: design
- Mode: compact
- Context hash: 24967bc53166ce618af9b1f2bcb8abc9c69cf199569c69d8b9124aa5758584ee

Generated-by: comet-handoff.sh

OpenSpec remains the canonical capability spec. This handoff is a deterministic, source-traceable context pack, not an agent-authored summary.

## openspec/changes/three-d-traceability/proposal.md

- Source: openspec/changes/three-d-traceability/proposal.md
- Lines: 1-27
- SHA256: 6e3c34246a035aaf913fe78adc6de28915508b887c25f925a2364d4c064821d3

```md
## Why

P0-1 实现了 spec↔test 双向反查，但缺少 Task→Git Commit 这一维的追溯。当代码变更出现问题时，无法通过 Requirement ID 或 commit hash 快速定位完整的变更影响链。P0-2 加入 Commit 维度，形成 Requirement→Scenario→Test→Commit→Task 完整三维追溯，这是狗粮验证 P0-1 并完成全链路闭环的关键一步。

## What Changes

- 新增 `comet-trace.sh` — 双向追溯查询脚本：通过 Requirement ID 或 commit hash 返回完整追溯链
- 扩展 `.comet.yaml` schema — task 条目追加 `requirement_id`、`scenario`、`test_file`、`test_name`、`commits` 字段
- 扩展 `comet-state.sh` 白名单 — 新增 `set-task` 命令用于写入 task 追溯信息
- 新增 `comet-guard.sh` 闸门 — verify→archive 转移时检查 commits 字段非空
- 新增 `test/shell/` BATS 测试 — 覆盖正向/反向查询和闸门判定

## Capabilities

### New Capabilities
- `three-d-traceability`: Requirement→Scenario→Test→Commit→Task 双向追溯查询

### Modified Capabilities
- *无修改已有 capability*

## Impact

- 新增 `src/scripts/comet-trace.sh`
- 新增 `test/shell/comet-trace.bats`
- 轻侵入：`.comet.yaml` schema 追加 task 字段
- 轻侵入：`comet-state.sh` 白名单扩展 `set-task`
- 轻侵入：`comet-guard.sh` 闸门扩展
```

## openspec/changes/three-d-traceability/design.md

- Source: openspec/changes/three-d-traceability/design.md
- Lines: 1-40
- SHA256: 867941126edb1cc32367969f5594e2a23f0ebb971561e486bc6807cf72be57f3

```md
## Context

P0-1 已实现 spec↔test 双向反查（`comet-forward-trace.sh` + `comet-backward-trace.sh` + `traceability.md`）。P0-2 在此基础上加入 Task→Git Commit 维度，形成 Requirement→Scenario→Test→Commit→Task 完整三维追溯链。实现方式：轻侵入扩展 `.comet.yaml` schema 和 `comet-state.sh` 白名单，新增 `comet-trace.sh` 查询脚本。

## Goals / Non-Goals

**Goals:**
- 实现 `comet-trace.sh`：支持通过 Requirement ID 或 commit hash 双向查询完整追溯链
- 扩展 `.comet.yaml` task 字段：`requirement_id`、`scenario`、`test_file`、`test_name`、`commits`
- 扩展 `comet-state.sh` 白名单：`set-task` 命令
- 闸门：verify→archive 前检查 commits 非空
- BATS 测试覆盖正向/反向查询

**Non-Goals:**
- 不修改 Comet 核心调度逻辑
- 不涉及 Git Notes 自动写入（那是 P2-7）
- 不实现 spec-to-test 映射（P1-4）

## Decisions

### 1. 追溯数据存储位置
- **决策**：存储在 `.comet.yaml` 的 task 条目中，不另建数据库
- **理由**：`.comet.yaml` 已是 Comet 状态机的唯一事实源，追加字段无需引入新存储机制
- **备选**：SQLite DB → 拒绝，过度工程化

### 2. comet-trace.sh 查询接口
- **决策**：两种查询模式——`--requirement-id <id>` 正向查，`--commit <hash>` 反向查
- **理由**：覆盖两个主要查询入口；单一脚本减少运维负担
- **备选**：独立 forward/backward 双脚本 → 拒绝，查询逻辑简单可合并

### 3. 闸门集成
- **决策**：`comet-guard.sh` verify→archive 时检查 `.comet.yaml` 中每个 completed task 的 `commits` 字段非空
- **理由**：与 P0-1 的 traceability.md GATE 行类似，闸门关注点不同但机制统一

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| `.comet.yaml` task 字段膨胀 | 仅追加必要字段，不影响已有结构 |
| commit hash 可能失效 | 查询时检查 `git rev-parse` 验证 |
```

## openspec/changes/three-d-traceability/tasks.md

- Source: openspec/changes/three-d-traceability/tasks.md
- Lines: 1-21
- SHA256: b91e2c5901030149bd9e70284177c94765e1c5abe6314c772355879800f72460

```md
## 1. comet-trace.sh 实现

- [ ] 1.1 实现 `comet-trace.sh`：正向查询 `--requirement-id <id>`，输出 Requirement→Scenario→Test→Commit→Task
- [ ] 1.2 实现反向查询 `--commit <hash>`，输出 Commit→Task→Requirement→Scenario→Test
- [ ] 1.3 实现无效输入错误处理：不存在的 ID/hash 输出 "Not found"，退出码非零

## 2. .comet.yaml schema 扩展

- [ ] 2.1 扩展 task 字段 schema：追加 `requirement_id`、`scenario`、`test_file`、`test_name`、`commits`
- [ ] 2.2 comet-state.sh 新增 `set-task` 命令支持写入追溯字段

## 3. 闸门集成

- [ ] 3.1 comet-guard.sh verify→archive 转移时检查 commits 非空
- [ ] 3.2 commits 为空时阻止转移

## 4. BATS 测试

- [ ] 4.1 编写 `test/shell/comet-trace.bats`：正向查询测试
- [ ] 4.2 编写反向查询测试
- [ ] 4.3 编写无效输入错误处理测试
```

## openspec/changes/three-d-traceability/specs/three-d-traceability/spec.md

- Source: openspec/changes/three-d-traceability/specs/three-d-traceability/spec.md
- Lines: 1-35
- SHA256: e7ab7182e4f184f46c7a6eab88e6ecd0ae851872fbddf567732b6022eaccd6cb

```md
## ADDED Requirements

### Requirement: Task 到 commit 的映射

Comet build 阶段每完成一个 task，系统 SHALL 支持在 `.comet.yaml` 中记录 task 与 commit 的映射关系。每个 task 条目 MUST 包含 `requirement_id`、`scenario`、`test_file`、`test_name` 和 `commits` 字段。

#### Scenario: set-task 写入映射
- GIVEN Comet build 阶段完成了一个 task
- WHEN 调用 `comet-state.sh set-task <name> <task-id>`
- THEN task 条目必须包含 requirement_id、scenario、test_file、test_name 和 commits
- AND commits 字段必须为非空数组（至少一个 commit hash）

#### Scenario: commits 字段非空闸门
- GIVEN `.comet.yaml` 中存在 commits 字段为空的 task
- WHEN comet-guard.sh 评估 verify→archive 转移
- THEN 阻止转移

### Requirement: 双向追溯查询

系统 SHALL 支持通过 Requirement ID 或 commit hash 双向查询完整追溯链。

#### Scenario: 正向查询——按 Requirement ID
- GIVEN 一个已知的 Requirement ID
- WHEN 调用 `comet-trace.sh --requirement-id <id>`
- THEN 返回完整追溯链：Requirement → Scenario → Test → Commit → Task

#### Scenario: 反向查询——按 commit hash
- GIVEN 一个已知的 commit hash
- WHEN 调用 `comet-trace.sh --commit <hash>`
- THEN 返回完整追溯链：Commit → Task → Requirement → Scenario → Test

#### Scenario: 无效输入的错误处理
- GIVEN 一个不存在的 Requirement ID 或 commit hash
- WHEN comet-trace.sh 查询
- THEN 输出 "Not found" 并退出码非零
```

