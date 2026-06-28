## 1. 核心脚本

- [x] 1.1 实现 `src/scripts/comet-revert-restore.sh` — revert-restore 循环逻辑
- [x] 1.2 实现 git revert + test 执行 + git revert 恢复 + test 再验证
- [x] 1.3 实现 Hard Gate 逻辑：撤销后测试仍 PASS → 阻断
- [x] 1.4 实现安全隔离：git worktree 优先，降级 stash + in-place
- [x] 1.5 实现范围限定：仅 Security/Core/Critical task 执行

## 2. 部署

- [x] 2.1 `bin/supercomet.js` 的 `supercomet init` 增加部署 revert-restore 脚本

## 3. 测试

- [x] 3.1 编写 `test/shell/revert-restore.bats` — 覆盖有效测试（撤销后失败）、无效测试阻断、非关键变更跳过、worktree 隔离
