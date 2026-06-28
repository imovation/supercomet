#!/usr/bin/env bash
set -euo pipefail

# comet-speculate.sh — Structured exploration before /comet-open
# Part of supercomet comet-speculate enhancement

usage() {
  cat <<'USAGE'
Usage: comet-speculate.sh [options]

Options:
  --mode MODE          Exploration mode: full | quick (required)
  --from-file PATH     YAML input file path (required)
  --output PATH        Output path (default: openspec/explore-findings.md)
  --help               Show this help
USAGE
}

MODE=""
FROM_FILE=""
OUTPUT="openspec/explore-findings.md"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --from-file) FROM_FILE="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    --help) usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [ -z "$MODE" ]; then
  echo "ERROR: --mode is required (full or quick)" >&2
  usage
  exit 1
fi

if [ "$MODE" != "full" ] && [ "$MODE" != "quick" ]; then
  echo "ERROR: Invalid mode: $MODE (must be full or quick)" >&2
  exit 1
fi

if [ -z "$FROM_FILE" ]; then
  echo "ERROR: --from-file is required" >&2
  usage
  exit 1
fi

if [ ! -f "$FROM_FILE" ]; then
  echo "ERROR: Input file not found: $FROM_FILE" >&2
  exit 1
fi

# --- Helper: strip paired surrounding double quotes only ---
strip_quotes() {
  sed 's/^[[:space:]]*"\(.*\)"$/\1/'
}

# --- YAML parsing (pure bash, no external yq dependency) ---

yaml_get() {
  local key="$1"
  local file="$2"
  grep -E "^${key}:" "$file" 2>/dev/null | head -1 | sed "s/^${key}:[[:space:]]*//" | strip_quotes || true
}

# --- Validate input ---

TOPIC=$(yaml_get "topic" "$FROM_FILE")
SUMMARY=$(yaml_get "summary" "$FROM_FILE")
RECOMMENDATION=$(yaml_get "recommendation" "$FROM_FILE")
REASON=$(yaml_get "reason" "$FROM_FILE")

VALIDATION_ERRORS=0

if [ -z "$TOPIC" ]; then
  echo "WARN: Missing required field: topic" >&2
  VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

if [ "$MODE" = "full" ]; then
  OPTION_NAMES=()
  while IFS= read -r line; do
    opt_name=$(echo "$line" | sed -n 's/^[[:space:]]*-[[:space:]]*name:[[:space:]]*//p')
    if [ -n "$opt_name" ]; then
      opt_name=$(echo "$opt_name" | strip_quotes)
      OPTION_NAMES+=("$opt_name")
    fi
  done < "$FROM_FILE"

  OPTION_COUNT=${#OPTION_NAMES[@]}

  if [ "$OPTION_COUNT" -lt 2 ]; then
    echo "WARN: Full mode requires 2-3 options, found $OPTION_COUNT" >&2
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
  elif [ "$OPTION_COUNT" -gt 3 ]; then
    echo "WARN: Full mode expects 2-3 options, found $OPTION_COUNT (continuing with all)" >&2
  fi

  if [ -z "$RECOMMENDATION" ]; then
    echo "WARN: Missing required field: recommendation" >&2
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
  fi
  if [ -z "$REASON" ]; then
    echo "WARN: Missing required field: reason" >&2
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
  fi
elif [ "$MODE" = "quick" ]; then
  if [ -z "$RECOMMENDATION" ]; then
    echo "WARN: Missing required field: recommendation" >&2
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
  fi
  if [ -z "$REASON" ]; then
    echo "WARN: Missing required field: reason" >&2
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
  fi
fi

if [ "$VALIDATION_ERRORS" -gt 0 ]; then
  echo "WARN: $VALIDATION_ERRORS validation warning(s)" >&2
  exit 1
fi

# --- Write explore-findings.md ---

OUTPUT_DIR=$(dirname "$OUTPUT")
if [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR" 2>/dev/null || {
    echo "ERROR: Cannot create output directory: $OUTPUT_DIR" >&2
    exit 1
  }
fi

TODAY=$(date +%Y-%m-%d)

{
  echo "# Explore Findings"
  echo ""
  echo "- **Topic**: $TOPIC"
  echo "- **Mode**: $MODE"
  echo "- **Date**: $TODAY"
  echo "- **Version**: 1"
  echo ""
  echo "## Summary"
  echo ""
  if [ -n "$SUMMARY" ]; then
    echo "$SUMMARY"
  else
    echo "(未提供概述)"
  fi
  echo ""

  if [ "$MODE" = "full" ]; then
    OPT_PRO=()
    OPT_CON=()
    OPT_EFF=()

    current_opt=-1
    in_pros=0
    in_cons=0
    in_effort=0

    while IFS= read -r line; do
      if echo "$line" | grep -qE "^[[:space:]]*-[[:space:]]*name:"; then
        current_opt=$((current_opt + 1))
        in_pros=0
        in_cons=0
        in_effort=0
        OPT_PRO+=("")
        OPT_CON+=("")
        OPT_EFF+=("")
        continue
      fi
      if [ "$current_opt" -ge 0 ]; then
        if echo "$line" | grep -qE "^[[:space:]]*pros:"; then
          in_pros=1
          in_cons=0
          in_effort=0
          continue
        fi
        if echo "$line" | grep -qE "^[[:space:]]*cons:"; then
          in_pros=0
          in_cons=1
          in_effort=0
          continue
        fi
        if echo "$line" | grep -qE "^[[:space:]]*effort:"; then
          in_pros=0
          in_cons=0
          in_effort=1
          OPT_EFF[$current_opt]=$(echo "$line" | sed "s/^[[:space:]]*effort:[[:space:]]*//" | strip_quotes)
          continue
        fi
        if [ "$in_pros" -eq 1 ]; then
          item=$(echo "$line" | sed -n 's/^[[:space:]]*-[[:space:]]*//p')
          if [ -n "$item" ]; then
            item=$(echo "$item" | strip_quotes)
            if [ -z "${OPT_PRO[$current_opt]}" ]; then
              OPT_PRO[$current_opt]="$item"
            else
              OPT_PRO[$current_opt]="${OPT_PRO[$current_opt]}, $item"
            fi
          fi
        fi
        if [ "$in_cons" -eq 1 ]; then
          item=$(echo "$line" | sed -n 's/^[[:space:]]*-[[:space:]]*//p')
          if [ -n "$item" ]; then
            item=$(echo "$item" | strip_quotes)
            if [ -z "${OPT_CON[$current_opt]}" ]; then
              OPT_CON[$current_opt]="$item"
            else
              OPT_CON[$current_opt]="${OPT_CON[$current_opt]}, $item"
            fi
          fi
        fi
      fi
    done < "$FROM_FILE"

    echo "## Options"
    echo ""
    opt_idx=0
    for opt_name in "${OPTION_NAMES[@]}"; do
      opt_idx=$((opt_idx + 1))
      array_idx=$((opt_idx - 1))
      echo "### Option $opt_idx: $opt_name"
      echo ""
      echo "- **Pros**: ${OPT_PRO[$array_idx]:-(未提供)}"
      echo "- **Cons**: ${OPT_CON[$array_idx]:-(未提供)}"
      if [ -n "${OPT_EFF[$array_idx]}" ]; then
        echo "- **Effort Estimate**: ${OPT_EFF[$array_idx]}"
      fi
      echo ""
    done
  fi

  echo "## Recommendation"
  echo ""
  echo "**推荐 ${RECOMMENDATION:-N/A}** — ${REASON:-(未提供理由)}"
} > "$OUTPUT"

echo "explore-findings.md written to $OUTPUT" >&2
echo "Mode: $MODE, Options: ${OPTION_COUNT:-0}" >&2
exit 0
