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
