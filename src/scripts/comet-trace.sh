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

# --- .comet.yaml tasks 段行级解析器 ---
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

  flush_task_match "$mode" "$query_val"
}

extract_yaml_value() {
  local line="$1"
  local key="$2"
  echo "$line" | sed "s/.*${key}:[[:space:]]*//" | sed 's/^"//;s/"$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

flush_task_match() {
  local mode="$1"
  local query_val="$2"
  local matched=false

  if [ -z "$task_id" ]; then
    return
  fi

  if [ "$mode" = "fwd" ] && [ "$task_reqid" = "$query_val" ]; then
    matched=true
  elif [ "$mode" = "rev" ]; then
    for ch in "${task_commits[@]}"; do
      if [ "$ch" = "$query_val" ]; then
        matched=true
        break
      fi
    done
  fi

  if $matched; then
    MATCHED_LINES+=("REQ:$task_reqid|SCEN:$task_scenario|TEST_N:$task_testname|TEST_F:$task_testfile|TASK_ID:$task_id|TASK_DESC:$task_desc|COMMITS:${task_commits[*]}")
  fi
}

# --- 正向查询输出 ---
print_fwd_tree() {
  local sorted
  sorted=$(printf '%s\n' "${MATCHED_LINES[@]}" | sort -t'|' -k1,1 -k2,2 -k5,5)

  local first=true
  local prev_reqid=""
  local prev_scenario=""

  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    local reqid scena testn testf tid tdesc commits_str
    reqid=$(echo "$entry" | sed 's/.*REQ://;s/|SCEN:.*//')
    scena=$(echo "$entry" | sed 's/.*SCEN://;s/|TEST_N:.*//')
    testn=$(echo "$entry" | sed 's/.*TEST_N://;s/|TEST_F:.*//')
    tid=$(echo "$entry" | sed 's/.*TASK_ID://;s/|TASK_DESC:.*//')
    tdesc=$(echo "$entry" | sed 's/.*TASK_DESC://;s/|COMMITS:.*//')
    commits_str=$(echo "$entry" | sed 's/.*COMMITS://')

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

    local -a commits_arr=()
    for word in $commits_str; do
      commits_arr+=("$word")
    done

    local num_commits=${#commits_arr[@]}
    local ci=0
    for commit in "${commits_arr[@]}"; do
      if [ $ci -lt $((num_commits - 1)) ]; then
        echo "            ├── Commit: $commit"
      else
        echo "            └── Commit: $commit"
      fi
      echo "            │    └── Task: $tid $tdesc"
      ci=$((ci + 1))
    done
  done <<< "$sorted"
}

# --- 反向查询输出 ---
print_rev_tree() {
  local sorted
  sorted=$(printf '%s\n' "${MATCHED_LINES[@]}" | sort -t'|' -k5,5)

  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    local reqid scena testn tid tdesc commits_str
    reqid=$(echo "$entry" | sed 's/.*REQ://;s/|SCEN:.*//')
    scena=$(echo "$entry" | sed 's/.*SCEN://;s/|TEST_N:.*//')
    testn=$(echo "$entry" | sed 's/.*TEST_N://;s/|TEST_F:.*//')
    tid=$(echo "$entry" | sed 's/.*TASK_ID://;s/|TASK_DESC:.*//')
    tdesc=$(echo "$entry" | sed 's/.*TASK_DESC://;s/|COMMITS:.*//')
    commits_str=$(echo "$entry" | sed 's/.*COMMITS://')

    echo "Commit: $COMMIT_HASH"
    echo "  └── Task: $tid $tdesc"
    echo "       └── Requirement: $reqid"
    echo "            └── Scenario: $scena"
    echo "                 └── Test: $testn"
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

# --- 反向查询入口 ---
if [ -n "$COMMIT_HASH" ]; then
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
