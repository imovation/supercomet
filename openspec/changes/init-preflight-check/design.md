## Context

`supercomet init` 部署增强到 `comet/scripts/` 和 `comet/reference/`，依赖 Comet 的目录结构。未安装 Comet 时这些目录无意义。

## Implementation

在 `cmdInit` 函数开头添加预检逻辑：

1. 检测环境变量 `$COMET_GUARD`、`$COMET_STATE` 是否可定位（验证 Comet 已安装）
2. 读取 `dist/version.yaml` 获取兼容版本范围
3. 尝试检测已安装的 Comet 版本（通过 `npm list @rpamis/comet` 或文件检测）
4. 不兼容时输出警告，提示升级或接受降级
5. 允许用户通过 `--force` 跳过预检

降级路径：无法检测版本时输出 INFO 级别提示，不阻断部署。
