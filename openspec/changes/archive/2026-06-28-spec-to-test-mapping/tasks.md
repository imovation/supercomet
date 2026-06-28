## 1. 核心脚本

- [x] 1.1 实现 `src/scripts/comet-spec-to-test.sh` — 解析 spec.md 的 Scenario 节，提取 GIVEN/WHEN/THEN 步骤
- [x] 1.2 实现测试框架检测逻辑（Jest/Vitest/Pytest/Go-test）
- [x] 1.3 实现框架对应的测试函数骨架生成
- [x] 1.4 实现降级路径：格式异常时标记 [MANUAL] + WARN 输出

## 2. Skill 文件与部署

- [x] 2.1 创建 `src/skills/spec-to-test/SKILL.md` — Skill 声明
- [x] 2.2 `bin/supercomet.js` 的 `supercomet init` 增加部署映射器脚本

## 3. 测试

- [x] 3.1 编写 `test/shell/spec-to-test-mapping.bats` — 覆盖正常解析、多框架输出、降级路径
