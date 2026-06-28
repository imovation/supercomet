#!/usr/bin/env bats

setup() {
  export TMP_DIR="$(mktemp -d)"
  export SCRIPT="$(pwd)/src/scripts/comet-revert-restore.sh"
  cd "$TMP_DIR"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "initial" > file.txt
  git add file.txt && git commit -q -m "initial"
  echo "feature" > file.txt
  git add file.txt && git commit -q -m "feat: add feature"
  IMPL_COMMIT=$(git rev-parse HEAD)
  echo "$IMPL_COMMIT" > /tmp/revert-restore-test-commit.txt
  # Create a state-toggling test command
  cat > "$TMP_DIR/test-cmd" << 'CMD'
#!/bin/bash
STATE_FILE=/tmp/revert-restore-state
if [ ! -f "$STATE_FILE" ]; then
  echo "first" > "$STATE_FILE"
  exit 1
else
  count=$(cat "$STATE_FILE")
  if [ "$count" = "first" ]; then
    echo "second" > "$STATE_FILE"
    exit 0
  else
    exit 0
  fi
fi
CMD
  chmod +x "$TMP_DIR/test-cmd"
  rm -f /tmp/revert-restore-state
}

teardown() {
  rm -rf "$TMP_DIR" /tmp/revert-restore-state
}

@test "missing --commit errors" {
  run bash "$SCRIPT"
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "ERROR"
}

@test "nonexistent commit errors" {
  run bash "$SCRIPT" --commit deadbeef --label Security
  [ "$status" -eq 1 ]
}

@test "non-critical label skips" {
  IMPL=$(cat /tmp/revert-restore-test-commit.txt)
  run bash "$SCRIPT" --commit "$IMPL" --label "minor"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "SKIP"
}

@test "no label skips" {
  IMPL=$(cat /tmp/revert-restore-test-commit.txt)
  run bash "$SCRIPT" --commit "$IMPL"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "SKIP"
}

@test "Critical label with valid tests passes" {
  IMPL=$(cat /tmp/revert-restore-test-commit.txt)
  run bash "$SCRIPT" --commit "$IMPL" --label Security --test-cmd "$TMP_DIR/test-cmd"
  echo "STATUS: $status"
  echo "OUTPUT: $output"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "GATE: PASS"
}

@test "Critical label with invalid tests blocked" {
  IMPL=$(cat /tmp/revert-restore-test-commit.txt)
  # Use a test cmd that always passes (tests don't catch the defect)
  cat > "$TMP_DIR/pass-cmd" << 'CMD'
#!/bin/bash
echo "all tests pass"
CMD
  chmod +x "$TMP_DIR/pass-cmd"
  run bash "$SCRIPT" --commit "$IMPL" --label Critical --test-cmd "$TMP_DIR/pass-cmd"
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "GATE: BLOCKED"
}
