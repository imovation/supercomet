# comet-speculate Specification

## Purpose
TBD - created by archiving change comet-speculate. Update Purpose after archive.
## Requirements
### Requirement: 完整探索模式

系统 SHALL 提供完整的结构化探索模式，在 `/comet-open` 之前运行，生成多方案对比与推荐。

#### Scenario: 完整探索，含方案对比
- **WHEN** `/comet-speculate` 以完整模式调用
- **THEN** 生成 2-3 个方案对比，每方案含优缺点、工作量估算和可行性评估
- **AND** 明确推荐 1 个方案并说明推荐理由
- **AND** 产出持久化文件 `explore-findings.md`

### Requirement: 快速探索模式

系统 SHALL 提供快速探索模式，跳过方案对比，直接输出推荐方案。

#### Scenario: 快速探索，小改动
- **WHEN** `/comet-quick-speculate` 被调用
- **THEN** 只出推荐方案，跳过多方案对比
- **AND** 仍产出 `explore-findings.md`，标注模式为 quick

### Requirement: 探索到 Open 阶段的交接

系统 SHALL 在 `/comet-open` 检测到 `explore-findings.md` 时自动注入探索结果为 proposal 上下文。

#### Scenario: speculate 到 open 的交接
- **WHEN** `/comet-open` 被调用且 `explore-findings.md` 已存在
- **THEN** 检测并读取探索结果
- **AND** 将探索发现注入为 proposal 起草上下文
- **AND** proposal 中注明来源为 `explore-findings.md`

