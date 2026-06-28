# Brainstorm Summary

- Change: bidirectional-verify
- Date: 2026-06-28

## 确认的技术方案

- **实现语言**：纯 Shell 脚本（grep/sed/awk），零依赖
- **架构**：双脚本分离——`comet-forward-trace.sh`（正向反查，退出码决定 Gate）+ `comet-backward-trace.sh`（反向反查，孤儿测试 WARN）
- **输入源优先级**：v6.0 task-brief + review-package → 全量 grep spec/ + test/
- **输出**：traceability.md（5 段式 + 末尾 `GATE:` 行）
- **部署**：`supercomet init` 通过 cp 零侵入注入

## 关键取舍与风险

- 纯 Shell vs Node.js → 选 Shell，与 specpower 一致，快速轻量
- 内嵌 GATE 行 vs 单独 gate 文件 → 选内嵌，单文件简化部署
- 风险：test/ 目录结构不标准 → 递归搜索 + NOT FOUND 标记
- 风险：Scenario 名称含特殊字符 → shell-safe 转义

## 测试策略

BATS 测试三路径：正向（覆盖率不足 → BLOCKED）、降级（v6.0 不可用 → WARN + grep）、反向（孤儿测试 → WARN）

## Spec Patch

无。现有 delta spec 已完整覆盖需求。
