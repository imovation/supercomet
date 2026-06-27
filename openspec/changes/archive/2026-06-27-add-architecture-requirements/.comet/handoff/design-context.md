# Comet Design Handoff

- Change: add-architecture-requirements
- Phase: design
- Mode: compact
- Context hash: 89f00062922e75ec6d0c906acb1b8f14a8d60a52f14fab8e6fd2228a9d64bb84

Generated-by: comet-handoff.sh

OpenSpec remains the canonical capability spec. This handoff is a deterministic, source-traceable context pack, not an agent-authored summary.

## openspec/changes/add-architecture-requirements/proposal.md

- Source: openspec/changes/add-architecture-requirements/proposal.md
- Lines: 1-30
- SHA256: cc9b5e55b4ec6d36acda886eeebf8f9f102969ce96e4be65bfe5d8be565191d9

```md
## Why

`openspec/specs/supercomet/spec.md` 当前只覆盖了 7 个功能增强（P0-1 ~ P2-7），缺失了 `supercomet-产品形态与开发环境方案-定稿.md` 中已审定的架构决策——产品形态、上游兼容性机制、开发环境方法论、测试约束。这些决策是 supercomet 的非功能根基，必须编码为可验证的 OpenSpec Requirement，才能被双向反查（P0-1）和后续验证流程覆盖。

## What Changes

- 向 `openspec/specs/supercomet/spec.md` 新增约 8 项架构/非功能 Requirement，覆盖：
  - 产品分发形态（npm 包 + peerDependencies）
  - 🔵🟡🔴 三级侵入性分层约束
  - 四级上游兼容性机制（消费产出文件、降级路径、版本哨兵、上游 PR 优先）
  - 开发环境方法论（渐进式狗粮替换）
  - 测试工具链（BATS + 集成测试）
  - 自身 spec 管理（dogfooding 约束）

## Capabilities

### New Capabilities

<!-- 无新增 capability，本 change 是对已存在 spec 的扩展 -->
（无）

### Modified Capabilities

- `supercomet`: 新增 8 项架构/非功能 Requirement（产品分发形态、侵入性分层、四级兼容机制、开发环境、测试、dogfooding 等）

## Impact

- `openspec/specs/supercomet/spec.md` — 新增约 8 个 Requirement + 对应 Scenario
- 未来开发阶段中，双向反查脚本将扫描这些新增 Requirement，验证其 Scenario 是否被测试覆盖
- 无 breaking changes，纯增量扩展
```

## openspec/changes/add-architecture-requirements/design.md

- Source: openspec/changes/add-architecture-requirements/design.md
- Lines: 1-38
- SHA256: 9ad32f483caf3baac386108000770c9519f3536529c68475c44cb8bfec58f7cd

```md
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
```

## openspec/changes/add-architecture-requirements/tasks.md

- Source: openspec/changes/add-architecture-requirements/tasks.md
- Lines: 1-15
- SHA256: 3f575bf97edf3cd90afe189d6f877abc7a968db8aab344c8fedd5f47cc87652a

```md
## 1. 准备工作

- [ ] 1.1 审查已有 `openspec/specs/supercomet/spec.md`，确认追加位置和格式一致性
- [ ] 1.2 审查 delta spec（`specs/supercomet/spec.md`）内容完整性，逐项对齐 `定稿.md`

## 2. 实施

- [ ] 2.1 将 delta spec 中的 8 项 `## ADDED Requirements` 追加到主 spec `openspec/specs/supercomet/spec.md` 末尾
- [ ] 2.2 追加 `## 架构约束` 分隔标题，与已有功能 Requirement 区分
- [ ] 2.3 在 spec.md 顶部添加定稿.md 源引用说明

## 3. 验证

- [ ] 3.1 运行 `openspec validate --strict` 确认 spec 格式合法
- [ ] 3.2 人工逐项检查 8 个新增 Requirement 的 Scenario 完整性和可验证性
```

## openspec/changes/add-architecture-requirements/specs/supercomet/spec.md

- Source: openspec/changes/add-architecture-requirements/specs/supercomet/spec.md
- Lines: 1-175
- SHA256: 568cec8d5d11c802e317389d089318201c86c9fd54fc9a98a15cbdf51450406f

[TRUNCATED]

```md
# supercomet Delta Spec — 架构约束

> **源文档**：`supercomet-产品形态与开发环境方案-定稿.md` v1.0（2025-06-27 审定）
>
> 本 delta spec 向已有 `supercomet` spec 新增架构/非功能 Requirement。

---

## ADDED Requirements

### Requirement: 产品分发形态

supercomet SHALL 以 npm 包形态独立分发，不 fork、不修改 Comet 任何源代码。通过 `peerDependencies` 声明对 `@rpamis/comet >=0.3.0` 的依赖，用户自行管理 Comet 版本。安装命令为 `npm install -g supercomet`，部署命令为 `supercomet init`。

#### Scenario: npm 包结构正确
- 给定 supercomet 的 `package.json` 
- 当 检查包结构
- 则 `name` 必须为 `supercomet`
- 且 `bin` 必须包含 `supercomet` 入口
- 且 `peerDependencies` 必须声明 `@rpamis/comet >=0.3.0`

#### Scenario: 不包含 Comet 源码
- 给定 supercomet 发布的 npm 包内容
- 当 检查包内文件
- 则 不得包含 Comet 核心 Shell 脚本（comet-state.sh、comet-guard.sh 等）的副本
- 且 不得包含 `assets/skills/comet/` 目录

---

### Requirement: 三级侵入性分层

supercomet SHALL 将 7 个增强按侵入性分为三级：🔵 零侵入（部署文件，不改 Comet）、🟡 轻侵入（合并 .comet.yaml schema + 追加白名单）、🔴 核心侵入（优先向上游提 PR，PR 未合并时作为独立 Skill 部署）。

#### Scenario: 零侵入项的部署方式
- 给定 supercomet 的零侵入增强（bidirectional-verify、Spec-to-Test 映射、Revert-Restore、Git Notes）
- 当 `supercomet init` 执行
- 则 仅部署 Skill 文件或 Shell 脚本到 Comet 已有目录
- 且 不修改任何 Comet 核心文件（comet-state.sh、comet-guard.sh、comet-handoff.sh 等）

#### Scenario: 轻侵入项的合并方式
- 给定 supercomet 的轻侵入增强（三维 Traceability、模型分层）
- 当 `supercomet init` 执行
- 则 `.comet.yaml` 的 schema 扩展通过追加方式合并，不覆盖已有字段
- 且 `comet-state.sh` 的白名单通过追加方式扩展，不修改已有命令

#### Scenario: 核心侵入的上游优先策略
- 给定 supercomet 的核心侵入增强（comet-speculate）
- 当 增强开发完成
- 则 优先向 Comet 上游提交 PR
- 且 PR 未合并时，作为独立 Skill 部署，不修改 Comet 入口调度器

---

### Requirement: 消费产出文件，不依赖上游内部实现

supercomet 的增强 SHALL 仅读取上游（Comet、Superpowers、OpenSpec）的产出文件作为输入，不得引用、导入或依赖上游内部实现代码。

#### Scenario: bidirectional-verify 的输入源
- 给定 bidirectional-verify 运行
- 当 收集输入数据
- 则 输入必须来自 task-brief、review-package、spec.md、test/ 目录等产出文件
- 且 不得引用 Superpowers SDD 内部审查流程的代码或数据结构

#### Scenario: 上游内部重构不影响 supercomet
- 给定 Comet 或 Superpowers 的某个内部实现文件被重构（产出文件格式不变）
- 当 supercomet 的增强功能运行
- 则 功能必须正常运行，不受内部重构影响

---

### Requirement: 每个功能有降级路径

supercomet 的每个增强 SHALL 在上游产出格式变化时具备降级路径，不得因上游变更而报错阻断 Comet 工作流。

#### Scenario: bidirectional-verify 降级
- 给定 Superpowers v6.0 的 task-brief 或 review-package 文件不可用或格式变化
- 当 bidirectional-verify 运行
- 则 降级为对 spec/ 和 test/ 目录的全量 grep 扫描
- 且 输出 WARN 级别信息："使用全量扫描，未利用 v6.0 优化"

```

Full source: openspec/changes/add-architecture-requirements/specs/supercomet/spec.md

