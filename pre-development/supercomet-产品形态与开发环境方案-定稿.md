# supercomet 产品形态与开发环境方案

> **版本**：v1.0
>
> **审定日期**：2025-06-27
>
> **来源**：两份独立 AI 分析经双份 AI 独立分析交叉验证后融合定稿（详见 `中间文档/supercomet-产品形态与开发环境-交叉验证报告.md`）
>
> **本文是 supercomet 产品形态与开发环境的唯一权威来源。**

---

## 一、产品形态：独立分发的 Comet 技能扩展包

supercomet 不是 Comet 的 fork，不是独立 CLI，不是 opencode 插件。它是以 **npm 包形态独立分发的 Comet 扩展包**——安装在一个正常工作的 Comet 项目之上，通过文件注入（技能部署、配置合并、脚本追加）将 7 个增强叠加到 Comet 工作流中。

不使用 fork 的原因：方案要求向 Comet 上游提 PR。fork 姿态与上游贡献矛盾。不修改 Comet 一行代码，仅消费其文档化扩展点。

```
npm install -g supercomet      # 安装
supercomet init                 # 注入增强到当前 Comet 项目
```

### 架构关系

```
comet（上游，@rpamis/comet >=0.3.0，peerDependency）
  └── supercomet（注入层，不改 comet）
       ├── 🔵 零侵入项：脚本/Skill 文件直接部署到 comet/ 目录
       ├── 🟡 轻侵入项：合并 schema 扩展到 .comet.yaml + 追加白名单
       └── 🔴 核心侵入项：优先向 Comet 提 PR；PR 未合并时作为独立 Skill 部署
```

### 安装后的项目结构

```
your-project/
├── .comet.yaml                      # supercomet 合并了 tasks/model_tier 字段
├── comet/                           # Comet 核心（不修改）
│   ├── scripts/
│   │   ├── comet-state.sh           # Comet 原有
│   │   ├── comet-guard.sh           # Comet 原有
│   │   ├── comet-handoff.sh         # Comet 原有
│   │   ├── comet-archive.sh         # Comet 原有
│   │   ├── comet-forward-trace.sh  ← supercomet 注入
│   │   ├── comet-backward-trace.sh ← supercomet 注入
│   │   ├── comet-trace.sh          ← supercomet 注入
│   │   └── comet-revert-restore.sh ← supercomet 注入
│   └── reference/
│       ├── bidirectional-verify.md  ← supercomet 注入
│       └── ...
├── assets/skills/
│   ├── comet/              ← Comet 原有（7 技能 + 2 预设）
│   ├── comet-speculate/    ← supercomet 注入（P1-3）
│   └── spec-to-test-mapper/← supercomet 注入（P1-4）
└── openspec/               # OpenSpec（不变）
```

### 7 项增强的侵入性分层

| # | 增强项 | 侵入级 | supercomet init 行为 |
|---|--------|--------|---------------------|
| 1 | bidirectional-verify | 🔵 零侵入 | 部署 `comet-forward-trace.sh`, `comet-backward-trace.sh`, `bidirectional-verify.md` |
| 2 | 三维 Traceability 账本 | 🟡 轻侵入 | 部署 `comet-trace.sh` + 合并 `.comet.yaml` tasks schema + 追加 `comet-state.sh` set-task 白名单 |
| 3 | comet-speculate | 🔴 核心侵入 | 优先向 Comet 提 PR。PR 未合并时作为独立 Skill 部署 |
| 4 | Spec-to-Test 映射 | 🔵 零侵入 | 部署独立 Skill，不修改 Comet 核心 |
| 5 | 子Agent 模型分层 | 🟡 轻侵入 | 修改 `comet-build/SKILL.md` 分发逻辑 + 合并 model_tier 字段 |
| 6 | Revert-Restore | 🔵 零侵入 | 部署独立脚本，comet-verify 手动追加 |
| 7 | Git Notes | 🔵 零侵入 | 部署 git alias/脚本，task 完成后自动写入 |

### 分发包结构

```json
{
  "name": "supercomet",
  "version": "1.0.0",
  "bin": { "supercomet": "bin/supercomet.js" },
  "peerDependencies": {
    "@rpamis/comet": ">=0.3.0"
  }
}
```

---

## 二、上游兼容性：四级机制

### 机制1：消费产出文件，不依赖内部实现

supercomet 只读上游的产出文件，不引用上游内部代码。上游内部重写不影响 supercomet：

| supercomet 功能 | 消费的上游产出 | 不依赖的上游内部 |
|---------------|-------------|----------------|
| bidirectional-verify | task-brief, review-package, spec.md, test/ | Superpowers SDD 内部审查流程 |
| 三维 Traceability | .comet.yaml, git log, traceability.md | comet-state.sh set 子命令内部实现 |
| Spec-to-Test 映射 | spec.md (Requirements + Scenarios) | OpenSpec 规格管理内部 |
| 模型分层 | writing-plans plan 文件, .comet.yaml | comet-state.sh, comet-build 内部 |

### 机制2：每个功能有降级路径

上游产出格式变化时，不报错阻断流程，降级运行：

| 功能 | 正常路径 | 降级路径 | 降级行为 |
|------|---------|---------|---------|
| bidirectional-verify | 消费 task-brief + review-package | 全量 grep spec/ + test/ | WARN："使用全量扫描，未利用 v6.0 优化" |
| Spec-to-Test 映射 | 自动解析 spec.md Scenario → test skeleton | 标记"需手动推导" | WARN："映射器不可用，test skeleton 需手动生成" |
| 模型分层 | 读取 .comet.yaml model_tier 字段 | 使用 session 默认模型 | INFO："使用默认模型" |
| comet-speculate | 作为 /comet-speculate Skill 注册 | 作为手动执行的 pre-hook 脚本 | INFO："comet-speculate 需手动触发" |

### 机制3：version.yaml 声明 + CI 哨兵

```yaml
# dist/version.yaml
supercomet: 0.1.0
compatible:
  comet: ">=0.3.0"
  superpowers: ">=6.0.0"
  openspec: ">=1.4.0"
```

安装器预检兼容性，不兼容时输出警告。CI 每日 `npm test` 基于 `@rpamis/comet@latest`，break 时告警。

### 机制4：上游 PR 优先

| 增强项 | 向上游贡献 | 合并后对 supercomet 的影响 |
|--------|-----------|--------------------------|
| bidirectional-verify | ✅ 提 PR 给 Comet | supercomet 移除自身部署的脚本 |
| comet-speculate | ✅ 提 PR 给 Comet | supercomet 移除 Skill |
| 模型分层 | ✅ 提 PR 给 Comet | supercomet 移除分发逻辑修改 |
| Spec-to-Test 映射 | ❌ 独立 Skill | 继续作为 supercomet 独有分发 |

上游 PR 被合并 = supercomet 对该功能的维护责任归零。PR 被拒时，备选路径包括独立 Comet 插件或独立 Skill 分发。

---

## 三、开发环境

### 策略：Comet 启动 + 渐进式狗粮替换

supercomet 开发 supercomet——用自己的产品管理自己的开发。但产品尚未存在，因此从纯 Comet 起步，每完成一个增强就部署并立即用它开发下一个。

### 项目自身目录结构

```
supercomet/
├── .opencode/                         # Comet init 产物（opencode 插件/技能/命令/规则）
├── .agents/skills/                    # Superpowers 14 技能
├── .comet/config.yaml                 # Comet 配置
├── .codegraph/                        # 代码索引
├── bin/
│   └── supercomet.js                  # npm 包入口（存根）
├── src/
│   ├── skills/                        # supercomet 技能定义（开发中）
│   │   ├── bidirectional-verify/
│   │   ├── comet-speculate/
│   │   └── spec-to-test-mapper/
│   └── scripts/                       # Shell 脚本（开发中）
│       ├── comet-forward-trace.sh
│       ├── comet-backward-trace.sh
│       ├── comet-trace.sh
│       └── comet-revert-restore.sh
├── dist/                              # 可分发的构建产物
│   ├── version.yaml
│   └── assets/
├── test/
│   ├── shell/                         # BATS Shell 测试
│   └── integration/                   # 端到端集成测试
├── openspec/
│   └── specs/supercomet/spec.md       # 用 OpenSpec 管自身规格（dogfooding）
├── package.json                       # supercomet npm 包定义
└── OpenSpec-Superpowers-深度融合-最终方案-v2.md  # 产品需求文档
```

### 开发时间线

```
═══════════════════════════════════════════════════════════
起步：纯 Comet 开发
═══════════════════════════════════════════════════════════
  平台：OpenCode
  流程：纯 Comet（supercomet 尚不存在）
  专注：P0-1 bidirectional-verify

═══════════════════════════════════════════════════════════
P0-1 完成 → 部署 v0.1 → 开发环境升级
═══════════════════════════════════════════════════════════
  流程：Comet + supercomet v0.1（含双向反查）
  狗粮：P0-2 的每个 commit 都有 traceability.md 产出
  如果 traceability.md 有问题 → P0-1 脚本有 bug → 在此暴露

═══════════════════════════════════════════════════════════
P0-2 完成 → 部署 v0.2 → 开发环境再升级
═══════════════════════════════════════════════════════════
  流程：Comet + supercomet v0.2（含双向反查 + 三维账本）
  狗粮：P1-3 开发全流程享受完整三维追溯

═══════════════════════════════════════════════════════════
P1-3 完成 → 部署 v0.3
═══════════════════════════════════════════════════════════
  流程：Comet + supercomet v0.3（新增 speculate）
  狗粮：P1-4 用 /comet-speculate 启动需求探索 → 验证 P1-3

═══════════════════════════════════════════════════════════
P1-4 完成 → 部署 v0.4
═══════════════════════════════════════════════════════════
  流程：Comet + supercomet v0.4（大半 P0+P1 可用）
  狗粮：P1-5 享受模型分层加速

═══════════════════════════════════════════════════════════
P1-5 完成 → 部署 v1.0-rc
═══════════════════════════════════════════════════════════
  流程：Comet + supercomet v1.0-rc（P0+P1 全部）
  狗粮：P2 享受全链路：speculate → open → design → build
        → verify(含双向反查+回归验证) → archive

═══════════════════════════════════════════════════════════
全部完成 → 发布 v1.0
═══════════════════════════════════════════════════════════
```

### 狗粮强度递增

| 阶段 | 运行中的 supercomet 功能 | 正在开发 | 狗粮场景 |
|------|------------------------|---------|---------|
| 起步 | 无 | P0-1 | 无狗粮，纯 Comet |
| P0-1 后 | bidirectional-verify | P0-2 | P0-2 的 traceability.md → 验证 P0-1 |
| P0-2 后 | P0-1 + P0-2 | P1-3 | P1-3 开发流程 → 验证 P0 全部 |
| P1-3 后 | P0 全部 + speculate | P1-4 | P1-4 用 speculate 启动 → 验证 P1-3 |
| P1-4 后 | P0 全部 + 大半 P1 | P1-5 | P1-5 享受全功能狗粮 |
| P1-5 后 | P0+P1 全部 | P2 | 全链路验证 |
| 全部后 | 全部 | — | 最终集成测试 |

### 测试工具链

| 层 | 工具 | 范围 |
|----|------|------|
| Shell 脚本 | BATS | `test/shell/` — 每个增强的 Shell 脚本单元测试 |
| 端到端 | Shell / 手写 | `test/integration/` — 完整 change 流程验证 |

### 自身 spec 管理（dogfooding）

`openspec/specs/supercomet/spec.md` — 用 OpenSpec 管 supercomet 自身的规格。7 个增强按 Requirement → Scenario → 给定/当/则 结构化表达。P0-1 完成后，双向反查脚本验证这份 spec 自身 Scenario 是否被测试覆盖。

---

## 四、相关文档

| 文档 | 定位 |
|------|------|
| `OpenSpec-Superpowers-深度融合-最终方案-v2.md` | 7 个增强的功能需求 |
| `supercomet-产品形态与开发环境方案.md` | **本文档** — 产品形态与开发环境唯一权威来源 |
| `中间文档/supercomet-产品形态与开发环境-交叉验证报告.md` | 交付本文档的交叉验证过程 |
| `中间文档/双份AI独立分析交叉验证方法论.md` | 交叉验证方法论定义 |
