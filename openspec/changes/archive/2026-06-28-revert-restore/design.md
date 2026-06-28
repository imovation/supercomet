## Context

验证阶段的薄弱之处：测试套件可能给出假的安全感。P2-6 通过 revert-restore 循环验证测试的有效性。

此增强为零侵入——独立 Shell 脚本，不修改 Comet 任何核心文件。

## Goals / Non-Goals

**Goals:**
- git revert 实施 commit → 运行测试 → 确认失败
- git revert（恢复）→ 运行测试 → 确认通过
- Hard Gate：撤销后测试仍通过则阻断
- 仅对 Security/Core/Critical task 执行

**Non-Goals:**
- 不自动修复无效测试
- 不修改 git 历史
- 不对所有 change 强制执行（仅关键变更）

## Decisions

### 1. 安全隔离

**选择**：在 worktree 或 branch 中执行 revert-restore，不影响当前工作区

**理由**：revert 会修改文件，必须在隔离环境中操作。利用 git worktree 创建临时副本。

### 2. 无 git worktree 时的降级

**选择**：要求工作区干净（clean），在原工作区执行；验证前自动 stash 任何未提交变更

**理由**：不是所有环境支持 git worktree。安全降级路径确保可用性。

### 3. 测试命令来源

**选择**：从 `.comet.yaml` 的 `verify_command` 字段读取测试命令

**理由**：每个 change 已有自定义验证命令，无需全局配置。不存在时使用 `make test` 作为默认。

## Risks / Trade-offs

- [风险] revert 可能产生冲突 → 缓解：降级为手动提示，输出"revert 冲突，需手动验证"，退出码 0（不阻断）
- [风险] 大型项目测试耗时长 → 缓解：仅对关联的 test file 执行测试，不是全量测试套件
