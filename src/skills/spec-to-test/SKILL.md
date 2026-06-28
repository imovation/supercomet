# spec-to-test Mapping Skill

## Description

将 spec.md 中的 GIVEN/WHEN/THEN Scenario 自动转换为测试用例骨架。解析 `#### Scenario:` 块，检测测试框架，生成测试函数模板。格式异常时降级标记 [MANUAL]。

## When to Use

- Comet build 阶段需要快速生成测试入口时
- spec.md 已包含完整的 Scenario 声明
- 需要多框架适配（Jest、Vitest、Pytest、Go-test）

## Protocol

### Step 1: 确认 spec 文件

确认目标 spec.md 路径，检查 Scenario 块是否存在。

### Step 2: 检测或指定框架

框架检测优先级：显式 `--framework` flag > 项目配置文件 > 通用格式。

### Step 3: 调用脚本

```bash
bash comet/scripts/comet-spec-to-test.sh <spec-file> --framework jest --output test/skeleton.test.js
```

## Output

测试函数骨架，每步以注释标注，末尾添加 `// TODO: implement test logic`。

## Degradation

- 无 Scenario 块 → [MANUAL] 标记 + WARN
- 无效框架 → 降级为 generic 格式 + WARN
- spec 文件损坏 → 不写输出 + ERROR exit 1

## Dependencies

- bash >= 4.0
- grep, sed (POSIX)
