## Why

`openspec/specs/supercomet/spec.md` 当前只覆盖了 7 个功能增强（P0-1 ~ P2-7），缺失了 `supercomet-产品形态与开发环境方案-定稿.md` 中已审定的架构决策——产品形态、上游兼容性机制、开发环境方法论、测试约束。这些决策是 supercomet 的非功能根基，必须编码为可验证的 OpenSpec Requirement，才能被双向反查（P0-1）和后续验证流程覆盖。

## What Changes

- 向 `openspec/specs/supercomet/spec.md` 新增约 8 项架构/非功能 Requirement，覆盖：
  - 产品分发形态（npm 包 + peerDependencies）
  - 🔵🟡🔴 三级侵入性分层约束
  - 四级上游兼容性机制（消费产出文件、降级路径、版本哨兵、上游 PR 优先）
  - 开发环境方法论（渐进式狗粮替换）
  - 测试工具链（BATS + 集成测试）
  - 自身 spec 管理（dogfooding 约束）

## Capabilities

### New Capabilities

<!-- 无新增 capability，本 change 是对已存在 spec 的扩展 -->
（无）

### Modified Capabilities

- `supercomet`: 新增 8 项架构/非功能 Requirement（产品分发形态、侵入性分层、四级兼容机制、开发环境、测试、dogfooding 等）

## Impact

- `openspec/specs/supercomet/spec.md` — 新增约 8 个 Requirement + 对应 Scenario
- 未来开发阶段中，双向反查脚本将扫描这些新增 Requirement，验证其 Scenario 是否被测试覆盖
- 无 breaking changes，纯增量扩展
