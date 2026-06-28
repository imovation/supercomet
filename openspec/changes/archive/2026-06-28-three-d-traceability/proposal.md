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
