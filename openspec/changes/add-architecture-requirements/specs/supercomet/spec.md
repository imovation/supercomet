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

#### Scenario: Spec-to-Test 映射降级
- 给定 spec.md 的格式或结构无法被映射器自动解析
- 当 映射器运行
- 则 标记对应 Scenario 为"需手动推导"
- 且 输出 WARN 级别信息，不阻断 build 流程

#### Scenario: 模型分层降级
- 给定 `.comet.yaml` 中不存在 model_tier 字段
- 当 comet-build 分发子Agent
- 则 使用当前 session 的默认模型
- 且 输出 INFO 级别信息："使用默认模型"

#### Scenario: comet-speculate 降级
- 给定 Comet 版本不支持 `/comet-speculate` Skill 注册
- 当 用户调用 speculate
- 则 以手动执行的 pre-hook 脚本形式提供
- 且 输出 INFO 级别信息："comet-speculate 需手动触发"

---

### Requirement: 版本兼容性声明与哨兵机制

supercomet SHALL 在 `dist/version.yaml` 中声明兼容的上游版本范围（Comet、Superpowers、OpenSpec），并 SHALL 配置 CI 每日基于最新上游版本执行测试以提前发现兼容性断裂。

#### Scenario: version.yaml 结构
- 给定 supercomet 的发布包
- 当 检查 `dist/version.yaml`
- 则 必须包含 `supercomet` 版本号
- 且 必须包含 `compatible` 字段，声明 comet、superpowers、openspec 的最低兼容版本

#### Scenario: 安装器预检
- 给定 `supercomet init` 执行
- 当 检测到上游版本低于 version.yaml 声明的兼容范围
- 则 输出明确警告，提示用户升级上游或接受降级行为
- 且 允许用户选择继续安装或中止

#### Scenario: CI 哨兵自动检测
- 给定 CI 流水线配置
- 当 每日定时触发测试
- 则 安装 `@rpamis/comet@latest` 并执行 supercomet 测试套件
- 且 测试失败时告警，不自动发布新版本

---

### Requirement: 上游 PR 优先策略

supercomet 的每个增强 SHALL 优先向 Comet 上游提交 PR。上游 PR 被合并后，supercomet SHALL 从自身分发中移除该增强的实现。PR 被拒时，supercomet SHALL 有明确的备用分发路径。

#### Scenario: 上游合并后的行为
- 给定 supercomet 的某个增强（如 bidirectional-verify）已被 Comet 上游合并
- 当 `supercomet init` 在包含该增强的 Comet 版本上执行
- 则 跳过该增强的文件部署
- 且 不输出警告或错误（上游已原生支持）

#### Scenario: 上游拒绝后的备用路径
- 给定 supercomet 的某个增强的 PR 被 Comet 上游拒绝
- 当 supercomet 发布
- 则 该增强作为独立 Comet 插件或独立 Skill 持续分发
- 且 以 pre-hook 或独立 Skill 方式工作，不硬依赖 Comet 核心修改

---

### Requirement: 渐进式狗粮替换开发方法论

supercomet SHALL 采用"Comet 启动 + 渐进式狗粮替换"的开发策略：从纯 Comet 起步开发 P0-1，每完成一个增强即部署并立即用于开发下一个增强。

#### Scenario: 狗粮递增强度
- 给定 supercomet 处于开发阶段
- 当 P0-1（bidirectional-verify）完成并部署
- 则 P0-2 的开发过程必须产出 traceability.md，验证 P0-1 功能正常
- 且 若 traceability.md 有异常，必须在 P0-2 开发中暴露并修复 P0-1

#### Scenario: 全链路狗粮验证
- 给定 所有 7 个增强均已开发完成
- 当 执行完整的 Comet change 流程
- 则 全链路必须包含：speculate → open → design → build → verify(含双向反查 + 回归验证) → archive
- 且 Git Notes 在每个 task 完成时自动写入

---

### Requirement: 测试工具链

supercomet SHALL 使用 BATS 进行 Shell 脚本单元测试，使用端到端集成测试验证完整 change 流程。

#### Scenario: BATS 测试 Shell 脚本
- 给定 `test/shell/` 目录
- 当 执行测试
- 则 每个增强的 Shell 脚本必须有对应的 BATS 测试文件
- 且 测试覆盖正向路径和降级路径

#### Scenario: 端到端集成测试
- 给定 `test/integration/` 目录
- 当 执行集成测试
- 则 必须验证一个完整 Comet change 从 open 到 archive 的流程
- 且 包含 supercomet 增强在流程中的行为验证
