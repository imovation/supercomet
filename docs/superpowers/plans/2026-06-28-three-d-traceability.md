---
change: three-d-traceability
design-doc: docs/superpowers/specs/2026-06-28-three-d-traceability-design.md
base-ref: 68673f8d7262f722fa654cc675c00f53a4a2007a
archived-with: 2026-06-28-three-d-traceability
---

# three-d-traceability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 P0-1 spec↔test 双向反查基础上，加入 Task→Git Commit 维度，通过 `comet-trace.sh` 单脚本实现 Requirement→Scenario→Test→Commit→Task 完整三维追溯链，配合 .comet.yaml schema 扩展和 verify→archive 闸门。

**Architecture:** 三个独立 Shell 脚本——`comet-trace.sh`（双向查询，解析 .comet.yaml tasks 段，支持 `--requirement-id` 正向和 `--commit` 反向两种模式，输出缩进树）、`comet-state-set-task.sh`（将 task 追溯字段写入 .comet.yaml，自动捕获 HEAD commit hash）、`comet-guard-check-commits.sh`（检查 tasks 中 commits 非空，供 verify→archive 闸门调用）。轻侵入：supercomet init 部署时将 set-task 命令追加到 comet-state.sh 白名单、guard-check 脚本注册到 comet-guard.sh 检查链。

**Tech Stack:** Pure Shell（bash 4+, grep, sed, sort）。BATS 用于测试。

## Global Constraints

- 不修改 Comet 核心 Shell 脚本源码（comet-state.sh、comet-guard.sh 等）
- 轻侵入：`.comet.yaml` 的 tasks schema 通过追加方式扩展，不覆盖已有字段
- 轻侵入：`comet-state.sh` 的白名单通过追加方式扩展 `set-task` 命令，不修改已有命令
- commit hash 查询时先通过 `git rev-parse --verify` 验证合法性
- 不存在的 ID/hash 输出 "Not found"，退出码非零
- 脚本使用 `set -euo pipefail`
- .comet.yaml tasks 条目的 YAML key 使用不带引号的缩进格式（与现有 .comet.yaml 风格一致）
- 仅消费上游产出文件，不依赖 upstream 内部实现

archived-with: 2026-06-28-three-d-traceability
---

### Task 1: comet-trace.sh — 双向追溯查询脚本

**Files:**
- Create: `src/scripts/comet-trace.sh`

**Interfaces:**
- Consumes: `--requirement-id ID` 或 `--commit HASH`（互斥，二选一），`--comet-yaml PATH`（默认 `openspec/changes/<change-name>/.comet.yaml`）
- Produces: 缩进树格式输出到 stdout；"Not found" 到 stdout + 退出码 1
- Exit: 0 = 找到匹配，1 = Not found

- [x] **Step 1: 创建脚本骨架，含参数解析和使用帮助**

```bash
#!/usr/bin/env bash
set -euo pipefail

# comet-trace.sh — Three-dimensional traceability query
# Queries .comet.yaml tasks section for Requirement→Scenario→Test→Commit→Task chains

usage() {
  cat <<'USAGE'
Usage: comet-trace.sh [--requirement-id ID | --commit HASH] [options]

Options:
  --requirement-id ID    Forward query: Requirement → Scenario → Test → Commit → Task
  --commit HASH          Reverse query: Commit → Task → Requirement → Scenario → Test
  --change-name NAME     Change name (default: derived from --comet-yaml path)
  --comet-yaml PATH      Path to .comet.yaml (default: openspec/changes/<name>/.comet.yaml)
  --help                 Show this help
USAGE
  exit 0
}

REQUIREMENT_ID=""
COMMIT_HASH=""
CHANGE_NAME=""
COMET_YAML=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --requirement-id) REQUIREMENT_ID="$2"; shift 2 ;;
    --commit) COMMIT_HASH="$2"; shift 2 ;;
    --change-name) CHANGE_NAME="$2"; shift 2 ;;
    --comet-yaml) COMET_YAML="$2"; shift 2 ;;
    --help) usage ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage ;;
  esac
done

# Validate exactly one query mode specified
if [ -n "$REQUIREMENT_ID" ] && [ -n "$COMMIT_HASH" ]; then
  echo "ERROR: Cannot specify both --requirement-id and --commit" >&2
  exit 2
fi
if [ -z "$REQUIREMENT_ID" ] && [ -z "$COMMIT_HASH" ]; then
  echo "ERROR: Must specify --requirement-id or --commit" >&2
  exit 2
fi

# Resolve .comet.yaml path
if [ -z "$COMET_YAML" ]; then
  if [ -n "$CHANGE_NAME" ]; then
    COMET_YAML="openspec/changes/$CHANGE_NAME/.comet.yaml"
  else
    COMET_YAML=".comet.yaml"
  fi
fi

if [ ! -f "$COMET_YAML" ]; then
  echo "ERROR: $COMET_YAML not found" >&2
  exit 1
fi

echo "DEBUG: mode=$([ -n "$REQUIREMENT_ID" ] && echo "forward" || echo "reverse") yaml=$COMET_YAML" >&2
```

- [x] **Step 2: 验证脚本骨架运行**

Run:
```bash
bash src/scripts/comet-trace.sh --help
```
Expected: 打印 USAGE 并退出 0

Run:
```bash
bash src/scripts/comet-trace.sh --requirement-id test --comet-yaml openspec/changes/three-d-traceability/.comet.yaml 2>&1
```
Expected: 打印 "DEBUG: mode=forward yaml=..." 到 stderr，不报错（.comet.yaml 无 tasks 段时静默无输出）

- [x] **Step 3: 实现 .comet.yaml tasks 段行级解析器**

将脚本中的 `DEBUG` 行替换为以下解析入口和解析函数。

解析器核心技术：行级状态机。读到 `tasks:` 进入 tasks 段；读到非缩进行退出 tasks 段。读到 `  - id:` 开启新 task 记录。读到二级缩进 key（`    requirement_id:`、`    scenario:` 等）填入对应字段。读到 `    commits:` 后的 `      - <hash>` 收集 commit 列表。

完整解析函数 `parse_tasks_yaml()`：

```bash
# --- .comet.yaml tasks 段行级解析器 ---
# 内部状态变量（全局，由 parse_tasks_yaml 维护）：
#   PARSE_TASK_ID, PARSE_TASK_DESC, PARSE_TASK_REQID
#   PARSE_TASK_SCENARIO, PARSE_TASK_TESTFILE, PARSE_TASK_TESTNAME
#   PARSE_TASK_COMMITS (array)
# 输入：YAML 文件路径
# 输出：MATCHED_LINES 数组，每元素为一条完整追溯链行

declare -a MATCHED_LINES=()

parse_tasks_yaml() {
  local yaml_file="$1"
  local mode="$2"     # "fwd" or "rev"
  local query_val="$3"

  MATCHED_LINES=()
  local in_tasks=false
  local in_task=false
  local in_commits=false

  local task_id=""
  local task_desc=""
  local task_reqid=""
  local task_scenario=""
  local task_testfile=""
  local task_testname=""
  local -a task_commits=()
  local found_any=false

  while IFS= read -r line || [ -n "$line" ]; do
    # Section boundary: non-indented top-level key ends tasks section
    if $in_tasks && [[ "$line" =~ ^[a-z_]+\:[[:space:]] || "$line" =~ ^[a-z_]+\: ]]; then
      in_tasks=false
      in_task=false
      in_commits=false
    fi

    if [[ "$line" =~ ^tasks\: ]]; then
      in_tasks=true
      continue
    fi

    $in_tasks || continue

    # New task entry: "  - id:"
    if [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]id\: ]]; then
      # Flush previous task match before starting new one
      flush_task_match "$mode" "$query_val"
      task_id=$(extract_yaml_value "$line" "id")
      task_desc=""
      task_reqid=""
      task_scenario=""
      task_testfile=""
      task_testname=""
      task_commits=()
      in_task=true
      in_commits=false
      continue
    fi

    $in_task || continue

    # commits array header: "    commits:"
    if [[ "$line" =~ ^[[:space:]]{4}commits\: ]]; then
      in_commits=true
      continue
    fi

    # commits items: "      - <hash>"
    if $in_commits && [[ "$line" =~ ^[[:space:]]{6}-[[:space:]] ]]; then
      local ch
      ch=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//')
      ch="${ch//\"/}"
      task_commits+=("$ch")
      continue
    fi

    # Non-commit field at 4-space indent exits commits array
    if $in_commits && [[ "$line" =~ ^[[:space:]]{4}[a-z_] ]]; then
      in_commits=false
    fi

    # Task scalar fields (4-space indent)
    case "$line" in
      *"requirement_id:"*)
        task_reqid=$(extract_yaml_value "$line" "requirement_id")
        ;;
      *"scenario:"*)
        task_scenario=$(extract_yaml_value "$line" "scenario")
        ;;
      *"test_file:"*)
        task_testfile=$(extract_yaml_value "$line" "test_file")
        ;;
      *"test_name:"*)
        task_testname=$(extract_yaml_value "$line" "test_name")
        ;;
      *"description:"*)
        task_desc=$(extract_yaml_value "$line" "description")
        ;;
    esac
  done < "$yaml_file"

  # Flush last task
  flush_task_match "$mode" "$query_val"
}

# Extract YAML scalar value: strip key, quotes, and whitespace
extract_yaml_value() {
  local line="$1"
  local key="$2"
  echo "$line" | sed "s/.*${key}:[[:space:]]*//" | sed 's/^"//;s/"$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Check if current task matches query and append to MATCHED_LINES
flush_task_match() {
  local mode="$1"
  local query_val="$2"
  local matched=false

  if [ -z "$task_id" ]; then
    return
  fi

  if [ "$mode" = "fwd" ] && [ "$task_reqid" = "$query_val" ]; then
    matched=true
    found_any=true
  elif [ "$mode" = "rev" ]; then
    for ch in "${task_commits[@]}"; do
      if [ "$ch" = "$query_val" ]; then
        matched=true
        found_any=true
        break
      fi
    done
  fi

  if $matched; then
    MATCHED_LINES+=("REQ:$task_reqid|SCEN:$task_scenario|TEST_N:$task_testname|TEST_F:$task_testfile|TASK_ID:$task_id|TASK_DESC:$task_desc|COMMITS:${task_commits[*]}")
  fi
}
```

- [x] **Step 4: 实现正向查询（--requirement-id）缩进树输出**

在解析完成后，添加 `print_fwd_tree()` 函数并调用：

```bash
print_fwd_tree() {
  local prev_reqid=""
  local prev_scenario=""
  local first=true

  # Sort by requirement_id, scenario, task_id for stable output
  local sorted
  sorted=$(printf '%s\n' "${MATCHED_LINES[@]}" | sort -t'|' -k1,1 -k2,2 -k5,5)

  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    local reqid scena testn testf tid tdesc commits_str
    reqid=$(echo "$entry" | sed 's/.*REQ://;s/|SCEN:.*//')
    scena=$(echo "$entry" | sed 's/.*SCEN://;s/|TEST_N:.*//')
    testn=$(echo "$entry" | sed 's/.*TEST_N://;s/|TEST_F:.*//')
    testf=$(echo "$entry" | sed 's/.*TEST_F://;s/|TASK_ID:.*//')
    tid=$(echo "$entry" | sed 's/.*TASK_ID://;s/|TASK_DESC:.*//')
    tdesc=$(echo "$entry" | sed 's/.*TASK_DESC://;s/|COMMITS:.*//')
    commits_str=$(echo "$entry" | sed 's/.*COMMITS://')

    # First task in group: print Requirement and Scenario headers
    if [ "$first" = true ] || [ "$reqid" != "$prev_reqid" ]; then
      echo "Requirement: $reqid"
      echo "  └── Scenario: $scena"
      prev_reqid="$reqid"
      prev_scenario="$scena"
    elif [ "$scena" != "$prev_scenario" ]; then
      echo "  └── Scenario: $scena"
      prev_scenario="$scena"
    fi
    first=false

    echo "       └── Test: $testn"

    # Parse commits into array
    local -a commits_arr=()
    for word in $commits_str; do
      commits_arr+=("$word")
    done

    local num_commits=${#commits_arr[@]}
    local ci=0
    for commit in "${commits_arr[@]}"; do
      local conn_prefix="            "
      local branch_char
      if [ $ci -lt $((num_commits - 1)) ]; then
        conn_prefix="            ├── Commit: $commit"
      else
        conn_prefix="            └── Commit: $commit"
      fi
      echo "$conn_prefix"
      echo "            │    └── Task: $tid $tdesc"
      ci=$((ci + 1))
    done
  done <<< "$sorted"
}

# --- 正向查询入口 ---
if [ -n "$REQUIREMENT_ID" ]; then
  parse_tasks_yaml "$COMET_YAML" "fwd" "$REQUIREMENT_ID"
  if [ ${#MATCHED_LINES[@]} -eq 0 ]; then
    echo "Not found"
    exit 1
  fi
  print_fwd_tree
  exit 0
fi
```

- [x] **Step 5: 验证正向查询（使用手动构造的测试 .comet.yaml）**

创建测试用 .comet.yaml：

```bash
TMPDIR=$(mktemp -d)
cat > "$TMPDIR/.comet.yaml" << 'YAML'
workflow: full
phase: build
tasks:
  - id: "1.1"
    description: "实现 comet-forward-trace.sh"
    requirement_id: "bidirectional-verify"
    scenario: "正向反查——spec 到 test"
    test_file: "test/shell/bidirectional-verify.bats"
    test_name: "forward trace 100pc coverage passes gate"
    commits:
      - abc123def
      - def456abc
  - id: "2.1"
    description: "回溯反查"
    requirement_id: "bidirectional-verify"
    scenario: "反向反查——test 到 spec"
    test_file: "test/shell/backward-trace.bats"
    test_name: "backward trace orphans warnings"
    commits:
      - ghi789jkl
YAML
```

Run:
```bash
bash src/scripts/comet-trace.sh --requirement-id bidirectional-verify --comet-yaml "$TMPDIR/.comet.yaml"
```
Expected output (缩进树格式):
```
Requirement: bidirectional-verify
  └── Scenario: 正向反查——spec 到 test
       └── Test: forward trace 100pc coverage passes gate
            ├── Commit: abc123def
            │    └── Task: 1.1 实现 comet-forward-trace.sh
            └── Commit: def456abc
                 └── Task: 1.1 实现 comet-forward-trace.sh
  └── Scenario: 反向反查——test 到 spec
       └── Test: backward trace orphans warnings
            └── Commit: ghi789jkl
                 └── Task: 2.1 回溯反查
```

Run (不存在 ID):
```bash
bash src/scripts/comet-trace.sh --requirement-id nonexistent --comet-yaml "$TMPDIR/.comet.yaml"
echo "Exit code: $?"
```
Expected: stdout 输出 `Not found`，退出码 1

清理：`rm -rf "$TMPDIR"`

- [x] **Step 6: 实现反向查询（--commit）缩进树输出**

添加 `print_rev_tree()` 函数：

```bash
print_rev_tree() {
  local sorted
  sorted=$(printf '%s\n' "${MATCHED_LINES[@]}" | sort -t'|' -k5,5)

  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    local reqid scena testn testf tid tdesc commits_str
    reqid=$(echo "$entry" | sed 's/.*REQ://;s/|SCEN:.*//')
    scena=$(echo "$entry" | sed 's/.*SCEN://;s/|TEST_N:.*//')
    testn=$(echo "$entry" | sed 's/.*TEST_N://;s/|TEST_F:.*//')
    tid=$(echo "$entry" | sed 's/.*TASK_ID://;s/|TASK_DESC:.*//')
    tdesc=$(echo "$entry" | sed 's/.*TASK_DESC://;s/|COMMITS:.*//')
    commits_str=$(echo "$entry" | sed 's/.*COMMITS://')

    local -a commits_arr=()
    for word in $commits_str; do
      commits_arr+=("$word")
    done

    echo "Commit: $COMMIT_HASH"
    echo "  └── Task: $tid $tdesc"
    echo "       └── Requirement: $reqid"
    echo "            └── Scenario: $scena"
    echo "                 └── Test: $testn"
  done <<< "$sorted"
}

# --- 反向查询入口 ---
if [ -n "$COMMIT_HASH" ]; then
  # Validate commit hash via git
  if ! git rev-parse --verify "$COMMIT_HASH^{commit}" >/dev/null 2>&1; then
    echo "ERROR: Invalid commit hash: $COMMIT_HASH" >&2
    exit 1
  fi

  parse_tasks_yaml "$COMET_YAML" "rev" "$COMMIT_HASH"
  if [ ${#MATCHED_LINES[@]} -eq 0 ]; then
    echo "Not found"
    exit 1
  fi
  print_rev_tree
  exit 0
fi
```

- [x] **Step 7: 验证反向查询**

Run (使用 Step 5 的 TMPDIR/.comet.yaml 和当前仓库任意真实 commit):
```bash
CURRENT_HEAD=$(git rev-parse HEAD)
# 先将 CURRENT_HEAD 加入测试 yaml 的某个 task
bash src/scripts/comet-trace.sh --commit "$CURRENT_HEAD" --comet-yaml "$TMPDIR/.comet.yaml"
```
Expected: 如果 CURRENT_HEAD 不在 tasks 中，输出 `Not found` + 退出码 1。

Run (无效 hash):
```bash
bash src/scripts/comet-trace.sh --commit 0000000000000000000000000000000000000000 --comet-yaml "$TMPDIR/.comet.yaml"
```
Expected: stderr 输出 `ERROR: Invalid commit hash: 000...`，退出码 1

- [x] **Step 8: 提交**

```bash
git add src/scripts/comet-trace.sh
git commit -m "feat(three-d-traceability): add comet-trace.sh with forward and reverse query modes"
```

archived-with: 2026-06-28-three-d-traceability
---

### Task 2: .comet.yaml schema 扩展 + set-task 写入脚本

**Files:**
- Create: `src/scripts/comet-state-set-task.sh`
- Modify: 无（schema 扩展通过 set-task 脚本自然写入；白名单注册由 supercomet init 处理）

**Interfaces:**
- Consumes: 位置参数 `<change-name> <task-id>` + 选项 `--requirement-id` `--scenario` `--test-file` `--test-name`
- Produces: 更新 `openspec/changes/<change-name>/.comet.yaml` 的 tasks 段，写入/追加对应 task 条目的追溯字段
- Exit: 0 成功，1 .comet.yaml 不存在或 task-id 冲突

- [x] **Step 1: 创建 comet-state-set-task.sh 骨架**

```bash
#!/usr/bin/env bash
set -euo pipefail

# comet-state-set-task.sh — 将追溯字段写入 .comet.yaml 的 task 条目
# 调用方式（与 comet-state.sh whitelist 注册格式一致）：
#   comet-state-set-task.sh <change-name> <task-id> \
#     --requirement-id <id> --scenario <name> \
#     --test-file <path> --test-name <name> [--description <desc>]

usage() {
  cat <<'USAGE'
Usage: comet-state-set-task.sh <change-name> <task-id> [options]

Options:
  --requirement-id ID   Requirement ID
  --scenario NAME       Scenario name
  --test-file PATH      Test file path
  --test-name NAME      Test function name
  --description DESC    Task description (optional)
  --help                Show this help
USAGE
  exit 0
}

CHANGE_NAME=""
TASK_ID=""
REQUIREMENT_ID=""
SCENARIO=""
TEST_FILE=""
TEST_NAME=""
TASK_DESC=""

# Parse positional args first
if [[ $# -lt 2 ]]; then
  echo "ERROR: Missing <change-name> or <task-id>" >&2
  usage
fi

CHANGE_NAME="$1"
TASK_ID="$2"
shift 2

while [[ $# -gt 0 ]]; do
  case "$1" in
    --requirement-id) REQUIREMENT_ID="$2"; shift 2 ;;
    --scenario) SCENARIO="$2"; shift 2 ;;
    --test-file) TEST_FILE="$2"; shift 2 ;;
    --test-name) TEST_NAME="$2"; shift 2 ;;
    --description) TASK_DESC="$2"; shift 2 ;;
    --help) usage ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage ;;
  esac
done

# Validate required fields
if [ -z "$REQUIREMENT_ID" ] || [ -z "$SCENARIO" ] || [ -z "$TEST_FILE" ] || [ -z "$TEST_NAME" ]; then
  echo "ERROR: --requirement-id, --scenario, --test-file, --test-name are required" >&2
  exit 2
fi

COMET_YAML="openspec/changes/$CHANGE_NAME/.comet.yaml"
if [ ! -f "$COMET_YAML" ]; then
  echo "ERROR: $COMET_YAML not found" >&2
  exit 1
fi

# Capture current HEAD commit
CURRENT_COMMIT=$(git rev-parse HEAD 2>/dev/null || true)
if [ -z "$CURRENT_COMMIT" ]; then
  echo "ERROR: Cannot determine current commit hash" >&2
  exit 1
fi
```

- [x] **Step 2: 验证骨架运行**

Run:
```bash
bash src/scripts/comet-state-set-task.sh --help
```
Expected: 打印 USAGE 并退出 0

Run:
```bash
bash src/scripts/comet-state-set-task.sh
```
Expected: "ERROR: Missing <change-name> or <task-id>" 到 stderr，然后打印 USAGE

- [x] **Step 3: 实现 set-task 写入逻辑**

替换骨架末尾的变量声明之后，添加写入逻辑。

核心技术：如果 .comet.yaml 中不存在 `tasks:` 段，则追加整个 `tasks:` 段到文件末尾。如果已存在 `tasks:` 段且已有该 task-id，则追加 commit hash 到其 `commits:` 列表。如果 tasks 段存在但无该 task-id，则追加新 task 条目。

```bash
# --- 写入逻辑 ---
# 检查 tasks 段是否存在
TASKS_SECTION_EXISTS=false
if grep -q '^tasks:' "$COMET_YAML"; then
  TASKS_SECTION_EXISTS=true
fi

# 检查 task-id 是否已存在
TASK_EXISTS=false
if $TASKS_SECTION_EXISTS && grep -qE "id:[[:space:]]*\"?${TASK_ID}\"?" "$COMET_YAML"; then
  TASK_EXISTS=true
fi

if ! $TASKS_SECTION_EXISTS; then
  # 追加完整 tasks 段到文件末尾
  echo "" >> "$COMET_YAML"
  cat >> "$COMET_YAML" << YAML
tasks:
  - id: "${TASK_ID}"
    description: "${TASK_DESC}"
    requirement_id: "${REQUIREMENT_ID}"
    scenario: "${SCENARIO}"
    test_file: "${TEST_FILE}"
    test_name: "${TEST_NAME}"
    commits:
      - ${CURRENT_COMMIT}
YAML
  echo "Task $TASK_ID added to $COMET_YAML with commit $CURRENT_COMMIT" >&2

elif $TASK_EXISTS; then
  # Task 已存在：追加 commit hash 到 commits 列表
  # 找到该 task 的 commits 段末尾，插入新 commit
  tmpfile=$(mktemp)
  in_target_task=false
  in_commits=false
  inserted=false

  while IFS= read -r line || [ -n "$line" ]; do
    echo "$line" >> "$tmpfile"

    # Track current task via id field
    if [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]id\:.*${TASK_ID} ]]; then
      in_target_task=true
    elif $in_target_task && [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]id\: ]]; then
      # Next task starts — if we haven't inserted yet, insert before this line
      if ! $inserted; then
        sed -i '$ d' "$tmpfile"  # remove the line we just added
        echo "      - ${CURRENT_COMMIT}" >> "$tmpfile"
        echo "$line" >> "$tmpfile"
        inserted=true
        in_target_task=false
      else
        in_target_task=false
      fi
    fi

    # Detect commits array within target task
    if $in_target_task && [[ "$line" =~ ^[[:space:]]{4}commits\: ]]; then
      in_commits=true
      continue
    fi

    # End of commits array: insert new commit before this line
    if $in_target_task && $in_commits && ! $inserted && [[ "$line" =~ ^[[:space:]]{4}[a-z_] ]]; then
      sed -i '$ d' "$tmpfile"
      echo "      - ${CURRENT_COMMIT}" >> "$tmpfile"
      echo "$line" >> "$tmpfile"
      in_commits=false
      inserted=true
    fi
  done < "$COMET_YAML"

  # If reached end of file without inserting, append at end
  if ! $inserted; then
    echo "      - ${CURRENT_COMMIT}" >> "$tmpfile"
  fi

  mv "$tmpfile" "$COMET_YAML"
  echo "Commit $CURRENT_COMMIT appended to task $TASK_ID in $COMET_YAML" >&2

else
  # Tasks 段存在但该 task-id 不存在：在最后一个 - id: 条目后追加新条目
  tmpfile=$(mktemp)
  after_last_task=false
  last_task_line=""

  # 找到所有 "- id:" 行的最后一行编号
  last_id_line=$(grep -nE '^[[:space:]]{2}-[[:space:]]id\:' "$COMET_YAML" | tail -1 | cut -d: -f1)

  if [ -z "$last_id_line" ]; then
    # 无 task 条目：在 tasks: 行后追加
    tasks_line=$(grep -n '^tasks:' "$COMET_YAML" | cut -d: -f1)
    head -n "$tasks_line" "$COMET_YAML" > "$tmpfile"
    cat >> "$tmpfile" << YAML
  - id: "${TASK_ID}"
    description: "${TASK_DESC}"
    requirement_id: "${REQUIREMENT_ID}"
    scenario: "${SCENARIO}"
    test_file: "${TEST_FILE}"
    test_name: "${TEST_NAME}"
    commits:
      - ${CURRENT_COMMIT}
YAML
    tail -n +$((tasks_line + 1)) "$COMET_YAML" >> "$tmpfile"
  else
    # 从文件开头到最后一个 task 条目的下一行，然后插入
    # 实际策略：找到最后一个 task 块后的第一个非 task 缩进行，在其前插入
    ln=0
    while IFS= read -r line || [ -n "$line" ]; do
      ln=$((ln + 1))
      if [ "$ln" -le "$last_id_line" ]; then
        echo "$line" >> "$tmpfile"
        continue
      fi
      # 在最后一个 task 后找到第一个非缩进行或下一个 task 前插入
      if ! $after_last_task; then
        if [[ "$line" =~ ^[a-z_]+\: || "$line" =~ ^[[:space:]]{2}-[[:space:]]id\: ]]; then
          after_last_task=true
          cat >> "$tmpfile" << YAML
  - id: "${TASK_ID}"
    description: "${TASK_DESC}"
    requirement_id: "${REQUIREMENT_ID}"
    scenario: "${SCENARIO}"
    test_file: "${TEST_FILE}"
    test_name: "${TEST_NAME}"
    commits:
      - ${CURRENT_COMMIT}
YAML
          echo "$line" >> "$tmpfile"
          continue
        fi
      fi
      echo "$line" >> "$tmpfile"
    done < "$COMET_YAML"
  fi

  mv "$tmpfile" "$COMET_YAML"
  echo "Task $TASK_ID added to $COMET_YAML with commit $CURRENT_COMMIT" >&2
fi
```

- [x] **Step 4: 验证 set-task 写入——tasks 段不存在时追加**

Run:
```bash
TMPDIR=$(mktemp -d)
cp openspec/changes/three-d-traceability/.comet.yaml "$TMPDIR/.comet.yaml"

bash src/scripts/comet-state-set-task.sh \
  three-d-traceability "1.1" \
  --requirement-id "three-d-traceability" \
  --scenario "正向查询——按 Requirement ID" \
  --test-file "test/shell/comet-trace.bats" \
  --test-name "forward trace requirement id" \
  --description "实现 comet-trace.sh 正向查询"

cat "$TMPDIR/.comet.yaml"
```
Expected: 文件末尾出现 `tasks:` 段，含 id、description、requirement_id、scenario、test_file、test_name、commits 字段，commits 含当前 HEAD hash。

- [x] **Step 5: 验证 set-task 追加 commit——task 已存在时**

Run:
```bash
# 基于上一测试的 tmp dir，再次调用 set-task
bash src/scripts/comet-state-set-task.sh \
  three-d-traceability "1.1" \
  --requirement-id "three-d-traceability" \
  --scenario "正向查询——按 Requirement ID" \
  --test-file "test/shell/comet-trace.bats" \
  --test-name "forward trace requirement id"

# 检查 commits 列表含 2 个 hash
grep -c '  - ' "$TMPDIR/.comet.yaml"
```
Expected: commits 下列出 2 个 commit hash（多于初始 1 个）

清理：`rm -rf "$TMPDIR"`

- [x] **Step 6: 提交**

```bash
git add src/scripts/comet-state-set-task.sh
git commit -m "feat(three-d-traceability): add comet-state-set-task.sh for traceability field writes"
```

archived-with: 2026-06-28-three-d-traceability
---

### Task 3: comet-guard.sh 闸门集成——verify→archive 时检查 commits 非空

**Files:**
- Create: `src/scripts/comet-guard-check-commits.sh`

**Interfaces:**
- Consumes: `<change-name>` 位置参数
- Produces: 退出码 0 = 所有 task 的 commits 非空；1 = 存在空 commits 的 task（输出错误信息到 stderr）
- Exit: 0 PASS, 1 BLOCKED

- [x] **Step 1: 创建 comet-guard-check-commits.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

# comet-guard-check-commits.sh — verify→archive gate: 检查所有 task 的 commits 非空
# 被 comet-guard.sh 在 verify→archive 转移时调用
# 调用方式：comet-guard-check-commits.sh <change-name>

usage() {
  cat <<'USAGE'
Usage: comet-guard-check-commits.sh <change-name>

Checks that every completed task in .comet.yaml has a non-empty commits list.
Exit 0 if all pass; exit 1 if any task has empty commits (gate BLOCKED).
USAGE
  exit 0
}

if [[ $# -lt 1 ]]; then
  echo "ERROR: Missing <change-name>" >&2
  usage
fi

CHANGE_NAME="$1"
COMET_YAML="openspec/changes/$CHANGE_NAME/.comet.yaml"

if [ ! -f "$COMET_YAML" ]; then
  echo "GATE: SKIP — $COMET_YAML not found (no tasks to check)" >&2
  exit 0
fi

# --- 解析 tasks 段，检查每个 task 的 commits ---
in_tasks=false
in_task=false
in_commits=false
task_id=""
has_commits=false
failed_tasks=""
total=0
failed=0

while IFS= read -r line || [ -n "$line" ]; do
  if [[ "$line" =~ ^tasks\: ]]; then
    in_tasks=true
    continue
  fi

  $in_tasks || continue

  if [[ "$line" =~ ^[a-z_]+\: ]]; then
    in_tasks=false
    continue
  fi

  # Start of new task
  if [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]id\: ]]; then
    # Evaluate previous task
    if $in_task; then
      total=$((total + 1))
      if ! $has_commits; then
        failed=$((failed + 1))
        failed_tasks="$failed_tasks  - $task_id"$'\n'
      fi
    fi
    task_id=$(echo "$line" | sed 's/.*id:[[:space:]]*"*//;s/"*$//')
    has_commits=false
    in_task=true
    in_commits=false
    continue
  fi

  $in_task || continue

  if [[ "$line" =~ ^[[:space:]]{4}commits\: ]]; then
    in_commits=true
    continue
  fi

  if $in_commits && [[ "$line" =~ ^[[:space:]]{6}-[[:space:]] ]]; then
    has_commits=true
  fi

  if $in_commits && [[ "$line" =~ ^[[:space:]]{4}[a-z_] ]]; then
    in_commits=false
  fi
done < "$COMET_YAML"

# Evaluate last task
if $in_task; then
  total=$((total + 1))
  if ! $has_commits; then
    failed=$((failed + 1))
    failed_tasks="$failed_tasks  - $task_id"$'\n'
  fi
fi

if [ "$total" -eq 0 ]; then
  echo "GATE: PASS — no tasks found in $COMET_YAML (nothing to check)" >&2
  exit 0
fi

if [ "$failed" -gt 0 ]; then
  echo "GATE: BLOCKED — $failed/$total task(s) have empty commits:" >&2
  echo -n "$failed_tasks" >&2
  exit 1
fi

echo "GATE: PASS — all $total tasks have commits" >&2
exit 0
```

- [x] **Step 2: 验证闸门——无 tasks 段时 PASS**

Run:
```bash
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/openspec/changes/test-change"
cat > "$TMPDIR/openspec/changes/test-change/.comet.yaml" << 'YAML'
workflow: full
phase: verify
YAML

bash src/scripts/comet-guard-check-commits.sh test-change 2>&1
echo "Exit: $?"
```
工作目录为 `$TMPDIR`：
```bash
(cd "$TMPDIR" && bash "$OLDPWD/src/scripts/comet-guard-check-commits.sh" test-change)
echo "Exit: $?"
```
Expected: stderr 输出 `GATE: PASS — no tasks found`，退出码 0

- [x] **Step 3: 验证闸门——所有 task 都有 commits 时 PASS**

在上一 TMPDIR 基础上，追加 tasks 段：
```bash
cat >> "$TMPDIR/openspec/changes/test-change/.comet.yaml" << 'YAML'
tasks:
  - id: "1.1"
    requirement_id: "test-req"
    scenario: "test scenario"
    test_file: "test/test.bats"
    test_name: "my test"
    commits:
      - abc123
  - id: "2.1"
    requirement_id: "test-req-2"
    scenario: "test scenario 2"
    test_file: "test/test2.bats"
    test_name: "my test 2"
    commits:
      - def456
YAML

(cd "$TMPDIR" && bash "$OLDPWD/src/scripts/comet-guard-check-commits.sh" test-change)
echo "Exit: $?"
```
Expected: stderr 输出 `GATE: PASS — all 2 tasks have commits`，退出码 0

- [x] **Step 4: 验证闸门——存在空 commits 时 BLOCKED**

追加一个 commits 为空的 task：
```bash
cat >> "$TMPDIR/openspec/changes/test-change/.comet.yaml" << 'YAML'
  - id: "3.1"
    requirement_id: "test-req-3"
    scenario: "bad scenario"
    test_file: "test/test3.bats"
    test_name: "bad test"
    commits:
YAML

(cd "$TMPDIR" && bash "$OLDPWD/src/scripts/comet-guard-check-commits.sh" test-change)
echo "Exit: $?"
```
Expected: stderr 输出 `GATE: BLOCKED — 1/3 task(s) have empty commits:` 并列出 `- 3.1`，退出码 1

清理：`rm -rf "$TMPDIR"`

- [x] **Step 5: 提交**

```bash
git add src/scripts/comet-guard-check-commits.sh
git commit -m "feat(three-d-traceability): add comet-guard-check-commits.sh for verify→archive gate"
```

archived-with: 2026-06-28-three-d-traceability
---

### Task 4: BATS 测试——5 场景

**Files:**
- Create: `test/shell/comet-trace.bats`

**Interfaces:**
- Consumes: `src/scripts/comet-trace.sh`, `src/scripts/comet-guard-check-commits.sh`
- Produces: 5 个 BATS @test 用例，覆盖正向/反向/无效输入/闸门

- [x] **Step 1: 创建 BATS 测试文件骨架和 setup/teardown**

```bash
#!/usr/bin/env bats

# three-d-traceability BATS tests
# Covers: forward query, reverse query, invalid requirement-id,
#         invalid commit hash, empty commits gate

setup() {
  export TMP_DIR="$(mktemp -d)"
  export CHANGE_DIR="$TMP_DIR/openspec/changes/test-change"
  export TRACE_SCRIPT="$(pwd)/src/scripts/comet-trace.sh"
  export GUARD_SCRIPT="$(pwd)/src/scripts/comet-guard-check-commits.sh"
  mkdir -p "$CHANGE_DIR"
  export COMET_YAML="$CHANGE_DIR/.comet.yaml"
}

teardown() {
  rm -rf "$TMP_DIR"
}

# Helper: create a .comet.yaml with predefined tasks
write_test_yaml() {
  cat > "$COMET_YAML" << 'YAML'
workflow: full
phase: build
tasks:
  - id: "1.1"
    description: "实现正向查询"
    requirement_id: "bidirectional-verify"
    scenario: "正向反查——spec 到 test"
    test_file: "test/shell/bidirectional-verify.bats"
    test_name: "forward trace 100pc coverage passes gate"
    commits:
      - abc123def
  - id: "1.2"
    description: "实现反向查询"
    requirement_id: "bidirectional-verify"
    scenario: "反向反查——test 到 spec"
    test_file: "test/shell/backward-trace.bats"
    test_name: "backward trace orphan warnings"
    commits:
      - def456abc
  - id: "2.1"
    description: "BATS 测试"
    requirement_id: "three-d-traceability"
    scenario: "正向查询——按 Requirement ID"
    test_file: "test/shell/comet-trace.bats"
    test_name: "forward trace requirement id"
    commits:
      - ghi789jkl
YAML
}
```

- [x] **Step 2: 编写场景 1——正向查询（按 Requirement ID）**

```bash
@test "forward trace by requirement id returns complete chain" {
  write_test_yaml

  run bash "$TRACE_SCRIPT" \
    --requirement-id "bidirectional-verify" \
    --comet-yaml "$COMET_YAML"

  [ "$status" -eq 0 ]

  # 检查输出含 Requirement header
  echo "$output" | grep -q "Requirement: bidirectional-verify"

  # 检查 Scenario 缩进
  echo "$output" | grep -q "正向反查——spec 到 test"

  # 检查 Test 缩进
  echo "$output" | grep -q "forward trace 100pc coverage passes gate"

  # 检查 Commit 缩进（含 abc123def 和 def456abc）
  echo "$output" | grep -q "Commit: abc123def"
  echo "$output" | grep -q "Commit: def456abc"

  # 检查 Task 行（两个 task）
  echo "$output" | grep -q "Task: 1.1 实现正向查询"
  echo "$output" | grep -q "Task: 1.2 实现反向查询"
}
```

- [x] **Step 3: 编写场景 2——反向查询（按 commit hash）**

```bash
@test "reverse trace by commit hash returns complete chain" {
  write_test_yaml

  run bash "$TRACE_SCRIPT" \
    --commit "abc123def" \
    --comet-yaml "$COMET_YAML"

  [ "$status" -eq 0 ]

  # 检查输出含 Commit header
  echo "$output" | grep -q "Commit: abc123def"

  # 检查 Task
  echo "$output" | grep -q "Task: 1.1 实现正向查询"

  # 检查 Requirement
  echo "$output" | grep -q "Requirement: bidirectional-verify"

  # 检查 Scenario
  echo "$output" | grep -q "Scenario: 正向反查——spec 到 test"

  # 检查 Test
  echo "$output" | grep -q "Test: forward trace 100pc coverage passes gate"
}
```

- [x] **Step 4: 编写场景 3——无效 Requirement ID**

```bash
@test "invalid requirement id returns Not found and exits non-zero" {
  write_test_yaml

  run bash "$TRACE_SCRIPT" \
    --requirement-id "nonexistent-req" \
    --comet-yaml "$COMET_YAML"

  [ "$status" -eq 1 ]
  echo "$output" | grep -q "Not found"
}
```

- [x] **Step 5: 编写场景 4——无效 commit hash**

需要 init git repo 以便 `git rev-parse --verify` 工作：
```bash
@test "invalid commit hash returns error and exits non-zero" {
  write_test_yaml

  # comet-trace.sh 用 realpath 定位脚本路径，需要确保 git 命令工作在仓库上下文中
  # 由于脚本调用 git rev-parse --verify，我们需要在真实的 git 仓库内运行
  run bash "$TRACE_SCRIPT" \
    --commit "0000000000000000000000000000000000000000" \
    --comet-yaml "$COMET_YAML"

  [ "$status" -eq 1 ]
  echo "$output" | grep -qE "(ERROR|Not found)"
}
```

- [x] **Step 6: 编写场景 5——空 commits 闸门**

`comet-guard-check-commits.sh` 使用相对路径 `openspec/changes/<name>/.comet.yaml`，需在脚本所在目录运行以正确定位。BATS 测试通过 `cd "$TMP_DIR"` 后调用：

```bash
@test "empty commits gate blocks on verify-to-archive transition" {
  cat > "$COMET_YAML" << 'YAML'
workflow: full
phase: verify
tasks:
  - id: "1.1"
    description: "有 commits 的 task"
    requirement_id: "test-req"
    scenario: "test scenario"
    test_file: "test/test.bats"
    test_name: "my test"
    commits:
      - abc123
  - id: "2.1"
    description: "空 commits 的 task"
    requirement_id: "test-req-2"
    scenario: "test scenario 2"
    test_file: "test/test2.bats"
    test_name: "my test 2"
    commits:
YAML

  run bash -c "cd '$TMP_DIR' && bash '$GUARD_SCRIPT' test-change"

  [ "$status" -eq 1 ]
  echo "$output" | grep -q "BLOCKED"
  echo "$output" | grep -q "2.1"
}
```

- [x] **Step 7: 运行全部 BATS 测试验证**

Run:
```bash
bats test/shell/comet-trace.bats
```
Expected: 5 个测试全部 PASS：
```
 ✓ forward trace by requirement id returns complete chain
 ✓ reverse trace by commit hash returns complete chain
 ✓ invalid requirement id returns Not found and exits non-zero
 ✓ invalid commit hash returns error and exits non-zero
 ✓ empty commits gate blocks on verify-to-archive transition

5 tests, 0 failures
```

如果 `bats` 未安装：
```bash
npm install -g bats 2>/dev/null || apt-get install -y bats 2>/dev/null || true
```

- [x] **Step 8: 提交**

```bash
git add test/shell/comet-trace.bats
git commit -m "test(three-d-traceability): add BATS tests for forward/reverse trace and gate check"
```

archived-with: 2026-06-28-three-d-traceability
---

### 自检

**1. Spec coverage:**
- Requirement "Task 到 commit 的映射" → Task 2（set-task 写入）+ Task 3（commits 非空闸门）
- Requirement "双向追溯查询" → Task 1（comet-trace.sh 正向/反向 + 无效输入错误处理）
- Scenario "set-task 写入映射" → Task 2 Step 4-5
- Scenario "commits 字段非空闸门" → Task 3 Step 3-4
- Scenario "正向查询——按 Requirement ID" → Task 1 Step 5
- Scenario "反向查询——按 commit hash" → Task 1 Step 7
- Scenario "无效输入的错误处理" → Task 1 Step 5 (not found) + Step 7 (invalid hash)
- 全局约束 "不修改 Comet 核心 Shell 脚本" → 所有脚本均为独立新建文件，不修改上游
- 全局约束 "仅消费上游产出文件" → comet-trace.sh 只读 .comet.yaml（上游产出），不依赖上游内部实现

**2. Placeholder scan:** 无 TBD/TODO/fill in details/implement later，所有步骤含完整代码和精确命令。

**3. Type consistency:**
- `parse_tasks_yaml` 在 Task 1 Step 3 定义，Step 4/6 调用，签名一致
- `MATCHED_LINES` 数组格式 `REQ:...|SCEN:...|TEST_N:...|TEST_F:...|TASK_ID:...|TASK_DESC:...|COMMITS:...` 在 Task 1 Step 3 定义，Step 4 的 `print_fwd_tree` 和 Step 6 的 `print_rev_tree` 一致解析
- comet-guard-check-commits.sh 的 `tasks:` 解析格式与 comet-trace.sh 的 `parse_tasks_yaml` 解析格式一致
- BATS 测试中 `COMET_YAML`、`TRACE_SCRIPT`、`GUARD_SCRIPT` 变量名与 setup 一致
