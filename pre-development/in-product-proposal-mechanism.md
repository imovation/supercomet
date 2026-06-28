# supercomet 产品内提案机制

## 当前做法

用户有新想法时，手动在 `pre-development/` 目录创建 markdown 文件，描述问题和建议方向。然后在新会话中用 `/comet` 启动正式 change。

## 问题

- **发现门槛高**：用户必须知道 `pre-development/` 目录存在且理解其用途
- **格式不统一**：随手写的 md 文件结构各异，agent 理解成本高
- **无跟踪**：写在文件里的提案无人跟进，容易石沉大海
- **与 Comet 割裂**：提案是提案，change 是 change，两者没有自动衔接
- **无社区参与**：单机操作，只有自己看得到
- **质量不可控**：人写的提案存在根因分析错误、问题描述歧义、建议方向偏差等问题，会误导新会话的 AI。AI 读到的"问题"可能是伪问题，"根因"可能是表象

## 建议方案

### 核心思路：AI 驱动自动提案

人类手动发现 → 写提案 → AI 读，这条链路存在信息损失和失真。

正确链路应该是：

```
AI 在使用 supercomet 过程中自动感知异常
  → AI 自动生成提案（结构化、可追溯、带证据）
    → 人工审核确认
      → /comet
```

### 自动发现触发点

supercomet 在以下时机自动评估是否需要提案：

| 触发时机 | 发现内容 | 示例 |
|---------|---------|------|
| `/comet-verify` 失败 | 流程阻塞点、重复失败模式 | 同一类验证失败出现 3 次 → 提案"验证失败自动分类" |
| `supercomet init` 被 `--force` | 预检机制设计问题 | `--force` 使用频率高 → 提案"降低预检误报" |
| 归档后提交次数异常 | 流程真空（amend 需求） | 归档后 3 天内 5+ 次非 Comet 提交 → 提案"归档后修补入口" |
| BATS 测试失败模式 | 脚本正确性问题 | 特定脚本在特定 Comet 版本持续失败 → 提案"兼容性适配" |
| 会话中用户重复表达困惑 | UX / 文档问题 | 同一概念被问 3 次 → 提案"文档补充" |
| CI Sentinel 连续失败 | 上游断裂 | 3 天连续失败 → 提案"紧急适配" |

### 提案自动生成

AI 发现问题后，自动创建结构化提案：

```markdown
---
status: ai-generated
created: 2026-06-28
discovered-by: supercomet-agent
discovery-context: /comet-verify phase, change=init-preflight-check
evidence:
  - commit: abc123 (direct-to-master bypass)
  - session-log: .superpowers/sdd/progress.md
confidence: high | medium | low
---

## 观察到的问题

<!-- AI 根据实际运行日志、错误输出、用户行为自动填写 -->

## 推断的根因

<!-- AI 基于上下文分析 -->

## 建议方向

<!-- 2-3 个方案，含工作量估算 -->
```

关键：`confidence` 字段标注 AI 对分析的信心，低信心提案人工审核门槛更高。

### 人工审核环

AI 生成的提案进入 `openspec/proposals/` 目录：

1. `supercomet proposals` 列出所有待审核提案，按 confidence 排序
2. 人工对每条提案选择：确认、修正根因、拒绝（附理由）
3. 确认后 `status: accepted`，可直接 `/comet-open`
4. 被拒绝的提案作为训练数据，提升后续准确率


