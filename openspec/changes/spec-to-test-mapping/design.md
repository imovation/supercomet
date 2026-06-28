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
