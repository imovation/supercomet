# Comet Design Handoff

- Change: comet-speculate
- Phase: design
- Mode: compact
- Context hash: 0edcd67cabb3e81a9d9bafbe9eb337455090a1e61f0cd9ceeeb11d20f7572380

Generated-by: comet-handoff.sh

OpenSpec remains the canonical capability spec. This handoff is a deterministic, source-traceable context pack, not an agent-authored summary.

## openspec/changes/comet-speculate/proposal.md

- Source: openspec/changes/comet-speculate/proposal.md
- Lines: 1-27
- SHA256: 26d130174ca994a7424b171013d623c5dcba75bfbbdd95a7e14f3a7bb9b6a2c9

```md
## Why

Comet 工作流缺少正式的结构化探索阶段。用户在面对开放性需求时直接从 `/comet-open` 开始，缺乏系统化的方案对比和选型分析。增加探索阶段可降低决策风险，产出可追溯的探索记录。

## What Changes

- 新增 `comet-speculate` Skill：完整探索模式，生成 2-3 个方案对比（含优缺点、工作量估算、推荐方案）
- 新增 `comet-quick-speculate` Skill：快速探索模式，仅出推荐方案，跳过多方案对比
- 探索结果持久化为 `explore-findings.md`
- `/comet-open` 检测 `explore-findings.md` 后自动注入为 proposal 上下文
- 探索阶段为可选（pre-hook），不阻塞不修改 Comet 任何阶段流转

## Capabilities

### New Capabilities
- `comet-speculate`: 结构化探索阶段——在 `/comet-open` 之前提供方案对比、工作量估算与推荐，产出 `explore-findings.md` 并交接给 open 阶段

### Modified Capabilities
<!-- None -->

## Impact

- 新增 Skill 文件：`src/skills/comet-speculate/SKILL.md`、`src/skills/comet-quick-speculate/SKILL.md`
- 新增 Shell 脚本：`src/scripts/comet-speculate.sh`
- 修改 `bin/supercomet.js`：`supercomet init` 部署 speculate Skill 文件
- 修改 `/comet-open` Skill 逻辑：检测并注入 `explore-findings.md`
- 核心侵入——优先向上游 Comet 提 PR，未合并前作为独立 Skill 部署
```

## openspec/changes/comet-speculate/design.md

- Source: openspec/changes/comet-speculate/design.md
- Lines: 1-63
- SHA256: c01556e0b38199ac9562acdc92afeefda28a4d27dc8329dc69f0f98df4379bb7

```md
## Context

Comet 当前无探索阶段，用户面对开放式需求时缺少结构化方案对比。supercomet 规格（P1-3）要求新增 comet-speculate 和 comet-quick-speculate 两个入口。

此增强为**核心侵入**级别——优先向上游 Comet 提 PR，PR 未合并前作为独立 Skill 部署。

遵循已有模式：所有增强用 Shell 脚本实现，通过 Skill 文件声明入口，由 `supercomet init` 部署。

## Goals / Non-Goals

**Goals:**
- 提供完整探索模式（2-3 方案对比 + 推荐）
- 提供快速探索模式（直接推荐）
- 产出持久化 `explore-findings.md`
- `/comet-open` 自动检测并注入探索结果
- 可选 hook，不阻塞或修改 Comet 阶段流程

**Non-Goals:**
- 不替代 `/comet-design` 的 brainstorming
- 不修改 Comet 入口调度器（核心侵入优先向上游提 PR）
- 不提供 AI 自动探索（explore 调用由用户或上层 agent 发起）

## Decisions

### 1. Shell 脚本 + Skill 文件

**选择**：Shell 脚本编排 + Skill 文件声明入口

**理由**：与现有 P0-1/P0-2 实现模式一致。`comet-forward-trace.sh` 等已建立 Shell 脚本作为增强实现的标准模式。

**替代方案**：
- Node.js 脚本：引入额外运行时依赖，不必要
- Python：不符合项目技术栈

### 2. explore-findings.md 格式

**选择**：Markdown 结构化输出，固定节结构

```
# Explore Findings
## Mode: full | quick
## Summary
## Options (仅 full 模式)
### Option N: <name>
- Pros
- Cons
- Effort Estimate
## Recommendation
```

**理由**：Markdown 格式与 Comet 产出一致，固定结构便于 `/comet-open` 解析和注入。

### 3. 上游 PR 策略

**选择**：开发完成后优先向 `rpamis/comet` 提 PR 添加 `/comet-speculate` 到 Comet 入口调度器

**理由**：按 supercomet 规格的"上游 PR 优先策略"，核心侵入项先向上游贡献。PR 未合并期间作为独立 Skill 部署。

## Risks / Trade-offs

- [风险] Comet 上游不合并 PR → 缓解：作为独立 Comet Skill 持续分发，通过 `supercomet init` 部署
- [风险] `explore-findings.md` 格式未来需要变更 → 缓解：版本号标注在文件头，`/comet-open` 检测版本后降级处理
- [风险] 探索阶段被跳过导致缺少方案对比 → 缓解：可选 hook，不影响核心流程；`/comet-open` 在无 `explore-findings.md` 时正常运行
```

## openspec/changes/comet-speculate/tasks.md

- Source: openspec/changes/comet-speculate/tasks.md
- Lines: 1-24
- SHA256: 3405e38aa1853260c916b0e3ce27f5a4c3593d82408f95d5d66bfdd2b58478bd

```md
## 1. Skill 文件与脚手架

- [ ] 1.1 创建 `src/skills/comet-speculate/SKILL.md` — 完整探索模式 Skill 声明
- [ ] 1.2 创建 `src/skills/comet-quick-speculate/SKILL.md` — 快速探索模式 Skill 声明

## 2. 核心实现

- [ ] 2.1 实现 `src/scripts/comet-speculate.sh` — 完整模式：多方案对比 + 推荐 + 产出 explore-findings.md
- [ ] 2.2 实现快速模式（quick shortcut）— 跳过多方案对比，直接推荐
- [ ] 2.3 `explore-findings.md` 格式固定（Mode、Summary、Options、Recommendation 节）

## 3. 交接集成

- [ ] 3.1 `/comet-open` Skill 增加探索结果检测逻辑：检测 `explore-findings.md` 存在时自动注入为 proposal 上下文
- [ ] 3.2 `bin/supercomet.js` 的 `supercomet init` 增加部署 comet-speculate 相关 Skill 文件

## 4. 测试

- [ ] 4.1 编写 `test/shell/comet-speculate.bats` — 覆盖完整模式、快速模式输出格式
- [ ] 4.2 编写探索到 open 交接的集成测试场景

## 5. 文档与上游 PR

- [ ] 5.1 准备向上游 rpamis/comet 提交 PR，将 `/comet-speculate` 集成到 Comet 入口调度器
```

## openspec/changes/comet-speculate/specs/comet-speculate/spec.md

- Source: openspec/changes/comet-speculate/specs/comet-speculate/spec.md
- Lines: 1-30
- SHA256: 0f429a88ea3eeaa708e46b4c9277ef28bc9912dcf8cfaab55245fbf0a0cd2e00

```md
## ADDED Requirements

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
```

