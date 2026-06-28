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
