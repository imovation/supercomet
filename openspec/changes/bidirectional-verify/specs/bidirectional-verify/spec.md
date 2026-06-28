## ADDED Requirements

### Requirement: 双向反查

`bidirectional-verify` SHALL 作为 `/comet-verify` 的附加验证项，执行 spec↔test 双向反查，产出 `traceability.md`。

#### Scenario: 正向反查——spec 到 test
- GIVEN 一个 change 的 spec 文件位于 `openspec/changes/<name>/specs/`
- WHEN `/comet-verify` 运行 bidirectional-verify
- THEN spec 中每一个 Scenario 必须有对应的测试函数
- AND 覆盖率不足时必须阻止 verify→archive 转移

#### Scenario: 反向反查——test 到 spec
- GIVEN 测试文件中包含测试函数
- WHEN `/comet-verify` 运行 bidirectional-verify
- THEN 每个测试函数必须可追溯到某个 spec Scenario
- AND 孤儿测试以 WARN 级别报告

#### Scenario: 消费 v6.0 交接材料
- GIVEN Superpowers v6.0 的 task-brief 和 review-package 文件
- WHEN bidirectional-verify 运行时
- THEN 优先以这些文件为输入源，而非对全量 spec/ 和 test/ 做 grep
- AND v6.0 文件不可用时降级为全量 grep

#### Scenario: traceability.md 的闸门判定
- GIVEN traceability.md 已产出
- WHEN comet-guard.sh 评估 verify→archive 转移
- THEN 必须检查 traceability.md 中 Gate = PASS 方可放行

### Requirement: 零侵入部署

supercomet 的 bidirectional-verify SHALL 通过部署 Shell 脚本和 Skill 文件实现，不修改 Comet 核心代码。

#### Scenario: 部署方式
- GIVEN `supercomet init` 执行
- WHEN 部署 bidirectional-verify
- THEN `comet-forward-trace.sh` 和 `comet-backward-trace.sh` 被复制到 `comet/scripts/`
- AND `bidirectional-verify.md`（参考文档）被复制到 `comet/reference/`
- AND 不修改任何 Comet 核心文件（comet-state.sh、comet-guard.sh 等）

### Requirement: 降级路径

bidirectional-verify SHALL 在上游产出格式变化时具备降级路径。

#### Scenario: v6.0 文件不可用
- GIVEN Superpowers v6.0 的 task-brief 或 review-package 文件不可用或格式变化
- WHEN bidirectional-verify 运行
- THEN 降级为对 spec/ 和 test/ 目录的全量 grep 扫描
- AND 输出 WARN 级别信息："使用全量扫描，未利用 v6.0 优化"
