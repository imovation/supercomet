# Comet Design Handoff

- Change: git-notes
- Phase: design
- Mode: compact
- Context hash: 42a49046d1268505d2cf5fe7b59923b1edd3bd5511253c2e20b606349623bb0d

Generated-by: comet-handoff.sh

OpenSpec remains the canonical capability spec. This handoff is a deterministic, source-traceable context pack, not an agent-authored summary.

## openspec/changes/git-notes/proposal.md

- Source: openspec/changes/git-notes/proposal.md
- Lines: 1-24
- SHA256: a80e9d35ffe09932ff6462acf20bf88e5d16780e8d044af721ffe5cfec5943cf

```md
## Why

Comet task 完成后，进度信息存储在 `.comet.yaml` 中。如果工作目录被 `git clean -fdx` 清理，所有进度账本丢失。Git Notes 作为不可变的分布式备份层，使 task→commit 映射可从 git 历史中恢复。

## What Changes

- 新增 `src/scripts/comet-git-notes.sh` — Git Notes 写入脚本
- 读入 task id、requirement id 和 commit hash
- 使用 `git notes append` 写入引用到对应 commit
- 支持 `comet-git-notes.sh --recover` 从 git notes 恢复进度信息

## Capabilities

### New Capabilities
- `git-notes`: Task 完成时自动写入 Git Notes 作为不可变进度备份

### Modified Capabilities
- `three-d-traceability`: comet-state-set-task.sh 完成时触发 git-notes 写入（轻侵入追加）

## Impact

- 新增 Shell 脚本：`src/scripts/comet-git-notes.sh`
- 修改 `src/scripts/comet-state-set-task.sh`：task 完成时调用 git-notes 写入
- 修改 `bin/supercomet.js`：`supercomet init` 部署 git-notes 脚本
```

## openspec/changes/git-notes/design.md

- Source: openspec/changes/git-notes/design.md
- Lines: 1-46
- SHA256: bf90ea80c860a3207abd8c3915a64c49a85488c0c4aeb98767de020636cac4c5

```md
## Context

P0-2 的三维追溯依赖 `.comet.yaml` 存储 task→commit 映射。Git Notes 为这个映射提供不可变的备份层——数据随 commit 存储在 git 对象库中。

此增强为轻侵入——追加调用到 `comet-state-set-task.sh`，不修改 Comet 核心脚本（仅修改 supercomet 自己的脚本）。

## Goals / Non-Goals

**Goals:**
- Task 完成时自动写入 git note
- 支持从 git notes 恢复进度信息
- 恢复数据格式与 `comet-trace.sh` 兼容

**Non-Goals:**
- 不替代 `.comet.yaml` 作为主数据源
- 不强制推送 notes（默认本地，可选推送）
- 不加密 notes 内容

## Decisions

### 1. Notes 命名空间

**选择**：`supercomet.task` 作为 git notes 引用名

**理由**：与 `refs/notes/commits`（常见 CI 用）区分，避免冲突。supercomet 前缀明确归属。

### 2. Notes 格式

**选择**：紧凑单行键值对
```
task_id=1.1 requirement_id=bidirectional-verify scenario=正向反查 commits=abc1234
```

**理由**：紧凑、机器可读、可追加。每行一个记录，多 task 引用同一 commit 时 append。

### 3. 恢复策略

**选择**：`git log --show-notes=supercomet.task` 遍历所有 notes，提取 task 映射，输出到临时 `.comet-recovery.yaml`

**理由**：不修改现有 `.comet.yaml`（只读恢复），由用户决定是否合并恢复数据。

## Risks / Trade-offs

- [风险] 用户未推送 notes 引用于是远程不可用 → 缓解：本地 notes 已提供保护；提示用户定期 `git push origin refs/notes/supercomet.task`
- [风险] Notes 体积随 commit 增长 → 缓解：单条 note < 200 bytes，10K commits 仅 ~2MB
- [风险] Squash merge 丢失 commit → 缓解：记录 note 在原始 commit 上；squash 后合并 commit 需手动关联
```

## openspec/changes/git-notes/tasks.md

- Source: openspec/changes/git-notes/tasks.md
- Lines: 1-13
- SHA256: dc53ff93fe363486ceb96f10fb3520c7dc0f2fad72d02fe2da7c56f7b40b98a5

```md
## 1. 核心脚本

- [ ] 1.1 实现 `src/scripts/comet-git-notes.sh` — git notes append 写入 task 追溯信息
- [ ] 1.2 实现 `comet-git-notes.sh --recover` — 从 git notes 恢复进度映射
- [ ] 1.3 修改 `src/scripts/comet-state-set-task.sh` — task 完成时自动调用 git-notes 写入

## 2. 部署

- [ ] 2.1 `bin/supercomet.js` 的 `supercomet init` 增加部署 git-notes 脚本

## 3. 测试

- [ ] 3.1 编写 `test/shell/git-notes.bats` — 覆盖 notes 写入、恢复流程、空 notes 处理
```

## openspec/changes/git-notes/specs/git-notes/spec.md

- Source: openspec/changes/git-notes/specs/git-notes/spec.md
- Lines: 1-20
- SHA256: 991ae0d62c0d612a6970700f9ec8dc4397b4ee643a5194bed5c7429536a1251f

```md
## ADDED Requirements

### Requirement: Task 完成时写入 git note

系统 SHALL 在 task 完成时自动调用 git notes 写入追溯信息。

#### Scenario: Task 完成时写入 git note
- **WHEN** `comet-state-set-task.sh` 标记 task 为完成
- **THEN** `comet-git-notes.sh` 自动调用 git notes append
- **AND** git note 记录 task id、requirement id 和 commit hash

### Requirement: 进度账本丢失后恢复

系统 SHALL 支持从 git notes 恢复 task 到 commit 的映射关系。

#### Scenario: 进度账本丢失后恢复
- **WHEN** 工作目录中的进度账本被 git clean -fdx 清除
- **THEN** `comet-git-notes.sh --recover` 可查询所有 git notes
- **AND** 输出可恢复的 task→commit 映射列表
- **AND** 恢复数据可在 `comet-trace.sh` 查询中使用
```

