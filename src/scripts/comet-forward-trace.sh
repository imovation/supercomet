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
