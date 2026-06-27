---
comet_change: add-architecture-requirements
role: technical-design
canonical_spec: openspec
archived-with: 2026-06-27-add-architecture-requirements
status: final
---

# 架构约束编码 — 技术设计

> **源文档**：`supercomet-产品形态与开发环境方案-定稿.md` v1.0

## 问题

`openspec/specs/supercomet/spec.md` 仅覆盖 7 个功能增强（P0-1 ~ P2-7），缺失 8 项已审定的架构决策。这些决策是 supercomet 的非功能根基，必须与功能 Requirement 同等待遇，才能在 P0-1 完成后被双向反查脚本覆盖。

## 方案

将 8 项架构决策从 delta spec 追加到主 spec，采用尾部追加 + 分隔标题模式：

```
已有 spec.md（7 个功能 Requirement）
  └── 末尾追加 ──┐
                 ├── ## 架构约束（分隔标题）
                 ├── Requirement: 产品分发形态
                 ├── Requirement: 三级侵入性分层
                 ├── Requirement: 消费产出文件，不依赖上游内部实现
                 ├── Requirement: 每个功能有降级路径
                 ├── Requirement: 版本兼容性声明与哨兵机制
                 ├── Requirement: 上游 PR 优先策略
                 ├── Requirement: 渐进式狗粮替换开发方法论
                 └── Requirement: 测试工具链
```

## 关键决策

1. **单文件不拆分**：架构 Requirement 与功能 Requirement 在同一文件，便于双向反查脚本统一扫描
2. **分隔标题区分**：`## 架构约束` 清晰标识非功能与功能的边界，未来可独立检索
3. **格式对齐已有**：中文 "给定/当/则" Scenario 格式，保持全文件一致性
4. **源引用追溯**：在 spec 开头添加定稿.md 引用，确保未来一致

## 实施步骤

1. 审查已有 spec.md，确认追加位置
2. 将 delta spec 中的 8 项 ADDED Requirements 追加到 spec.md 末尾
3. 添加 `## 架构约束` 分隔标题
4. 在 spec 头部添加定稿.md 源引用
5. 运行 `openspec validate --strict` 验证
