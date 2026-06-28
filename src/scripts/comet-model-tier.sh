#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: comet-model-tier.sh --change <name> [options]

Options:
  --change NAME     Change name (required)
  --task-id ID      Task ID to score (default: all tasks)
  --json            Output JSON format (default)
  --human           Output human-readable format
  --override TIER   Override tier: fast|economy|balanced|best
  --help            Show this help
USAGE
  exit 0
}

CHANGE=""
TASK_ID=""
FORMAT="json"
OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --change) CHANGE="$2"; shift 2 ;;
    --task-id) TASK_ID="$2"; shift 2 ;;
    --json) FORMAT="json"; shift ;;
    --human) FORMAT="human"; shift ;;
    --override) OVERRIDE="$2"; shift 2 ;;
    --help) usage ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage ;;
  esac
done

if [ -z "$CHANGE" ]; then
  echo "ERROR: --change is required" >&2
  exit 1
fi

COMET_YAML="openspec/changes/${CHANGE}/.comet.yaml"
if [ ! -f "$COMET_YAML" ]; then
  COMET_YAML="openspec/changes/archive/"*"-${CHANGE}/.comet.yaml" 2>/dev/null || true
  COMET_YAML=$(ls openspec/changes/archive/*-${CHANGE}/.comet.yaml 2>/dev/null | head -1 || true)
  if [ -z "$COMET_YAML" ] || [ ! -f "$COMET_YAML" ]; then
    echo "ERROR: .comet.yaml not found for change: $CHANGE" >&2
    exit 1
  fi
fi

if [ -n "$OVERRIDE" ]; then
  case "$OVERRIDE" in
    fast|economy|balanced|best) ;;
    *)
      echo "ERROR: Invalid override tier: $OVERRIDE. Valid: fast, economy, balanced, best" >&2
      exit 1
      ;;
  esac
  if [ "$FORMAT" = "json" ]; then
    echo "{\"tier\":\"$OVERRIDE\",\"reason\":\"manually overridden\",\"score\":-1,\"override\":true}"
  else
    echo "Tier: $OVERRIDE (manually overridden)"
  fi
  exit 0
fi

file_count=0
risk_score=0
plan_score=0

# Count task files - from tasks block in .comet.yaml
if grep -q "tasks:" "$COMET_YAML" 2>/dev/null; then
  task_count=$(grep -cE "^\s+- (task_id|requirement_id):" "$COMET_YAML" 2>/dev/null || echo 0)
  file_count=$task_count
  if [ "$file_count" -eq 0 ]; then
    file_count=1
  fi
else
  file_count=1
fi

if grep -qE "Security|Critical|Core" "$COMET_YAML" 2>/dev/null; then
  risk_score=2
fi

if [ -n "$TASK_ID" ]; then
  if grep -A 20 "task_id.*${TASK_ID}" "$COMET_YAML" 2>/dev/null | grep -q "commits:"; then
    plan_score=0
  else
    plan_score=1
  fi
else
  plan_score=1
fi

# File count scoring
if [ "$file_count" -le 2 ]; then
  f_score=0
elif [ "$file_count" -le 5 ]; then
  f_score=1
else
  f_score=2
fi

total=$((f_score + risk_score + plan_score))

if [ "$total" -le 1 ]; then
  tier="fast"
elif [ "$total" -le 3 ]; then
  tier="economy"
elif [ "$total" -le 5 ]; then
  tier="balanced"
else
  tier="best"
fi

if [ "$FORMAT" = "json" ]; then
  echo "{\"tier\":\"$tier\",\"reason\":\"file_count=${file_count}, risk_score=${risk_score}, plan_score=${plan_score}\",\"score\":$total,\"override\":false}"
else
  echo "Tier: $tier"
  echo "  Score: $total (file=$f_score, risk=$risk_score, plan=$plan_score)"
  echo "  File count: $file_count"
fi

exit 0
