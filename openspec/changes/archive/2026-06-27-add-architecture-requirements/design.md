## Context

`supercomet-产品形态与开发环境方案-定稿.md` 已经通过双份 AI 独立分析交叉验证审定了 supercomet 的 8 项架构决策。当前主 spec（`openspec/specs/supercomet/spec.md`）仅覆盖 7 个功能增强，缺失了这些非功能架构约束。本 change 将架构决策编码为可验证的 OpenSpec Requirement，纳入主 spec。

## Goals / Non-Goals

**Goals:**
- 将 8 项架构决策转换为 OpenSpec Requirement + Scenario 格式
- 新增 Requirement 遵循与已有功能 Requirement 一致的 GIVEN/WHEN/THEN 格式
- 使 P0-1 双向反查脚本能够扫描这些 Requirement 并验证对应测试覆盖

**Non-Goals:**
- 不修改已有的 7 个功能 Requirement
- 不改变 spec.md 本身的文件结构（追加式扩展，不重构）
- 不涉及代码实现，仅规格文档变更

## Decisions

**决策1：采用 ADDED 而非 MODIFIED**

8 项架构决策均为新增 Requirement，不与已有功能 Requirement 冲突或修改已有行为。使用 `## ADDED Requirements` delta 操作，避免 MODIFIED 的部分内容风险。

**决策2：Scenario 使用中文，格式对齐已有 spec**

已有 spec.md 已全部中文化（"给定/当/则"格式）。新增 Requirement 保持一致，确保文件可读性和追溯脚本能统一解析。

**决策3：在已有 spec.md 末尾追加，不重排顺序**

已有 7 个功能 Requirement 按优先级（P0→P2）排列。架构 Requirement 逻辑上独立于功能，追加在末尾，以 `## 架构约束` 分隔标题区分。

**决策4：每个 Requirement 至少 1 个 Scenario，部分配 2-3 个**

遵循 OpenSpec 硬性要求（每个 Requirement 必须至少 1 个 Scenario）。对可验证行为多的（如降级路径、哨兵机制）配置多个 Scenario。

## Risks / Trade-offs

- [Risk] 架构 Requirement 的 Scenario 部分较抽象（如"给定 supercomet 已安装，当 Comet 内部实现变更，则 supercomet 不受影响"）→ Mitigation: 每个 Scenario 尽量绑定可自动化检查的具体条件
- [Risk] 定稿.md 未来更新可能导致 spec 与源文档不一致 → Mitigation: 在 spec.md 中添加定稿.md 源引用
