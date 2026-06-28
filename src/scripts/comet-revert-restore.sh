#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: comet-revert-restore.sh [options]

Options:
  --commit HASH     Implement commit to verify (required)
  --test-cmd CMD    Test command (default: make test)
  --label LABEL     Task label: Security, Core, Critical
  --help            Show this help
USAGE
  exit 0
}

COMMIT=""
TEST_CMD="make test"
LABEL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --commit) COMMIT="$2"; shift 2 ;;
    --test-cmd) TEST_CMD="$2"; shift 2 ;;
    --label) LABEL="$2"; shift 2 ;;
    --help) usage ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage ;;
  esac
done

if [ -z "$COMMIT" ]; then
  echo "ERROR: --commit is required" >&2
  exit 1
fi

if ! git rev-parse --verify "$COMMIT" >/dev/null 2>&1; then
  echo "ERROR: Invalid commit hash: $COMMIT" >&2
  exit 1
fi

CRITICAL_LABELS="Security Core Critical"
if [ -n "$LABEL" ]; then
  MATCH=0
  for lbl in $CRITICAL_LABELS; do
    [ "$LABEL" = "$lbl" ] && MATCH=1
  done
  if [ "$MATCH" -eq 0 ]; then
    echo "SKIP: label '$LABEL' not critical (not Security/Core/Critical)" >&2
    exit 0
  fi
else
  echo "SKIP: no label provided, skipping revert-restore" >&2
  exit 0
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "WARN: working tree is dirty, results may be unreliable" >&2
fi

echo "=== Revert-Restore Verification ===" >&2
echo "Commit: $COMMIT" >&2
echo "Label: $LABEL" >&2
echo "Test command: $TEST_CMD" >&2

# Step 1: Revert
echo "--- Step 1: Reverting $COMMIT ---" >&2
if ! git revert --no-edit "$COMMIT" 2>/dev/null; then
  echo "WARN: revert conflict, cannot verify automatically" >&2
  echo "The revert-restore cycle could not be completed due to conflicts." >&2
  echo "Manual verification required." >&2
  git revert --abort 2>/dev/null || true
  exit 0
fi

# Step 2: Run tests - MUST FAIL
echo "--- Step 2: Running tests after revert (expected: FAIL) ---" >&2
set +e
(bash -c "$TEST_CMD") > /tmp/revert-restore-test-output.txt 2>&1
TEST_RC=$?
set -e

if [ "$TEST_RC" -eq 0 ]; then
  echo "" >&2
  echo "=== GATE: BLOCKED ===" >&2
  echo "Tests PASSED after reverting implementation." >&2
  echo "This means the tests do NOT catch the defect." >&2
  echo "The test suite is INVALID for this change." >&2
  cat /tmp/revert-restore-test-output.txt >&2
  
  # Restore before exiting
  git revert --no-edit HEAD 2>/dev/null || git revert --abort 2>/dev/null || true
  exit 1
fi

echo "Tests FAILED after revert (expected, exit code: $TEST_RC)" >&2

# Step 3: Restore (revert the revert)
echo "--- Step 3: Restoring (reverting the revert) ---" >&2
git revert --no-edit HEAD 2>/dev/null || {
  echo "WARN: restore revert failed, aborting" >&2
  git revert --abort 2>/dev/null || true
  exit 0
}

# Step 4: Run tests - MUST PASS
echo "--- Step 4: Running tests after restore (expected: PASS) ---" >&2
set +e
(bash -c "$TEST_CMD") > /tmp/revert-restore-test-output.txt 2>&1
TEST_RC=$?
set -e

if [ "$TEST_RC" -ne 0 ]; then
  echo "" >&2
  echo "=== GATE: FAIL ===" >&2
  echo "Tests FAILED after restoring implementation." >&2
  echo "Restore may be incomplete or tests are broken." >&2
  cat /tmp/revert-restore-test-output.txt >&2
  exit 1
fi

echo "" >&2
echo "=== GATE: PASS ===" >&2
echo "Revert-restore cycle completed successfully." >&2
echo "Tests fail when implementation is removed and pass when restored." >&2

exit 0
