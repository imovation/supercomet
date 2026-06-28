## Context

Comet 当前无探索阶段，用户面对开放式需求时缺少结构化方案对比。supercomet 规格（P1-3）要求新增 comet-speculate 和 comet-quick-speculate 两个入口。

此增强为**核心侵入**级别——优先向上游 Comet 提 PR，PR 未合并前作为独立 Skill 部署。

遵循已有模式：所有增强用 Shell 脚本实现，通过 Skill 文件声明入口，由 `supercomet init` 部署。

## Goals / Non-Goals

**Goals:**
- 提供完整探索模式（2-3 方案对比 + 推荐）
- 提供快速探索模式（直接推荐）
- 产出持久化 `explore-findings.md`
- `/comet-open` 自动检测并注入探索结果
- 可选 hook，不阻塞或修改 Comet 阶段流程

**Non-Goals:**
- 不替代 `/comet-design` 的 brainstorming
- 不修改 Comet 入口调度器（核心侵入优先向上游提 PR）
- 不提供 AI 自动探索（explore 调用由用户或上层 agent 发起）

## Decisions

### 1. Shell 脚本 + Skill 文件

**选择**：Shell 脚本编排 + Skill 文件声明入口

**理由**：与现有 P0-1/P0-2 实现模式一致。`comet-forward-trace.sh` 等已建立 Shell 脚本作为增强实现的标准模式。

**替代方案**：
- Node.js 脚本：引入额外运行时依赖，不必要
- Python：不符合项目技术栈

### 2. explore-findings.md 格式

**选择**：Markdown 结构化输出，固定节结构

```
# Explore Findings
## Mode: full | quick
## Summary
## Options (仅 full 模式)
### Option N: <name>
- Pros
- Cons
- Effort Estimate
## Recommendation
```

**理由**：Markdown 格式与 Comet 产出一致，固定结构便于 `/comet-open` 解析和注入。

### 3. 上游 PR 策略

**选择**：开发完成后优先向 `rpamis/comet` 提 PR 添加 `/comet-speculate` 到 Comet 入口调度器

**理由**：按 supercomet 规格的"上游 PR 优先策略"，核心侵入项先向上游贡献。PR 未合并期间作为独立 Skill 部署。

## Risks / Trade-offs

- [风险] Comet 上游不合并 PR → 缓解：作为独立 Comet Skill 持续分发，通过 `supercomet init` 部署
- [风险] `explore-findings.md` 格式未来需要变更 → 缓解：版本号标注在文件头，`/comet-open` 检测版本后降级处理
- [风险] 探索阶段被跳过导致缺少方案对比 → 缓解：可选 hook，不影响核心流程；`/comet-open` 在无 `explore-findings.md` 时正常运行
