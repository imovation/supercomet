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

### 方案 A：verify 可选扩展（轻侵入）

`.comet.yaml` 增加 `e2e_command` 字段，verify 阶段单元测试通过后，可选跑 E2E 验证。

- 失败不阻断归档，输出 WARN
- 实现简单，不改变 Comet 阶段结构

### 方案 B：独立 E2E 验证阶段（架构级）

Comet 增加一个新阶段 `e2e-verify`，置于 verify 和 archive 之间：

```
open → design → build → verify → e2e-verify → archive
```

**优势**：
- E2E 验证与单元验证分离，互不污染
- E2E 需要隔离环境（干净项目、全新安装），独立阶段可做 setup/teardown
- 明确语义：verify = 代码正确，e2e-verify = 行为正确
- 可独立跳过：轻量变更不需要 E2E

**细节**：
- `.comet.yaml` 增加 `e2e_mode: on|off`，默认 off
- `e2e_command` 定义 E2E 测试脚本
- E2E 工作在隔离的临时环境中（独立目录，不影响项目工作区）
- E2E 失败不阻断 archive，但必须输出完整报告
- agent 在 E2E 验证完成后有用户决策点：确认通过、忽略失败继续归档、回退修复

**推荐方案 B**。E2E 本质上是独立验证维度，不应作为 verify 子项。
