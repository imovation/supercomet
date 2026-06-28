## 1. 核心脚本

- [ ] 1.1 实现 `src/scripts/comet-model-tier.sh` — 解析 `.comet.yaml` task 元数据，计算复杂度评分
- [ ] 1.2 实现模型层级推荐逻辑（fast/economy/balanced/best 四档映射）
- [ ] 1.3 实现降级路径：无 model_tier 字段时输出默认模型
- [ ] 1.4 支持 `--human` 和 `--json` 输出格式，支持 `--override` 手动覆盖

## 2. 部署

- [ ] 2.1 `bin/supercomet.js` 的 `supercomet init` 增加部署模型层级脚本

## 3. 测试

- [ ] 3.1 编写 `test/shell/model-tier-selection.bats` — 覆盖各复杂度档位、降级路径、--override 覆盖
