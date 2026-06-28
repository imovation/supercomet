# Brainstorm Summary

- Change: spec-to-test-mapping
- Date: 2026-06-28

## 确认的技术方案

Shell 脚本 `comet-spec-to-test.sh`：
- 解析 spec.md 的 `#### Scenario:` 块，提取 GIVEN/WHEN/THEN 步骤
- 框架检测：package.json → 文件后缀（.py/.go）→ 通用 fallback
- 输出测试骨架：注释标注步骤 + `it()/def test_/func Test` 空函数体
- 降级：[MANUAL] 标记 + WARN stderr + exit 0

## 关键取舍与风险

- 纯 Shell 解析 Markdown，不依赖外部解析器
- 框架误判风险 → 支持 `--framework` 手动覆盖
- 复杂嵌套 Scenario 解析失败 → [MANUAL] 降级

## 测试策略

BATS 测试：正常 Scenario 解析、多框架格式、损坏输入降级、空场景边缘情况

## Spec Patch

无
