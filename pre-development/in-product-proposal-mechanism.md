# supercomet 产品内提案机制

## 当前做法

用户有新想法时，手动在 `pre-development/` 目录创建 markdown 文件，描述问题和建议方向。然后在新会话中用 `/comet` 启动正式 change。

## 问题

- **发现门槛高**：用户必须知道 `pre-development/` 目录存在且理解其用途
- **格式不统一**：随手写的 md 文件结构各异，agent 理解成本高
- **无跟踪**：写在文件里的提案无人跟进，容易石沉大海
- **与 Comet 割裂**：提案是提案，change 是 change，两者没有自动衔接
- **无社区参与**：单机操作，只有自己看得到

## 建议方案

### CLI 命令

```bash
supercomet propose              # 交互式创建提案（引导填写模板）
supercomet propose --list       # 列出所有待处理提案
supercomet propose --open <id>  # 基于某个提案直接 /comet-open
supercomet propose --close <id> # 标记提案为已处理
```

### 提案模板（标准化）

`openspec/proposals/<YYYY-MM-DD>-<slug>.md`：

```markdown
---
status: draft | accepted | implemented | rejected
created: 2026-06-28
author: <user>
---

## 问题

<!-- 描述遇到的问题或发现的机会 -->

## 建议方向

<!-- 2-3 个可能的方案，含优缺点 -->

## 影响评估

<!-- 对现有功能、架构、用户的影响 -->

## 关联

<!-- 关联的已归档 change、上游 issue 等 -->
```

### 与 Comet 衔接

1. `supercomet propose` → 生成标准化提案文件
2. 提案文件包含 `status: accepted` 后，`/comet-open` 可自动读取
3. Change 归档时，关联的提案自动标记为 `implemented`
4. archive 目录中包含提案 → change 的双向链接

### 可选：GitHub Issue 同步

- `supercomet propose --sync` 将提案同步为 GitHub Issue
- 社区可在 Issue 上讨论，结论回写到提案文件
