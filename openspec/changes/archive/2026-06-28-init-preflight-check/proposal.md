## Why

`supercomet init` 直接写入文件，不检查 Comet 是否已安装。未安装 Comet 时部署无意义且令人困惑。

## What Changes

- `supercomet init` 增加预检：检测 Comet 是否存在及版本是否兼容
- 预检失败时输出明确警告并允许用户选择继续或中止

## Impact

- 修改 `bin/supercomet.js`：`cmdInit` 函数增加预检逻辑
