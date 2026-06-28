---
comet_change: bidirectional-verify
role: technical-design
canonical_spec: openspec
archived-with: 2026-06-28-bidirectional-verify
status: final
---

# bidirectional-verify Design Doc

## Background

supercomet 需要为 Comet 工作流增加 `bidirectional-verify` 增强——作为 `/comet-verify` 的附加验证项，执行 spec↔test 双向追溯，产出 `traceability.md`。该增强继承自 specpower 的 `bidirectional-verify` Skill 和 `forward-trace.sh`（53 行）+ `backward-trace.sh`（60 行），被重构为 Comet 的零侵入扩展。

当前状态：`src/scripts/` 和 `src/skills/bidirectional-verify/` 均为空目录，`bin/supercomet.js` 为存根。

## Architecture

```
/comet-verify
    │
    ├── 现有验证项 1-N ...
    │
    └── [新增] bidirectional-verify
         │
         ├── comet-forward-trace.sh (正向反查)
         │   · 提取 specs/ 中所有 #### Scenario: 名称
         │   · 在 test/ 目录中搜索对应测试函数
         │   · 覆盖率 < 100% → traceability.md 末尾 GATE: BLOCKED
         │   · 退出码: 0=PASS, 1=BLOCKED
         │
         ├── comet-backward-trace.sh (反向反查)
         │   · 提取所有 test function 名称
         │   · 比对 spec 中的 Scenario
         │   · 孤儿测试 → WARN，不 blocking
         │   · 退出码始终 0
         │
         └── 输出 traceability.md (5 段式 + 末尾 GATE: 行)
```

### 设计决策

| 决策 | 选型 | 理由 |
|------|------|------|
| 实现语言 | 纯 Shell (grep/sed/awk) | 零依赖，与 specpower 一致，快速轻量 |
| 脚本结构 | 双脚本分离 | 正向 Hard Gate / 反向 WARN 语义不同 |
| 输入优先级 | v6.0 → 全量 grep | 优先消费 task-brief + review-package |
| Gate 输出 | traceability.md 内嵌 GATE: 行 | 单文件，简化 comet-guard.sh 解析 |
| 部署方式 | supercomet init cp 注入 | 零侵入，不改 Comet 核心 |

## Input Source Priority

```
IF task-brief + review-package 存在 (v6.0 模式)
  → comet-forward-trace.sh: 从 task-brief 提取 Scenario → 在 review-package 变更 test 文件中搜索
  → comet-backward-trace.sh: 从 review-package 提取变更 test 文件 → 反向搜索 spec
ELSE
  → 全量 grep spec/ 和 test/ 目录
  → 输出 WARN: "使用全量扫描，未利用 v6.0 优化"
```

v6.0 文件路径：`openspec/changes/<name>/.comet/handoff/` 下的 task-brief 和 review-package。

## Output Format: traceability.md

```markdown
# Spec ↔ Test Traceability Report

## 1. Coverage Matrix (正向：Spec → Test)
| Requirement | Scenario | Test Found | Status |
| Session Exp | Default timeout | test_expire_24h | ✅ |
| Session Exp | Remember me (30d) | NOT FOUND | ❌ |
Coverage: N/M = XX%

## 2. Orphan Tests (反向：Test → Spec)
| Test Function | Matched Scenario | Status |
| test_random   | (无匹配)        | ⚠️ WARN |

## 3. Edge Case Analysis
| Scenario | GIVEN Condition | Code Branch? |
| Idle timeout | inactive 30min | ✅ timer.sh:45 |

## 4. Gate Verdict
Spec Coverage: ✅ PASS / ❌ BLOCKED
Test Orphans: ✅ CLEAN / ⚠️ N orphan(s)

## 5. Next Action
✅ → Proceed to archive
❌ → Blocking: {N} missing scenarios. Return to implementer.

GATE: PASS
```

末尾 `GATE: PASS` 或 `GATE: BLOCKED` 供 comet-guard.sh 的 `grep '^GATE:'` 解析。

## File Structure

```
src/
├── scripts/
│   ├── comet-forward-trace.sh    # 正向反查脚本
│   └── comet-backward-trace.sh   # 反向反查脚本
└── skills/
    └── bidirectional-verify/
        └── SKILL.md              # 能力描述、协议、降级策略

bin/
└── supercomet.js                 # 更新 init 子命令

test/
└── shell/
    └── bidirectional-verify.bats # BATS 测试
```

部署到目标项目后：
```
comet/scripts/
├── comet-forward-trace.sh        # ← supercomet 注入
└── comet-backward-trace.sh       # ← supercomet 注入

comet/reference/
└── bidirectional-verify.md       # ← supercomet 注入
```

## Testing Strategy

BATS 测试覆盖三路径：

1. **正向路径**：mock spec 含 3 个 Scenario，mock test 含其中 2 个 → 66% coverage → GATE: BLOCKED
2. **降级路径**：task-brief/review-package 不存在 → WARN + 全量 grep 成功
3. **反向路径**：mock test 含孤儿测试 → WARN 标记，退出码 0
4. **全通过路径**：100% match → GATE: PASS

## Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| test/ 目录结构不标准导致 grep 漏匹配 | 递归搜索 + NOT FOUND 行标记 |
| Scenario 名称含特殊字符 | shell-safe 转义后 grep |
| task-brief/review-package 格式变化 | 降级全量 grep + WARN |
| 大量孤儿测试污染报告 | 汇总计数，逐条列出不阻断 |
