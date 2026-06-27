# supercomet 产品形态与开发环境方案

> **目标**：以 `supercomet` 项目为起点，独立开发 OpenSpec × Superpowers 深度融合方案的全部增强项，产品可独立分发，持续兼容上游更新。

---

## 一、产品形态：Comet 技能扩展包

### 1.1 定位

supercomet 不是 Comet 的 fork，也不是独立 CLI 工具。它是 **Comet 的技能扩展包（Skill Bundle）**——安装在一个正常工作的 Comet 项目之上，通过 Comet 已有的渐进加载、reference 和 manifest 机制注入增强。

```
comet（上游，不修改，不 fork）
  └── supercomet（技能扩展包，按侵入性分层叠加）
       · 🔵 零侵入项：脚本/Skill 文件直接部署
       · 🟡 轻侵入项：合并 schema 扩展 + 追加白名单
       · 🔴 核心侵入项：优先 PR 上游，同时保持独立可用
```

### 1.2 安装后的项目结构

```
your-project/
├── .comet/
│   └── config.yaml                  # Comet 配置
├── comet/                           # Comet 核心（不修改）
│   ├── scripts/
│   │   ├── comet-state.sh
│   │   ├── comet-guard.sh
│   │   ├── comet-handoff.sh
│   │   ├── comet-archive.sh
│   │   ├── comet-forward-trace.sh  ← supercomet 注入
│   │   ├── comet-backward-trace.sh ← supercomet 注入
│   │   ├── comet-trace.sh          ← supercomet 注入
│   │   └── comet-revert-restore.sh ← supercomet 注入
│   └── reference/
│       ├── bidirectional-verify.md  ← supercomet 注入
│       └── ... (Comet 原有)
├── assets/skills/
│   ├── comet/              ← Comet 原有
│   ├── comet-open/         ← Comet 原有
│   ├── comet-design/       ← Comet 原有
│   ├── comet-build/        ← Comet 原有
│   ├── comet-verify/       ← Comet 原有（验证清单会追加）
│   ├── comet-archive/      ← Comet 原有
│   ├── comet-speculate/    ← supercomet 注入（P1-3）
│   └── spec-to-test-mapper/← supercomet 注入（P1-4）
├── .comet.yaml             # supercomet 安装器合并 schema 扩展
├── openspec/               # OpenSpec（不变）
└── docs/superpowers/       # Superpowers（不变）
```

### 1.3 7 项增强的侵入性分层

| # | 增强项 | 侵入级 | 安装方式 |
|---|--------|--------|---------|
| 1 | bidirectional-verify | 🔵 零侵入 | 部署 2 个脚本 + 1 个 reference 文档，不修改 Comet 任何文件 |
| 2 | 三维 Traceability 账本 | 🟡 轻侵入 | 部署 `comet-trace.sh` + 合并 `.comet.yaml` tasks schema + 追加 `comet-state.sh` set-task 白名单 |
| 3 | comet-speculate | 🔴 核心侵入 | 优先向 Comet 提 PR。PR 未合并时作为独立 Skill，通过 `.comet.yaml` 的 auto_transition 触发 |
| 4 | Spec-to-Test 映射 | 🔵 零侵入 | 部署独立 Skill，不修改 Comet 核心 |
| 5 | 子Agent 模型分层 | 🟡 轻侵入 | 修改 `comet-build/SKILL.md` 分发逻辑 + 合并 model_tier 字段 |
| 6 | Revert-Restore | 🔵 零侵入 | 部署独立脚本，comet-verify 手动追加 |
| 7 | Git Notes | 🔵 零侵入 | 部署一个 git alias/脚本，task 完成后自动写入 |

### 1.4 分发方式

```
supercomet-install.sh <comet-project-dir>
  ├── 检测 Comet 版本兼容性（>= 0.3.0）
  ├── 检测 Superpowers 版本（>= 6.0.0）
  ├── 🔵 部署零侵入项到 comet/scripts/ + comet/reference/
  ├── 🟡 合并 schema扩展到 .comet.yaml（追加不覆盖）
  ├── 🔴 comet-speculate：若 Comet >= 目标版本则直接注册；否则作为独立 pre-hook 部署
  └── 输出安装摘要（已安装项 / 需手动配置项）
```

---

## 二、上游兼容性策略

### 2.1 四个机制

**机制1：消费API，不复制内部实现**

supercomet 的增强功能通过读取上游的**产出文件**来工作，不依赖上游内部代码。如果上游改变内部实现但产出格式不变，supercomet 不受影响。

| supercomet 功能 | 消费的上游产出 | 上游内部实现 | 健壮性 |
|---------------|-------------|------------|--------|
| bidirectional-verify | task-brief, review-package, spec.md, test/ | Superpowers SDD 内部审查流程 | ✅ 内部重写不影响 |
| 三维 Traceability | .comet.yaml, git log, traceability.md | comet-state.sh set 子命令 | ✅ 白名单扩展不影响原有 |
| Spec-to-Test 映射 | spec.md (Requirements + Scenarios) | OpenSpec 规格管理 | ✅ 只用 spec 文件格式 |
| 模型分层 | writing-plans plan 文件, .comet.yaml | comet-state.sh, comet-build | ✅ 附加字段不影响原有流程 |

**机制2：每个功能有降级路径**

如果上游产出格式变化导致 supercomet 无法正常工作，不使用报错来阻断流程，而是降级。

| 功能 | 正常路径 | 降级路径 | 降级行为 |
|------|---------|---------|---------|
| bidirectional-verify | 消费 task-brief + review-package | 全量 grep spec/ + test/ | 输出 WARN："使用全量扫描，未利用 v6.0 优化" |
| Spec-to-Test 映射 | 自动解析 spec.md Scenario → test skeleton | 标记"需手动推导" | 输出 WARN："映射器不可用，test skeleton 需手动生成" |
| 模型分层 | 读取 .comet.yaml model_tier 字段 | 使用 session 默认模型 | 输出 INFO："使用默认模型" |
| comet-speculate | 作为 /comet-speculate Skill 注册 | 作为手动执行的 pre-hook 脚本 | 输出 INFO："comet-speculate 需手动触发" |

**机制3：版本兼容性声明**

每个 supercomet 发布声明兼容的上游版本范围：

```yaml
# supercomet/version.yaml
supercomet: 1.0.0
compatible:
  comet: ">=0.3.0"
  superpowers: ">=6.0.0"
  openspec: ">=1.4.0"
```

安装器在部署前检测，不兼容时输出明确警告：

```
⚠️ 检测到 Superpowers 5.1.0，supercomet 需要 >= 6.0.0
   双向反查可继续使用（降级到全量 grep），但无法利用 v6.0 优化
   是否继续安装？[y/N]
```

**机制4：上游贡献降低维护负担**

| 增强项 | 向上游贡献？ | 合并后对 supercomet 的影响 |
|--------|-----------|--------------------------|
| bidirectional-verify | ✅ 提 PR 给 Comet | supercomet 移除自身部署的脚本，改用 Comet 原生 |
| comet-speculate | ✅ 提 PR 给 Comet | supercomet 移除 Skill，改用 Comet 原生 /comet-speculate |
| 模型分层 | ✅ 提 PR 给 Comet | supercomet 移除分发逻辑修改，使用上游原生配置 |
| Spec-to-Test 映射 | ❌ 独立 Skill | 继续作为 supercomet 独有分发 |

上游 PR 被合并 = supercomet 对该功能的维护责任归零。

---

## 三、开发环境搭建

### 3.1 项目目录结构

```
supercomet/
├── .opencode/                         # OpenCode 插件配置（已有）
│   └── skills/                        # 符号链接 → ../src/skills/
├── src/
│   ├── skills/                        # supercomet 技能定义（开发中）
│   │   ├── bidirectional-verify/
│   │   │   └── SKILL.md
│   │   ├── comet-speculate/
│   │   │   └── SKILL.md
│   │   └── spec-to-test-mapper/
│   │       └── SKILL.md
│   └── scripts/                       # Shell 脚本（开发中）
│       ├── comet-forward-trace.sh
│       ├── comet-backward-trace.sh
│       ├── comet-trace.sh
│       └── comet-revert-restore.sh
├── dist/                              # 可分发的产品
│   ├── supercomet-install.sh          # 安装器
│   ├── version.yaml                   # 版本兼容性声明
│   └── assets/                        # 所有可部署文件（从 src/ 构建）
├── test/
│   ├── shell/                         # BATS Shell 测试
│   └── integration/                   # 端到端集成测试
│       └── test-bidirectional-verify.sh
├── openspec/                          # OpenSpec 管理 supercomet 自身规格
│   ├── config.yaml
│   └── specs/
│       └── supercomet/
│           └── spec.md                # 用 OpenSpec 管自己的 spec
├── opencode.json                      # OpenCode 项目配置（已有）
└── OpenSpec-Superpowers-深度融合-最终方案-v2.md  # 产品需求文档
```

### 3.2 开发流程：Comet 启动 + 渐进式狗粮替换

不创建单独的"验证阶段"。每一个增强的构建都是下一个增强的开发环境——开发一个就用一个，即时验证。

```
═══════════════════════════════════════════════════════════════
Day 1: 安装 Comet，项目 init
═══════════════════════════════════════════════════════════════

  comet init → 初始化 supercomet 项目
  创建 src/ / dist/ / test/ 目录
  初始化 openspec/ （用 OpenSpec 管自身 spec）

  开发环境：
    平台：OpenCode
    流程：纯 Comet（无 supercomet 增强）
    理由：此时 supercomet 还不存在

  专注开发：P0-1 bidirectional-verify
    · comet-forward-trace.sh
    · comet-backward-trace.sh
    · bidirectional-verify.md

═══════════════════════════════════════════════════════════════
P0-1 完成 → 部署 v0.1 → 开发环境升级
═══════════════════════════════════════════════════════════════

  supercomet-install.sh → 将 P0-1 注入 Comet
  此时：/comet-verify 开始产出 traceability.md

  专注开发：P0-2 三维 Traceability 账本
    · comet-trace.sh
    · 合并 .comet.yaml tasks schema

  开发环境：
    平台：OpenCode
    流程：Comet + supercomet v0.1（含双向反查）
    狗粮验证：P0-2 的每个 commit 都有三维追溯链
    如果 traceability.md 产出有问题 → P0-1 脚本有 bug → 在此暴露

═══════════════════════════════════════════════════════════════
P0-2 完成 → 部署 v0.2 → 开发环境再升级
═══════════════════════════════════════════════════════════════

  专注开发：P1-3 comet-speculate
    · assets/skills/comet-speculate/SKILL.md
    · speculate-checklist.md / self-review-checklist.md

  开发环境：
    流程：Comet + supercomet v0.2（含双向反查 + 三维账本）
    每次 build→verify 都跑双向反查
    如果 traceability.md 或 三维账本有问题 → 在 P1-3 开发中暴露

  ⚠️ comet-speculate 自身暂不使用（它是可选前置）
     P1-3 的变更直接用 /comet-open 进入，跳过 speculate
     等 P1-4 开发时再回头用 speculate（验证 P1-3 产出）

═══════════════════════════════════════════════════════════════
P1-3 完成 → 部署 v0.3
═══════════════════════════════════════════════════════════════

  专注开发：P1-4 Spec-to-Test 自动映射
  开发环境：Comet + supercomet v0.3
    ⚡ 可选：用 /comet-speculate 启动 P1-4 的需求探索
       → 验证 P1-3 的 comet-speculate 是否正常运作

═══════════════════════════════════════════════════════════════
P1-4 完成 → 部署 v0.4
═══════════════════════════════════════════════════════════════

  专注开发：P1-5 子Agent 模型分层选择
  开发环境：Comet + supercomet v0.4
    此时：全 P0 + 大半 P1 功能可用
    模型分层在 comet-build 分发 implementer 时生效
    → 验证：P1-5 的 PR 构建速度是否因模型分层而不同

═══════════════════════════════════════════════════════════════
P1 全部完成 → 部署 v1.0-rc
═══════════════════════════════════════════════════════════════

  专注开发：P2-6 Revert-Restore + P2-7 Git Notes
  开发环境：Comet + supercomet v1.0-rc（全量狗粮）
    全链路：/comet-speculate → open → design → build
            → verify(含双向反查+回归验证) → archive
    Git Notes 在每次 commit 时自动写入 → 验证不可变性

═══════════════════════════════════════════════════════════════
全部完成 → 发布 v1.0
═══════════════════════════════════════════════════════════════
```

### 3.3 狗粮强度递增表

| 阶段 | 使用中的 supercomet 功能 | 正在开发的功能 | 狗粮场景 |
|------|------------------------|-------------|---------|
| 起步 | 无 | P0-1 | 无狗粮，纯 Comet 开发 |
| P0-1 后 | bidirectional-verify | P0-2 | P0-2 提交的 traceability.md 产出 → 验证 P0-1 |
| P0-2 后 | bidirectional-verify + 三维账本 | P1-3 | P1-3 开发的全流程 → 验证 P0 全部功能 |
| P1-3 后 | P0 全部 + comet-speculate | P1-4 | P1-4 用 speculate 启动 → 验证 speculate |
| P1-4 后 | P0 全部 + P1 大半 | P1-5 | P1-5 用模型分层 → 验证分层策略 |
| P1-5 后 | P0+P1 全部 | P2 | 全链路验证 |
| 全部后 | 全部 | 无 | 最终集成测试 |

---