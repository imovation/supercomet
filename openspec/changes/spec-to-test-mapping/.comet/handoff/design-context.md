# Comet Design Handoff

- Change: spec-to-test-mapping
- Phase: design
- Mode: compact
- Context hash: 6a79f06c8214d24d19fad1954429ce172640f890105ee889307d29a955064835

Generated-by: comet-handoff.sh

OpenSpec remains the canonical capability spec. This handoff is a deterministic, source-traceable context pack, not an agent-authored summary.

## openspec/changes/spec-to-test-mapping/proposal.md

- Source: openspec/changes/spec-to-test-mapping/proposal.md
- Lines: 1-24
- SHA256: 29c7b45d43581bef8cdc83e78b3e194991d7c5738fd13a3b5a21f039722cf4cb

```md
## Why

Comet build 阶段产出的 spec.md 与测试代码之间缺少自动化映射。开发者需要手动从 Scenario 推导测试用例，效率低且容易遗漏。supercomet 提供自动化映射器，将 GIVEN/WHEN/THEN Scenario 转换为测试函数骨架。

## What Changes

- 新增 `src/scripts/comet-spec-to-test.sh` — 映射器脚本，解析 spec.md 的 Scenario 节
- 支持多测试框架检测与适配：Jest (`it()`)、Vitest (`it()`)、Pytest (`def test_`)、Go-test (`func Test`)
- 产出测试函数骨架，每步以注释标注
- 格式异常时降级：标记 Scenario 为"需手动推导"，输出 WARN

## Capabilities

### New Capabilities
- `spec-to-test-mapping`: 将 spec.md 中的 Scenario 自动转换为测试用例骨架，支持多框架适配与降级

### Modified Capabilities
<!-- None -->

## Impact

- 新增 Shell 脚本：`src/scripts/comet-spec-to-test.sh`
- 修改 `bin/supercomet.js`：`supercomet init` 部署映射器脚本
- 新增零侵入 Skill 文件：`src/skills/spec-to-test/SKILL.md`
```

## openspec/changes/spec-to-test-mapping/design.md

- Source: openspec/changes/spec-to-test-mapping/design.md
- Lines: 1-53
- SHA256: c36dcdae6ecee49fc278eca7d155e7d68105589cbe58e4429dd4dcdc29713647

```md
## Context

现有 P0-1（bidirectional-verify）已实现 spec↔test 双向反查，但仅检查覆盖关系。P1-4 向前一步：从 spec Scenario 自动生成测试骨架，让开发者有起点而非从空白开始。

此增强为零侵入级别——部署 Skill 文件或 Shell 脚本到已有目录，不修改 Comet 核心文件。

## Goals / Non-Goals

**Goals:**
- 解析 spec.md 的 Scenario 节，提取 GIVEN/WHEN/THEN 步骤
- 检测项目测试框架（Jest、Vitest、Pytest、Go-test）
- 按框架语法生成测试函数骨架
- 格式异常时降级处理

**Non-Goals:**
- 不生成完整测试逻辑代码
- 不执行测试
- 不修改 spec.md 格式

## Decisions

### 1. 框架检测策略

**选择**：按优先级检测：package.json（Jest/Vitest）→ 文件后缀（`.py` → Pytest，`_test.go` → Go-test）→ 默认通用格式

**理由**：逐一尝试各框架检测规则，命中即用。无需环境变量或配置文件。

### 2. 测试骨架格式

**选择**：注释标注 Scenario 步骤 + 空函数体

```javascript
// Scenario: 正向反查——spec 到 test
it('scenario: forward-trace-spec-to-test', () => {
  // GIVEN spec 文件包含 Scenario
  // WHEN 映射器解析 spec file
  // THEN 生成对应测试函数骨架
  // TODO: implement test logic
})
```

**理由**：开发者只需在骨架中填充具体断言，注释保留与 spec 的可追溯性。

### 3. 降级路径

**选择**：Scenario 名称前加 `[MANUAL]` 标记，输出 WARN 到 stderr，退出码 0

**理由**：不阻断工作流，与 bidirectional-verify 降级行为一致。

## Risks / Trade-offs

- [风险] 框架检测误判 → 缓解：允许用户通过环境变量 `SUPERCOMET_TEST_FRAMEWORK` 显式指定
- [风险] 复杂 Scenario（嵌套 WHEN/THEN）解析失败 → 缓解：标记为 [MANUAL]，不强行生成
```

## openspec/changes/spec-to-test-mapping/tasks.md

- Source: openspec/changes/spec-to-test-mapping/tasks.md
- Lines: 1-15
- SHA256: 974e9e08e720afa725e264815373534745329e95623832a724478a77466732d9

```md
## 1. 核心脚本

- [ ] 1.1 实现 `src/scripts/comet-spec-to-test.sh` — 解析 spec.md 的 Scenario 节，提取 GIVEN/WHEN/THEN 步骤
- [ ] 1.2 实现测试框架检测逻辑（Jest/Vitest/Pytest/Go-test）
- [ ] 1.3 实现框架对应的测试函数骨架生成
- [ ] 1.4 实现降级路径：格式异常时标记 [MANUAL] + WARN 输出

## 2. Skill 文件与部署

- [ ] 2.1 创建 `src/skills/spec-to-test/SKILL.md` — Skill 声明
- [ ] 2.2 `bin/supercomet.js` 的 `supercomet init` 增加部署映射器脚本

## 3. 测试

- [ ] 3.1 编写 `test/shell/spec-to-test-mapping.bats` — 覆盖正常解析、多框架输出、降级路径
```

## openspec/changes/spec-to-test-mapping/specs/spec-to-test-mapping/spec.md

- Source: openspec/changes/spec-to-test-mapping/specs/spec-to-test-mapping/spec.md
- Lines: 1-28
- SHA256: 08adc8373c2d26fb85fcee7d58a34feb054b16ca2c1a57a4a7d5df5cc9a2bbe3

```md
## ADDED Requirements

### Requirement: Scenario 映射为测试骨架

系统 SHALL 将 spec.md 中的 GIVEN/WHEN/THEN Scenario 自动转换为测试用例骨架。

#### Scenario: Scenario 映射为测试骨架
- **WHEN** 映射器处理包含 GIVEN/WHEN/THEN 声明的 spec.md
- **THEN** 产出测试函数骨架，每步以注释标注
- **AND** 测试函数名由 Scenario 名称派生

### Requirement: 多测试框架适配

系统 SHALL 自动检测项目测试框架并适配输出格式。

#### Scenario: 多测试框架适配
- **WHEN** 项目使用 Jest、Vitest、Pytest 或 Go-test
- **THEN** 映射器检测并适配对应的测试函数格式
- **AND** 未检测到已知框架时使用通用注释块

### Requirement: 降级路径

当 spec.md 格式无法被自动解析时，映射器 SHALL 降级处理，不阻断工作流。

#### Scenario: 格式异常降级
- **WHEN** spec.md 的格式或结构无法被映射器自动解析
- **THEN** 标记对应 Scenario 为"需手动推导"
- **AND** 输出 WARN 级别信息，退出码为 0
```

