# Comet Design Handoff

- Change: revert-restore
- Phase: design
- Mode: compact
- Context hash: 39da657f51e3f0acabe85341d32f7fafc12e0f8b97bb102c20e0f94077a5d243

Generated-by: comet-handoff.sh

OpenSpec remains the canonical capability spec. This handoff is a deterministic, source-traceable context pack, not an agent-authored summary.

## openspec/changes/revert-restore/proposal.md

- Source: openspec/changes/revert-restore/proposal.md
- Lines: 1-24
- SHA256: d0a3673fd3a689ee2e5ac0232d2b17da111e7535ae774a9fdfa83d3ca47dc31f

```md
## Why

关键变更（Security/Core/Critical）的测试可能表面通过但实际无效。revert-restore 回归验证通过"撤销实现→验证测试失败→恢复实现→验证测试通过"的循环，确保测试真正能捕捉缺陷。

## What Changes

- 新增 `src/scripts/comet-revert-restore.sh` — 回归验证脚本
- 接受一个 implement commit hash，执行：git revert → run tests → git revert (restore) → run tests
- Hard Gate：撤销后测试仍 PASS → 阻断（测试无效）
- 仅对标记 Security/Core/Critical 的 task 执行
- 零侵入——独立脚本，不修改 Comet 核心

## Capabilities

### New Capabilities
- `revert-restore`: 对关键变更执行回归验证，确保测试能捕捉缺陷

### Modified Capabilities
<!-- None -->

## Impact

- 新增 Shell 脚本：`src/scripts/comet-revert-restore.sh`
- 修改 `bin/supercomet.js`：`supercomet init` 部署脚本
```

## openspec/changes/revert-restore/design.md

- Source: openspec/changes/revert-restore/design.md
- Lines: 1-43
- SHA256: b6acc2611da2ec16dd8ecaae705d7f1809eacf596b3edd32bd667cb596a87f36

```md
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
```

## openspec/changes/revert-restore/tasks.md

- Source: openspec/changes/revert-restore/tasks.md
- Lines: 1-15
- SHA256: a6ccd230f6b6940f227445e003114435546b9104797dd669a8387c51031bdbaa

```md
## 1. 核心脚本

- [ ] 1.1 实现 `src/scripts/comet-revert-restore.sh` — revert-restore 循环逻辑
- [ ] 1.2 实现 git revert + test 执行 + git revert 恢复 + test 再验证
- [ ] 1.3 实现 Hard Gate 逻辑：撤销后测试仍 PASS → 阻断
- [ ] 1.4 实现安全隔离：git worktree 优先，降级 stash + in-place
- [ ] 1.5 实现范围限定：仅 Security/Core/Critical task 执行

## 2. 部署

- [ ] 2.1 `bin/supercomet.js` 的 `supercomet init` 增加部署 revert-restore 脚本

## 3. 测试

- [ ] 3.1 编写 `test/shell/revert-restore.bats` — 覆盖有效测试（撤销后失败）、无效测试阻断、非关键变更跳过、worktree 隔离
```

## openspec/changes/revert-restore/specs/revert-restore/spec.md

- Source: openspec/changes/revert-restore/specs/revert-restore/spec.md
- Lines: 1-29
- SHA256: dcd1f3600fa6ed869d636e811c0e34db846f73116b25acfb9df1b49ebdf24fb5

```md
## ADDED Requirements

### Requirement: 测试应能捕捉缺陷

系统 SHALL 通过撤销-测试-恢复循环验证测试有效性。

#### Scenario: 测试应能捕捉缺陷
- **WHEN** revert-restore 验证在关键变更的 implement commit 上运行
- **THEN** 撤销实现后相关测试必须 FAIL
- **AND** 恢复实现后测试必须 PASS
- **AND** 确认恢复后工作区干净（无残留变更）

### Requirement: 无效测试被阻断

当撤销实现后测试仍然 PASS 时，系统 SHALL 阻断流程。

#### Scenario: 无效测试被阻断
- **WHEN** 撤销实现后测试仍然 PASS
- **THEN** Hard Gate 阻断，退出码非 0
- **AND** 输出诊断信息：哪些测试本应失败但通过了

### Requirement: 范围限定

回归验证 SHALL 仅对标记为 Security、Core 或 Critical 的关键 task 执行。

#### Scenario: 非关键变更跳过
- **WHEN** task 未标记 Security、Core、Critical
- **THEN** revert-restore 自动跳过并输出 SKIP 信息
- **AND** 退出码为 0（不阻断流程）
```

