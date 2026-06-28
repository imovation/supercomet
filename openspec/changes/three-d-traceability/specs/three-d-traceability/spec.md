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
