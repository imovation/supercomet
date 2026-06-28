# OpenSpec × Superpowers 深度融合 — 最终方案

> **版本**：v2.0
>
> **审定日期**：2025-06-27

---

## 背景

### 原点问题

OpenSpec 擅长管需求（结构化 spec、Delta 变更、持久化规格），Superpowers 擅长管实现（强制 TDD、子Agent 编排、代码审查）。两者如何取长补短、优势互补、分工协作、无缝融合？

### 探索路径

1. **自研方案**：设计了 3 层协作架构（需求层 → 桥接层 → 执行层），6 个重难点及解决方案
2. **发现 Comet**：`rpamis/comet` 是已有的 OpenSpec × Superpowers 融合项目——Shell 脚本状态机 + PreToolUse hooks + SHA256 上下文交接 + 29 平台支持。评估结论：它是我们方案的工程化升级版，不应从头自建
3. **吸收 specpower**：审验自有的 `specpower` 项目（v1.0.0），识别可吸收资产——双向反查、探索阶段、Revert-Restore、Git Notes
4. **交叉审查**：与 specpower 项目内的另一份独立 AI 分析交叉验证——6 项一致、2 项采纳补充、3 项冲突裁决（Triple Arbitration 降级、7 项验证解耦、i18n gate 剔除）
5. **两轮自检**：19 个问题，全部修复。第 20 个问题（17 反模式审验）发现其中 11/17 在 Comet 架构下前提消失，放弃吸收
6. **定稿**：本文档为最终成果

### 文档定位

本文档是 OpenSpec × Superpowers 深度融合方案的唯一权威来源。所有先前的探索文档已废弃，以本文为准。

---

## 一、决策：基于 Comet 扩展

经过对 `rpamis/comet`（`@rpamis/comet` v0.3.11）的全面评估，以及对 `specpower`（v1.0.0）的吸收分析，最终决策如下：

**不从头自建。以 Comet 为基础，通过 7 个增强（来自 specpower 资产 4 项 + 原创 3 项）构建完整的 OpenSpec × Superpowers 深度融合方案。**

### 为什么是 Comet

Comet 并非"另一个可选方案"，而是我们自研方案在工程上的正确形态：

| 我们的设计 | Comet 的工程实现 | 差距 |
|-----------|-----------------|------|
| Prompt 文本约定作为阶段路由 | Shell 脚本状态机（`comet-state.sh` + `comet-guard.sh`） | 可执行 > 文本，不可绕过 |
| Agent 自律作为执行纪律 | PreToolUse hooks 物理阻止写代码 + `direct_override` 锁 | 系统级拦截 > 口头约定 |
| Skill 手动调用作为桥接 | SHA256 确定性上下文包（`comet-handoff.sh`） | 可验证 > 不可验证 |

三者叠加构成了从"依赖 Agent 自律"到"脚本强制执行"的范式升级。重新实现这些不值得，也未必能比 Comet 做得更好。

### 架构哲学

```
OpenSpec = System of Record（需求、规格、变更历史的权威来源）
    ↕  comet-handoff.sh + .comet.yaml 状态机 + guard.sh 守卫
Superpowers = Execution Engine（TDD、子Agent 审查、代码质量的执行纪律）

编排层的唯一职责：确保两者之间的每一次数据交换都是可验证的，每一个阶段转换都是可执行的。
```

### 关键洞察

1. **"刻舟求剑"的教训**：架构改变后，旧反模式的前提可能消失。specpower 的 17 条反模式中 11 条在 Comet 架构下不再适用（如 YAML 缩进风险被脚本管理消除、[HARD-GATE] 文本被 guard.sh 取代）。任何吸收项必须经过架构前提审验，而非盲目搬移。

2. **T1/T2/T3 冲突框架**（来源：specpower 项目内的独立 AI 分析）揭示了 OpenSpec 与 Superpowers 之间的三个设计张力——需求→Spec 的格式主权（翻译 vs 归化）、实现中途改 Spec 的响应策略（推迟裁决 vs 级联回退）、完成标准的权威归属（archive vs test pass）。Comet 对三者的处理给出了工程上的最佳实践。

3. **双份 AI 独立分析交叉验证**是本次工作的方法论保障——两份互不知晓的分析在 6 个核心结论上一致，2 项互补，3 项冲突经裁决消除，有效降低了单一 AI 分析的盲区风险。

---

## 二、Comet 基础能力（保持）

Comet 提供以下不可替代的基础设施，所有这些均保留：

| 类别 | 能力 |
|------|------|
| **状态管理** | Shell 脚本状态机（`comet-state.sh`）+ 阶段守卫（`comet-guard.sh`） |
| **执行纪律** | PreToolUse hooks 写保护 + `direct_override` 锁 + SHA256 上下文交接 |
| **阶段管线** | 5 阶段（open → design → build → verify → archive） |
| **平台覆盖** | 29 个 AI 编码平台 + CLI 安装器 + Web 面板 |
| **自动化** | auto-transition 三级可配 + archive-reopen 逃生舱 + doctor 健康检查 |
| **优化** | 上下文压缩（beta）+ 渐进加载参考文档 + 双语言（中/英） |

---

## 三、7 个增强项

### 按优先级排列

```
P0（最高优先，即插即用，不改 Comet 核心）:
  ├── #1 bidirectional-verify（双向反查，来自 specpower）
  └── #2 三维 Traceability 账本（原创，结合双向反查 + commit 映射）

P1（需修改 Comet 入口调度）:
  ├── #3 comet-speculate（探索阶段，来自 specpower）
  ├── #4 Spec-to-Test 自动映射（原创）
  └── #5 子Agent 模型分层选择（原创）

P2（独立可选扩展）:
  ├── #6 Revert-Restore 回归验证（来自 specpower）
  └── #7 Git Notes 不可变备份（来自 specpower，降优先级）
```

---

### P0-1：bidirectional-verify（双向反查）

**来源**：specpower 的 `bidirectional-verify` Skill + `forward-trace.sh` (53行) + `backward-trace.sh` (60行)

**定位**：作为 `/comet-verify` 的附加验证项，不改 Comet 核心逻辑。

**工作原理**：

```
/comet-verify
    │
    ├── 现有验证项 1-N ...
    │
    └── [新增] bidirectional-verify
         │
         ├── 正向反查 (spec → test)
         │   · 提取 specs/ 中所有 Scenario 名称
         │   · grep 每个 Scenario 在 test/ 中
         │   · 标记无对应 test 的 Scenario
         │   · Hard Gate: 覆盖率 ≠ 100% → BLOCK
         │
         ├── 反向反查 (test → spec)
         │   · 提取所有 test function 名称
         │   · 比对 spec 中的 Scenario
         │   · 标记无法对应的 test（孤儿测试）
         │   · 无对应 spec 的 test → WARN
         │
          └── 输出 traceability.md
               ┌───────────────────────────────────────────────────┐
               │ # Spec ↔ Test Traceability Report                 │
               │                                                  │
               │ ## 1. Coverage Matrix (正向：Spec → Test)        │
               │ | Requirement | Scenario | Test | Code Evidence | │
               │ | Session Exp | Default timeout | test_expire_24h | ✅ │
               │ | Session Exp | Remember me (30d) | NOT FOUND  | ❌ │
               │ | ...                                            │
               │ Coverage: N/M = XX%                              │
               │                                                  │
               │ ## 2. Orphan Tests (反向：Test → Spec)           │
               │ | Test Function | Matched Scenario | Status      │
               │ | test_random   | (无匹配)          | ⚠️ WARN    │
               │                                                  │
               │ ## 3. Edge Case Analysis                         │
               │ | Scenario | GIVEN Condition | Code Branch?      │
               │ | Idle timeout | inactive 30min | ✅ timer.ts:45 │
               │ | Empty input | email="" | ❌ not handled        │
               │                                                  │
               │ ## 4. Gate Verdict                               │
               │ Spec Coverage: ✅ PASS / ❌ BLOCKED               │
               │ Test Orphans: ✅ CLEAN / ⚠️ N orphan(s)          │
               │ Edge Cases: ✅ ALL COVERED / ❌ N missing         │
               │                                                  │
               │ ## 5. Next Action                                │
               │ ✅ → Proceed to archive                          │
               │ ❌ → Blocking: {N} missing scenarios, {M} edge   │
               │      cases. Return to implementer.               │
               └───────────────────────────────────────────────────┘
```

**集成方式**：

| 集成点 | 实现 |
|--------|------|
| comet-verify | 验证清单追加第 N+1 项 |
| comet-guard.sh | verify→archive 转移时校验 `traceability.md` 中 Gate = ✅ |
| `.comet.yaml` | 新增 `bidirectional_verify` 字段 |
| comet-state.sh | 新增 `cmd_set` 白名单项 |

**新增文件**：

```
comet/scripts/
├── comet-forward-trace.sh       # spec→test 正向扫描
└── comet-backward-trace.sh      # test→spec 反向扫描

comet/reference/
└── bidirectional-verify.md      # 完整协议文档
```

**与 Superpowers v6.0 的兼容性**：完全独立于 SDD 审查机制。不依赖任何 Superpowers reviewer prompt 版本。

**输入源优化**：Superpowers v6.0 已将交接材料文件化——`task-brief`（单任务描述，含涉及的 spec 范围）和 `review-package`（变更文件 diff）。双向反查脚本应优先消费这些文件作为输入源，而非对全量 spec/ 和 test/ 目录 grep：
- **正向反查**：specpower 原版的 `grep -rn "^#### Scenario:" $SPECS_DIR` 替换为从 `task-brief` 中提取相关 Scenario 再在 `review-package` 变更的 test 文件中搜索
- **反向反查**：specpower 原版的全量 test 函数提取替换为从 `review-package` 中提取变更的 test 文件，再反向搜索 spec
- **降级**：若 task-brief / review-package 不可用（如非 v6.0 模式），回退到全量 grep

**与 v6.0 per-task 审查的关系**：互补，非重复——
- v6.0 task-reviewer：检查"这个 task 的 code 是否符合它对应的 spec（微观，task 级）
- bidirectional-verify：检查"整个 spec 的所有 Scenario 是否都被某个 test 覆盖了"（宏观，全 branch 级）
v6.0 reviewer 可能因为"can't verify from diff"跳过跨 task 需求，bidirectional-verify 恰好填补这个盲区。

**理由**：纯增量，不改 Comet 核心。与 Comet 的 guard.sh 体系天然契合。specpower 已有可执行脚本，免去从零开发。

**方法论来源**：traceability.md 的覆盖矩阵（Section 1）、边界分析（Section 3）和 Gate Verdict（Section 4）格式源自 specpower 的 `spec-compliance-check` Skill。该 Skill 的独立审查者角色因 v6.0 统一 reviewer 被废弃，但其结构化报告方法论在此重生为 bidirectional-verify 的标准输出格式。

---

### P0-2：三维 Traceability 账本（原创，结合双向反查）

**定位**：在 bidirectional-verify 的 spec↔test 映射基础上，加入 Task → Git Commit 这一维，形成三维完整可追溯性。

```
           Spec Requirement
                 │
    ┌────────────┼────────────┐
    │            │            │
    ▼            ▼            ▼
  Scenario A  Scenario B  Scenario C
    │            │            │
    ▼            ▼            ▼
  Test A      Test B      Test C
    │            │            │
    ▼            ▼            ▼
  Commit X    Commit Y    Commit Z
    │            │            │
    └────────────┼────────────┘
                 │
                 ▼
           Task 1.1 (OpenSpec)
```

**扩展的进度账本格式**：

```yaml
# .comet.yaml 中新增
tasks:
  - id: 1.1
    description: "Create ThemeContext"
    requirement_id: "REQ-ThemeState-001"
    scenario: "Default light theme"
    test_file: "src/contexts/__tests__/ThemeContext.test.tsx"
    test_name: "ThemeProvider shows default light theme"
    commits: ["abc1234", "def5678"]
    review_result: pass

  - id: 1.2
    description: "Add CSS variables"
    requirement_id: "REQ-VisualTheme-001"
    scenario: "All components use theme colors"
    test_file: "src/styles/__tests__/theme.test.tsx"
    test_name: "all components render with theme colors"
    commits: ["def5678..ghi9012"]
    review_result: pass
```

**双向查询能力**：
- **任意 Requirement → 找到每 Scenario 的测试和实现 Commit**
- **任意代码 Commit → 找到对应的 Task → Requirement → Spec**

**集成方式**：

| 集成点 | 实现 |
|--------|------|
| `.comet.yaml` | 新增 `tasks` 字段（含 requirement_id / scenario / test_file / test_name / commits） |
| 三维查询脚本 | 独立脚本 `comet-trace.sh`：接受 Requirement ID 或 commit hash，返回完整追溯链 |
| `comet-state.sh` | task 完成时通过 `comet-state.sh set-task` 写入 tasks 条目 |
| `comet-guard.sh` | verify→archive 转移时校验 tasks 列表中无空 commits 字段 |

**Requirement ID 生成规则**：OpenSpec 的 spec.md 中 Requirement 以 `### Requirement: <name>` 的 markdown header 形式存在，无显式 ID。三维账本中的 `requirement_id` 通过以下规则自动生成（不侵入 spec.md 格式）：
- 从 Requirement 名称生成 slug（如 `Session Expiration` → `session-expiration`）
- 同名冲突时追加 spec domain 前缀（如 `auth-session-expiration`）

---

### P1-3：comet-speculate（探索阶段）

**来源**：specpower 的 Speculate 阶段（Phase 1: SPECULATE）+ B1-B6 子步骤

**定位**：在 `/comet-open` 之前插入可选的结构化探索阶段。

**工作流**：

```
用户说 "帮我做一个 X 功能"
         │
         ▼
  comet-speculate（新增，Phase 0）
         │
         ├─ B1: 加载 config.yaml context + 项目上下文
         ├─ B2: 逐项提问澄清（目标/约束/成功标准），一次一个问题
         ├─ B3: 生成 2-3 方案对比（≥2 优点 + ≥1 缺点 + 工作量估算 + 推荐方案）
         ├─ B4: 【卡点A: 用户选择方案】
         ├─ B5: 自检（placeholder 扫描/一致性/范围/歧义）
         └─ B6: 写入 explore-findings.md
                  │
                  ▼
           /comet-open（检测到 explore-findings.md → 作为上下文注入）
```

**为什么需要独立的 Speculate？**

Comet 的 `/comet-open` 使用 OpenSpec 的 explore 进行需求探索，但探索和提案生成在同一个阶段内。specpower 的 Speculate 有两个硬性要求是 Comet 缺失的：

1. **必须生成 2-3 个方案对比**——防止过早锁定单一方案
2. **必须写入 explore-findings.md**——产生持久化桥接文件，而非仅在会话中讨论

**扩展分层**：

| 模式 | 适用场景 | 内容 |
|------|---------|------|
| `comet-speculate` | 新功能、架构变更 | 完整 6 步（含方案对比） |
| `comet-quick-speculate` | 小改动、明确需求 | 精简 3 步（只出推荐方案，跳过对比） |

**集成方式**：

| 集成点 | 实现 |
|--------|------|
| comet 入口调度 | phase=null 且无活动 change 时，路由选项含 speculate |
| comet-open 衔接 | 检测 `explore-findings.md` → 读取方案+批准标记 → 注入为 proposal 上下文 |
| comet-guard.sh | speculate→open 转移时校验 explore-findings.md 存在且自检通过 |
| `.comet.yaml` | 新增 `speculate_doc` 字段 |
| `explore-findings.md` 存储 | 存于 `.comet/explore-<topic>.md`（项目根目录），创建 change 后由 comet-open 复制到 `openspec/changes/<name>/` |

**新增文件**：

```
assets/skills/comet-speculate/SKILL.md
assets/skills/comet-speculate/reference/
├── speculate-checklist.md
└── self-review-checklist.md
```

**理由**：填补 Comet 在结构化探索阶段的空白。需修改 Comet 入口调度器，改动量高于 P0 项。先以 fork 验证，再向 Comet 上游提 PR。

**与 Comet 预设的交互**：

| Comet 预设 | speculate 行为 |
|-----------|---------------|
| `full` | 建议走 `comet-speculate`（完整 6 步），用户可跳过 |
| `hotfix` | 默认跳过 speculate；用户可显式调用 `/comet-speculate` |
| `tweak` | 默认走 `comet-quick-speculate`（精简 3 步），用户可跳过 |
| **动态升级** | 若 hotfix 因文件变更量触发 Comet 自动升级为 full → 同步提示"建议使用完整 speculate 模式" |

speculate→open 的 guard 转移在 hotfix/tweak 模式下放宽（不强制 explore-findings.md 存在）。

---

### P1-4：Spec-to-Test 自动映射（原创）

**定位**：将 spec.md 中的 GIVEN/WHEN/THEN Scenario 自动转换为测试用例骨架，减少 Agent 从 spec 到 test 的手动推导。

**输入 → 输出**：

```
spec.md 中:
#### Scenario: Default session timeout
- GIVEN a user has authenticated
- WHEN 24 hours pass without "Remember me"
- THEN invalidate the session token
- AND require re-authentication

            ↓ 自动映射

testing plan 中:
### Task 3.2: Session timeout handler
Coverage: Requirement "Session Expiration", Scenario "Default timeout"

test('session expires after 24h inactivity without remember me',
  async () => {
    // GIVEN a user has authenticated
    const session = await createSession({ userId: 'user-1', rememberMe: false });
    // WHEN 24 hours pass without "Remember me"
    vi.advanceTimersByTime(24 * 60 * 60 * 1000);
    // THEN invalidate the session token
    await expect(validateSession(session.token)).rejects.toThrow('Session expired');
    // AND require re-authentication
  });
```

**与 Superpowers v6.0 的集成**：映射结果注入到 `writing-plans` 生成的微任务中，替代 Agent 手动推导测试。不修改 Superpowers 的 TDD 流程。

**框架适配**：映射器需支持至少 Jest / Vitest / Pytest / Go-test 四种测试框架。示例以 Vitest 展示；其他框架的适配逻辑参照 bidirectional-verify 的框架检测机制（`backward-trace.sh` 已实现多框架的 test function 名称提取）。

---

### P1-5：子Agent 模型分层选择策略（原创）

**定位**：在 Comet 的 build 阶段，按任务复杂度自动选择不同级别的模型。

| 任务类型 | 模型层级 | 判定标准 | 示例 |
|---------|---------|---------|------|
| **机械实现** | 廉价/快速 | 1-2 文件 + plan 含完整代码 | 纯样式改动、单文件组件创建 |
| **标准实现** | 标准 | 多文件 + 集成逻辑 | 跨文件数据流、状态管理 |
| **架构审查** | 最强 | 全分支审查、设计决策 | finishing-branch 之前的 final review、spec 合规深度审查 |

**与 Superpowers v6.0 的对接**：v6.0 已要求每次子Agent 调度**必须显式指定模型**。本策略提供自动化模型推荐，但不替代 v6.0 的强制声明。

**集成位置**：`comet-build/SKILL.md` 中 implementer subagent 分发逻辑 + `comet-state.sh` 新增 `model_tier` 字段。

---

### P2-6：Revert-Restore 回归验证（来自 specpower）

**定位**：独立可选验证项，仅对标记 Security/Core/Critical 的关键变更执行。

```
对每个关键变更:
  git revert <实现 commit> → 运行测试 → 确认 FAIL（证明测试能捕捉缺陷）
  git revert <revert commit> → 运行测试 → 确认 PASS（确认恢复）
  
若撤销实现后测试仍通过 → 测试无效 → Hard Gate BLOCK
```

**集成方式**：独立 Shell 脚本，作为 comet-verify 的可选附加项。不强制集成到 Comet 核心流程。

**理由**：测试有效性的强验证。但适用场景窄（仅对可 revert 的关键变更有意义），作为按需选项。

---

### P2-7：Git Notes 不可变备份层（来自 specpower）

**定位**：作为 v6.0 进度账本（`.superpowers/sdd/progress.md`）的不可变备份。

```
每个 task 完成后:
  git notes --ref=comet add -m "task: 1.1, requirement: REQ-ThemeState-001, hash: $(git rev-parse HEAD)"

恢复:
  git log --show-notes=comet
```

**与 v6.0 的关系**：v6.0 的进度账本已提供 task→commit 映射，但 `git clean -fdx` 会清除它。Git Notes 存储在 Git object 数据库中，不受 working tree 清理影响。作为"账本丢失时的恢复源"。

**理由**：锦上添花。v6.0 进度账本 + `.comet.yaml` 已覆盖大多数恢复场景。Git Notes 作为额外的不可变层，在 key scenario 中提供最终保险。优先级降为 P2。

**限制**：Git Notes 默认不跟随 `git push`（需 `git push origin refs/notes/comet`）。若未推送，clone 后同样丢失，等同于进度账本丢失。因此主要价值场景是同一本地仓库内的恢复，或团队有 git notes 推送 CI 约定的场景。

---

## 四、不吸收的 specpower 能力

| 能力 | 原因 |
|------|------|
| 两阶段审查铁律（spec-reviewer + code-reviewer 分别独立子Agent） | 被 Superpowers v6.0 废弃，合并为更优的单轮双 verdict |
| 级联回退矩阵 | 依赖 Agent 自律无脚本验证；v6.0 per-task 双 verdict 使其更无必要；Comet 的"推迟裁决+接受偏差"更务实 |
| HARD-GATE 内联文本约束 | Comet 的 guard.sh --apply 是更强的脚本级强制执行 |
| i18n 中文 gate | 项目特定需求，不作为通用工作流组件 |
| `.specpower-state.json` / JSON 状态文件 | Comet 的 `.comet.yaml` + 脚本管理更可靠 |
| install.sh 自包含安装器 | Comet 的 npm CLI 安装更优 |
| 17 反模式参考 | 逐条审验后放弃——17 条中 11 条在 Comet 架构下前提条件消失（如 AP-07 的 [HARD-GATE] 文本被 guard.sh 取代、AP-11 的 YAML 缩进被 comet-state.sh 管理消除），4 条不构成独立参考价值，属刻舟求剑。AP-02 的提醒已直接写入 P0-1 实现注意事项 |

**已吸收但非独立增强项**：

| 能力                             | 处理方式                                                                                                      |
| ------------------------------ | --------------------------------------------------------------------------------------------------------- |
| Triple Arbitration（Git log 仲裁） | 降级为 `comet-state.sh check` 中的轻量一致性校验。当 `.comet.yaml` phase 与 git log 任务完成状态矛盾时输出警告。不改变 Comet 状态机架构。（低优先级） |
| spec-compliance-check          | 独立审查者角色因 v6.0 统一 reviewer 不再需要。其覆盖矩阵和边界分析方法论已融入 bidirectional-verify 的 `traceability.md` 输出格式。            |

---

## 五、OpenSpec 与 Superpowers 的三个核心冲突（T1/T2/T3）— Comet 的处理

> T1/T2/T3 框架来自 specpower 项目内的独立 AI 分析（《Comet和SpecPower对比分析及Comet吸收建议》），经本会话交叉审查后确认为有效的冲突分析框架。

| 冲突 | 张力 | Comet 的处理方式 | 评价 |
|------|------|-----------------|------|
| **T1** 需求→Spec | Superpowers 自由格式 vs OpenSpec 严格格式 | **翻译模式**：handoff.sh 做格式转换，互不侵犯格式主权。Design Doc frontmatter 标注 `canonical_spec: openspec` | 务实，无损失 |
| **T2** 实现中途改 Spec | OpenSpec 要求走 change 流程 vs Superpowers "发现问题就修正" | **推迟裁决**：build 中不改 spec。偏差推到 verify gate 集中裁决。用户可"接受偏差"继续 archive | 工程上可靠 |
| **T3** 完成标准 | OpenSpec `validate --strict` + archive vs Superpowers test + review | **archive 是唯一终态**：test pass + review pass 是进门条件，delta merge 是出门证 | 完整闭环 |

### 已知 tradeoff

| 取舍 | 说明 | 缓解措施 |
|------|------|---------|
| Design Doc ↔ delta spec 一致性 | Comet 的 handoff.sh 不检查 Superpowers Design Doc 是否完整覆盖了 OpenSpec delta spec 的所有 Requirement。v6.0 task-reviewer 和 bidirectional-verify 分别在 code 和 test 层面做了验证，但 Design Doc → spec 的设计层对齐无自动化 | 在 build 开始前通过 `openspec validate --strict` 做语法检查 + guard.sh 输出一致性提示 |
| "推迟裁决" 的施工浪费风险 | Comet 在 build 中不改 spec，偏差推到 verify gate。若 spec 有明显错误，implementer 会基于错误 spec 施工 | 在 build 开始前做轻量 spec 完整性预检（非级联回退，仅输出警告） |

---

## 六、实施路线图

> **侵入性标签**：🔵 零侵入（Skill/脚本外挂） · 🟡 轻侵入（扩展 `.comet.yaml` + `comet-state.sh`） · 🔴 需修改 Comet 核心入口

```
Phase 1（当前，P0）：
  ├── 🔵 在 fork 上验证 bidirectional-verify 与 Comet 的集成
  ├── 🔵 实现双向追溯 Shell 脚本
  └── 向 Comet 上游提 PR #1

Phase 2（P0）：
  ├── 🟡 实现三维 Traceability 账本（依赖 bidirectional-verify）
  └── 向 Comet 上游提 PR #2

Phase 3a（P0 PR 提交后，可并行启动）：
  ├── 🔴 fork Comet 验证 comet-speculate 可行性
  └── 🔵 开始 Spec-to-Test 映射器开发（独立模块，不依赖 Comet 核心修改）

Phase 3b（P0 PR 合并后）：
  ├── 🔴 将已验证的 comet-speculate 提交为 PR #3
  ├── 🔵 将 Spec-to-Test 映射器提交为 PR #4
  └── 🟡 将子Agent 模型分层选择提交为 PR #5

Phase 4（P2，按需）：
  ├── 🔵 Revert-Restore 可选脚本
  └── 🔵 Git Notes 不可变备份
```

### 上游 PR 被拒的备用路径

| 场景 | Plan B |
|------|--------|
| P0 PR（bidirectional-verify）被拒 | 概率极低（纯增量、不改核心）。若被拒，作为独立 Comet 插件发布 |
| P1 PR（comet-speculate）被拒 | 在 Comet fork 上维护，或作为独立 pre-hook 脚本（在 `/comet-open` 前手动执行） |
| P1 PR（模型分层/映射器）被拒 | 作为独立 Skill 分发，通过 Comet 的渐进加载 reference 机制集成 |

### 集成适配注意事项

从 specpower 迁移资产到 Comet 时需关注的适配项：

| 适配点 | specpower 原样 | Comet 目标 |
|--------|--------------|-----------|
| 状态文件路径 | `.specpower-state.json` | `.comet.yaml`（已有） |
| spec 文件路径 | `openspec/changes/*/specs/**/*.spec.md` | `openspec/changes/<name>/specs/`（与 Comet 一致） |
| test 目录 | `tests/`（硬编码） | 从 Comet 项目配置或约定中检测 |
| 产出文件路径 | `openspec/changes/<name>/traceability.md` | 与 Comet 保持一致的产出路径 |
| 错误码约定 | 独立 exit code | 对齐 Comet 的 guard.sh 退出码风格 |
| 进度账本路径 | `.specpower-state.json` | `.superpowers/sdd/progress.md`（v6.0 标准） |

---

## 七、交叉审查证书

本方案经过两份独立 AI 分析的交叉审查：核心决策和 bidirectional-verify 等 6 项一致，探索阶段与回归验证 2 项采纳补充方案，Triple Arbitration 降级、验证清单解耦、i18n 剔除 3 项经冲突裁决，原创 3 增强无争议保留。17 反模式经逐条审验后放弃（11/17 在 Comet 架构下前提消失）。另外经过两轮共 20 个问题的深度自检，全部修复。

---

## 八、附录：对 Comet 上游的建议

以下不是我们要实现的增强，而是建议 Comet 项目本身采纳的实践：

| 建议 | 来源 | 说明 |
|------|------|------|
| **用 OpenSpec 管 Comet 自身的 spec** | specpower 的 dogfooding 实践 | Comet 目前"无独立 living spec"。specpower 用 6 个 spec domain（82 条可验证 Requirements）规约自身行为。Comet 可效仿，将工作流设计、状态机逻辑、桥接协议形式化 |
| **bidirectional-verify 作为核心验证项** | 本方案 P0-1 | 不同于 v6.0 的 per-task 审查，这是一个全 branch 级的 spec↔test 覆盖检查，填补了 v6.0 reviewer "can't verify from diff" 的盲区 |
| **comet-speculate 作为可选前置** | specpower 的 Speculate 阶段 | 防止过早锁定单一方案，提供持久化的需求探索产物 |
