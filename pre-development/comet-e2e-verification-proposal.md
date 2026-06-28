# Comet 缺少 E2E 验证能力

## 当前状况

Comet verify 阶段只执行 `verify_command`（通常为单元测试或构建命令）。以下验证场景无法自动化：

- `supercomet install` → `supercomet init` → 部署文件验证
- CI Sentinel 是否在 GitHub Actions 上正常运行
- 多个服务/工具链路端到端验证
- 跨 change 的集成行为验证

## 问题表现

- `cli-and-toolchain` change 归档后，CI Sentinel 文件在 GitHub 上实际能不能跑，没人知道，直到手动触发才确认
- `init-preflight-check` change 归档后，`supercomet init` 在真实项目中行为是否正确，靠手动测试发现，而不是自动化发现
- 以上验证都发生在归档之后，属于"事后发现"，增大了修补成本

## 建议方向

supercomet 增加 E2E 验证能力，作为 `/comet-verify` 的可选增强：

- `.comet.yaml` 增加 `e2e_command` 字段
- 支持定义需要在隔离环境中执行的端到端脚本
- verify 阶段跑完单元测试后，可选跑 E2E 验证
- 失败不阻断归档，但输出 WARN 标记为"未充分验证"
