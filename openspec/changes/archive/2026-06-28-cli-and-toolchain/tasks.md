## 1. supercomet init 完善

- [x] 1.1 创建 `dist/manifest.yaml` — 声明式部署清单
- [x] 1.2 修改 `bin/supercomet.js` — 基于 manifest 的全量部署逻辑
- [x] 1.3 实现版本预检：检查上游版本满足 dist/version.yaml 兼容范围

## 2. npm 包结构检查

- [x] 2.1 检查 `package.json` 符合规格（bin、peerDependencies、name）
- [x] 2.2 确保发布包不包含 Comet 源码副本

## 3. BATS 测试补全

- [x] 3.1 `test/shell/comet-speculate.bats` — 对应 change comet-speculate
- [x] 3.2 `test/shell/spec-to-test-mapping.bats` — 对应 change spec-to-test-mapping
- [x] 3.3 `test/shell/model-tier-selection.bats` — 对应 change model-tier-selection
- [x] 3.4 `test/shell/revert-restore.bats` — 对应 change revert-restore
- [x] 3.5 `test/shell/git-notes.bats` — 对应 change git-notes

## 4. 集成测试

- [x] 4.1 编写 `test/integration/` 端到端集成测试（完整 Comet change 流程）

## 5. CI 哨兵

- [x] 5.1 创建 `.github/workflows/ci-sentinel.yml` — 每日定时测试
