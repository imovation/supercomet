## Why

Comet 工作流缺少正式的结构化探索阶段。用户在面对开放性需求时直接从 `/comet-open` 开始，缺乏系统化的方案对比和选型分析。增加探索阶段可降低决策风险，产出可追溯的探索记录。

## What Changes

- 新增 `comet-speculate` Skill：完整探索模式，生成 2-3 个方案对比（含优缺点、工作量估算、推荐方案）
- 新增 `comet-quick-speculate` Skill：快速探索模式，仅出推荐方案，跳过多方案对比
- 探索结果持久化为 `explore-findings.md`
- `/comet-open` 检测 `explore-findings.md` 后自动注入为 proposal 上下文
- 探索阶段为可选（pre-hook），不阻塞不修改 Comet 任何阶段流转

## Capabilities

### New Capabilities
- `comet-speculate`: 结构化探索阶段——在 `/comet-open` 之前提供方案对比、工作量估算与推荐，产出 `explore-findings.md` 并交接给 open 阶段

### Modified Capabilities
<!-- None -->

## Impact

- 新增 Skill 文件：`src/skills/comet-speculate/SKILL.md`、`src/skills/comet-quick-speculate/SKILL.md`
- 新增 Shell 脚本：`src/scripts/comet-speculate.sh`
- 修改 `bin/supercomet.js`：`supercomet init` 部署 speculate Skill 文件
- 修改 `/comet-open` Skill 逻辑：检测并注入 `explore-findings.md`
- 核心侵入——优先向上游 Comet 提 PR，未合并前作为独立 Skill 部署
