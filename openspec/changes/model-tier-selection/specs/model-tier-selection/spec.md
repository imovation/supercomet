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
