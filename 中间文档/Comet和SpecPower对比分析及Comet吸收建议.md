# Comet和SpecPower对比分析及Comet吸收建议

> 日期: 2026-06-26
> 对象: SpecPower vs Comet 对比分析，及 SpecPower 核心资产向 Comet 迁移方案
> 前提: Superpowers 6.0 已于 2026-06-16 发布，SDD 评审链路大幅重写

---

## 一、背景

### 1.1 两个项目的共同目标

SpecPower 和 Comet 都是 **OpenSpec + Superpowers 融合编排层**，不修改 OpenSpec 和 Superpowers 源码，将两者桥接为一个完整的开发工作流。核心理念一致：

> "用 OpenSpec 管需求，实现做对的事；用 Superpowers 管实现，实现把事情做对。两者取长补短，无缝融合。"

### 1.2 各自的定位

| 维度 | Comet | SpecPower |
|------|-------|-----------|
| 设计基调 | 工程化、自动化、可靠性优先 | 规约驱动、正确性优先、文件驱动 |
| 实施方式 | TypeScript CLI + 7 个 Shell 脚本自动化门卫体系 | 纯 Shell + Markdown，990 行 All-in-one Skill |
| 规约体系 | 无独立 living spec | 6 个 spec domain，82 条可验证 Requirements |
| 社区 | 1.6k stars，29 平台支持，npm 包分发 | 个人项目 |

### 1.3 关键前提：SpecPower 基于旧版 Superpowers 设计

SpecPower 的开发基于 **Superpowers 6.0 之前版本**的 SDD（Subagent-Driven Development）架构。2026 年 6 月 16 日 Superpowers 6.0 发布后，SDD 评审链路被大幅重写，这对 SpecPower 的核心设计假设有重大影响。

---

## 二、Superpowers 6.0 的关键变化

### 2.1 SDD 评审模型变更

```
旧版 SDD (SpecPower 基于此设计):          新版 SDD (6.0):
━━━━━━━━━━━━━━━━━━━━━━━━━━            ━━━━━━━━━━━━━━━━━━━━━━━━━

implementer                             implementer
    │                                       │
    ▼                                       ▼
spec-compliance reviewer               Task Reviewer
    │                                  (一个子代理, 读一次 diff,
    ▼                                   出 spec + quality 双 verdict)
code-quality reviewer                        │
                                            ▼
两轮评审, 两份 diff 上下文              .superpowers/sdd/progress.md
顺序不可颠倒 (SpecPower 铁律)           文件化交接
```

### 2.2 文件化交接

6.0 新增了三个文件化产物：

| 文件 | 作用 |
|------|------|
| `.superpowers/sdd/task-N-brief.md` | 从计划中抽取的单任务描述，implementer 只读这个 |
| `.superpowers/sdd/review-package` | 包含 commit list、files changed、带上下文的 net diff |
| `.superpowers/sdd/progress.md` | 长任务恢复时的账本 |

### 2.3 对 SpecPower 的影响

| SpecPower 设计假设 | 6.0 冲击 | 结论 |
|-------------------|----------|------|
| 两阶段审查铁律（先 spec-compliance 后 code-quality，由独立子代理执行，顺序不可颠倒） | 6.0 合并为一个 Task Reviewer，一次读 diff 出双 verdict。benchmark 显示速度 ~2x，token ~-50%，质量不降 | **铁律被上游废弃** |
| Implement 阶段子代理审查依赖主 Agent 传递 diff | 6.0 将 diff 文件化（review-package），不做会话内粘帖 | **SpecPower 的手动处理被 6.0 自动化了** |
| 文件驱动协作是 SpecPower 的特色 | 6.0 自己走向了文件驱动（brief/review-package/progress） | **差异化缩小** |

---

## 三、OpenSpec 与 Superpowers 的核心冲突

两者在三个关键时刻存在设计哲学上的张力：

```
OpenSpec 的假设:                     Superpowers 的假设:
━━━━━━━━━━━━━━━━                    ━━━━━━━━━━━━━━━━
Spec 是真相来源                      代码是真相来源
先写 spec，再写代码                  先探索设计，spec 是副产品
Delta spec 只应在 archive 时合并     Design 是一个持续演化的过程
formal validation 是完成标准         test pass + review 是完成标准
人对 spec 的审批在 Propose 阶段      人在 Design 阶段的审批才是关键
```

### T1: 需求 → Spec 的桥接

**张力**：Superpowers brainstorming 产出自由格式的 Design Doc。OpenSpec 要求严格的 GIVEN/WHEN/THEN delta spec。谁向谁妥协？

### T2: 实现中 Spec 需要修改

**张力**：写着写着发现 spec 低估了复杂度或遗漏了边界。OpenSpec 说改 spec 应该走 change 流程。Superpowers 说"发现问题就修正"。怎么取舍？

### T3: 完成标准是什么

**张力**：OpenSpec 说 `validate --strict` 通过 + archive 完成。Superpowers 说 test pass + review pass 就算完成。以谁为准？

---

## 四、两者的处理机制对比

### 4.1 Comet: "分层分权 + 脚本仲裁"

```
        OpenSpec 域               Bridge              Superpowers 域
    ═══════════════════     ═══════════════     ═════════════════════

     proposal.md ─────┐
     design.md   ─────┤
     tasks.md    ─────┤
                      │    comet-handoff.sh
                      ├──────────►  SHA256 追踪  ──►  Design Doc + Plan
     specs/       ─────┤          context package      (Superpowers 自由格式)
                      │          
                      │          
    ←─────────────────┤    comet-guard.sh --apply    ←─  实现完成
       验证 spec        │    自动化校验                  build_mode/verify_result
       是否仍有效       │    
                      │    
    openspec archive ←─┤    comet-archive.sh         ←─  验证通过
       delta merge     │    delta → main spec merge
```

**T1 处理（需求 → Spec）**："翻译"模式。双方保持原生格式，handoff.sh 做翻译层。Design Doc 自由格式 → SHA256 溯源 → Build 阶段读压缩包。格式主权分离。

**T2 处理（Spec 中途变更）**："推迟裁决"。build 中不准改 spec。偏差推到 verify gate 由 guard.sh 统一裁决。用户可选择"接受偏差"或"回 build 修复"。小偏差 → 推迟到 verify gate，大偏差 → 触发 preset 升级（如 hotfix 改了 3+ 文件 → 自动升级为 full workflow）。

**T3 处理（完成标准）**："OpenSpec archive 是唯一终态"。test pass + review pass 是进门条件，`comet-archive.sh` 执行 delta merge 才是出门证。

### 4.2 SpecPower: "同步演化 + 人为仲裁"

```
         OpenSpec 域                     SpecPower 调度器           Superpowers 域
    ═══════════════════           ═══════════════════════     ═════════════════════

                                        Phase 1: SPECULATE
                                            │
                                            ├── Brainstorming 方法论
                                            ├── 2-3 方案对比 + 自检 4/4
                                            ├── 卡点A: 用户选方案
                                            └── explore-findings.md  ← 桥接文件
                                            │
     proposal.md  ←──────────────────────────┤  Phase 2: PROPOSE
     design.md                                │  读取 explore-findings.md
     specs/*.md  ← 严格格式                   │  按 Kahn 排序 DAG 生成
     tasks.md                                 │  卡点B: 用户审批
                                            │
                                            │  Phase 3-4: PLAN + IMPLEMENT
                                            │
     ←── 若 spec 需改 ──────────────────────┤  级联更新:
         proposal → design → specs → tasks  │  按变更源回退到对应阶段
                                            │
                                            │  Phase 5: VERIFY
                                            │  7 项 hard gate (含双向反查)
                                            │  卡点F
                                            │
     openspec archive ←────────────────────┤  Phase 6: ARCHIVE
                                            │  卡点G
```

**T1 处理（需求 → Spec）**："归化"模式。吸收 Superpowers 方法论，输出统一到 OpenSpec 格式。explore-findings.md 是中间桥接产物——Brainstorming 的方案对比被结构化注入到 proposal 的 `## Why` 中。

**T2 处理（Spec 中途变更）**："即时响应 + 级联回退"。

```
┌───────────────┬──────────────────┬─────────────────────────┐
│ 变更来源       │ 影响范围          │ 回退动作                  │
├───────────────┼──────────────────┼─────────────────────────┤
│ proposal.md   │ design → specs   │ 回退到 Propose → Plan   │
│               │ → tasks 全部重做  │                         │
├───────────────┼──────────────────┼─────────────────────────┤
│ design.md     │ specs → tasks    │ 回退到 Propose → Plan   │
│               │ 部分重做          │                         │
├───────────────┼──────────────────┼─────────────────────────┤
│ specs/        │ 增量需求→新增task │ 回退到 Propose→Plan→    │
│               │ 修改需求→revert  │ Implement               │
│               │   已完成task     │                         │
├───────────────┼──────────────────┼─────────────────────────┤
│ tasks.md      │ 已完成task保留    │ 回退到 Plan→Implement   │
│ (implement中) │ 未完成以新版为准  │                         │
└───────────────┴──────────────────┴─────────────────────────┘
```

关键约束：必须先通知用户、列出影响范围、建议回退路径、请求确认后才执行。

**T3 处理（完成标准）**："7 项 hard gate 缺一不可"。

```
① 全量测试 fresh run
② openspec validate --strict
③ spec 合规终验
④ 代码质量终验
⑤ 双向反查 (正向 100% + 反向无孤儿)  ← Comet 没有
⑥ Revert-Restore 回归                  ← Comet 没有
⑦ i18n 简体中文检查
```

### 4.3 机制对比总表

| 机制维度 | Comet | SpecPower |
|----------|-------|-----------|
| **桥接模型** | 翻译层：handoff.sh 格式转换，互不侵犯格式主权 | 归化层：吸收方法论，输出统一到 OpenSpec 格式 |
| **冲突处理策略** | 推迟裁决。build 中不改 spec，verify gate 集中处理 | 即时响应。spec 变更触发级联回退 |
| **格式权威** | El双方保持原生格式主权 | OpenSpec 格式是唯一标准 |
| **门卫实现** | Shell 脚本自动化 (guard.sh --apply, state.sh transition) | 内联指令 + Agent 自律 (HARD-GATE 文本) |
| **完成标准** | archive = 完成 (test pass 是进门条件) | 7 项验证 + archive = 完成 |
| **偏差容忍** | 允许用户接受偏差后继续 archive | 不允许。任一验证失败必须修复或回退 |
| **小改动** | hotfix/tweak 预设 + 量化升级条件 | 无快捷路径，全量 6 阶段 |
| **恢复机制** | phase 检测 + build_pause/plan-ready 中止点 | 8 checkpoint + 三重仲裁 (git log > 文件系统 > 状态) |
| **spec↔test 对齐** | 无 | bidirectional-verify 双向扫描 + traceability.md |

### 4.4 优劣总结

**Comet 做得更好的**：

1. **格式主权分离**：不强迫 Superpowers Design Doc 遵守 OpenSpec 格式。handoff.sh 做翻译层，双方保持原生表达方式。
2. **冲突的工程化处理**：guard.sh --apply 是脚本驱动的，不会"忘记检查"。比 Agent 按文本指令自律可靠。
3. **偏差的务实态度**：允许用户选择"接受偏差"继续 archive。现实中不是所有 spec 偏差都值得回退重做。
4. **分层工作流**：full / hotfix / tweak 三种模式 + 自动升级条件。

**SpecPower 做得更好的**：

1. **T1 预防层**：Speculate 阶段在 OpenSpec 和 Superpowers 真正碰撞之前做结构化探索。从源头减少冲突。
2. **T3 检验层**：bidirectional-verify 能发现"测试全绿但 spec 没全覆盖"的隐蔽不对齐。Revert-Restore 验证测试有效性。
3. **spec 变更建模**：级联更新矩阵是现实中 spec 变更影响链的完整表达。
4. **形式化规约**：82 条可验证 Requirements。

**Comet 的盲区**：

- Design Doc 和 delta spec 之间无强制关联。handoff.sh 不检查一致性
- verify gate 的"推迟裁决"可能让 implementer 基于错误 spec 白做工
- 无 spec↔test 自动化对齐检查

**SpecPower 的盲区**：

- 两阶段审查铁律被 Superpowers 6.0 废弃
- 级联回退太重且执行上依赖 Agent 自律
- 无"接受偏差"降级路径
- HARD-GATE 无脚本级强制执行
- 无快捷路径（hotfix/tweak），小改动也要走 6 个阶段

---

## 五、结论：应放弃 SpecPower 独立项目

### 5.1 三大差异化中两项已失效

| SpecPower 差异化能力 | 状态 | 原因 |
|---------------------|------|------|
| 两阶段审查铁律 | ❌ 已失效 | Superpowers 6.0 合并为单轮双 verdict 评审 |
| Speculate 探索阶段 | ✅ 可保留 | Comet 仍无此能力 |
| bidirectional-verify | ✅ 可保留 | Comet 仍无此能力 |

两项差异化撑不起一个独立项目。

### 5.2 Superpowers 6.0 强化了"切 Comet"的理由

- 6.0 的 per-task 双 verdict 评审让 SpecPower 的"推迟到 verify gate"不再成立
- 6.0 的文件化交接（brief/review-package/progress）与 SpecPower 的"文件驱动"理念一致，但这让 SpecPower 的差异化进一步缩小
- 6.0 的 SDD 基准测试（速度 ~2x, token ~-50%）是对旧版架构的最强否定

### 5.3 建议

**放弃 SpecPower 独立项目，将核心资产以可插拔扩展形式迁移到 Comet。**

---

## 六、基于 Comet 的扩展方案

### 6.1 总体架构

```
                    comet (入口调度器)
                         │
    ┌────────────────────┼────────────────────┐
    │                    │                    │
    ▼                    ▼                    ▼
┌─────────┐   ┌──────────────┐   ┌──────────────────┐
│ 现有 5   │   │ comet-       │   │ bidirectional-   │
│ 阶段流程 │   │ speculate    │   │ verify            │
│         │   │ (新增, 阶段0) │   │ (增强 verify)     │
└─────────┘   └──────────────┘   └──────────────────┘
                      │                    │
              ┌───────┴───────┐   ┌────────┴────────┐
              │ explore-      │   │ forward-trace.sh │
              │ findings.md   │   │ backward-trace.sh│
              └───────────────┘   │ traceability.md  │
                                  └──────────────────┘
```

### 6.2 扩展一: bidirectional-verify (P0 优先级)

**定位**：作为 `/comet-verify` 的附加验证项，不替代现有逻辑。

**工作原理**：

```
/comet-verify
    │
    ├── 现有验证项 1-N ...
    │
    └── [新增] bidirectional-verify
         │
         ├── 正向反查 (spec → test)
         │   │  提取 specs/ 中所有 Scenario 名称
         │   │  → grep 每个 Scenario 在 test/ 中
         │   │  → 标记无对应 test 的 Scenario
         │   └── Hard Gate: 覆盖率 ≠ 100% → BLOCK
         │
         ├── 反向反查 (test → spec)
         │   │  提取 test 文件中所有 test function
         │   │  → 比对 spec 中的 Scenario
         │   │  → 标记无法对应的 test (孤儿测试)
         │   └── 无对应 spec 的 test → WARN
         │
         └── 输出 traceability.md
              ┌─────────────────────────────────┐
              │ Scenario      │ Test           │ Status │
              │ login_ok      │ test_login_ok  │ ✅     │
              │ login_fail    │ NOT FOUND      │ ❌     │
              │ ...                             │
              │ Coverage: 15/16 = 93.75%        │
              │ Gate: ❌ BLOCKED                │
              └─────────────────────────────────┘
```

**与 Superpowers 6.0 的集成**：6.0 已将交接材料文件化（review-package、task-brief），双向反查脚本可直接消费这些文件作为输入源，不需要自己从零提取 git diff 和 task 信息。

**与 Comet 的集成点**：

| 集成点 | 实现方式 |
|--------|---------|
| comet-verify | 在验证清单中追加第 N+1 项，调用两个 shell 脚本 |
| comet-guard.sh | verify→archive 转移时校验 `traceability.md` 中 Gate = ✅ |
| .comet.yaml | 新增 `bidirectional_verify` 字段记录状态 |
| comet-state.sh | 新增 `cmd_set` 白名单项 |

**新增文件**：

```
comet/scripts/
├── comet-forward-trace.sh              # spec→test 正向扫描
└── comet-backward-trace.sh             # test→spec 反向扫描

comet/reference/
└── bidirectional-verify.md             # 完整协议文档
```

**理由**：纯增量，不改 Comet 核心，和 Comet 的 guard.sh 体系天然契合。可实现后向 Comet 上游提 PR。

### 6.3 扩展二: comet-speculate (P1 优先级)

**定位**：在 `/comet-open` **之前**插入结构化探索阶段。作为 Comet 的可选前置，不改变现有 5 阶段流程。

**工作流**：

```
用户说 "帮我做一个 X 功能"
         │
         ▼
  comet-speculate (新增, 阶段 0)
         │
         ├─ B1: 加载 config.yaml context + 项目上下文
         ├─ B2: 逐项提问澄清 (目标/约束/成功标准)
         ├─ B3: 生成 2-3 方案对比
         │      ┌──────────────────────────────────────┐
         │      │ 方案A: 描述 + ≥2优点 + ≥1缺点 + 工作量 │
         │      │ 方案B: 描述 + ≥2优点 + ≥1缺点 + 工作量 │
         │      │ 推荐方案 + 理由                       │
         │      └──────────────────────────────────────┘
         ├─ B4: 【卡点A: 用户选择方案】
         ├─ B5: 自检 (placeholder/internal/scope/ambiguity)
         └─ B6: 写入 explore-findings.md
                  │
                  ▼
           /comet-open (检测到 explore-findings.md → 作为上下文注入)
```

**与 Comet 的集成点**：

| 集成点 | 实现方式 |
|--------|---------|
| comet 入口调度 | phase=null 且无活动 change 时，优先路由到 comet-speculate |
| comet-open 衔接 | 检测 `explore-findings.md` 存在 → 读取方案+批准标记 → 注入为 proposal 上下文 |
| comet-guard.sh | speculate→open 转移时校验 explore-findings.md 存在且自检通过 |
| .comet.yaml | 新增 `speculate_doc` 字段 |
| auto_transition | speculate→open 的自动跳转遵守 `auto_transition` 配置 |

**新增文件**：

```
assets/skills/comet-speculate/SKILL.md       # Skill 定义
assets/skills/comet-speculate/reference/
├── speculate-checklist.md                   # B1-B6 步骤
└── self-review-checklist.md                 # B5 自检清单
```

**扩展分层**：同时提供 `comet-speculate`（完整 6 步，方案对比）和 `comet-quick-speculate`（精简 3 步，只出推荐方案），对应 Comet 的 full/hotfix/tweak 分层设计。

**理由**：需要修改 Comet 入口调度和 comet-open。建议先以 fork 验证可行性，再向上游提 PR。

### 6.4 扩展三: Revert-Restore 回归验证 (P2 可选)

**定位**：对标记 Security/Core/Critical 的关键变更，验证测试有效性。

```
对每个关键变更:
  git revert <实现 commit> → 运行测试 → 确认 FAIL
  git revert <revert commit> → 运行测试 → 确认 PASS
```

若撤销实现后测试仍通过 → **测试无效** → Hard Gate BLOCK。

独立验证项，可作为 comet-verify 的附加验证项，不强制。

### 6.5 不迁移的 SpecPower 能力

| 能力 | 原因 |
|------|------|
| 两阶段审查铁律 | 被 Superpowers 6.0 废弃，上游已合并为更优的单轮双 verdict |
| 级联回退矩阵 | 执行上依赖 Agent 自律无脚本验证；6.0 的 per-task 双 verdict 使级联回退更无必要；Comet 的"推迟裁决 + 接受偏差"更务实 |
| 7 项 hard gate 全部强制 | 太重。Comet 的分层工作流（hotfix/tweak）更灵活。i18n gate 是项目特定需求，不应作为通用工作流组件 |
| .specpower-state.json 三重仲裁 | Comet 的 .comet.yaml + guard.sh 体系更可靠。Comet 的脚本驱动状态管理比 JSON 手动操作更不易出错 |
| HARD-GATE 内联文本约束 | Comet 的 guard.sh --apply 是更强的强制执行方式 |
| install.sh 自包含安装器 | Comet 的 npm 全局安装 + CLI 在所有维度上更优 |

### 6.6 三个冲突时刻的覆盖评估

| 冲突时刻 | SpecPower 机制 | Comet 原生 | 扩展后方案 | 覆盖评价 |
|----------|---------------|-----------|-----------|---------|
| T1: 需求→Spec | Speculate + explore-findings.md 归化 | 无探索 | comet-speculate 前置 | ✅ 完整覆盖 |
| T2: Spec 中途变更 | 级联回退矩阵 | 推迟裁决 + 接受偏差 | 保留 Comet 原生，不搬 | ⚠️ 不搬。Comet 方案工程上更可靠，6.0 per-task 双 verdict 进一步验证了这一判断 |
| T3: 完成标准 | 7 项 hard gate 含双向反查 | test + validate | bidirectional-verify 附加 | ✅ 完整覆盖 |

### 6.7 实施优先级

| 优先级 | 扩展 | 改动量 | 理由 |
|--------|------|-------|------|
| P0 | bidirectional-verify | 3 个文件 | 纯增量，不改核心。可与 Comet guard.sh 无缝衔接。可独立提 PR 给上游 |
| P1 | comet-speculate | 5+ 文件 + 调度器修改 | 需改 Comet 入口，先 fork 验证。触达 Comet 核心流程 |
| P2 | revert-restore | 1 个脚本 | 使用场景窄，独立验证项，按需 |

---

## 七、迁移路线图

```
Phase 1 (现在):    放弃 SpecPower 独立开发
                    保留仓库为归档
                    提取核心资产

Phase 2 (P0):      实现 bidirectional-verify
                    + comet-forward-trace.sh
                    + comet-backward-trace.sh
                    + bidirectional-verify.md
                    作为 Comet 独立扩展

Phase 3 (P0):      向 Comet 上游提 PR
                    验证与 6.0 SDD 的兼容性
                    双向反查消费 review-package 作为输入

Phase 4 (P1):      实现 comet-speculate
                    fork Comet 验证
                    探索与 comet-open 的衔接

Phase 5 (P1):      向 Comet 上游提 speculate PR
                    提供 comet-speculate + comet-quick-speculate 两种模式

Phase 6 (P2 按需): 实现 revert-restore 作为可选验证项
```

---

## 八、结论

SpecPower 完成了它的历史使命——探索了 OpenSpec + Superpowers 融合的边界。在这个过程中：

- **被上游否定的**（两阶段审查铁律）：Superpowers 6.0 给出了更好的答案，应该放下
- **被上游超越的**（文件驱动、SDD 交接）：6.0 自己走向了文件驱动，不需要 SpecPower 的中间层
- **仍然独特的**（Speculate、bidirectional-verify）：有独立价值，应该作为 Comet 扩展存活

不是失败，是上游验证了你的方向并给出了更优的实现。把独特的部分提炼出来贡献给更大的生态，比维护一个在工程成熟度上无法追赶的独立项目更有意义。
