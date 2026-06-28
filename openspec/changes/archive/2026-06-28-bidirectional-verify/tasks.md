## 1. 正向反查脚本实现

- [x] 1.1 实现 `src/scripts/comet-forward-trace.sh`：提取 spec 中 `#### Scenario:` 名称，在 test/ 中搜索对应测试函数
- [x] 1.2 实现输入源优先级：优先消费 task-brief 和 review-package，不可用时降级全量 grep
- [x] 1.3 输出覆盖率数据：已覆盖 N/M 个 Scenario，覆盖率不足 100% 时设置 Gate = BLOCKED

## 2. 反向反查脚本实现

- [x] 2.1 实现 `src/scripts/comet-backward-trace.sh`：提取测试函数名称，比对 spec Scenario
- [x] 2.2 孤儿测试标记：无对应 spec Scenario 的测试以 WARN 级别报告，不阻断流程

## 3. traceability.md 生成

- [x] 3.1 实现 5 段式标准化报告输出：覆盖矩阵、孤儿测试、边界分析、闸门判定、下一步行动
- [x] 3.2 确保输出格式可被 comet-guard.sh 解析闸门状态（Gate = PASS/BLOCKED）

## 4. Skill 定义与部署

- [x] 4.1 创建 `src/skills/bidirectional-verify/SKILL.md`：定义能力描述、输入输出协议、降级策略
- [x] 4.2 更新 `bin/supercomet.js`：实现 `init` 子命令的部署逻辑（cp 脚本到 comet/scripts/，参考文档到 comet/reference/）

## 5. BATS 测试

- [x] 5.1 编写 `test/shell/bidirectional-verify.bats`：正向路径（场景全覆盖）测试
- [x] 5.2 编写降级路径测试：task-brief/review-package 不可用时验证全量 grep 降级行为
- [x] 5.3 编写反向路径测试：孤儿测试被正确 WARN 且不阻断

## 6. 关键集成验证

- [x] 6.1 验证 traceability.md 闸门格式与 comet-guard.sh 兼容
- [x] 6.2 验证 `supercomet init` 幂等执行（多次运行不报错）
