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
