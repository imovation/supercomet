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
