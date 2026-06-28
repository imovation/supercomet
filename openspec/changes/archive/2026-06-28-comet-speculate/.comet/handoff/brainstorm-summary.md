# Brainstorm Summary

- Change: comet-speculate
- Date: 2026-06-28

## 确认的技术方案

**架构分工**：Shell 脚本（comet-speculate.sh）作为框架+验证器，接受 YAML 临时文件输入，验证并转换为结构化 Markdown 输出。Agent 负责方案推理、对比、推荐决策。SKILL.md 文件定义 Agent 探索流程指引。

**CLI 接口**：`comet-speculate.sh --mode full|quick --from-file <yaml-path>` → 产出 `openspec/explore-findings.md`

**双模式**：单一脚本 `--mode full`（含 2-3 方案对比节）和 `--mode quick`（仅推荐方案节），减少代码重复。

**交接**：`/comet-open` 在 init 阶段检测 `openspec/explore-findings.md` 存在时，自动读取并注入为 proposal 起草上下文。

## 关键取舍与风险

- [风险] YAML 格式变化 → 缓解：版本号标注，/comet-open 检测版本后降级
- [风险] Comet 上游不合并 speculate PR → 缓解：作为独立 Skill 分发
- [取舍] 未选择纯交互模式（CLI 逐个 prompt）—— Agent 需要以编程方式调用，不适合交互

## 测试策略

- BATS 单元测试：YAML→Markdown 转换、缺少字段检测、格式异常降级
- 集成测试：speculate → open 交接检测

## Spec Patch

无——delta spec 已覆盖全部 3 个 Scenario。
