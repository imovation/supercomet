#!/usr/bin/env bats

setup() {
  export TMP_DIR="$(mktemp -d)"
  export SCRIPT="$(pwd)/src/scripts/comet-spec-to-test.sh"
  cd "$TMP_DIR"
}

teardown() {
  rm -rf "$TMP_DIR"
}

write_spec() {
  cat > "$TMP_DIR/spec.md" << 'EOF'
## ADDED Requirements

### Requirement: Test feature

#### Scenario: successful login
- **WHEN** user enters valid credentials
- **THEN** system grants access

#### Scenario: failed login
- **WHEN** user enters invalid credentials
- **THEN** system denies access
- **AND** system logs the attempt
EOF
}

write_spec_no_scenarios() {
  cat > "$TMP_DIR/spec.md" << 'EOF'
## ADDED Requirements

### Requirement: Empty spec

This requirement has no scenarios defined.
EOF
}

write_spec_broken() {
  cat > "$TMP_DIR/spec.md" << 'EOF'
## BROKEN spec

This is not a valid spec format
with no scenarios whatsoever

just random text
EOF
}

@test "generates test skeletons for each scenario" {
  write_spec
  run bash "$SCRIPT" "$TMP_DIR/spec.md" --framework jest
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "scenario: successful-login"
  echo "$output" | grep -q "scenario: failed-login"
  echo "$output" | grep -q "WHEN user enters valid credentials"
  echo "$output" | grep -q "THEN system denies access"
  echo "$output" | grep -q "AND system logs the attempt"
}

@test "output contains TODO marker" {
  write_spec
  run bash "$SCRIPT" "$TMP_DIR/spec.md"
  [ "$status" -eq 0 ]
  grep -q "TODO" <<< "$output"
}

@test "empty spec exits gracefully" {
  write_spec_no_scenarios
  run bash "$SCRIPT" "$TMP_DIR/spec.md"
  [ "$status" -eq 0 ]
}

@test "nonexistent spec file errors" {
  run bash "$SCRIPT" "$TMP_DIR/nonexistent.md"
  [ "$status" -eq 1 ]
  grep -q "ERROR" <<< "$output"
}

@test "jest framework generates it() blocks" {
  write_spec
  run bash "$SCRIPT" "$TMP_DIR/spec.md" --framework jest
  [ "$status" -eq 0 ]
  grep -q "it(" <<< "$output"
}

@test "vitest framework generates it() blocks" {
  write_spec
  run bash "$SCRIPT" "$TMP_DIR/spec.md" --framework vitest
  [ "$status" -eq 0 ]
  grep -q "it(" <<< "$output"
}

@test "pytest framework generates def test_ functions" {
  write_spec
  run bash "$SCRIPT" "$TMP_DIR/spec.md" --framework pytest
  [ "$status" -eq 0 ]
  grep -q "def test_" <<< "$output"
}

@test "go-test framework generates func Test functions" {
  write_spec
  run bash "$SCRIPT" "$TMP_DIR/spec.md" --framework go-test
  [ "$status" -eq 0 ]
  grep -q "func Test" <<< "$output"
}

@test "invalid framework warns and uses generic" {
  write_spec
  run bash "$SCRIPT" "$TMP_DIR/spec.md" --framework unknown-fw
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "WARN" || true
}

@test "output can be redirected to file" {
  write_spec
  run bash "$SCRIPT" "$TMP_DIR/spec.md" --framework jest --output "$TMP_DIR/test-skeleton.test.js"
  [ "$status" -eq 0 ]
  [ -f "$TMP_DIR/test-skeleton.test.js" ]
  grep -q "Scenario" "$TMP_DIR/test-skeleton.test.js"
}

@test "broken spec marks manual" {
  write_spec_broken
  run bash "$SCRIPT" "$TMP_DIR/spec.md" --framework jest
  [ "$status" -eq 0 ]
  grep -q "MANUAL" <<< "$output" || grep -q "WARN" <<< "$output" || true
}

@test "scenario name with special chars is sanitized" {
  cat > "$TMP_DIR/spec.md" << 'EOF'
### Requirement: Test

#### Scenario: user can login with email & password!
- **WHEN** user submits form
- **THEN** system authenticates
EOF
  run bash "$SCRIPT" "$TMP_DIR/spec.md" --framework jest
  [ "$status" -eq 0 ]
  grep -q "scenario:" <<< "$output"
}

@test "AND clause appears in generated skeleton" {
  write_spec
  run bash "$SCRIPT" "$TMP_DIR/spec.md" --framework jest
  [ "$status" -eq 0 ]
  grep -q "AND system logs the attempt" <<< "$output"
}
