#!/usr/bin/env bats

# bidirectional-verify BATS tests
# Covers: forward path (PASS/BLOCKED), backward path (orphans), fallback mode

setup() {
  export TMP_DIR="$(mktemp -d)"
  export SPEC_DIR="$TMP_DIR/specs"
  export TEST_DIR="$TMP_DIR/test/shell"
  export OUTPUT_DIR="$TMP_DIR/output"
  export FORWARD_SCRIPT="$(pwd)/src/scripts/comet-forward-trace.sh"
  export BACKWARD_SCRIPT="$(pwd)/src/scripts/comet-backward-trace.sh"
  mkdir -p "$SPEC_DIR" "$TEST_DIR" "$OUTPUT_DIR"
}

teardown() {
  rm -rf "$TMP_DIR"
}

@test "forward trace 100pc coverage passes gate" {
  printf '%s\n' '#### Scenario: 用户登录' '#### Scenario: 用户退出' > "$SPEC_DIR/spec.md"
  printf '%s\n' '@test "用户登录" { true; }' '@test "用户退出" { true; }' > "$TEST_DIR/test-auth.bats"

  run bash "$FORWARD_SCRIPT" \
    --spec-dir "$SPEC_DIR" \
    --test-dir "$TEST_DIR" \
    --output-dir "$OUTPUT_DIR"

  [ "$status" -eq 0 ]
  grep -q "GATE: PASS" "$OUTPUT_DIR/traceability.md"
  grep -q "Coverage: 2/2 = 100%" "$OUTPUT_DIR/traceability.md"
}

@test "forward trace partial coverage blocks gate" {
  printf '%s\n' '#### Scenario: 用户登录' '#### Scenario: 用户退出' '#### Scenario: 密码重置' > "$SPEC_DIR/spec.md"
  printf '%s\n' '@test "用户登录" { true; }' '@test "用户退出" { true; }' > "$TEST_DIR/test-auth.bats"

  run bash "$FORWARD_SCRIPT" \
    --spec-dir "$SPEC_DIR" \
    --test-dir "$TEST_DIR" \
    --output-dir "$OUTPUT_DIR"

  [ "$status" -eq 1 ]
  grep -q "GATE: BLOCKED" "$OUTPUT_DIR/traceability.md"
  grep -q "NOT FOUND" "$OUTPUT_DIR/traceability.md"
}

@test "forward trace zero scenarios blocks gate" {
  printf '' > "$SPEC_DIR/spec.md"
  printf '%s\n' '@test "用户登录" { true; }' > "$TEST_DIR/test-auth.bats"

  run bash "$FORWARD_SCRIPT" \
    --spec-dir "$SPEC_DIR" \
    --test-dir "$TEST_DIR" \
    --output-dir "$OUTPUT_DIR"

  [ "$status" -eq 1 ]
  grep -q "GATE: BLOCKED" "$OUTPUT_DIR/traceability.md"
}

@test "backward trace orphan tests generate warnings" {
  printf '%s\n' '#### Scenario: 用户登录' > "$SPEC_DIR/spec.md"
  printf '%s\n' '@test "用户登录" { true; }' '@test "未定义功能" { true; }' > "$TEST_DIR/test-orphan.bats"

  run bash "$BACKWARD_SCRIPT" \
    --spec-dir "$SPEC_DIR" \
    --test-dir "$TEST_DIR"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "WARN"
}

@test "backward trace no orphans clean output" {
  printf '%s\n' '#### Scenario: 用户登录' '#### Scenario: 用户退出' > "$SPEC_DIR/spec.md"
  printf '%s\n' '@test "用户登录" { true; }' '@test "用户退出" { true; }' > "$TEST_DIR/test-auth.bats"

  run bash "$BACKWARD_SCRIPT" \
    --spec-dir "$SPEC_DIR" \
    --test-dir "$TEST_DIR"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "forward trace fallback mode when handoff directory missing" {
  printf '%s\n' '#### Scenario: 用户登录' > "$SPEC_DIR/spec.md"
  printf '%s\n' '@test "用户登录" { true; }' > "$TEST_DIR/test-auth.bats"

  run bash "$FORWARD_SCRIPT" \
    --change-name "nonexistent-change" \
    --spec-dir "$SPEC_DIR" \
    --test-dir "$TEST_DIR" \
    --output-dir "$OUTPUT_DIR"

  [ "$status" -eq 0 ]
  grep -q "GATE: PASS" "$OUTPUT_DIR/traceability.md"
}

@test "full integration forward backward produces all 5 sections" {
  printf '%s\n' '#### Scenario: 用户登录' '#### Scenario: 用户退出' > "$SPEC_DIR/spec.md"
  printf '%s\n' '@test "用户登录" { true; }' '@test "用户退出" { true; }' > "$TEST_DIR/test-auth.bats"

  run bash "$FORWARD_SCRIPT" \
    --spec-dir "$SPEC_DIR" \
    --test-dir "$TEST_DIR" \
    --output-dir "$OUTPUT_DIR"

  [ "$status" -eq 0 ]

  grep -q "## 1. Coverage Matrix" "$OUTPUT_DIR/traceability.md"
  grep -q "## 2. Orphan Tests" "$OUTPUT_DIR/traceability.md"
  grep -q "## 3. Edge Case Analysis" "$OUTPUT_DIR/traceability.md"
  grep -q "## 4. Gate Verdict" "$OUTPUT_DIR/traceability.md"
  grep -q "## 5. Next Action" "$OUTPUT_DIR/traceability.md"
  grep -q "^GATE: PASS" "$OUTPUT_DIR/traceability.md"
}
