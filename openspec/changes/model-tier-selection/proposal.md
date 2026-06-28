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
