# supercomet 产品形态与开发环境 — 交叉验证报告

> **审查日期**：2025-06-27
>
> **方法论**：双份 AI 独立分析交叉验证（参见 `双份AI独立分析交叉验证方法论.md`）
>
> **分析 A**：本会话生成 — supercomet = npm 包，依赖 `@rpamis/comet`
> **分析 B**：`supercomet-产品形态与开发环境方案.md` — supercomet = install.sh 扩展包

---

## 一、原点问题

1. supercomet 的产品形态定位是什么？靠什么机制自动兼容上游（OpenSpec、Superpowers、Comet）更新？
2. 基于 opencode 如何搭建 supercomet 的开发环境？是否用 Comet，还是吃自己的狗粮？

---

## 二、逐项对照，四分类

### 问题1：产品形态

| # | 维度 | A 结论 | B 结论 | 分类 |
|---|------|--------|--------|------|
| 1.1 | 与 Comet 的关系 | npm 包，声明依赖 `@rpamis/comet` | Comet 技能扩展包，不 fork，不独立 CLI | **一致** |
| 1.2 | 分发方式 | `npm install -g supercomet` → 自带 Comet | `supercomet-install.sh <project-dir>` → 用户先装 Comet | **冲突** |
| 1.3 | 侵入性分层 | 提到 PR 策略但未做分级 | 🔵🟡🔴 三级分层，每项明确安装方式 | **互补 B→A** |
| 1.4 | 安装后项目结构 | 未给出 | 给出完整目录树，标注每项来源 | **互补 B→A** |
| 1.5 | 产品身份 | 独立 npm 包 | 扩展包（依附 Comet） | **冲突（粒度不同）** |

### 问题1：上游兼容性

| # | 维度 | A 结论 | B 结论 | 分类 |
|---|------|--------|--------|------|
| 2.1 | 核心策略 | 接口边界纪律，仅通过文档化扩展点交互 | 消费 API/产出文件，不复制内部实现 | **一致** |
| 2.2 | 降级路径 | 未明确提及 | 每个功能有具体降级路径（4 项） | **互补 B→A** |
| 2.3 | 版本声明机制 | semver 范围 in `package.json` | `version.yaml` 独立声明文件 | **互补** — 可融合 |
| 2.4 | 哨兵机制 | 每日 `npm install @rpamis/comet@latest && test` | 安装器预检 + 警告 | **互补** — 可叠加 |
| 2.5 | 上游 PR 策略 | PR 策略，被拒后独立发布 | PR 策略 + "合并后维护责任归零" | **一致** |

### 问题2：开发环境

| # | 维度 | A 结论 | B 结论 | 分类 |
|---|------|--------|--------|------|
| 3.1 | 核心策略 | Comet 启动 + 渐进式狗粮替换 | Comet 启动 + 渐进式狗粮替换 | **一致** |
| 3.2 | 狗粮路径 | 抽象描述 3 阶段 | 逐日/逐版本可执行时间线（Day 1 → v1.0） | **互补 B→A** |
| 3.3 | 项目目录结构 | 未给出 | 完整 `src/ dist/ test/` 结构 | **互补 B→A** |
| 3.4 | 工具栈 | opencode + Comet + Superpowers | opencode + Comet + Superpowers | **一致** |
| 3.5 | 自身 spec 管理 | 未提及 | 用 OpenSpec 管自身 spec（dogfooding） | **互补 B→A** |
| 3.6 | 测试规划 | `npm link` 本地测试 | `test/{shell,integration}/`，BATS + 端到端 | **互补** — 融合 |
| 3.7 | 具体启动步骤 | `comet init` + `npm init -y` | `comet init` + 创建目录 + `openspec/` 初始化 | **互补 B→A** |

### 汇总

| 类别 | 数量 |
|------|------|
| 一致 | 5 |
| 互补（B→A，B 有而 A 无） | 10 |
| 互补（A→B，A 有而 B 无） | 2 |
| 冲突 | 2 |
| 双方均遗漏 | 0 |

---

## 三、冲突裁决

### 冲突 1：npm 包 vs install.sh

| | A：npm 包 | B：install.sh |
|--|----------|--------------|
| 论点 | supercomet 是独立产品，npm 生态提供版本管理、CI 集成、一键安装的完整体验 | supercomet 是扩展包，不应碰用户已有的 Comet 安装，install.sh 是外科手术式注入 |
| 证据 | Comet 本身就用 npm 分发——follow proven pattern | 🔵🟡🔴 分层中大部分是零侵入文件注入——install.sh 更贴近实际行为 |

**裁决：融合。**

supercomet 发布为 **npm 包 + peerDependency**。不对抗也不包含 Comet：

```json
{
  "name": "supercomet",
  "bin": { "supercomet": "bin/supercomet.js" },
  "peerDependencies": {
    "@rpamis/comet": ">=0.3.0"
  }
}
```

- `supercomet init` 的行为 = B 的 install.sh 逻辑（检测版本 + 部署文件 + 合并配置）
- npm 生态提供版本发现、CI 集成、`npx supercomet init` 零安装体验
- `peerDependency` 让用户自行管理 Comet 版本——不做保姆，做伙伴
- 核心理念仍是 B 的"扩展包"定位——不改 Comet 一行代码，只注入文件

### 冲突 2：独立产品 vs 扩展包（粒度冲突，非对立）

A 说"独立产品"，B 说"扩展包"。经审验，两者不在同一粒度：独立产品可以是扩展包（ESLint 插件就是独立 npm 包）。合并为：**supercomet 是一个独立分发的 Comet 扩展包**。

---

## 四、合并方案

### 产品形态

```
npm install -g supercomet      # 安装
supercomet init                 # 注入增强到当前 Comet 项目
```

侵入性分层（采用 B 的框架）：

| # | 增强项 | 侵入级 | supercomet init 行为 |
|---|--------|--------|---------------------|
| 1 | bidirectional-verify | 🔵 | 部署 2 脚本 + 1 参考文档 |
| 2 | 三维 Traceability 账本 | 🟡 | 部署脚本 + 合并 `.comet.yaml` tasks schema + 追加白名单 |
| 3 | comet-speculate | 🔴 | 优先上游 PR；未合并时作为独立 Skill 部署 |
| 4 | Spec-to-Test 映射 | 🔵 | 部署独立 Skill |
| 5 | 子Agent 模型分层 | 🟡 | 修改 SKILL.md 分发逻辑 + 合并 model_tier 字段 |
| 6 | Revert-Restore | 🔵 | 部署独立脚本 |
| 7 | Git Notes | 🔵 | 部署 git alias/脚本 |

### 上游兼容性：四级机制

1. **消费产出文件，不依赖内部实现**（B）——只读上游的 spec、task-brief、review-package，不上游内部代码
2. **每个功能有降级路径**（B）——上游格式变化时降级运行，不报错阻断
3. **version.yaml 独立声明 + CI 哨兵**（融合 A+B）
   ```yaml
   # dist/version.yaml
   supercomet: 0.1.0
   compatible:
     comet: ">=0.3.0"
     superpowers: ">=6.0.0"
     openspec: ">=1.4.0"
   ```
   CI 每日测试 `@rpamis/comet@latest`，break 时告警。
4. **上游 PR 优先，合并后维护责任归零**（B，A 一致）

### 开发环境

**策略**：Comet 启动 + 渐进式狗粮替换（两份分析一致）

**时间线**（采用 B 的逐版本规划）：

```
Day 1: comet init → 纯 Comet 开发 P0-1
P0-1 完成 → 部署 v0.1 → 用 bidirectional-verify 验证 P0-2 开发
P0-2 完成 → 部署 v0.2 → P1-3 开发时享受完整三维追溯
P1-3 完成 → 部署 v0.3 → P1-4 用 speculate 启动需求探索
P1-4 完成 → 部署 v0.4 → P1-5 享受模型分层加速
P1-5 完成 → 部署 v1.0-rc → P2 享受全链路狗粮
全部完成 → 发布 v1.0
```

**项目目录结构**（采用 B 的规划）：

```
supercomet/
├── src/
│   ├── skills/                # supercomet 技能定义
│   └── scripts/               # Shell 脚本源码
├── dist/                      # 可分发的构建产物
│   ├── version.yaml
│   └── assets/
├── test/
│   ├── shell/                 # BATS Shell 测试
│   └── integration/           # 端到端集成测试
├── openspec/
│   └── specs/supercomet/      # 用 OpenSpec 管自身规格（狗粮）
├── .opencode/                 # Comet init 产物
├── .agents/skills/            # Superpowers 14 技能
├── .comet/config.yaml         # Comet 配置
└── bin/supercomet.js          # npm 包入口
```

---

## 五、交叉验证证书

| 类别 | 数量 | 结论 |
|------|------|------|
| 一致 | 5 | 与 Comet 的关系、核心兼容策略、上游贡献、核心开发策略、工具栈——高置信度采纳 |
| 互补（B→A） | 10 | 侵入性分层、降级路径、version.yaml、逐阶段时间线、目录结构、自身 spec 管理、安装结构、测试目录、启动步骤、狗粮强度表——低风险吸收 |
| 互补（A→B） | 2 | CI 哨兵机制、npm 生态便利性——补充吸收 |
| 冲突 | 2 | npm 包 vs install.sh（→融合为 npm + peerDependencies）；独立产品 vs 扩展包（→粒度不同，合并） |
| 双方均遗漏 | 0 | — |

**总评**：两份分析在核心判断上高度一致。B 在执行细节上更充分，A 在分发机制上有独特视角。融合方案取两者之长，已落地为当前项目实际结构。
