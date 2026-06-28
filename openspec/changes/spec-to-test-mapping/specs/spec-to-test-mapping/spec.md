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
