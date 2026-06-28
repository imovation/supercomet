---
comet_change: three-d-traceability
role: technical-design
canonical_spec: openspec
archived-with: 2026-06-28-three-d-traceability
status: final
---

# three-d-traceability Design Doc

## Background

P0-1 实现了 spec↔test 双向反查。P0-2 在此基础上加入 Task→Git Commit 维度，形成完整三维追溯链。通过轻侵入扩展 `.comet.yaml` schema 和 `comet-state.sh` 白名单实现。

## Architecture

```
                 comet-trace.sh
                      │
      ┌───────────────┼───────────────┐
      ▼               ▼               ▼
  --requirement-id  --commit       无效输入
  grep .comet.yaml  grep .comet.yaml  返回错误
```

### Data Model

`.comet.yaml` task 条目扩展字段：

```yaml
tasks:
  - id: "1.1"
    description: "实现 comet-forward-trace.sh"
    requirement_id: "bidirectional-verify"
    scenario: "正向反查——spec 到 test"
    test_file: "test/shell/bidirectional-verify.bats"
    test_name: "forward trace 100pc coverage passes gate"
    commits:
      - abc123def
```

### Query Output (缩进树)

```
$ comet-trace.sh --requirement-id bidirectional-verify
Requirement: bidirectional-verify
  └── Scenario: 正向反查——spec 到 test
       └── Test: forward trace 100pc coverage passes gate
            ├── Commit: abc123def
            │    └── Task: 1.1 实现 comet-forward-trace.sh
            └── Commit: def456abc
                 └── Task: 3.1 traceability.md 组装
```

### Set-Task Command

`comet-state.sh set-task <change-name> <task-id>` 写入对应 task 的追溯字段值。

### Gate

`comet-guard.sh` 在 verify→archive 转移时检查每个 completed task 的 `commits` 非空。

## Design Decisions

| 决策 | 选型 | 理由 |
|------|------|------|
| 数据存储 | .comet.yaml task 字段 | 与状态机绑定，无需新文件 |
| 查询接口 | 单脚本（--requirement-id / --commit） | 逻辑简单可合并 |
| 输出格式 | 缩进树 | 终端友好，人类可读 |
| 侵入性 | 轻侵入 | schema 追加 + 白名单扩展，不改核心 |

## Files

```
src/scripts/comet-trace.sh           # 双向追溯查询脚本
test/shell/comet-trace.bats          # BATS 测试
```

## Testing

BATS 测试 5 场景：
1. 正向查询（--requirement-id）
2. 反向查询（--commit）
3. 无效 requirement_id
4. 无效 commit hash
5. 空 commits 闸门
