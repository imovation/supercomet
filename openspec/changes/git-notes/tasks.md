## 1. 核心脚本

- [x] 1.1 实现 `src/scripts/comet-git-notes.sh` — git notes append 写入 task 追溯信息
- [x] 1.2 实现 `comet-git-notes.sh --recover` — 从 git notes 恢复进度映射
- [x] 1.3 修改 `src/scripts/comet-state-set-task.sh` — task 完成时自动调用 git-notes 写入

## 2. 部署

- [x] 2.1 `bin/supercomet.js` 的 `supercomet init` 增加部署 git-notes 脚本

## 3. 测试

- [x] 3.1 编写 `test/shell/git-notes.bats` — 覆盖 notes 写入、恢复流程、空 notes 处理
