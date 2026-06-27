# Comet 项目评估报告

> **评估对象**：[rpamis/comet](https://github.com/rpamis/comet)（`@rpamis/comet` v0.3.11）
>
> **评估目的**：决定 OpenSpec × Superpowers 深度融合的下一步方向
>
> **评估日期**：2025-06-26

---

## 一、评估框架

### 原点问题

> OpenSpec 和 Superpowers 如何取长补短、优势互补、分工协作、无缝融合？

评估全程锚定这个原点问题，而非锚定我们的已有方案。

### 决策矩阵

| 决策 | 触发条件 |
|------|----------|
| **完全用它** | Comet 在回答原点问题上明显更优，且我们没有不可替代的独到之处 |
| **基于它扩展** | Comet 的核心解正确，但缺了我们发现的某些关键维度 |
| **部分参考，独立迭代** | Comet 在某些设计点上优于我们，但核心架构不如我们的简洁/适合 |
| **完全不参考** | Comet 要么没真正解决原点问题，要么方案存在结构性缺陷 |
| **融合出新方案** | 两方案各有优劣，结合后产生第三个更好的解 |

---

## 二、Comet 深度剖析

### 2.1 项目概况

| 属性 | 值 |
|------|----|
| 名称 | `@rpamis/comet` |
| 版本 | v0.3.11 |
| 提交数 | 218 |
| 许可证 | MIT |
| 技术栈 | TypeScript (CLI) + Shell (状态机) + BATS (测试) + Vitest (测试) |
| 平台支持 | 29 个 AI 编码平台 |
| 语言 | 中文 + 英文双语言 |

### 2.2 架构：三层 + 五阶段管线

```
┌─────────────────────────────────────────────────────────────────┐
│                      COMET 整体架构                               │
│                                                                  │
│  Layer 1: OpenSpec (WHAT) → Layer 2: Bridge (Shell 脚本)         │
│  → Layer 3: Superpowers (HOW 执行)                                │
│                                                                  │
│  五阶段管线：/comet-open → /comet-design → /comet-build           │
│            → /comet-verify → /comet-archive                      │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 核心能力

| 能力 | 实现 |
|------|------|
| **状态机** | `comet-state.sh`（1338 行）— `.comet.yaml` CRUD + transition 引擎 |
| **阶段守卫** | `comet-guard.sh`（778 行）— 退出条件验证 + --apply 自动转阶段 |
| **上下文交接** | `comet-handoff.sh`（390 行）— SHA256 确定性上下文包 |
| **写保护** | PreToolUse hooks — open/design/archive 阶段禁止写代码文件 |
| **预设模式** | full / hotfix / tweak + 自动升级条件 |

### 2.4 部署后的项目结构

```
your-project/
├── .comet/config.yaml
├── openspec/changes/<name>/
│   ├── .openspec.yaml
│   ├── .comet.yaml
│   ├── proposal.md / design.md / tasks.md
│   ├── specs/<capability>/spec.md
│   └── .comet/handoff/
└── docs/superpowers/
    ├── specs/ / plans/ / reports/
```

---

## 三、我们的方案 vs Comet：逐项对比

### 3.1 总体方案一致性

两者核心思路完全相同——"OpenSpec 管 WHAT + Superpowers 管 HOW + 桥接层连接两者"。Comet 的 5 阶段划分比我们更精细（将"设计"独立为正式阶段）。

### 3.2 6 个重难点对比

| 重难点 | 我们的方案 | Comet | 结论 |
|--------|----------|------|------|
| 规格格式不兼容 | Skill 读取 → 手动调用 writing-plans | handoff.sh 生成 SHA256 上下文包 | Comet 更可靠 |
| 任务粒度断层 | 两级分解 | 两级分解 + build_mode 显式选择 + direct_override 锁 | Comet 更好 |
| 理念冲突（流体 vs 刚性） | Prompt 文本约定 | PreToolUse hooks 物理阻止写入 + guard.sh | **Comet 显著优于** |
| 上下文持久化 | 进度账本手动维护 | .comet.yaml 状态机自动追踪 phase | Comet 更好 |
| 审查流程重叠 | 3 层审查 | 2 层 + comet-state scale 自动缩放强度 | Comet 更好 |
| Agent 触发优先级 | 静态路由表 | Phase 自动检测 + 守卫脚本 | Comet 更好 |

---

## 四、Comet 独有的亮点（我们未曾想到的）

| # | 设计 | 说明 |
|---|------|------|
| 1 | Shell 脚本作为工作流基础设施 | 可执行、确定性、不可绕过 |
| 2 | PreToolUse hooks 写保护 | 物理层面阻止设计阶段写代码 |
| 3 | SHA256 上下文交接 | 防篡改验证 |
| 4 | .comet.yaml 与 .openspec.yaml 解耦 | 独立演进 |
| 5 | 29 平台 + 平台特定 hook 注入 | 生产级覆盖 |
| 6 | direct_override 锁 | 默认阻止跳过 TDD |
| 7 | archive-reopen 逃生舱 | 归档前可回退 |
| 8 | Web 面板 | 可视化进度 |
| 9 | 渐进加载参考文档 | 减少 token 开销 |
| 10 | 上下文压缩（beta） | 25-30% token 节省 |

---

## 五、我们方案中优于 Comet 的点

| # | 优势 | 说明 |
|---|------|------|
| 1 | Spec Requirement → 测试用例自动映射 | Comet 的 brainstorming → writing-plans 需 Agent 手动推导测试 |
| 2 | 任务→Git Commit 双向可追溯 | 进度账本精确记录三维映射 |
| 3 | 子Agent 模型分层选择策略 | 按任务复杂度路由模型 |

---

## 六、综合评价

| 维度 | Comet | 我们的方案 |
|------|-------|-----------|
| 需求层能力 | ★★★★★ | ★★★★★ |
| 实现层能力 | ★★★★★ | ★★★★★ |
| **桥接质量** | ★★★★★ | ★★★☆☆ |
| **架构健壮性** | ★★★★★ | ★★☆☆☆ |
| **工程完整度** | ★★★★★ | ★☆☆☆☆ |

---

## 七、最终决策：基于 Comet 扩展

Comet 是我们方案的工程化升级版——用 Shell 脚本代替 prompt 文本、用 PreToolUse hooks 代替软性约定、用 SHA256 代替手动桥接。不应从头自建，而应将我们独有的三个增强（Spec-to-Test 映射、双向 Traceability、子Agent 模型分层）贡献给 Comet。

> 详见《OpenSpec-Superpowers-深度融合-最终方案-v2.md》。
