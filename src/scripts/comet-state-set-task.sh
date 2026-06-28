#!/usr/bin/env bash
set -euo pipefail

# comet-state-set-task.sh — 将追溯字段写入 .comet.yaml 的 task 条目
# 调用方式：comet-state-set-task.sh <change-name> <task-id> \
#   --requirement-id <id> --scenario <name> \
#   --test-file <path> --test-name <name> [--description <desc>]

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

if [ -z "$REQUIREMENT_ID" ] || [ -z "$SCENARIO" ] || [ -z "$TEST_FILE" ] || [ -z "$TEST_NAME" ]; then
  echo "ERROR: --requirement-id, --scenario, --test-file, --test-name are required" >&2
  exit 2
fi

COMET_YAML="openspec/changes/$CHANGE_NAME/.comet.yaml"
if [ ! -f "$COMET_YAML" ]; then
  echo "ERROR: $COMET_YAML not found" >&2
  exit 1
fi

CURRENT_COMMIT=$(git rev-parse HEAD 2>/dev/null || true)
if [ -z "$CURRENT_COMMIT" ]; then
  echo "ERROR: Cannot determine current commit hash" >&2
  exit 1
fi

# --- 写入逻辑 ---
TASKS_SECTION_EXISTS=false
if grep -q '^tasks:' "$COMET_YAML"; then
  TASKS_SECTION_EXISTS=true
fi

TASK_EXISTS=false
if $TASKS_SECTION_EXISTS && grep -qE "id:[[:space:]]*\"?${TASK_ID}\"?" "$COMET_YAML"; then
  TASK_EXISTS=true
fi

if ! $TASKS_SECTION_EXISTS; then
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
  tmpfile=$(mktemp)
  in_target_task=false
  in_commits=false
  inserted=false

  while IFS= read -r line || [ -n "$line" ]; do
    echo "$line" >> "$tmpfile"

    if [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]id\:.*${TASK_ID} ]]; then
      in_target_task=true
    elif $in_target_task && [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]id\: ]]; then
      if ! $inserted; then
        sed -i '$ d' "$tmpfile"
        echo "      - ${CURRENT_COMMIT}" >> "$tmpfile"
        echo "$line" >> "$tmpfile"
        inserted=true
        in_target_task=false
      else
        in_target_task=false
      fi
    fi

    if $in_target_task && [[ "$line" =~ ^[[:space:]]{4}commits\: ]]; then
      in_commits=true
      continue
    fi

    if $in_target_task && $in_commits && ! $inserted && [[ "$line" =~ ^[[:space:]]{4}[a-z_] ]]; then
      sed -i '$ d' "$tmpfile"
      echo "      - ${CURRENT_COMMIT}" >> "$tmpfile"
      echo "$line" >> "$tmpfile"
      in_commits=false
      inserted=true
    fi
  done < "$COMET_YAML"

  if ! $inserted; then
    echo "      - ${CURRENT_COMMIT}" >> "$tmpfile"
  fi

  mv "$tmpfile" "$COMET_YAML"
  echo "Commit $CURRENT_COMMIT appended to task $TASK_ID in $COMET_YAML" >&2

else
  tmpfile=$(mktemp)
  after_last_task=false
  last_id_line=$(grep -nE '^[[:space:]]{2}-[[:space:]]id\:' "$COMET_YAML" | tail -1 | cut -d: -f1)

  if [ -z "$last_id_line" ]; then
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
    ln=0
    while IFS= read -r line || [ -n "$line" ]; do
      ln=$((ln + 1))
      if [ "$ln" -le "$last_id_line" ]; then
        echo "$line" >> "$tmpfile"
        continue
      fi
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
