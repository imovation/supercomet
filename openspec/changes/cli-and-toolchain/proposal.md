## Why

P0-1 至 P2-7 的 7 个增强均已实现后，需要完善的 CLI 部署机制、全量 BATS 测试覆盖，以及端到端集成测试和 CI 哨兵机制。`supercomet init` 需完整部署所有增强的脚本和 Skill 文件。

## What Changes

- `supercomet init` 完善：部署所有 7 个增强的 Shell 脚本和 Skill 文件
- 版本兼容性预检：`supercomet init` 检查上游版本是否满足 `dist/version.yaml` 兼容范围
- CI 哨兵机制：每日基于 `@rpamis/comet@latest` 运行测试套件
- 测试工具链：所有增强的 BATS 测试覆盖 + 端到端集成测试
- npm 包结构完善：确保 `bin`、`peerDependencies`、不包含 Comet 源码副本

## Capabilities

### New Capabilities
- `cli-and-toolchain`: supercomet CLI 部署、版本预检、测试覆盖、CI 哨兵

### Modified Capabilities
<!-- None -->

## Impact

- 修改 `bin/supercomet.js`：完善 init 部署逻辑 + 版本预检
- 新增 `test/integration/` 端到端测试
- 新增 `.github/workflows/ci-sentinel.yml` CI 配置
- 补全 `test/shell/` 下所有新增强的 BATS 测试
