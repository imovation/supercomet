## 1. 准备工作

- [x] 1.1 审查已有 `openspec/specs/supercomet/spec.md`，确认追加位置和格式一致性
- [x] 1.2 审查 delta spec（`specs/supercomet/spec.md`）内容完整性，逐项对齐 `定稿.md`

## 2. 实施

- [x] 2.1 将 delta spec 中的 8 项 `## ADDED Requirements` 追加到主 spec `openspec/specs/supercomet/spec.md` 末尾
- [x] 2.2 追加 `**架构约束**` 标注，与已有功能 Requirement 区分
- [x] 2.3 在 spec.md 顶部添加定稿.md 源引用说明

## 3. 验证

- [x] 3.1 运行 `openspec validate supercomet` 确认 spec 格式合法
- [x] 3.2 人工逐项检查 8 个新增 Requirement 的 Scenario 完整性和可验证性
