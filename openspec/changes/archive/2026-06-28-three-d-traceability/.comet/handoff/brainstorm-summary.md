# Brainstorm Summary

- Change: three-d-traceability
- Date: 2026-06-28

## 确认的技术方案

- **数据存储**：`.comet.yaml` task 字段扩展（requirement_id / scenario / test_file / test_name / commits），不建外部 DB
- **查询接口**：`comet-trace.sh` 单脚本，`--requirement-id` 正向查 + `--commit` 反向查
- **输出格式**：缩进树（终端友好），每条链路逐行缩进展示 Requiremen→Scenario→Test→Commit→Task
- **set-task**：`comet-state.sh` 新增 `set-task` 命令，build 阶段完成后写入追溯字段
- **闸门**：comet-guard.sh 检查 commits 非空

## 关键取舍与风险

- .comet.yaml 字段膨胀 → 仅追加必要字段，不影响已有结构
- commit hash 可能失效 → 查询时 git rev-parse 验证
- 选 .comet.yaml 而非独立 JSON → 避免同步问题

## 测试策略

BATS 5 场景：正向查询 / 反向查询 / 无效 ID / 无效 commit / 空 commits 闸门

## Spec Patch

无。现有 delta spec 已完整覆盖需求。
