#!/usr/bin/env bats

# three-d-traceability BATS tests
# Covers: forward query, reverse query, invalid requirement-id,
#         invalid commit hash, empty commits gate

setup() {
  export TMP_DIR="$(mktemp -d)"
  export CHANGE_DIR="$TMP_DIR/openspec/changes/test-change"
  export TRACE_SCRIPT="$(pwd)/src/scripts/comet-trace.sh"
  export GUARD_SCRIPT="$(pwd)/src/scripts/comet-guard-check-commits.sh"
  mkdir -p "$CHANGE_DIR"
  export COMET_YAML="$CHANGE_DIR/.comet.yaml"
}

teardown() {
  rm -rf "$TMP_DIR"
}

write_test_yaml() {
  cat > "$COMET_YAML" << 'YAML'
workflow: full
phase: build
tasks:
  - id: "1.1"
    description: "实现正向查询"
    requirement_id: "bidirectional-verify"
    scenario: "正向反查——spec 到 test"
    test_file: "test/shell/bidirectional-verify.bats"
    test_name: "forward trace 100pc coverage passes gate"
    commits:
      - abc123def
  - id: "1.2"
    description: "实现反向查询"
    requirement_id: "bidirectional-verify"
    scenario: "反向反查——test 到 spec"
    test_file: "test/shell/backward-trace.bats"
    test_name: "backward trace orphan warnings"
    commits:
      - def456abc
  - id: "2.1"
    description: "BATS 测试"
    requirement_id: "three-d-traceability"
    scenario: "正向查询——按 Requirement ID"
    test_file: "test/shell/comet-trace.bats"
    test_name: "forward trace requirement id"
    commits:
      - ghi789jkl
YAML
}

@test "forward trace by requirement id returns complete chain" {
  write_test_yaml

  run bash "$TRACE_SCRIPT" \
    --requirement-id "bidirectional-verify" \
    --comet-yaml "$COMET_YAML"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Requirement: bidirectional-verify"
  echo "$output" | grep -q "正向反查——spec 到 test"
  echo "$output" | grep -q "forward trace 100pc coverage passes gate"
  echo "$output" | grep -q "Commit: abc123def"
  echo "$output" | grep -q "Commit: def456abc"
  echo "$output" | grep -q "Task: 1.1 实现正向查询"
  echo "$output" | grep -q "Task: 1.2 实现反向查询"
}

@test "reverse trace by commit hash returns complete chain" {
  CURRENT_HASH=$(git rev-parse HEAD)

  cat > "$COMET_YAML" << YAML
workflow: full
phase: build
tasks:
  - id: "1.1"
    description: "测试正向查询"
    requirement_id: "bidirectional-verify"
    scenario: "正向反查——spec 到 test"
    test_file: "test/shell/bidirectional-verify.bats"
    test_name: "forward trace 100pc coverage passes gate"
    commits:
      - ${CURRENT_HASH}
YAML

  run bash "$TRACE_SCRIPT" \
    --commit "$CURRENT_HASH" \
    --comet-yaml "$COMET_YAML"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Commit: $CURRENT_HASH"
  echo "$output" | grep -q "Task: 1.1 测试正向查询"
  echo "$output" | grep -q "Requirement: bidirectional-verify"
  echo "$output" | grep -q "Scenario: 正向反查——spec 到 test"
  echo "$output" | grep -q "Test: forward trace 100pc coverage passes gate"
}

@test "invalid requirement id returns Not found and exits non-zero" {
  write_test_yaml

  run bash "$TRACE_SCRIPT" \
    --requirement-id "nonexistent-req" \
    --comet-yaml "$COMET_YAML"

  [ "$status" -eq 1 ]
  echo "$output" | grep -q "Not found"
}

@test "invalid commit hash returns error and exits non-zero" {
  write_test_yaml

  run bash "$TRACE_SCRIPT" \
    --commit "0000000000000000000000000000000000000000" \
    --comet-yaml "$COMET_YAML"

  [ "$status" -eq 1 ]
  echo "$output" | grep -qE "(ERROR|Not found)"
}

@test "empty commits gate blocks on verify-to-archive transition" {
  cat > "$COMET_YAML" << 'YAML'
workflow: full
phase: verify
tasks:
  - id: "1.1"
    description: "有 commits 的 task"
    requirement_id: "test-req"
    scenario: "test scenario"
    test_file: "test/test.bats"
    test_name: "my test"
    commits:
      - abc123
  - id: "2.1"
    description: "空 commits 的 task"
    requirement_id: "test-req-2"
    scenario: "test scenario 2"
    test_file: "test/test2.bats"
    test_name: "my test 2"
    commits:
YAML

  run bash -c "cd '$TMP_DIR' && bash '$GUARD_SCRIPT' test-change"

  [ "$status" -eq 1 ]
  echo "$output" | grep -q "BLOCKED"
  echo "$output" | grep -q "2.1"
}
