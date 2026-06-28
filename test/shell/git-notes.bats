#!/usr/bin/env bats

setup() {
  export TMP_DIR="$(mktemp -d)"
  export SCRIPT="$(pwd)/src/scripts/comet-git-notes.sh"
  cd "$TMP_DIR"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "test" > file.txt
  git add file.txt && git commit -q -m "initial"
}

teardown() {
  rm -rf "$TMP_DIR"
}

@test "writes git note on commit" {
  COMMIT=$(git rev-parse HEAD)
  run bash "$SCRIPT" --task-id "1.1" --requirement-id "test-req" --commit "$COMMIT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Git note written"
  NOTES=$(git notes --ref=supercomet.task show "$COMMIT" 2>/dev/null || echo "")
  echo "$NOTES" | grep -q "task_id=1.1"
  echo "$NOTES" | grep -q "requirement_id=test-req"
}

@test "uses HEAD when no commit specified" {
  run bash "$SCRIPT" --task-id "2.1" --requirement-id "req-2"
  [ "$status" -eq 0 ]
  COMMIT=$(git rev-parse HEAD)
  NOTES=$(git notes --ref=supercomet.task show "$COMMIT" 2>/dev/null || echo "")
  echo "$NOTES" | grep -q "task_id=2.1"
}

@test "recover lists all notes" {
  bash "$SCRIPT" --task-id "1.1" --requirement-id "req-a" > /dev/null 2>&1
  echo "v2" > file.txt
  git add file.txt && git commit -q -m "v2"
  COMMIT2=$(git rev-parse HEAD)
  bash "$SCRIPT" --task-id "1.2" --requirement-id "req-b" --commit "$COMMIT2" > /dev/null 2>&1
  
  run bash "$SCRIPT" --recover
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "task_id=1.1"
  echo "$output" | grep -q "task_id=1.2"
}

@test "missing --task-id errors" {
  run bash "$SCRIPT"
  [ "$status" -eq 1 ]
}

@test "recover with no notes succeeds" {
  run bash "$SCRIPT" --recover
  [ "$status" -eq 0 ]
}
