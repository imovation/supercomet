---
change: bidirectional-verify
design-doc: docs/superpowers/specs/2026-06-28-bidirectional-verify-design.md
base-ref: d2c1bd5ce13a02ba1fc9fbe655aa3bb7304625ca
---

# bidirectional-verify Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add spec↔test bidirectional traceability as a `/comet-verify` enhancement, producing `traceability.md` with a GATE line that comet-guard.sh can parse.

**Architecture:** Two shell scripts — `comet-forward-trace.sh` (orchestrator, extracts Scenario names from spec, matches against test files, assembles 5-section report, sets GATE verdict) and `comet-backward-trace.sh` (helper, extracts test function names, reports orphans). A SKILL.md defines the protocol. The `supercomet init` CLI injects these into `comet/scripts/` and `comet/reference/` without modifying any Comet core file.

**Tech Stack:** Pure Shell (bash 4+, grep, sed, find, POSIX). BATS for testing.

## Global Constraints

- Zero intrusion: No modifications to Comet core Shell scripts or `.comet.yaml`
- bash >= 4.0 required (uses `declare -a`, `set -euo pipefail`)
- Input priority: v6.0 mode (task-brief + review-package under `.comet/handoff/`) first, full grep fallback
- On fallback, output WARN: "使用全量扫描，未利用 v6.0 优化"
- Exit code 0 = PASS, 1 = BLOCKED (forward); exit code always 0 (backward)
- traceability.md must end with `GATE: PASS` or `GATE: BLOCKED` on its own line
- BATS tests cover: 100% coverage (PASS), partial coverage (BLOCKED), orphan tests (WARN), fallback mode

---

### Task 1: 正向反查脚本 comet-forward-trace.sh（场景提取 + 测试匹配）

**Files:**
- Create: `src/scripts/comet-forward-trace.sh`
- Test: manual run with temp spec/test dirs

**Interfaces:**
- Consumes: `--change-name NAME`, `--spec-dir DIR`, `--test-dir DIR`, `--output-dir DIR`
- Produces: coverage matrix data (stdout lines), coverage percentage, list of missing scenarios
- Exit: 0 if all scenarios matched, 1 otherwise

- [ ] **Step 1: Create script skeleton with argument parsing and usage**

```bash
#!/usr/bin/env bash
set -euo pipefail

# comet-forward-trace.sh — Forward trace: Spec Scenario → Test coverage
# Part of supercomet bidirectional-verify enhancement

usage() {
  cat <<'USAGE'
Usage: comet-forward-trace.sh [options]

Options:
  --change-name NAME  Change name (used for handoff path resolution)
  --change-dir DIR    Change directory (default: openspec/changes/<name>)
  --spec-dir DIR      Spec directory (default: <change-dir>/specs)
  --test-dir DIR      Test directory (default: test)
  --output-dir DIR    Output directory (default: .)
  --help              Show this help
USAGE
  exit 0
}

CHANGE_NAME=""
CHANGE_DIR=""
SPEC_DIR=""
TEST_DIR=""
OUTPUT_DIR="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --change-name) CHANGE_NAME="$2"; shift 2 ;;
    --change-dir) CHANGE_DIR="$2"; shift 2 ;;
    --spec-dir) SPEC_DIR="$2"; shift 2 ;;
    --test-dir) TEST_DIR="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --help) usage ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage ;;
  esac
done

if [ -z "$CHANGE_DIR" ] && [ -n "$CHANGE_NAME" ]; then
  CHANGE_DIR="openspec/changes/$CHANGE_NAME"
fi
if [ -z "$SPEC_DIR" ] && [ -n "$CHANGE_DIR" ]; then
  SPEC_DIR="$CHANGE_DIR/specs"
fi
SPEC_DIR="${SPEC_DIR:-openspec/specs}"
TEST_DIR="${TEST_DIR:-test}"

echo "Forward trace: spec=$SPEC_DIR test=$TEST_DIR output=$OUTPUT_DIR" >&2
exit 0
```

- [ ] **Step 2: Verify script runs and usage works**

Run:
```bash
bash src/scripts/comet-forward-trace.sh --help
```
Expected: Prints usage and exits 0

Run:
```bash
bash src/scripts/comet-forward-trace.sh --spec-dir /tmp --test-dir /tmp --output-dir /tmp
```
Expected: Prints "Forward trace: ..." line and exits 0

- [ ] **Step 3: Implement input source priority (v6.0 vs fallback) and scenario extraction**

Replace the `echo "Forward trace..."` line and `exit 0` with:

```bash
# --- Input source priority ---
V6_MODE=false
MODE_WARN=""
if [ -n "$CHANGE_DIR" ]; then
  HANDOFF_DIR="$CHANGE_DIR/.comet/handoff"
  TASK_BRIEF="$HANDOFF_DIR/task-brief"
  REVIEW_PACKAGE="$HANDOFF_DIR/review-package"
  if [ -f "$TASK_BRIEF" ] && [ -f "$REVIEW_PACKAGE" ]; then
    V6_MODE=true
  fi
fi
if [ "$V6_MODE" = false ]; then
  MODE_WARN="WARN: 使用全量扫描，未利用 v6.0 优化"
fi

# --- Extract all #### Scenario: names ---
declare -a ALL_SCENARIOS=()

collect_scenarios() {
  local dir="$1"
  while IFS= read -r -d '' spec_file; do
    while IFS= read -r line; do
      sname=""
      sname=$(echo "$line" | sed -n 's/^#### Scenario:[[:space:]]*//p')
      if [ -n "$sname" ]; then
        ALL_SCENARIOS+=("$sname")
      fi
    done < "$spec_file"
  done < <(find "$dir" -name '*.md' -type f -print0 2>/dev/null || true)
}

# Try task-brief first (v6.0), then spec dirs
if [ "$V6_MODE" = true ] && [ -s "$TASK_BRIEF" ]; then
  collect_scenarios "$(dirname "$TASK_BRIEF")"
fi
if [ ${#ALL_SCENARIOS[@]} -eq 0 ]; then
  collect_scenarios "$SPEC_DIR"
fi

TOTAL=${#ALL_SCENARIOS[@]}
echo "Found $TOTAL scenarios" >&2
for s in "${ALL_SCENARIOS[@]}"; do
  echo "  Scenario: $s" >&2
done
```

- [ ] **Step 4: Implement test file discovery and scenario-to-test matching**

Append after the scenario listing:

```bash
# --- Determine test targets ---
declare -a TEST_TARGETS=()

if [ "$V6_MODE" = true ] && [ -f "$REVIEW_PACKAGE" ]; then
  while IFS= read -r line; do
    tfile=""
    tfile=$(echo "$line" | grep -oE 'test/[^[:space:]]+' || true)
    if [ -n "$tfile" ] && [ -f "$tfile" ]; then
      TEST_TARGETS+=("$tfile")
    fi
  done < "$REVIEW_PACKAGE"
fi

if [ ${#TEST_TARGETS[@]} -eq 0 ] && [ -d "$TEST_DIR" ]; then
  while IFS= read -r -d '' f; do
    TEST_TARGETS+=("$f")
  done < <(find "$TEST_DIR" -type f -print0 2>/dev/null || true)
fi

echo "Test targets: ${#TEST_TARGETS[@]}" >&2

# --- Match scenarios to tests ---
COVERED=0
COVERAGE_ROWS=""

for scenario in "${ALL_SCENARIOS[@]}"; do
  esc=$(echo "$scenario" | sed 's/[][\.*^$(){}?+|]/\\&/g' | sed 's/[[:space:]]\{1,\}/.*/g')
  found_file=""
  for tf in "${TEST_TARGETS[@]}"; do
    if grep -qE "$esc" "$tf" 2>/dev/null; then
      found_file="$tf"
      break
    fi
  done
  if [ -n "$found_file" ]; then
    COVERED=$((COVERED + 1))
    COVERAGE_ROWS="$COVERAGE_ROWS| | $scenario | $found_file | ✅ |"$'\n'
  else
    COVERAGE_ROWS="$COVERAGE_ROWS| | $scenario | NOT FOUND | ❌ |"$'\n'
  fi
done

COVERAGE=$(( TOTAL > 0 ? (COVERED * 100 / TOTAL) : 0 ))
echo "Coverage: $COVERED/$TOTAL = ${COVERAGE}%" >&2

# --- Determine gate ---
if [ "$TOTAL" -eq 0 ]; then
  GATE="BLOCKED"
  GATE_REASON="No scenarios found in spec"
elif [ "$COVERAGE" -ge 100 ]; then
  GATE="PASS"
  GATE_REASON=""
else
  GATE="BLOCKED"
  MISSING=$((TOTAL - COVERED))
  GATE_REASON="{$MISSING} missing scenarios"
fi

echo "Gate: $GATE" >&2
if [ "$GATE" = "PASS" ]; then
  exit 0
else
  exit 1
fi
```

- [ ] **Step 5: Manually test with temp spec and test files**

Run:
```bash
TMP=$(mktemp -d)
mkdir -p "$TMP/specs" "$TMP/test/shell"

cat > "$TMP/specs/spec.md" << 'EOF'
#### Scenario: 用户登录
#### Scenario: 用户退出
#### Scenario: 密码重置
EOF

cat > "$TMP/test/shell/test-auth.bats" << 'EOF'
@test "用户登录" { true; }
@test "用户退出" { true; }
EOF

bash src/scripts/comet-forward-trace.sh --spec-dir "$TMP/specs" --test-dir "$TMP/test" --output-dir "$TMP"
echo "Exit code: $?"

rm -rf "$TMP"
```
Expected: coverage 2/3 = 66%, exit 1

- [ ] **Step 6: Second manual test — full coverage**

Run:
```bash
TMP=$(mktemp -d)
mkdir -p "$TMP/specs" "$TMP/test/shell"

cat > "$TMP/specs/spec.md" << 'EOF'
#### Scenario: 用户登录
#### Scenario: 用户退出
EOF

cat > "$TMP/test/shell/test-auth.bats" << 'EOF'
@test "用户登录" { true; }
@test "用户退出" { true; }
EOF

bash src/scripts/comet-forward-trace.sh --spec-dir "$TMP/specs" --test-dir "$TMP/test" --output-dir "$TMP"
echo "Exit code: $?"

rm -rf "$TMP"
```
Expected: coverage 2/2 = 100%, exit 0

- [ ] **Step 7: Commit**

```bash
git add src/scripts/comet-forward-trace.sh
git commit -m "feat(bidirectional-verify): add forward trace script with scenario extraction and test matching"
```

---

### Task 2: 反向反查脚本 comet-backward-trace.sh（孤儿测试检测）

**Files:**
- Create: `src/scripts/comet-backward-trace.sh`

**Interfaces:**
- Consumes: `--spec-dir DIR`, `--test-dir DIR`
- Produces: orphan test rows to stdout (pipe-delimited `| tname (file) | (无匹配) | ⚠️ WARN |`)
- Exit: always 0

- [ ] **Step 1: Create backward trace script**

```bash
#!/usr/bin/env bash
set -euo pipefail

# comet-backward-trace.sh — Backward trace: Test → Spec Scenario
# Outputs orphan test rows for inclusion in traceability.md

usage() {
  echo "Usage: $(basename "$0") --spec-dir <dir> --test-dir <dir>"
  exit 0
}

SPEC_DIR=""
TEST_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec-dir) SPEC_DIR="$2"; shift 2 ;;
    --test-dir) TEST_DIR="$2"; shift 2 ;;
    --help) usage ;;
    *) echo "Unknown: $1" >&2; shift ;;
  esac
done

if [ -z "$SPEC_DIR" ] || [ -z "$TEST_DIR" ]; then
  usage
fi

# --- Collect all scenario names from spec ---
declare -a SCENARIO_NAMES=()
while IFS= read -r -d '' spec_file; do
  while IFS= read -r line; do
    sname=$(echo "$line" | sed -n 's/^#### Scenario:[[:space:]]*//p')
    [ -n "$sname" ] && SCENARIO_NAMES+=("$sname")
  done < "$spec_file"
done < <(find "$SPEC_DIR" -name '*.md' -type f -print0 2>/dev/null || true)

# Build grep patterns from scenario names
declare -a SCENARIO_PATTERNS=()
for s in "${SCENARIO_NAMES[@]}"; do
  esc=$(echo "$s" | sed 's/[][\.*^$(){}?+|]/\\&/g' | sed 's/[[:space:]]\{1,\}/.*/g')
  SCENARIO_PATTERNS+=("$esc")
done

# --- Collect test function names ---
declare -a TEST_ENTRIES=()

collect_test_names() {
  local file="$1"
  while IFS= read -r line; do
    tname=""
    # BATS @test "name"
    tname=$(echo "$line" | sed -n 's/^@test[[:space:]]*"\(.*\)".*/\1/p')
    if [ -n "$tname" ]; then
      TEST_ENTRIES+=("${tname}|${file}")
      continue
    fi
    # test_function()
    tname=$(echo "$line" | sed -n 's/^\(test_[a-zA-Z0-9_]*\)().*/\1/p')
    if [ -n "$tname" ]; then
      TEST_ENTRIES+=("${tname}|${file}")
      continue
    fi
    # Jest/Python it("name")
    tname=$(echo "$line" | sed -n 's/^[[:space:]]*it\(.*\)("\(.*\)").*/\2/p')
    if [ -n "$tname" ]; then
      TEST_ENTRIES+=("${tname}|${file}")
      continue
    fi
  done < "$file"
}

while IFS= read -r -d '' tf; do
  collect_test_names "$tf"
done < <(find "$TEST_DIR" -type f -print0 2>/dev/null || true)

# --- Match each test against scenario patterns ---
ORPHAN_COUNT=0
for entry in "${TEST_ENTRIES[@]}"; do
  tname="${entry%%|*}"
  tfile="${entry#*|}"
  matched=false
  for pat in "${SCENARIO_PATTERNS[@]}"; do
    if echo "$tname" | grep -qE "$pat" 2>/dev/null; then
      matched=true
      break
    fi
  done
  if [ "$matched" = false ]; then
    ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
    echo "| $tname (${tfile}) | (无匹配) | ⚠️ WARN |"
  fi
done

exit 0
```

- [ ] **Step 2: Manual test — backward trace with orphan**

Run:
```bash
TMP=$(mktemp -d)
mkdir -p "$TMP/specs" "$TMP/test/shell"

cat > "$TMP/specs/spec.md" << 'EOF'
#### Scenario: 用户登录
EOF

cat > "$TMP/test/shell/test-orphan.bats" << 'EOF'
@test "用户登录" { true; }
@test "未定义功能" { true; }
EOF

bash src/scripts/comet-backward-trace.sh --spec-dir "$TMP/specs" --test-dir "$TMP/test"
echo "Exit code: $?"

rm -rf "$TMP"
```
Expected: One orphan row, exit 0

- [ ] **Step 3: Commit**

```bash
git add src/scripts/comet-backward-trace.sh
git commit -m "feat(bidirectional-verify): add backward trace script for orphan test detection"
```

---

### Task 3: traceability.md 组装（将正向 + 反向输出合成为 5 段式报告）

**Files:**
- Modify: `src/scripts/comet-forward-trace.sh` (add backward-script delegation and report assembly)

**Interfaces:**
- Consumes: output of comet-backward-trace.sh (orphan rows)
- Produces: `traceability.md` with 5 sections + `GATE: PASS/BLOCKED` final line

- [ ] **Step 1: Add backward-trace delegation and report assembly to comet-forward-trace.sh**

In `comet-forward-trace.sh`, after the gate determination and before the final `exit`, replace the current `echo "Gate: $GATE"` block with the full traceability.md writer:

```bash
# --- Run backward trace ---
ORPHAN_ROWS=""
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKWARD_SCRIPT="$SCRIPT_DIR/comet-backward-trace.sh"
if [ -f "$BACKWARD_SCRIPT" ]; then
  ORPHAN_ROWS=$(bash "$BACKWARD_SCRIPT" --spec-dir "$SPEC_DIR" --test-dir "$TEST_DIR" 2>/dev/null || true)
fi

# --- Determine gate ---
if [ "$TOTAL" -eq 0 ]; then
  GATE="BLOCKED"
  GATE_REASON="No scenarios found in spec"
elif [ "$COVERAGE" -ge 100 ]; then
  GATE="PASS"
  GATE_REASON=""
else
  GATE="BLOCKED"
  MISSING=$((TOTAL - COVERED))
  GATE_REASON="{$MISSING} missing scenarios"
fi

# --- Write traceability.md ---
OUTPUT_FILE="$OUTPUT_DIR/traceability.md"

{
  echo "# Spec ↔ Test Traceability Report"
  echo ""
  echo "## 1. Coverage Matrix (正向：Spec → Test)"
  echo "| Requirement | Scenario | Test Found | Status |"
  echo -n "$COVERAGE_ROWS"
  echo "Coverage: $COVERED/$TOTAL = ${COVERAGE}%"
  echo ""
  echo "## 2. Orphan Tests (反向：Test → Spec)"
  if [ -n "$ORPHAN_ROWS" ]; then
    echo "| Test Function | Matched Scenario | Status |"
    echo -n "$ORPHAN_ROWS"
  else
    echo "| (无孤儿测试) | - | ✅ |"
  fi
  echo ""
  echo "## 3. Edge Case Analysis"
  echo "| Scenario | GIVEN Condition | Code Branch? |"
  for scenario in "${ALL_SCENARIOS[@]}"; do
    echo "| $scenario | (见 spec 描述) | (需人工补充) |"
  done
  echo ""
  echo "## 4. Gate Verdict"
  if [ "$GATE" = "PASS" ]; then
    echo "Spec Coverage: ✅ PASS"
  else
    echo "Spec Coverage: ❌ BLOCKED"
  fi
  if [ -z "$ORPHAN_ROWS" ]; then
    echo "Test Orphans: ✅ CLEAN"
  else
    orphan_count=$(echo "$ORPHAN_ROWS" | grep -c "WARN" || true)
    echo "Test Orphans: ⚠️ $orphan_count orphan(s)"
  fi
  echo ""
  echo "## 5. Next Action"
  if [ "$GATE" = "PASS" ]; then
    echo "✅ → Proceed to archive"
  else
    echo "❌ → Blocking: $GATE_REASON. Return to implementer."
  fi
  echo ""
  if [ -n "$MODE_WARN" ]; then
    echo "$MODE_WARN"
    echo ""
  fi
  echo "GATE: $GATE"
} > "$OUTPUT_FILE"

echo "traceability.md written with Gate: $GATE" >&2
if [ "$GATE" = "PASS" ]; then
  exit 0
else
  exit 1
fi
```

- [ ] **Step 2: Verify the script now produces traceability.md**

Run:
```bash
TMP=$(mktemp -d)
mkdir -p "$TMP/specs" "$TMP/test/shell"

cat > "$TMP/specs/spec.md" << 'EOF'
#### Scenario: 用户登录
#### Scenario: 用户退出
EOF

cat > "$TMP/test/shell/test-auth.bats" << 'EOF'
@test "用户登录" { true; }
@test "用户退出" { true; }
EOF

bash src/scripts/comet-forward-trace.sh --spec-dir "$TMP/specs" --test-dir "$TMP/test" --output-dir "$TMP"
echo "Exit code: $?"
cat "$TMP/traceability.md"

rm -rf "$TMP"
```
Expected: Full 5-section traceability.md with `GATE: PASS`, exit 0

- [ ] **Step 3: Verify BLOCKED output with GATE: BLOCKED**

Run:
```bash
TMP=$(mktemp -d)
mkdir -p "$TMP/specs" "$TMP/test/shell"

cat > "$TMP/specs/spec.md" << 'EOF'
#### Scenario: 用户登录
#### Scenario: 用户退出
#### Scenario: 密码重置
EOF

cat > "$TMP/test/shell/test-auth.bats" << 'EOF'
@test "用户登录" { true; }
EOF

bash src/scripts/comet-forward-trace.sh --spec-dir "$TMP/specs" --test-dir "$TMP/test" --output-dir "$TMP"
echo "Exit code: $?"
grep '^GATE:' "$TMP/traceability.md"

rm -rf "$TMP"
```
Expected: `GATE: BLOCKED`, exit 1

- [ ] **Step 4: Commit**

```bash
git add src/scripts/comet-forward-trace.sh
git commit -m "feat(bidirectional-verify): add traceability.md assembly with 5-section report and GATE line"
```

---

### Task 4: Skill 定义 SKILL.md

**Files:**
- Create: `src/skills/bidirectional-verify/SKILL.md`

- [ ] **Step 1: Create SKILL.md**

```markdown
# bidirectional-verify Skill

## Description

作为 `/comet-verify` 的附加验证项，执行 spec↔test 双向追溯验证，产出 `traceability.md`。

## Protocol

### Inputs

| 参数 | 说明 | 来源 |
|------|------|------|
| `--change-name` | Change 名称 | comet-verify 传递 |
| `--change-dir` | Change 目录路径 | comet-verify 传递 |
| `--spec-dir` | Spec 目录（默认 `<change-dir>/specs`） | comet-verify 传递 |
| `--test-dir` | 测试目录（默认 `test/`） | 固定配置 |
| `--output-dir` | 输出目录（默认 `.`） | 固定配置 |

### Input Sources (优先级)

1. **v6.0 mode** — 优先消费 `task-brief` + `review-package`（位于 `<change-dir>/.comet/handoff/`），缩小搜索范围到变更文件
2. **Fallback mode** — task-brief/review-package 不可用时，全量 grep `spec/` 和 `test/` 目录，输出 WARN

### Outputs

- `traceability.md` — 5 段式报告：
  1. Coverage Matrix — 每个 Scenario 的测试覆盖状态
  2. Orphan Tests — 无对应 Scenario 的测试方法（WARN）
  3. Edge Case Analysis — 边界条件扫描（需人工补充）
  4. Gate Verdict — 覆盖率和孤儿测试的综合判定
  5. Next Action — 通过或阻塞说明
- 末尾 `GATE: PASS` 或 `GATE: BLOCKED` 供 comet-guard.sh 解析
- Exit code: 0 = PASS（允许归档），1 = BLOCKED（阻止归档）

### Degradation

| 上游问题 | 降级行为 |
|---------|---------|
| task-brief/review-package 不存在 | 全量 grep + WARN 信息 |
| Spec 目录无 .md 文件 | 空覆盖矩阵 → GATE: BLOCKED |
| Test 目录不存在 | 所有 Scenario 标记 NOT FOUND → GATE: BLOCKED |
| Scenario 含特殊字符 | sed 转义后 grep |

## Files

```
src/
├── scripts/
│   ├── comet-forward-trace.sh     # 正向反查主脚本（编排器）
│   └── comet-backward-trace.sh    # 反向反查辅助脚本
└── skills/
    └── bidirectional-verify/
        └── SKILL.md               # 本 Skill 定义

comet/ (部署后)
├── scripts/
│   ├── comet-forward-trace.sh     # supercomet init 注入
│   └── comet-backward-trace.sh    # supercomet init 注入
└── reference/
    └── bidirectional-verify.md    # supercomet init 注入
```

## Usage

```bash
# 在 /comet-verify 中调用
bash comet/scripts/comet-forward-trace.sh \
  --change-name bidirectional-verify \
  --spec-dir openspec/changes/bidirectional-verify/specs \
  --test-dir test \
  --output-dir .
```

## Dependencies

- bash >= 4.0 (for `declare -a`)
- grep, sed, find (POSIX)
- 无外部依赖
```

- [ ] **Step 2: Commit**

```bash
git add src/skills/bidirectional-verify/SKILL.md
git commit -m "feat(bidirectional-verify): add skill definition SKILL.md with protocol and degradation strategy"
```

---

### Task 5: CLI init 子命令 — 部署脚本和参考文档

**Files:**
- Modify: `bin/supercomet.js` (implement `init` subcommand)

- [ ] **Step 1: Implement `cmdInit` function in supercomet.js**

Replace the `if (cmd === 'init')` block (lines 17-19) in `bin/supercomet.js`:

```javascript
const { copyFileSync, mkdirSync, readdirSync, existsSync, chmodSync } = require('fs');
const { resolve } = require('path');

function cmdInit() {
  const srcDir = resolve(__dirname, '..', 'src');
  const cwd = process.cwd();

  const scriptsDir = resolve(cwd, 'comet', 'scripts');
  const refDir = resolve(cwd, 'comet', 'reference');

  // Create target directories (idempotent)
  mkdirSync(scriptsDir, { recursive: true });
  mkdirSync(refDir, { recursive: true });

  // Copy .sh scripts from src/scripts/ to comet/scripts/
  const scriptSrcDir = resolve(srcDir, 'scripts');
  let copiedCount = 0;
  if (existsSync(scriptSrcDir)) {
    const files = readdirSync(scriptSrcDir);
    for (const f of files) {
      if (f.endsWith('.sh')) {
        const src = resolve(scriptSrcDir, f);
        const dest = resolve(scriptsDir, f);
        copyFileSync(src, dest);
        try { chmodSync(dest, 0o755); } catch (e) { /* ignore */ }
        copiedCount++;
        console.log(`  ${f} → comet/scripts/`);
      }
    }
  }

  // Copy reference doc (SKILL.md → comet/reference/bidirectional-verify.md)
  const skillSrc = resolve(srcDir, 'skills', 'bidirectional-verify', 'SKILL.md');
  if (existsSync(skillSrc)) {
    const refDest = resolve(refDir, 'bidirectional-verify.md');
    copyFileSync(skillSrc, refDest);
    copiedCount++;
    console.log(`  SKILL.md → comet/reference/bidirectional-verify.md`);
  }

  console.log(`supercomet: deployed ${copiedCount} files to comet/`);
}
```

Then update the `main()` function to call `cmdInit`, and add the `resolve` import at the top. The full file after edit:

```javascript
#!/usr/bin/env node

const { readFileSync, existsSync, copyFileSync, mkdirSync, readdirSync, chmodSync } = require('fs');
const { resolve } = require('path');

const VERSION = '0.1.0';

function cmdInit() {
  const srcDir = resolve(__dirname, '..', 'src');
  const cwd = process.cwd();

  const scriptsDir = resolve(cwd, 'comet', 'scripts');
  const refDir = resolve(cwd, 'comet', 'reference');

  mkdirSync(scriptsDir, { recursive: true });
  mkdirSync(refDir, { recursive: true });

  const scriptSrcDir = resolve(srcDir, 'scripts');
  let copiedCount = 0;
  if (existsSync(scriptSrcDir)) {
    const files = readdirSync(scriptSrcDir);
    for (const f of files) {
      if (f.endsWith('.sh')) {
        const src = resolve(scriptSrcDir, f);
        const dest = resolve(scriptsDir, f);
        copyFileSync(src, dest);
        try { chmodSync(dest, 0o755); } catch (e) { /* ignore */ }
        copiedCount++;
        console.log(`  ${f} → comet/scripts/`);
      }
    }
  }

  const skillSrc = resolve(srcDir, 'skills', 'bidirectional-verify', 'SKILL.md');
  if (existsSync(skillSrc)) {
    const refDest = resolve(refDir, 'bidirectional-verify.md');
    copyFileSync(skillSrc, refDest);
    copiedCount++;
    console.log(`  SKILL.md → comet/reference/bidirectional-verify.md`);
  }

  console.log(`supercomet: deployed ${copiedCount} files to comet/`);
}

function main() {
  const args = process.argv.slice(2);
  const cmd = args[0];

  if (cmd === 'version' || cmd === '--version' || cmd === '-v') {
    console.log(`supercomet v${VERSION}`);
    return;
  }

  if (cmd === 'init') {
    cmdInit();
    return;
  }

  console.log('supercomet — Comet skill bundle');
  console.log('');
  console.log('Usage:');
  console.log('  supercomet init       Deploy supercomet enhancements to current project');
  console.log('  supercomet version    Show version');
}

main();
```

- [ ] **Step 2: Test init — first run**

Run:
```bash
TMP=$(mktemp -d)
cp -r src "$TMP/"
cp bin/supercomet.js "$TMP/bin/" 2>/dev/null || true
# Run from TMP to test dir creation
bash -c "cd '$TMP' && node '$TMP/../bin/supercomet.js' init"
echo "---"
ls -la "$TMP/comet/scripts/" "$TMP/comet/reference/"
rm -rf "$TMP"
```
Expected: Scripts and reference doc deployed to comet/ directory

- [ ] **Step 3: Test init — idempotency (second run does not error)**

Run:
```bash
TMP=$(mktemp -d)
# Copy source structure
mkdir -p "$TMP/src/scripts" "$TMP/src/skills/bidirectional-verify"
cp src/scripts/comet-forward-trace.sh src/scripts/comet-backward-trace.sh "$TMP/src/scripts/"
cp src/skills/bidirectional-verify/SKILL.md "$TMP/src/skills/bidirectional-verify/"
cp bin/supercomet.js "$TMP/bin/"

# Run init twice
node "$TMP/bin/supercomet.js" init
echo "--- Second run ---"
node "$TMP/bin/supercomet.js" init

rm -rf "$TMP"
```
Expected: Both runs succeed with no errors

- [ ] **Step 4: Commit**

```bash
git add bin/supercomet.js
git commit -m "feat(bidirectional-verify): implement supercomet init subcommand for script deployment"
```

---

### Task 6: BATS 测试

**Files:**
- Create: `test/shell/bidirectional-verify.bats`

- [ ] **Step 1: Create the BATS test file**

```bash
#!/usr/bin/env bats

# bidirectional-verify BATS tests
# Covers: forward path (PASS/BLOCKED), backward path (orphans), fallback mode

setup() {
  export TMP_DIR="$(mktemp -d)"
  export SPEC_DIR="$TMP_DIR/specs"
  export TEST_DIR="$TMP_DIR/test/shell"
  export OUTPUT_DIR="$TMP_DIR/output"
  export FORWARD_SCRIPT="$(pwd)/src/scripts/comet-forward-trace.sh"
  export BACKWARD_SCRIPT="$(pwd)/src/scripts/comet-backward-trace.sh"
  mkdir -p "$SPEC_DIR" "$TEST_DIR" "$OUTPUT_DIR"
}

teardown() {
  rm -rf "$TMP_DIR"
}

@test "forward trace: 100% coverage passes gate" {
  cat > "$SPEC_DIR/spec.md" << 'EOF'
#### Scenario: 用户登录
#### Scenario: 用户退出
EOF

  cat > "$TEST_DIR/test-auth.bats" << 'EOF'
@test "用户登录" { true; }
@test "用户退出" { true; }
EOF

  run bash "$FORWARD_SCRIPT" \
    --spec-dir "$SPEC_DIR" \
    --test-dir "$TEST_DIR" \
    --output-dir "$OUTPUT_DIR"

  [ "$status" -eq 0 ]
  grep -q "GATE: PASS" "$OUTPUT_DIR/traceability.md"
  grep -q "Coverage: 2/2 = 100%" "$OUTPUT_DIR/traceability.md"
}

@test "forward trace: partial coverage blocks gate" {
  cat > "$SPEC_DIR/spec.md" << 'EOF'
#### Scenario: 用户登录
#### Scenario: 用户退出
#### Scenario: 密码重置
EOF

  cat > "$TEST_DIR/test-auth.bats" << 'EOF'
@test "用户登录" { true; }
@test "用户退出" { true; }
EOF

  run bash "$FORWARD_SCRIPT" \
    --spec-dir "$SPEC_DIR" \
    --test-dir "$TEST_DIR" \
    --output-dir "$OUTPUT_DIR"

  [ "$status" -eq 1 ]
  grep -q "GATE: BLOCKED" "$OUTPUT_DIR/traceability.md"
  grep -q "NOT FOUND" "$OUTPUT_DIR/traceability.md"
}

@test "forward trace: zero scenarios blocks gate" {
  cat > "$SPEC_DIR/spec.md" << 'EOF'
EOF

  cat > "$TEST_DIR/test-auth.bats" << 'EOF'
@test "用户登录" { true; }
EOF

  run bash "$FORWARD_SCRIPT" \
    --spec-dir "$SPEC_DIR" \
    --test-dir "$TEST_DIR" \
    --output-dir "$OUTPUT_DIR"

  [ "$status" -eq 1 ]
  grep -q "GATE: BLOCKED" "$OUTPUT_DIR/traceability.md"
}

@test "backward trace: orphan tests generate warnings" {
  cat > "$SPEC_DIR/spec.md" << 'EOF'
#### Scenario: 用户登录
EOF

  cat > "$TEST_DIR/test-orphan.bats" << 'EOF'
@test "用户登录" { true; }
@test "未定义功能" { true; }
EOF

  run bash "$BACKWARD_SCRIPT" \
    --spec-dir "$SPEC_DIR" \
    --test-dir "$TEST_DIR"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "WARN"
}

@test "backward trace: no orphans, clean output" {
  cat > "$SPEC_DIR/spec.md" << 'EOF'
#### Scenario: 用户登录
#### Scenario: 用户退出
EOF

  cat > "$TEST_DIR/test-auth.bats" << 'EOF'
@test "用户登录" { true; }
@test "用户退出" { true; }
EOF

  run bash "$BACKWARD_SCRIPT" \
    --spec-dir "$SPEC_DIR" \
    --test-dir "$TEST_DIR"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "forward trace: fallback mode when handoff directory missing" {
  # No handoff dir = fallback mode
  cat > "$SPEC_DIR/spec.md" << 'EOF'
#### Scenario: 用户登录
EOF

  cat > "$TEST_DIR/test-auth.bats" << 'EOF'
@test "用户登录" { true; }
EOF

  run bash "$FORWARD_SCRIPT" \
    --change-name "nonexistent-change" \
    --spec-dir "$SPEC_DIR" \
    --test-dir "$TEST_DIR" \
    --output-dir "$OUTPUT_DIR"

  [ "$status" -eq 0 ]
  grep -q "GATE: PASS" "$OUTPUT_DIR/traceability.md"
}

@test "full integration: forward + backward produces all 5 sections" {
  cat > "$SPEC_DIR/spec.md" << 'EOF'
#### Scenario: 用户登录
#### Scenario: 用户退出
EOF

  cat > "$TEST_DIR/test-auth.bats" << 'EOF'
@test "用户登录" { true; }
@test "用户退出" { true; }
EOF

  run bash "$FORWARD_SCRIPT" \
    --spec-dir "$SPEC_DIR" \
    --test-dir "$TEST_DIR" \
    --output-dir "$OUTPUT_DIR"

  [ "$status" -eq 0 ]

  # Check all 5 sections present
  grep -q "## 1. Coverage Matrix" "$OUTPUT_DIR/traceability.md"
  grep -q "## 2. Orphan Tests" "$OUTPUT_DIR/traceability.md"
  grep -q "## 3. Edge Case Analysis" "$OUTPUT_DIR/traceability.md"
  grep -q "## 4. Gate Verdict" "$OUTPUT_DIR/traceability.md"
  grep -q "## 5. Next Action" "$OUTPUT_DIR/traceability.md"
  grep -q "^GATE: PASS" "$OUTPUT_DIR/traceability.md"
}
```

- [ ] **Step 2: Install BATS if not available and run tests**

Run:
```bash
# Install bats if needed
if ! command -v bats &> /dev/null; then
  npm install -g bats 2>/dev/null || sudo apt-get install -y bats 2>/dev/null || true
fi

bats test/shell/bidirectional-verify.bats --verbose
```
Expected: All 7 tests PASS

- [ ] **Step 3: If tests fail, fix and re-run**

If any test fails, inspect the specific test output and fix either the test (if it has the wrong expectation) or the script (if it has a bug), then re-run:

```bash
bats test/shell/bidirectional-verify.bats --verbose
```
Expected: All 7 tests PASS

- [ ] **Step 4: Commit**

```bash
git add test/shell/bidirectional-verify.bats
git commit -m "test(bidirectional-verify): add BATS tests for forward, backward, and fallback paths"
```

---

## Self-Review Checklist

### Spec Coverage

Each requirement from the delta spec is covered:

| Spec Requirement | Covered By | Task |
|---|---|---|
| 双向反查 — 正向反查 spec→test | `comet-forward-trace.sh`: scenario extraction + grep test matching | Task 1 |
| 双向反查 — 反向反查 test→spec | `comet-backward-trace.sh`: test function extraction + scenario matching | Task 2 |
| 双向反查 — 消费 v6.0 交接材料 | v6.0 mode in forward-trace.sh: task-brief + review-package input | Task 1 |
| 双向反查 — traceability.md 闸门判定 | `GATE: PASS/BLOCKED` line in report | Task 3 |
| 零侵入部署 — 部署方式 | `supercomet init` copies to `comet/scripts/` + `comet/reference/` | Task 5 |
| 零侵入部署 — 不修改 Comet 核心 | No modification to comet-*.sh or .comet.yaml | Global constraint |
| 降级路径 — v6.0 文件不可用 | Fallback to full grep + WARN output | Task 1 (Step 3) |

### Placeholder Check

- No "TBD", "TODO", "implement later", "fill in details" — all code is complete
- No "Add error handling" without actual code — error handling is built into `set -euo pipefail` and condition checks
- No "Write tests for above" without actual test code — Task 6 has complete test code
- No references to undefined types or functions — all functions are defined in the same task or referenced task

### Type Consistency

- `--spec-dir`, `--test-dir`, `--output-dir` — consistent across all tasks
- `GATE: PASS/BLOCKED` — consistent format in both script output and test expectations
- `ORPHAN_ROWS` format `| name (file) | (无匹配) | ⚠️ WARN |` — consistent between backward-trace output and forward-trace consumption
