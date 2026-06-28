## Why

关键变更（Security/Core/Critical）的测试可能表面通过但实际无效。revert-restore 回归验证通过"撤销实现→验证测试失败→恢复实现→验证测试通过"的循环，确保测试真正能捕捉缺陷。

## What Changes

- 新增 `src/scripts/comet-revert-restore.sh` — 回归验证脚本
- 接受一个 implement commit hash，执行：git revert → run tests → git revert (restore) → run tests
- Hard Gate：撤销后测试仍 PASS → 阻断（测试无效）
- 仅对标记 Security/Core/Critical 的 task 执行
- 零侵入——独立脚本，不修改 Comet 核心

## Capabilities

### New Capabilities
- `revert-restore`: 对关键变更执行回归验证，确保测试能捕捉缺陷

### Modified Capabilities
<!-- None -->

## Impact

- 新增 Shell 脚本：`src/scripts/comet-revert-restore.sh`
- 修改 `bin/supercomet.js`：`supercomet init` 部署脚本
