# Superpowers 6.0 对 specpower 吸收方案的影响分析

> **背景**：specpower（v1.0.0，2026-06-04 发布）基于旧版 Superpowers（5.x 系列）设计开发。Superpowers v6.0.0（2026-06-16 发布）对 SDD 子Agent 流程进行了重大重写。

---

## 一、Superpowers v6.0 关键变更（与 specpower 相关的）

| # | 变更 | 影响 |
|---|------|------|
| 1 | 两个审查者合并为一个（`task-reviewer-prompt.md`） | 旧版 spec-reviewer + code-reviewer → 统一 reviewer，一次 diff 出双 verdict |
| 2 | Diff 和任务文本通过文件传递（`task-brief` + `review-package`） | 不再粘贴文本进 prompt |
| 3 | 每个调度必须显式指定模型 | 强制声明，引导便宜 tier |
| 4 | Controller 不允许告诉审查者忽略什么 | 禁止压制发现和预判严重级别 |
| 5 | 进度账本 `.superpowers/sdd/progress.md` | 持久化进度追踪 |
| 6 | Writing Plans 增加 Global Constraints + Interfaces 块 | 每个微任务显式声明依赖 |
| 7 | Plan 预检（Pre-Flight Read） | 扫描全计划检测内部冲突 |
| 8 | SDD scratch 文件迁移到 `.superpowers/sdd/` | 从 `.git/sdd/` 迁出 |
| 9 | Worktree 目录改为项目内 `.worktrees/` | 旧版在 `~/.config/` |
| 10 | 技能语言平台中性化 | "dispatch a subagent" 替代 "use the Task tool" |

---

## 二、specpower 5 个吸收项逐项审查

| A# | 吸收项 | v6.0 影响 | 状态 |
|----|--------|----------|------|
| A1 | 双向追溯 Shell 脚本 | 无影响（完全独立于 SDD 审查机制） | ✅ 直接吸收 |
| A2 | Triple Arbitration 状态恢复 | 增强 v6.0——v6.0.3 承认 progress ledger 会被 `git clean -fdx` 清除 | ✅ 互补增强 |
| A3 | Git Notes 原子任务绑定 | 互补——不可变备份 vs 运行时账本 | ✅ 互补 |
| A4 | 7 项验证清单 | 2 项被 v6.0 覆盖（spec + quality），5 项仍独有 | ⚠️ 修正为"5 项补充验证" |
| A5 | 17 反模式 | 无影响（框架无关参考文档） | ✅ 直接吸收 |

---

## 三、特殊情况：spec-compliance-check Skill

specpower 的 `spec-compliance-check` 设计基于旧版的两审查者模型。v6.0 合并为统一 reviewer 后，它的角色需要重新定义。

**结论**：角色升级——从"替代 Superpowers 的 spec reviewer"变为"增强 Superpowers unified reviewer 的高风险任务专用 spec 深度审查工具"。覆盖矩阵和边界分析方法论融入 bidirectional-verify 的 `traceability.md` 输出格式。

---

## 四、结论

**0 个吸收项因 v6.0 而失效。** Triple Arbitration 在 v6.0 下反而更有价值（v6.0.3 明确承认 progress ledger 被 `git clean` 清除的缺陷）。spec-compliance-check 从"替代"转为"增强"，价值聚焦。

> 详见《OpenSpec-Superpowers-深度融合-最终方案-v2.md》。
