# supercomet

> Comet 技能扩展包 — OpenSpec × Superpowers 深度融合

supercomet 为 [Comet](https://github.com/rpamis/comet) 工作流增加 **7 个增强功能**，构建完整的双向追溯、结构化探索、自动测试映射和模型分层体系。

```text
  /comet-speculate        探索阶段（方案对比 + 推荐）
       ↓
  /comet-open  ──→  /comet-design  ──→  /comet-build
                                               │
                                    ┌──────────┼──────────┐
                                    │ 模型分层  │ spec→test │
                                    └──────────┼──────────┘
                                               ↓
                        /comet-verify  ←──  /comet-build
                            │    │
                 双向反查 ◄─┘    └─► 回归验证
                            │
                      /comet-archive
                            │
                       Git Notes 备份
```

## 安装

**前提**：需要 `@rpamis/comet >= 0.3.0`。安装 supercomet 前先装 Comet：

```bash
npm install -g @rpamis/comet
```

```bash
# 从 GitHub 安装
npm install -g github:imovation/supercomet

# 从 npm 安装（发布后）
npm install -g supercomet
```

卸载：

```bash
npm uninstall -g supercomet
```

依赖 `@rpamis/comet >= 0.3.0`（peer dependency，需自行安装）。

## 使用

```bash
# 1. 安装并初始化 Comet（如未执行）
npm install --save-dev @rpamis/comet
npx comet init

# 2. 部署 supercomet 增强（自动预检 Comet 是否已初始化）
supercomet init

# 跳过预检，强制部署
supercomet init --force

# 查看版本
supercomet version
```

`supercomet init` 将所有增强脚本和 Skill 文件部署到当前项目的 `comet/scripts/` 和 `comet/reference/` 目录。部署前自动检测 Comet 是否已安装，版本不兼容时输出警告。

## 7 个增强

| 优先级 | 增强 | 说明 |
|--------|------|------|
| P0-1 | 双向反查 | spec ↔ test 双向追溯，产出 traceability.md，覆盖率不足时阻断 verify→archive |
| P0-2 | 三维追溯 | Requirement → Scenario → Test → Commit → Task 完整追溯链 |
| P1-3 | 探索阶段 | `/comet-open` 之前的可选结构化探索，生成 2-3 个方案对比 + 推荐 |
| P1-4 | Spec→Test 映射 | 将 spec.md 的 GIVEN/WHEN/THEN 声明自动转换为测试骨架（Jest/Vitest/Pytest/Go） |
| P1-5 | 模型分层 | 按 task 复杂度自动推荐模型层级（fast / economy / balanced / best） |
| P2-6 | 回归验证 | Revert-Restore 循环：撤销实现 → 测试必须失败 → 恢复 → 测试必须通过 |
| P2-7 | Git Notes | task 完成时自动写入不可变 Git Notes，进度丢失后可恢复 |

## 架构

```
src/
├── scripts/                  # 10 个 Shell 脚本（7 个增强）
│   ├── comet-forward-trace.sh
│   ├── comet-backward-trace.sh
│   ├── comet-trace.sh
│   ├── comet-speculate.sh
│   ├── comet-spec-to-test.sh
│   ├── comet-model-tier.sh
│   ├── comet-revert-restore.sh
│   ├── comet-git-notes.sh
│   ├── comet-state-set-task.sh
│   └── comet-guard-check-commits.sh
├── skills/                   # Skill 文件（Agent 工作流定义）
│   ├── comet-speculate/
│   ├── comet-quick-speculate/
│   ├── spec-to-test/
│   └── bidirectional-verify/
dist/
├── version.yaml              # 兼容版本声明
bin/
└── supercomet.js             # CLI 入口
```

**核心约束**：不 fork、不修改 Comet 源代码。所有增强通过 Skill 文件或独立脚本部署，仅消费上游产出文件作为输入。

## 侵入性分层

| 级别 | 增强 | 方式 |
|------|------|------|
| 零侵入 | bidirectional-verify、spec-to-test、revert-restore、git-notes | 部署文件到已有目录 |
| 轻侵入 | 三维追溯、模型分层 | 追加 `.comet.yaml` schema |
| 核心侵入 | comet-speculate | 优先向上游提 PR，未合并时独立部署 |

每个增强都有降级路径：上游产出格式变化时降级运行，不阻断 Comet 工作流。

## 测试

```bash
# Shell 单元测试（61 个用例）
bats test/shell/*.bats

# 集成测试（15 个用例）
bats test/integration/*.bats
```

## 兼容性

| 上游 | 最低版本 |
|------|---------|
| @rpamis/comet | >= 0.3.0 |
| Superpowers | >= 6.0.0 |
| OpenSpec | >= 1.4.0 |

## License

MIT
