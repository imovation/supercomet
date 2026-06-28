# comet-speculate Skill

## Description

作为 /comet-open 之前的可选结构化探索阶段。以完整模式运行，生成 2-3 个方案对比（各含优缺点 + 工作量估算），明确推荐方案并说明理由，产出 `openspec/explore-findings.md`。

## When to Use

- 用户请求一个新功能但实现路径不清晰时
- 多个技术方案需要权衡利弊时
- 需要对工作量做粗略估算以帮助决策时

## Protocol

### Step 1: 明确探索主题

向用户确认：
- 要解决的核心问题是什么
- 有哪些明确的需求或约束
- 探索的范围边界（不做什么）

### Step 2: 提出 2-3 个方案

分析并提出 2-3 个可行方案，每个方案描述：
- **名称**：简短标识（如 "方案 A: 纯前端方案"）
- **优缺点**：至少 1 个优点和 1 个缺点
- **工作量估算**：用时间单位描述（如 "3天"、"1周"）

必须包含至少 2 个方案，不超过 3 个。

### Step 3: 形成推荐

基于方案对比，明确推荐 1 个方案并解释理由。理由必须具体，与优缺点和业务目标相关。

### Step 4: 写出 YAML 输入

将探索结果写入临时 YAML 文件：

```yaml
topic: "用户功能的实现方式"
summary: "一句话概述核心问题和解决方案空间"
options:
  - name: "方案 A: 纯前端"
    pros:
      - "简单直接"
      - "部署无依赖"
    cons:
      - "性能有限"
    effort: "3天"
  - name: "方案 B: 前后端分离"
    pros:
      - "可扩展"
    cons:
      - "复杂度高"
      - "部署成本高"
    effort: "5天"
recommendation: "方案 A"
reason: "符合当前项目架构，开发周期短，满足 MVP 需求"
```

### Step 5: 调用 comet-speculate.sh

```bash
bash comet/scripts/comet-speculate.sh --mode full --from-file /tmp/explore-input.yaml
```

脚本验证 YAML 并生成 `openspec/explore-findings.md`。

## YAML Schema

### Full Mode

| 字段 | 必须 | 类型 | 说明 |
|------|------|------|------|
| topic | 是 | string (非空) | 探索主题 |
| summary | 否 | string | 一句话概述 |
| options | 是 | list (2-3 项) | 可选方案列表 |
| options[].name | 是 | string (非空) | 方案名称 |
| options[].pros | 是 | list (≥1 项) | 优点列表 |
| options[].cons | 是 | list (≥1 项) | 缺点列表 |
| options[].effort | 否 | string | 工作量估算 |
| recommendation | 是 | string (非空) | 推荐方案名称 |
| reason | 是 | string (非空) | 推荐理由 |

## Output

脚本产出 `openspec/explore-findings.md`，包含以下节：

- **Topic**: 探索主题
- **Mode**: full
- **Date**: 生成日期
- **Version**: 输出格式版本
- **Summary**: 概述
- **Options**: 方案对比表（每方案含 Pros/Cons/Effort）
- **Recommendation**: 推荐方案及理由

## Degradation

| 上游问题 | 降级行为 |
|---------|---------|
| YAML 解析失败 | WARN stderr, exit 0, 不产出文件 |
| 缺少非必须字段 (effort) | INFO, 跳过该字段 |
| 缺少必须字段 | WARN stderr, exit 1 |
| comet-speculate.sh 不可用 | 手动写 explore-findings.md |

## Dependencies

- comet-speculate.sh (部署在 comet/scripts/)
- bash >= 4.0
- grep, sed (POSIX)
