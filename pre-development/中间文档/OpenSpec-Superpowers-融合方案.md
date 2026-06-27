# OpenSpec × Superpowers 深度融合方案

> **核心命题**：OpenSpec 更擅长管需求，保证做对的事；Superpowers 更擅长管实现，保证把事情做对。两者如何取长补短、优势互补、分工协作、无缝融合？

---

## 一、总体方案：三层协作架构

OpenSpec 和 Superpowers 的定位存在天然互补关系——**OpenSpec 专精于"做什么"（WHAT：需求层），Superpowers 专精于"怎么做"（HOW：实现层）**。两者的融合不需要互相侵入，而是通过"需求层 → 计划层 → 执行层"的清晰分工实现端到端覆盖。

### 1.1 协作全景

```
┌─────────────────────────────────────────────────────────────────┐
│                     完整开发循环                                  │
│                                                                  │
│  ┌──────────────────────┐                                       │
│  │  OpenSpec (需求层)    │  ← WHAT：管需求，保证做对的事          │
│  │  · /opsx:explore     │     · 结构化规格（Requirements +       │
│  │  · /opsx:propose     │       Scenarios + RFC 2119 关键词）    │
│  │  · specs/ deltas     │     · Delta 式变更（ADDED/MODIFIED/    │
│  │  · tasks.md          │       REMOVED）——天生适合已有系统       │
│  │  · /opsx:verify      │     · 持久化上下文（存在 Git 仓库中，   │
│  │  · /opsx:archive     │       不在聊天记录里丢失）               │
│  └──────┬───────────────┘     · 团队协作：通过 Git PR 审查        │
│         │                                                        │
│         │  产出：proposal.md + spec.md + design.md + tasks.md    │
│         ▼                                                        │
│  ┌──────────────────────┐                                       │
│  │  Bridge (计划层)      │  ← 桥接层：需求翻译为可执行计划         │
│  │  openspec-to-        │     · 读取 OpenSpec 完整 change 上下文  │
│  │    superpowers       │     · 将 spec.md 的 Requirements +     │
│  │                      │       Scenarios 注入计划               │
│  │                      │     · 将 tasks.md 展开为 TDD 微任务     │
│  └──────┬───────────────┘     · 标注每个微任务覆盖的 Spec Req ID  │
│         │                                                        │
│         │  产出：2-5分钟/任务的微任务执行计划                      │
│         ▼                                                        │
│  ┌──────────────────────┐                                       │
│  │  Superpowers (执行层) │  ← HOW Execute：保证把事情做对         │
│  │  · subagent-driven-  │     · 每个微任务一个独立子Agent         │
│  │    development       │     · 强制 TDD：RED-GREEN-REFACTOR     │
│  │  · test-driven-      │     · 两级审查：规格符合性 ✅ + 代码质量 ✅│
│  │    development       │     · 进度账本（防上下文压缩丢失）      │
│  │  · requesting-code-  │     ·  最终分支审查                     │
│  │    review            │                                        │
│  │  · finishing-branch  │                                        │
│  └──────┬───────────────┘                                       │
│         │                                                        │
│         ▼                                                        │
│  ┌──────────────────────┐                                       │
│  │  OpenSpec (收尾)      │  ← 闭环                                │
│  │  · /opsx:verify      │     · 完整性：所有任务是否完成？         │
│  │  · /opsx:archive     │     · 正确性：实现是否匹配提案意图？     │
│  └──────────────────────┘     · 一致性：设计方案是否落地？         │
│                               · Delta 合并到主规格 → 归档        │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 各就其位：分工矩阵

| 维度 | OpenSpec | Superpowers |
|------|----------|-------------|
| **定位** | 记录系统（System of Record） | 执行引擎（Execution Engine） |
| **核心理念** | "先约定，再自信地构建" | "先写测试，再看它失败" |
| **核心产出** | 结构化规格文档 + Delta 变更 | 可执行微任务 + 测试 + 审查报告 |
| **擅长领域** | 需求探索、范围界定、规格化、团队对齐 | 严格 TDD、子Agent执行、质量把关、系统调试 |
| **上下文持久化** | Git 仓库中的 `openspec/`（永久） | Git 仓库 `docs/superpowers/` + `.superpowers/sdd/` 进度账本 |
| **团队协作** | 通过 Git PR 审查规格和变更 | 通过代码审查 |
| **治理风格** | "Enablers, not gates"（流体） | "Iron Law"（刚性） |
| **跨 Agent** | 25+ 编码 Agent 原生支持 | 10+ 编码 Agent 插件支持 |
| **Brownfield 适配** | ★★★★★ Delta 机制天生适合已有系统 | ★★★ 依赖代码库探索 |
| **执行纪律** | ★★ 不强制 TDD / 审查 | ★★★★★ 铁律级别强制 |

---

## 二、重难点：关键问题及解决方案

### 问题1：规格格式不兼容

**问题描述**：OpenSpec 使用结构化的 `spec.md`（Requirements + Scenarios + RFC 2119 关键词：SHALL/MUST/SHOULD），Superpowers 的 brainstorming 产出是自由格式的 `design.md`。两者之间缺乏直接映射，无法将规格自动转化为测试用例。

**解决方案：以 OpenSpec spec.md 为唯一法源，Spec Requirement → Test Case 自动映射**

OpenSpec 的 `spec.md` 作为规格的唯一权威来源。在桥接层中，每个 Requirement 和 Scenario 被转换为 Superpowers 微任务的测试骨架。关键规则：桥接层不修改 `spec.md`，只读取；每个微任务必须在头部标注覆盖的 OpenSpec Requirement ID。

### 问题2：任务粒度断层

**问题描述**：OpenSpec 的 `tasks.md` 是检查清单级别的（如 "1.1 创建 ThemeContext"，粒度约 10-30 分钟/项），Superpowers 的 `writing-plans` 要求 2-5 分钟的微任务（含精确代码和完整测试）。中间存在粒度跳跃。

**解决方案：两级分解，桥接层自动展开**

- Level 1（OpenSpec tasks.md）：粗粒度，用于人类审查和进度跟踪（10-20项/特性）
- Level 2（Superpowers writing-plans）：细粒度，由 Agent 自动将每个 Level 1 任务展开为 2-5 分钟的微任务（每项 Level 1 任务 → 3-8 个微任务）

### 问题3：理念冲突——"流体" vs "刚性"

**问题描述**：OpenSpec 强调 "Enablers, not gates"（无阶段门禁，允许回退修改），Superpowers 强调铁律（必须先写测试才能写代码，必须先审查才能继续）。两者的执行哲学存在张力。

**解决方案：按阶段分配治理强度**

在"探索要做什么"的时候保持流体（OpenSpec），在"执行怎么做"的时候保持刚性（Superpowers）。探索阶段无门禁，规格审批是硬门禁（人工审查），执行阶段铁律级别。

---

## 三、如何工程化

### 3.1 实施路线图

```
Phase 1: 桥接核心（1-2周）
  ├── 创建 openspec-to-superpowers Skill
  ├── 实现 spec.md → 微任务测试用例的自动映射
  ├── 实现 tasks.md → 微任务链的自动展开
  └── 进度账本扩展（OpenSpec Task ID ↔ Git Commit）

Phase 2: 流程编排（1周）
  ├── 定义融合 Schema（spec-driven-superpowers）
  ├── 实现路由规则
  ├── 目录结构约定 + 文档
  └── 端到端测试（完整开发循环）

Phase 3: 工具链（1周）
  ├── CI/CD 集成：PR 时自动运行 /opsx:verify
  ├── 进度可视面板
  └── 团队规范文档 + 培训材料
```

### 3.2 桥接 Skill 设计

桥接 Skill (`openspec-to-superpowers`) 负责读取 OpenSpec 的 proposal/specs/design/tasks，调用 Superpowers 的 writing-plans 展开微任务，保存到 `docs/superpowers/plans/`。

### 3.3 核心设计原则

1. **OpenSpec 是记录系统（System of Record）**——需求、规格、变更历史以它为准
2. **Superpowers 是执行引擎（Execution Engine）**——实现质量、测试纪律、代码审查以它为准
3. **桥接层是胶水**——自动、透明，不增加开发者心智负担
4. **两者都不需要被修改核心逻辑**——通过 Skill 和 Schema 机制实现无缝对接

---

> **后续**：此方案在设计阶段后被 `rpamis/comet` 评估替代。Comet 是本方案的工程化升级版——Shell 脚本状态机代替 prompt 文本、PreToolUse hooks 代替软性约定、SHA256 上下文交接代替手动桥接。最终决策：基于 Comet 扩展，而非从头自建。

> 详见《OpenSpec-Superpowers-深度融合-最终方案-v2.md》。
