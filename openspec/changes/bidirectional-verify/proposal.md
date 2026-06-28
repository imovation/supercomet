## Why

supercomet 作为 Comet 技能扩展包，需要提供 spec↔test 双向追溯能力来确保所有 Scenario 都有对应测试覆盖，并在 verify 阶段产出标准化的 `traceability.md` 报告。这是 7 个增强中优先级最高的 P0 项，也是后续增强（如 P0-2 三维追溯）的依赖基础。

## What Changes

- 新增 `comet-forward-trace.sh` — 正向反查脚本：提取 change spec 中所有 `#### Scenario:` 名称，在 `test/` 中 grep 对应测试函数
- 新增 `comet-backward-trace.sh` — 反向反查脚本：提取测试函数名称，比对 spec Scenario，标记孤儿测试
- 新增 `bidirectional-verify` Skill 文件 — 定义协议、输入源、输出格式、降级路径
- 新增 `supercomet init` 部署逻辑 — 将上述文件注入到 `comet/scripts/` 和 `comet/reference/`
- 新增 `test/shell/` BATS 测试 — 覆盖正向路径和降级路径
- 优先消费 Superpowers v6.0 的 `task-brief` / `review-package` 作为输入源；不可用时降级为全量 grep
- 输出 `traceability.md`，包含覆盖矩阵、孤儿测试、边界分析、闸门判定

## Capabilities

### New Capabilities
- `bidirectional-verify`: spec↔test 双向追溯验证，作为 /comet-verify 的附加验证项

### Modified Capabilities
- *无修改已有 capability*

## Impact

- 新增 `src/scripts/comet-forward-trace.sh`
- 新增 `src/scripts/comet-backward-trace.sh`
- 新增 `src/skills/bidirectional-verify/SKILL.md`
- 新增 `test/shell/bidirectional-verify.bats`
- 更新 `bin/supercomet.js`（init 子命令部署逻辑）
- 不修改任何 Comet 核心文件（零侵入）
