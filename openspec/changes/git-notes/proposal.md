## Why

Comet task 完成后，进度信息存储在 `.comet.yaml` 中。如果工作目录被 `git clean -fdx` 清理，所有进度账本丢失。Git Notes 作为不可变的分布式备份层，使 task→commit 映射可从 git 历史中恢复。

## What Changes

- 新增 `src/scripts/comet-git-notes.sh` — Git Notes 写入脚本
- 读入 task id、requirement id 和 commit hash
- 使用 `git notes append` 写入引用到对应 commit
- 支持 `comet-git-notes.sh --recover` 从 git notes 恢复进度信息

## Capabilities

### New Capabilities
- `git-notes`: Task 完成时自动写入 Git Notes 作为不可变进度备份

### Modified Capabilities
- `three-d-traceability`: comet-state-set-task.sh 完成时触发 git-notes 写入（轻侵入追加）

## Impact

- 新增 Shell 脚本：`src/scripts/comet-git-notes.sh`
- 修改 `src/scripts/comet-state-set-task.sh`：task 完成时调用 git-notes 写入
- 修改 `bin/supercomet.js`：`supercomet init` 部署 git-notes 脚本
