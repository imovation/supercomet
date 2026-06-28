# revert-restore Specification

## Purpose
TBD - created by archiving change revert-restore. Update Purpose after archive.
## Requirements
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

