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
