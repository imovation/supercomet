# comet-speculate 上游 PR 准备

## 目标

将 `/comet-speculate` 集成到 Comet 入口调度器，使其成为 Comet 原生支持的阶段（在 /comet-open 之前可选调用）。

## 当前状态

comet-speculate 作为独立 Skill 部署在 supercomet 中：

- `src/skills/comet-speculate/SKILL.md` — 完整探索模式 Skill 定义
- `src/skills/comet-quick-speculate/SKILL.md` — 快速探索模式 Skill 定义
- `src/scripts/comet-speculate.sh` — 核心脚本

## PR 内容

### 需要提交到上游的变更

1. **comet-speculate.sh** — 放在 Comet 的 `assets/scripts/` 目录
2. **comet-speculate SKILL.md** — 放在 Comet 的 `assets/skills/` 目录
3. **comet-quick-speculate SKILL.md** — 同上
4. **Comet 入口调度器** — 增加 `/comet-speculate` 和 `/comet-quick-speculate` 命令路由

### PR 被合并后的 supercomet 行为

- `supercomet init` 检测当前 Comet 版本是否原生支持 comet-speculate
- 若支持，跳过 comet-speculate 相关文件的部署
- 若不支持，继续作为独立 Skill 部署

### PR 被拒绝后的备用路径

comet-speculate 继续作为 supercomet 的独立 Skill 分发，不硬依赖 Comet 核心修改：

- 用户手动触发：`/comet-speculate` 通过 supercomet 部署的 Skill 文件加载
- 集成仍通过 /comet-open step 0a 的 explore-findings.md 检测机制实现
- 降级路径：comet-speculate.sh 不可用时，用户手动编写 explore-findings.md

## 时间线

- [x] 本 change (comet-speculate) 在 supercomet 中完成并验证
- [ ] 向上游 rpamis/comet 提交 PR
- [ ] 根据上游反馈调整
- [ ] 上游合并后，更新 supercomet 的部署逻辑
