#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: comet-git-notes.sh [options]

Options:
  --task-id ID      Task ID (required for write)
  --requirement-id REQ  Requirement ID
  --commit HASH     Commit hash to annotate
  --recover         Recover progress from git notes
  --help            Show this help
USAGE
  exit 0
}

TASK_ID=""
REQ_ID=""
COMMIT=""
RECOVER=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-id) TASK_ID="$2"; shift 2 ;;
    --requirement-id) REQ_ID="$2"; shift 2 ;;
    --commit) COMMIT="$2"; shift 2 ;;
    --recover) RECOVER=1; shift ;;
    --help) usage ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage ;;
  esac
done

if [ "$RECOVER" -eq 1 ]; then
  echo "# Recovered Progress from Git Notes"
  echo ""
  git log --all --show-notes=supercomet.task --format="%H" 2>/dev/null | while IFS= read -r hash; do
    if [ -n "$hash" ]; then
      note=$(git notes --ref=supercomet.task show "$hash" 2>/dev/null || true)
      if echo "$note" | grep -q "task_id="; then
        echo "- commit: ${hash:0:7} | $note"
      fi
    fi
  done
  exit 0
fi

if [ -z "$TASK_ID" ]; then
  echo "ERROR: --task-id is required for write" >&2
  exit 1
fi

if [ -z "$COMMIT" ]; then
  COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "")
fi

if [ -z "$COMMIT" ]; then
  echo "ERROR: No commit available" >&2
  exit 1
fi

NOTE_DATA="task_id=${TASK_ID}"
[ -n "$REQ_ID" ] && NOTE_DATA="${NOTE_DATA} requirement_id=${REQ_ID}"

git notes --ref=supercomet.task append -m "$NOTE_DATA" "$COMMIT" 2>/dev/null || {
  echo "WARN: Failed to write git note" >&2
  exit 0
}

echo "Git note written: $NOTE_DATA on commit ${COMMIT:0:7}"

exit 0
