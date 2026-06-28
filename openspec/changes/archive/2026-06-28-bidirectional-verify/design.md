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
