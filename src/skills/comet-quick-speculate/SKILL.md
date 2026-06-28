# comet-quick-speculate Skill

## Description

作为 /comet-open 之前的快速探索捷径。跳过方案对比，直接输出推荐方案及理由，产出 `openspec/explore-findings.md`（标注 mode: quick）。

## When to Use

- 需求明确的小改动，无需多方案对比
- 用户已心中有方案，只需记录决策理由
- 对已有功能的微调或配置变更

## Protocol

### Step 1: 明确探索主题

向用户确认：
- 要解决的核心问题
- 已有偏好方案或约束

### Step 2: 形成推荐

直接给出推荐方案和理由，不展开多方案对比。

### Step 3: 写出 YAML 输入

将快速探索结果写入临时 YAML 文件：

```yaml
topic: "Feature X 的实现方式"
summary: "一句话概述"
recommendation: "方案 A"
reason: "因为 xxx"
```

### Step 4: 调用 comet-speculate.sh

```bash
bash comet/scripts/comet-speculate.sh --mode quick --from-file /tmp/explore-input.yaml
```

## YAML Schema

### Quick Mode

| 字段 | 必须 | 类型 | 说明 |
|------|------|------|------|
| topic | 是 | string (非空) | 探索主题 |
| summary | 否 | string | 一句话概述 |
| recommendation | 是 | string (非空) | 推荐方案 |
| reason | 是 | string (非空) | 推荐理由 |

## Output

与完整模式输出格式相同，但 Mode 字段为 quick，且不包含 Options 节。

## Degradation

| 上游问题 | 降级行为 |
|---------|---------|
| YAML 解析失败 | WARN stderr, exit 0 |
| comet-speculate.sh 不可用 | 手动写 explore-findings.md |
