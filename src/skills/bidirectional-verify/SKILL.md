# bidirectional-verify Skill

## Description

作为 `/comet-verify` 的附加验证项，执行 spec↔test 双向追溯验证，产出 `traceability.md`。

## Protocol

### Inputs

| 参数 | 说明 | 来源 |
|------|------|------|
| `--change-name` | Change 名称 | comet-verify 传递 |
| `--change-dir` | Change 目录路径 | comet-verify 传递 |
| `--spec-dir` | Spec 目录（默认 `<change-dir>/specs`） | comet-verify 传递 |
| `--test-dir` | 测试目录（默认 `test/`） | 固定配置 |
| `--output-dir` | 输出目录（默认 `.`） | 固定配置 |

### Input Sources (优先级)

1. **v6.0 mode** — 优先消费 `task-brief` + `review-package`（位于 `<change-dir>/.comet/handoff/`），缩小搜索范围到变更文件
2. **Fallback mode** — task-brief/review-package 不可用时，全量 grep `spec/` 和 `test/` 目录，输出 WARN

### Outputs

- `traceability.md` — 5 段式报告：
  1. Coverage Matrix — 每个 Scenario 的测试覆盖状态
  2. Orphan Tests — 无对应 Scenario 的测试方法（WARN）
  3. Edge Case Analysis — 边界条件扫描（需人工补充）
  4. Gate Verdict — 覆盖率和孤儿测试的综合判定
  5. Next Action — 通过或阻塞说明
- 末尾 `GATE: PASS` 或 `GATE: BLOCKED` 供 comet-guard.sh 解析
- Exit code: 0 = PASS（允许归档），1 = BLOCKED（阻止归档）

### Degradation

| 上游问题 | 降级行为 |
|---------|---------|
| task-brief/review-package 不存在 | 全量 grep + WARN 信息 |
| Spec 目录无 .md 文件 | 空覆盖矩阵 → GATE: BLOCKED |
| Test 目录不存在 | 所有 Scenario 标记 NOT FOUND → GATE: BLOCKED |
| Scenario 含特殊字符 | sed 转义后 grep |

## Files

```
src/
├── scripts/
│   ├── comet-forward-trace.sh     # 正向反查主脚本（编排器）
│   └── comet-backward-trace.sh    # 反向反查辅助脚本
└── skills/
    └── bidirectional-verify/
        └── SKILL.md               # 本 Skill 定义

comet/ (部署后)
├── scripts/
│   ├── comet-forward-trace.sh     # supercomet init 注入
│   └── comet-backward-trace.sh    # supercomet init 注入
└── reference/
    └── bidirectional-verify.md    # supercomet init 注入
```

## Usage

```bash
# 在 /comet-verify 中调用
bash comet/scripts/comet-forward-trace.sh \
  --change-name bidirectional-verify \
  --spec-dir openspec/changes/bidirectional-verify/specs \
  --test-dir test \
  --output-dir .
```

## Dependencies

- bash >= 4.0 (for `declare -a`)
- grep, sed, find (POSIX)
- 无外部依赖
