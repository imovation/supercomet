# Comet Design Handoff

- Change: cli-and-toolchain
- Phase: design
- Mode: compact
- Context hash: 59f4efa5a3ba69e7022c9d05af97f1ec3185b3897fdde080c9a44b50cc300ded

Generated-by: comet-handoff.sh

OpenSpec remains the canonical capability spec. This handoff is a deterministic, source-traceable context pack, not an agent-authored summary.

## openspec/changes/cli-and-toolchain/proposal.md

- Source: openspec/changes/cli-and-toolchain/proposal.md
- Lines: 1-26
- SHA256: b907b08a371cb35d736593de8dafd17ca772d3041ddb6708b84b48388b98477e

```md
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
```

## openspec/changes/cli-and-toolchain/design.md

- Source: openspec/changes/cli-and-toolchain/design.md
- Lines: 1-55
- SHA256: 0061c4a361b0b1e738976fa99f8695dc007f3a469f1d3b3271193eb42d871828

```md
## Context

P0-1 至 P2-7 的 5 个功能性增强每个都有独立的 Shell 脚本。cli-and-toolchain 是聚合层：确保 `supercomet init` 一揽子部署所有增强，并提供完整的测试和 CI 基础设施。

## Goals / Non-Goals

**Goals:**
- `supercomet init` 部署全部增强脚本和 Skill 文件
- 版本预检（`dist/version.yaml` vs 实际安装版本）
- 所有新脚本的 BATS 测试覆盖
- 端到端集成测试
- CI 哨兵

**Non-Goals:**
- 不改变各增强的独立可部署性（每个仍可单独部署）
- 不引入新的构建工具（保持纯 Shell + npm）

## Decisions

### 1. init 部署清单

**选择**：从 manifest 文件读取部署清单而非硬编码

`dist/manifest.yaml`:
```yaml
scripts:
  - comet-speculate.sh
  - comet-spec-to-test.sh
  - comet-model-tier.sh
  - comet-revert-restore.sh
  - comet-git-notes.sh
skills:
  - comet-speculate
  - comet-quick-speculate
  - spec-to-test
```

**理由**：新增增强只需追加 manifest，不修改 JS 代码。可扩展性好。

### 2. CI 哨兵设计

**选择**：GitHub Actions 定时任务 + `npm install @rpamis/comet@latest` + 运行 BATS 测试

**理由**：无需额外 CI 平台。每日运行，失败时 issue 或 Slack 告警。

### 3. 集成测试框架

**选择**：BATS + git 操作模拟完整 Comet 流程

**理由**：与单元测试统一框架。设置临时 git 仓库，执行完整 change 生命周期，验证每个阶段的增强行为。

## Risks / Trade-offs

- [风险] CI 哨兵误报（上游临时 bug）→ 缓解：3 次重试，持续 3 天失败才告警
- [风险] 集成测试依赖 git 环境 → 缓解：测试脚本自建临时 git 仓库，不依赖外部
```

## openspec/changes/cli-and-toolchain/tasks.md

- Source: openspec/changes/cli-and-toolchain/tasks.md
- Lines: 1-26
- SHA256: 4b6fbed9cb028a019480a8a1299f0417f0252f094440f34a4e39afd91d5a3234

```md
## 1. supercomet init 完善

- [ ] 1.1 创建 `dist/manifest.yaml` — 声明式部署清单
- [ ] 1.2 修改 `bin/supercomet.js` — 基于 manifest 的全量部署逻辑
- [ ] 1.3 实现版本预检：检查上游版本满足 dist/version.yaml 兼容范围

## 2. npm 包结构检查

- [ ] 2.1 检查 `package.json` 符合规格（bin、peerDependencies、name）
- [ ] 2.2 确保发布包不包含 Comet 源码副本

## 3. BATS 测试补全

- [ ] 3.1 `test/shell/comet-speculate.bats` — 对应 change comet-speculate
- [ ] 3.2 `test/shell/spec-to-test-mapping.bats` — 对应 change spec-to-test-mapping
- [ ] 3.3 `test/shell/model-tier-selection.bats` — 对应 change model-tier-selection
- [ ] 3.4 `test/shell/revert-restore.bats` — 对应 change revert-restore
- [ ] 3.5 `test/shell/git-notes.bats` — 对应 change git-notes

## 4. 集成测试

- [ ] 4.1 编写 `test/integration/` 端到端集成测试（完整 Comet change 流程）

## 5. CI 哨兵

- [ ] 5.1 创建 `.github/workflows/ci-sentinel.yml` — 每日定时测试
```

## openspec/changes/cli-and-toolchain/specs/cli-and-toolchain/spec.md

- Source: openspec/changes/cli-and-toolchain/specs/cli-and-toolchain/spec.md
- Lines: 1-48
- SHA256: 8fa04e2766fd43891f544adb990c2b4564574c038e24f21eb8e19b6505d09167

```md
## ADDED Requirements

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
```

