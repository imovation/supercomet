# Comet Design Handoff

- Change: bidirectional-verify
- Phase: design
- Mode: compact
- Context hash: 58d7392aec7c7be21aaa341acafd140bffd4de0b8648d4c84aafe26b635cb029

Generated-by: comet-handoff.sh

OpenSpec remains the canonical capability spec. This handoff is a deterministic, source-traceable context pack, not an agent-authored summary.

## openspec/changes/bidirectional-verify/proposal.md

- Source: openspec/changes/bidirectional-verify/proposal.md
- Lines: 1-30
- SHA256: acff8457201c38cddde061b44a67919abc8c796566d45ef5985e254a199d5a7b

```md
## Why

supercomet 作为 Comet 技能扩展包，需要提供 spec↔test 双向追溯能力来确保所有 Scenario 都有对应测试覆盖，并在 verify 阶段产出标准化的 `traceability.md` 报告。这是 7 个增强中优先级最高的 P0 项，也是后续增强（如 P0-2 三维追溯）的依赖基础。

## What Changes

- 新增 `comet-forward-trace.sh` — 正向反查脚本：提取 change spec 中所有 `#### Scenario:` 名称，在 `test/` 中 grep 对应测试函数
- 新增 `comet-backward-trace.sh` — 反向反查脚本：提取测试函数名称，比对 spec Scenario，标记孤儿测试
- 新增 `bidirectional-verify` Skill 文件 — 定义协议、输入源、输出格式、降级路径
- 新增 `supercomet init` 部署逻辑 — 将上述文件注入到 `comet/scripts/` 和 `comet/reference/`
- 新增 `test/shell/` BATS 测试 — 覆盖正向路径和降级路径
- 优先消费 Superpowers v6.0 的 `task-brief` / `review-package` 作为输入源；不可用时降级为全量 grep
- 输出 `traceability.md`，包含覆盖矩阵、孤儿测试、边界分析、闸门判定

## Capabilities

### New Capabilities
- `bidirectional-verify`: spec↔test 双向追溯验证，作为 /comet-verify 的附加验证项

### Modified Capabilities
- *无修改已有 capability*

## Impact

- 新增 `src/scripts/comet-forward-trace.sh`
- 新增 `src/scripts/comet-backward-trace.sh`
- 新增 `src/skills/bidirectional-verify/SKILL.md`
- 新增 `test/shell/bidirectional-verify.bats`
- 更新 `bin/supercomet.js`（init 子命令部署逻辑）
- 不修改任何 Comet 核心文件（零侵入）
```

## openspec/changes/bidirectional-verify/design.md

- Source: openspec/changes/bidirectional-verify/design.md
- Lines: 1-50
- SHA256: 1dbaa29ee9271efc27011400aeeecdf4d29ad277b4672a46971ffc47a320cf74

```md
## Context

supercomet 需要为 Comet 工作流增加 `bidirectional-verify` 增强——作为 `/comet-verify` 的附加验证项，执行 spec↔test 双向追溯。该增强继承自 specpower 的 `bidirectional-verify` Skill 和 `forward-trace.sh`（53 行）+ `backward-trace.sh`（60 行），被重构为 Comet 的零侵入扩展。

当前状态：`src/scripts/` 和 `src/skills/bidirectional-verify/` 均为空目录，`bin/supercomet.js` 为存根。

## Goals / Non-Goals

**Goals:**
- 实现 `comet-forward-trace.sh`：提取 change spec 中所有 `#### Scenario:` 名称，在 `test/` 目录中搜索对应测试函数，标记缺失覆盖
- 实现 `comet-backward-trace.sh`：提取测试函数名称，比对 spec Scenario，标记孤儿测试
- 优先消费 Superpowers v6.0 的 `task-brief` / `review-package` 文件作为输入源
- 不可用时降级为全量 grep spec/ + test/
- 输出标准化的 `traceability.md`（覆盖矩阵、孤儿测试、边界分析、闸门判定、下一步行动）
- 实现 `supercomet init` 部署逻辑，零侵入注入到 `comet/scripts/` 和 `comet/reference/`
- BATS 测试覆盖正向路径和降级路径

**Non-Goals:**
- 不修改 Comet 核心 Shell 脚本（comet-state.sh, comet-guard.sh, comet-handoff.sh）
- 不实现 P0-2 三维追溯账本（含 commit 映射）
- 不实现其他增强（spec-to-test, model-tiering, revert-restore, git-notes）

## Decisions

### 1. 双脚本设计（分离正向/反向）
- **决策**：保持两个独立脚本 (`comet-forward-trace.sh` + `comet-backward-trace.sh`)，而非合并为一个
- **理由**：与 specpower 原始设计一致；正向反查是 Hard Gate（阻断 verify→archive），反向反查是 WARN 级别，职责分离便于独立维护和测试。合并脚本的条件判断会引入不必要的复杂度
- **备选**：单脚本 `comet-bidirectional-trace.sh` → 拒绝，因为两个方向的闸门语义不同

### 2. 输入源优先级策略
- **决策**：三级输入优先级：task-brief + review-package → full-grep
- **理由**：v6.0 已将交接材料文件化，task-brief 含涉及的 spec 范围，review-package 含变更文件 diff。优先消费这些文件将 grep 范围从全仓库缩小到变更范围，性能更好且更精确
- **备选**：始终全量 grep → 拒绝，失去 v6.0 优化机会

### 3. traceability.md 输出格式
- **决策**：5 段式标准化报告，继承自 specpower 的 spec-compliance-check Skill
- **理由**：结构化输出便于 comet-guard.sh 解析闸门状态；一致的格式便于狗粮消耗（P0-2 等后续增强依赖此格式）

### 4. 部署方式
- **决策**：`supercomet init` 通过 `cp` 将脚本从 `src/scripts/` 复制到 `comet/scripts/`，将 `SKILL.md` 复制到 `comet/reference/`
- **理由**：零侵入——不修改 Comet 核心文件；幂等——复制不报错；卸载只需删除文件

## Risks / Trade-offs

| 风险 | 缓解措施 |
|------|---------|
| test/ 目录结构不标准导致 grep 漏匹配 | 支持递归搜索并输出 NOT FOUND 行——不静默失败 |
| task-brief/review-package 格式变化 | 降级路径：全量 grep + WARN 输出 |
| 大量孤儿测试污染报告 | 输出汇总计数，不逐行 BLOCK，仅在报告中列出 |
| spec Scenario 名称含特殊字符导致 grep 失败 | 脚本对 Scenario 名称做 shell-safe 转义后再 grep |
```

## openspec/changes/bidirectional-verify/tasks.md

- Source: openspec/changes/bidirectional-verify/tasks.md
- Lines: 1-31
- SHA256: 1f085e23e55aeac642245882b73747c2f9126ab451f9a121aee32543bd20f643

```md
## 1. 正向反查脚本实现

- [ ] 1.1 实现 `src/scripts/comet-forward-trace.sh`：提取 spec 中 `#### Scenario:` 名称，在 test/ 中搜索对应测试函数
- [ ] 1.2 实现输入源优先级：优先消费 task-brief 和 review-package，不可用时降级全量 grep
- [ ] 1.3 输出覆盖率数据：已覆盖 N/M 个 Scenario，覆盖率不足 100% 时设置 Gate = BLOCKED

## 2. 反向反查脚本实现

- [ ] 2.1 实现 `src/scripts/comet-backward-trace.sh`：提取测试函数名称，比对 spec Scenario
- [ ] 2.2 孤儿测试标记：无对应 spec Scenario 的测试以 WARN 级别报告，不阻断流程

## 3. traceability.md 生成

- [ ] 3.1 实现 5 段式标准化报告输出：覆盖矩阵、孤儿测试、边界分析、闸门判定、下一步行动
- [ ] 3.2 确保输出格式可被 comet-guard.sh 解析闸门状态（Gate = PASS/BLOCKED）

## 4. Skill 定义与部署

- [ ] 4.1 创建 `src/skills/bidirectional-verify/SKILL.md`：定义能力描述、输入输出协议、降级策略
- [ ] 4.2 更新 `bin/supercomet.js`：实现 `init` 子命令的部署逻辑（cp 脚本到 comet/scripts/，参考文档到 comet/reference/）

## 5. BATS 测试

- [ ] 5.1 编写 `test/shell/bidirectional-verify.bats`：正向路径（场景全覆盖）测试
- [ ] 5.2 编写降级路径测试：task-brief/review-package 不可用时验证全量 grep 降级行为
- [ ] 5.3 编写反向路径测试：孤儿测试被正确 WARN 且不阻断

## 6. 关键集成验证

- [ ] 6.1 验证 traceability.md 闸门格式与 comet-guard.sh 兼容
- [ ] 6.2 验证 `supercomet init` 幂等执行（多次运行不报错）
```

## openspec/changes/bidirectional-verify/specs/bidirectional-verify/spec.md

- Source: openspec/changes/bidirectional-verify/specs/bidirectional-verify/spec.md
- Lines: 1-49
- SHA256: 6d9da8d8762ac2fa4ff65567dbaf8be999b19a4416df960cecbb9058f2f20b4d

```md
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
```

