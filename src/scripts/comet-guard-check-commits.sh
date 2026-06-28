#!/usr/bin/env bash
set -euo pipefail

# comet-guard-check-commits.sh — verify→archive gate: 检查所有 task 的 commits 非空

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

  if [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]id\: ]]; then
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
