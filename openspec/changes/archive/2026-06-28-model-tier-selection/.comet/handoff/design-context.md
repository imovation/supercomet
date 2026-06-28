# Comet Design Handoff

- Change: model-tier-selection
- Phase: design
- Mode: compact
- Context hash: 005e40f90b01b5eef64469e8d6d2c2fcad2ac881bc8cb2eb6a949f35c5123827

Generated-by: comet-handoff.sh

OpenSpec remains the canonical capability spec. This handoff is a deterministic, source-traceable context pack, not an agent-authored summary.

## openspec/changes/model-tier-selection/proposal.md

- Source: openspec/changes/model-tier-selection/proposal.md
- Lines: 1-25
- SHA256: 3c0164e6fb23594aa00281568b2a90498b2f1ec4207fc58c80038145234278e5

```md
## Why

Comet build 阶段分发子Agent 时，所有任务使用同一模型层级。轻量机械任务消耗不必要的计算资源，而复杂架构审查可能因模型能力不足而质量下降。按任务复杂度自动推荐模型层级可优化资源分配和质量。

## What Changes

- 新增 `src/scripts/comet-model-tier.sh` — 模型层级推荐脚本
- 分析 `.comet.yaml` 中 task 的复杂度元数据（文件数、类型、风险标签）
- 轻量任务（1-2 文件，plan 含完整代码）→ 推荐快速/廉价模型
- 重度任务（全分支审查、设计决策）→ 推荐最强模型
- 参考 `.comet.yaml` 的 `model_tier` 字段，不存在时降级为默认模型

## Capabilities

### New Capabilities
- `model-tier-selection`: 按 comet-build 子Agent 任务复杂度自动推荐模型层级

### Modified Capabilities
<!-- None -->

## Impact

- 新增 Shell 脚本：`src/scripts/comet-model-tier.sh`
- 修改 `bin/supercomet.js`：`supercomet init` 部署脚本
- 轻侵入——`.comet.yaml` schema 追加 `model_tier` 字段
```

## openspec/changes/model-tier-selection/design.md

- Source: openspec/changes/model-tier-selection/design.md
- Lines: 1-46
- SHA256: 73eba268b446fe6a4180ce30a0f0d643ca4c57ef52de36bfd7d7ee6b0fa4dd1a

```md
## Context

P0-1/P0-2 已完成 spec↔test↔commit 的追溯体系。P1-5 关注 build 阶段的资源效率：不同任务需要不同能力的模型。

此增强为轻侵入——`.comet.yaml` schema 追加 `model_tier` 字段，通过追加合并而非覆盖现有字段。

## Goals / Non-Goals

**Goals:**
- 分析 task 复杂度（文件数、类型 label、含 code 的 plan 等）
- 输出推荐模型层级（fast/economy/balanced/best）
- 降级路径：无 model_tier 时输出默认模型

**Non-Goals:**
- 不执行实际的模型切换（由子 Agent 调用方消费推荐结果）
- 不修改 Comet 核心脚本

## Decisions

### 1. 复杂度评分模型

**选择**：三因子评分
```
file_count_score  + risk_label_score  + plan_detail_score

file_count:    1-2 → 0,  3-5 → 1,  6+ → 2
risk_label:    none → 0,  Security/Critical/Core → 2
plan_detail:   含 code → 0,  仅描述 → 1
```
总分 0-1 → fast, 2-3 → economy, 4-5 → balanced, 6+ → best

**理由**：简单可解释，不需要额外依赖。基于 `.comet.yaml` 中已有的 task 元数据。

### 2. 输出格式

**选择**：JSON 单行输出（便于脚本消费）
```json
{"tier":"fast","reason":"机械实现: 1 file, plan含完整代码, no risk label"}
```

**理由**：机器可读，上层 agent 可直接取用。同时支持 `--human` flag 输出可读文本。

## Risks / Trade-offs

- [风险] 评分模型过于简单，误判任务复杂度 → 缓解：支持 `comet-model-tier --override <tier>` 手动覆盖
- [风险] 不同模型提供商的 tier 映射不一致 → 缓解：输出通用层级名称（fast/economy/balanced/best），由调用方映射
```

## openspec/changes/model-tier-selection/tasks.md

- Source: openspec/changes/model-tier-selection/tasks.md
- Lines: 1-14
- SHA256: 4bd0137b291afdf89d583c870a017f6b3b219452d6e074b15c4f3af1cdd96d12

```md
## 1. 核心脚本

- [ ] 1.1 实现 `src/scripts/comet-model-tier.sh` — 解析 `.comet.yaml` task 元数据，计算复杂度评分
- [ ] 1.2 实现模型层级推荐逻辑（fast/economy/balanced/best 四档映射）
- [ ] 1.3 实现降级路径：无 model_tier 字段时输出默认模型
- [ ] 1.4 支持 `--human` 和 `--json` 输出格式，支持 `--override` 手动覆盖

## 2. 部署

- [ ] 2.1 `bin/supercomet.js` 的 `supercomet init` 增加部署模型层级脚本

## 3. 测试

- [ ] 3.1 编写 `test/shell/model-tier-selection.bats` — 覆盖各复杂度档位、降级路径、--override 覆盖
```

## openspec/changes/model-tier-selection/specs/model-tier-selection/spec.md

- Source: openspec/changes/model-tier-selection/specs/model-tier-selection/spec.md
- Lines: 1-28
- SHA256: 956fe59b723732771f057be1ec2131f600828dc28f836149a02d681e76897a63

```md
## ADDED Requirements

### Requirement: 机械实现任务用快速模型

系统 SHALL 对低复杂度任务推荐廉价/快速模型层级。

#### Scenario: 机械实现任务用快速模型
- **WHEN** 任务仅涉及 1-2 个文件且 plan 已含完整代码
- **THEN** 模型层级推荐器输出 fast/economy 层级
- **AND** 输出理由为"机械实现，plan 已含完整代码"

### Requirement: 架构审查用最强模型

系统 SHALL 对高复杂度任务推荐最强模型层级。

#### Scenario: 架构审查用最强模型
- **WHEN** 全分支审查或设计决策任务
- **THEN** 模型层级推荐器输出 best/premium 层级
- **AND** 输出理由为"架构决策，需要最强推理"

### Requirement: 降级路径

当 `.comet.yaml` 中不存在 model_tier 字段时，系统 SHALL 降级为默认模型。

#### Scenario: 模型分层降级
- **WHEN** `.comet.yaml` 中不存在 model_tier 字段
- **THEN** 推荐器使用当前 session 的默认模型
- **AND** 输出 INFO 级别信息"使用默认模型"
```

