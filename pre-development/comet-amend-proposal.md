# 问题：Comet 归档后修补缺少规范入口

## 事件回顾

`init-preflight-check` change 按 Comet tweak 流程完成归档。随后在执行端到端测试时，连续发现 10+ 个问题（shebang 修复、检测路径调整、消息分化、`--force` 参数、`postinstall` 脚本等），每个都是 1-2 行代码的修补。所有这些修补都绕过了 Comet，直接往 master 提交。

## 根因

归档后的修补存在流程真空：**没有对应"小修补"的 Comet 入口**。

| 修补类型 | 现有入口 | 摩擦 |
|---------|---------|------|
| 新特性/大改动 | /comet（full） | 太重 |
| 小优化（未归档） | /comet-tweak | 正常 |
| bug 修复（未归档） | /comet-hotfix | 正常 |
| **归档后的 1 行修补** | **无** | **只能绕过** |

hotfix 和 tweak 的逻辑是"当前 change 的快速路径"，前提是有活跃 change。归档后 change 已关闭——对已归档 change 做修补时，两者都不适用：

- `/comet-tweak`：语义上 tweak 要创建新 change，但修补应关联到原 change
- 直接往 master 改：方便，违反协议
- 走完整 `/comet`：1 行改动，open→design→build→verify→archive 全套下来太重

**结果**：大多数人会在"方便"和"合规"之间选方便。

## supercomet 的定位

supercomet 立项就是为了增强 Comet 流程。之前 7 个增强（双向追溯、结构化探索等）聚焦于**质量保障**（可追溯、可验证），但没有覆盖**流程纪律**（怎么让人不容易犯规）。

## 建议方向

### 方案 1（推荐）：`/comet-amend` — 归档后修补专用入口

- 接受已归档 change 名称，自动关联
- 创建最小 change，跳过 brainstorming、plan
- 1-2 文件单次提交，直接归档
- 归档记录标注为"amend of <original-change-name>"

### 方案 2（辅助）：提交旁路检测

- 有活跃 change 或最近刚归档 change 时警告
- 不解决问题 1（`init-preflight-check` 当时没有活跃 change）

**推荐优先方案 1**，因为它直接对应根因：先有入口才能有纪律。

---

**简言之：归档后修补是 Comet 流程的一个黑市——人人都用，但没人承认。用 supercomet 把它合法化。**
