## ADDED Requirements

### Requirement: Task 完成时写入 git note

系统 SHALL 在 task 完成时自动调用 git notes 写入追溯信息。

#### Scenario: Task 完成时写入 git note
- **WHEN** `comet-state-set-task.sh` 标记 task 为完成
- **THEN** `comet-git-notes.sh` 自动调用 git notes append
- **AND** git note 记录 task id、requirement id 和 commit hash

### Requirement: 进度账本丢失后恢复

系统 SHALL 支持从 git notes 恢复 task 到 commit 的映射关系。

#### Scenario: 进度账本丢失后恢复
- **WHEN** 工作目录中的进度账本被 git clean -fdx 清除
- **THEN** `comet-git-notes.sh --recover` 可查询所有 git notes
- **AND** 输出可恢复的 task→commit 映射列表
- **AND** 恢复数据可在 `comet-trace.sh` 查询中使用
