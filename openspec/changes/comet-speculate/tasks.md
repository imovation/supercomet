## 1. Skill 文件与脚手架

- [x] 1.1 创建 `src/skills/comet-speculate/SKILL.md` — 完整探索模式 Skill 声明
- [x] 1.2 创建 `src/skills/comet-quick-speculate/SKILL.md` — 快速探索模式 Skill 声明

## 2. 核心实现

- [x] 2.1 实现 `src/scripts/comet-speculate.sh` — 完整模式：多方案对比 + 推荐 + 产出 explore-findings.md
- [x] 2.2 实现快速模式（quick shortcut）— 跳过多方案对比，直接推荐
- [x] 2.3 `explore-findings.md` 格式固定（Mode、Summary、Options、Recommendation 节）

## 3. 交接集成

- [x] 3.1 `/comet-open` Skill 增加探索结果检测逻辑：检测 `explore-findings.md` 存在时自动注入为 proposal 上下文
- [x] 3.2 `bin/supercomet.js` 的 `supercomet init` 增加部署 comet-speculate 相关 Skill 文件

## 4. 测试

- [x] 4.1 编写 `test/shell/comet-speculate.bats` — 覆盖完整模式、快速模式输出格式
- [x] 4.2 编写探索到 open 交接的集成测试场景

## 5. 文档与上游 PR

- [x] 5.1 准备向上游 rpamis/comet 提交 PR，将 `/comet-speculate` 集成到 Comet 入口调度器
