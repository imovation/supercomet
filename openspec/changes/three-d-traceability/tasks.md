## 1. comet-trace.sh 实现

- [ ] 1.1 实现 `comet-trace.sh`：正向查询 `--requirement-id <id>`，输出 Requirement→Scenario→Test→Commit→Task
- [ ] 1.2 实现反向查询 `--commit <hash>`，输出 Commit→Task→Requirement→Scenario→Test
- [ ] 1.3 实现无效输入错误处理：不存在的 ID/hash 输出 "Not found"，退出码非零

## 2. .comet.yaml schema 扩展

- [ ] 2.1 扩展 task 字段 schema：追加 `requirement_id`、`scenario`、`test_file`、`test_name`、`commits`
- [ ] 2.2 comet-state.sh 新增 `set-task` 命令支持写入追溯字段

## 3. 闸门集成

- [ ] 3.1 comet-guard.sh verify→archive 转移时检查 commits 非空
- [ ] 3.2 commits 为空时阻止转移

## 4. BATS 测试

- [ ] 4.1 编写 `test/shell/comet-trace.bats`：正向查询测试
- [ ] 4.2 编写反向查询测试
- [ ] 4.3 编写无效输入错误处理测试
