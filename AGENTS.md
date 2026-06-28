# AGENTS.md — supercomet

## 这是什么仓库

supercomet 是一个 **Comet 技能扩展包**（npm 包），不是传统应用程序。它基于 `@rpamis/comet` 和 `@fission-ai/openspec`，为 Comet 工作流增加 7 个增强功能（双向追溯、结构化探索、自动测试映射、模型分层等）。

**核心约束**：不 fork、不修改 Comet 任何源代码。所有增强通过 Skill 文件或独立脚本部署，消费上游产出文件作为输入。

## 项目结构速览

```
bin/supercomet.js          # CLI 入口（npm 包 bin 字段）
src/skills/                # supercomet 自有 Skill（comet-speculate, comet-quick-speculate, spec-to-test, bidirectional-verify）
src/scripts/               # Shell 脚本源码（10 个 .sh 脚本覆盖 7 个增强）
dist/                      # 发布产物，含 version.yaml（兼容版本声明）
test/shell/                # BATS Shell 测试（7 个文件，61 个测试用例）
test/integration/          # 端到端集成测试（2 个文件，15 个测试用例）
.github/workflows/         # CI Sentinel：每日自动检测上游兼容性
.opencode/                 # OpenCode 插件：commands/、skills/、rules/
.agents/skills/            # Superpowers Skill（来自 obra/superpowers，通过 skills-lock.json 锁定）
openspec/                  # OpenSpec：specs/ 主规格、changes/ 变更记录、archive/
docs/superpowers/           # 设计文档、验证报告、实施计划（按日期命名）
pre-development/           # 历史决策文档、中间分析、未来增强提案
pre-development/           # 历史决策文档与中间分析
.comet/config.yaml         # Comet 自身配置：review_mode、auto_transition
.codegraph/                # CodeGraph 索引（支持 codegraph_explore）
```

注意：项目根目录没有 `opencode.json`。Comet init 将 opencode 配置写入 `.opencode/` 目录（skills/、commands/、rules/），不使用根级 config 文件。

## 关键约定

### 狗粮自用（Dogfooding）
- 本项目**自身使用 Comet 流程开发**，`openspec/specs/supercomet/spec.md` 是唯一权威规格
- 每完成一个增强即部署并用于开发下一个增强（渐进式狗粮替换）
- **所有代码变更必须走 Comet**：无论多少文件、多小改动，禁止绕过 `/comet` 直接提交。hotfix/tweak 是唯一捷径，但仍需通过对应 preset skill 创建 change 并归档
- 所有设计决策来源记录在 `pre-development/` 下

### 上游不可修改
- 不得修改 Comet 核心 Shell 脚本（comet-state.sh、comet-guard.sh 等）
- 仅消费上游产出文件（spec.md、task-brief、review-package），不依赖其内部实现
- 每个增强必须有降级路径：上游产出格式变化时降级运行，不阻断 Comet 工作流

### 侵入性分层
| 级别 | 项 | 部署方式 |
|------|-----|---------|
| 零侵入 | bidirectional-verify、spec-to-test 映射、revert-restore、git-notes | 部署 Skill 文件到已有目录 |
| 轻侵入 | 三维追溯、模型分层 | 追加合并 .comet.yaml schema + 白名单 |
| 核心侵入 | comet-speculate | 优先向上游提 PR，未合并时作为独立 Skill |

## 开发命令

```bash
# 查看版本
supercomet version

# 部署增强到当前项目（自动预检 Comet 状态）
supercomet init

# 跳过预检强制部署
supercomet init --force
```

测试使用 BATS：

```bash
# 运行全部 Shell 单元测试（61 个测试用例）
bats test/shell/*.bats

# 运行集成测试（15 个测试用例）
bats test/integration/*.bats
```

## Comet 工作流

本项目及其开发的目标项目均使用 Comet 5 阶段流程：

```
/comet-open → /comet-design → /comet-build → /comet-verify → /comet-archive
```

- **预设路径**：`/comet-hotfix`（跳过 brainstorming）和 `/comet-tweak`（跳过 brainstorming + 完整 plan）
- **阶段守卫**：`.opencode/rules/comet-phase-guard.md` 每轮注入，防止长上下文漂移
- **硬性脚本**：Comet 脚本随 skill 包分发，路径通过环境变量 `$COMET_GUARD`、`$COMET_STATE` 等定位，不硬编码
- **上下文恢复**：怀疑压缩后运行 `comet-state check <name> <phase> --recover`
- **用户确认**：决策点（方案确认、plan-ready、验证失败处理、归档前确认等）必须暂停等待用户明确选择，不得自动跳过

### 脚本定位样板

每个 Comet 阶段都需要运行 `comet-state.sh`、`comet-guard.sh` 等，但路径随 skill 安装位置变化。每个阶段开始时必须执行以下样板定位一次，后续复用 `$COMET_GUARD`、`$COMET_STATE`、`$COMET_HANDOFF`、`$COMET_ARCHIVE`：

```bash
COMET_ENV="${COMET_ENV:-$(find . "$HOME"/.*/skills "$HOME/.config" "$HOME/.gemini" -path '*/comet/scripts/comet-env.sh' -type f -print -quit 2>/dev/null)}"
if [ -z "$COMET_ENV" ]; then
  echo "ERROR: comet-env.sh not found. Ensure the comet skill is installed." >&2
  return 1
fi
. "$COMET_ENV"
```

脚本定位失败时停止流程，不要猜测路径或手动编辑 `.comet.yaml`。

### 实战坑位

**OpenSpec spec 格式硬要求**：
- 主 spec 必须包含 `## Purpose` 和 `## Requirements` 两级标题
- 每个 Requirement 用 `### Requirement: <name>`（三级标题），描述中必须含 SHALL/MUST
- 每个 Scenario 用 `#### Scenario: <name>`（四级标题）
- **`---` 水平线会截断 `## Requirements` 节的解析**，所有 Requirement 在该线之后都会被视为"在 Requirements 节外"而报错。分隔内容用空行或 `**粗体标注**`，不用 `---`
- 验证命令：`openspec validate supercomet`

**build 阶段：纯文档变更需要显式配置构建命令**：
纯文档变更（如修改 spec.md）在 build 阶段无实际构建步骤。Comet 的 build guard 会运行 `build_command` 检查构建是否通过。需在 change 的 `.comet.yaml` 中显式设置：
```yaml
build_command: "openspec validate supercomet"
verify_command: "openspec validate supercomet"
```

**archive 阶段：不要提前手工合并 delta 到主 spec**：
build 阶段实现应仅产出文件变更，不应手工将 delta spec 内容合并到 `openspec/specs/` 主 spec。主 spec 合并由归档脚本 `comet-archive.sh` 在 archive 阶段按 OpenSpec delta 语义（ADDED/MODIFIED/REMOVED）自动完成。若已手工合并，archive 时会报 `already exists` 导致归档失败。

## 使用 CodeGraph

仓库已配置 CodeGraph 索引（`.codegraph/`），查询代码结构时优先使用 `codegraph_explore` 或 `codegraph explore` 命令，而非 grep/find。

## Comet 配置

`.comet/config.yaml`：
- `context_compression: off` — 上下文压缩关闭
- `review_mode: off` — 代码审查模式关闭
- `auto_transition: true` — 阶段间自动衔接

修改这些配置可能影响整个工作流行为。

## 上游兼容范围

根据 `dist/version.yaml`：
- `@rpamis/comet >= 0.3.0`
- Superpowers >= 6.0.0
- OpenSpec >= 1.4.0
