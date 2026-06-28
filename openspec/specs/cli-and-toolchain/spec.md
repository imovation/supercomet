# cli-and-toolchain Specification

## Purpose
TBD - created by archiving change cli-and-toolchain. Update Purpose after archive.
## Requirements
### Requirement: supercomet init 完整部署

`supercomet init` SHALL 部署全部 7 个增强的 Shell 脚本和 Skill 文件。

#### Scenario: 全量部署
- **WHEN** `supercomet init` 执行
- **THEN** 所有 `src/scripts/*.sh` Shell 脚本部署到 `comet/scripts/`
- **AND** 所有 `src/skills/**/SKILL.md` 的 Skill 文件部署到对应 `comet/` 目录
- **AND** 安装器预检执行：上游版本不满足兼容性时输出明确警告

### Requirement: BATS 测试全量覆盖

每个增强的 Shell 脚本 SHALL 有对应的 BATS 测试文件。

#### Scenario: BATS 测试全量覆盖
- **WHEN** 执行 BATS 测试套件
- **THEN** 每个 `src/scripts/*.sh` 有对应的 `test/shell/<name>.bats` 测试文件
- **AND** 测试覆盖正向路径和降级路径

### Requirement: 端到端集成测试

系统 SHALL 通过端到端测试验证完整 Comet change 流程中 supercomet 增强的行为。

#### Scenario: 端到端集成测试
- **WHEN** 执行集成测试
- **THEN** 验证完整流程：open → design → build → verify(含双向反查+回归验证) → archive
- **AND** Git Notes 在每个 task 完成时触发写入

### Requirement: CI 哨兵机制

系统 SHALL 配置每日 CI 检测上游兼容性断裂。

#### Scenario: CI 哨兵自动检测
- **WHEN** CI 每日定时触发
- **THEN** 安装 @rpamis/comet@latest 执行测试套件
- **AND** 测试失败时告警，不自动发布新版本

### Requirement: npm 包结构正确

supercomet 的 `package.json` SHALL 符合规格要求。

#### Scenario: npm 包结构正确
- **WHEN** 检查包结构
- **THEN** name 为 supercomet，bin 含 supercomet 入口
- **AND** peerDependencies 声明 @rpamis/comet >=0.3.0
- **AND** 不得包含 Comet 核心 Shell 脚本的副本

