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
