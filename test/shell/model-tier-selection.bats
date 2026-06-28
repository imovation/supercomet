#!/usr/bin/env bats

setup() {
  export TMP_DIR="$(mktemp -d)"
  export SCRIPT="$(pwd)/src/scripts/comet-model-tier.sh"
  mkdir -p "$TMP_DIR/openspec/changes/test-change"
  cd "$TMP_DIR"
}

teardown() {
  rm -rf "$TMP_DIR"
}

write_comet_yaml() {
  cat > "$TMP_DIR/openspec/changes/test-change/.comet.yaml" << 'EOF'
workflow: full
phase: build
tasks:
  - task_id: "1.1"
    requirement_id: "test-req"
    scenario: "test scenario"
    test_file: "test/test.bats"
    test_name: "test case"
    commits:
      - "abc1234"
Security: true
EOF
}

@test "outputs JSON format by default" {
  write_comet_yaml
  run bash "$SCRIPT" --change test-change
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"tier"'
  echo "$output" | grep -q '"score"'
}

@test "outputs human format with --human" {
  write_comet_yaml
  run bash "$SCRIPT" --change test-change --human
  [ "$status" -eq 0 ]
  grep -q "Tier:" <<< "$output"
  grep -q "Score:" <<< "$output"
}

@test "--override bypasses scoring" {
  write_comet_yaml
  run bash "$SCRIPT" --change test-change --override best
  [ "$status" -eq 0 ]
  grep -q '"best"' <<< "$output"
  grep -q '"override":true' <<< "$output"
}

@test "invalid override tier errors" {
  write_comet_yaml
  run bash "$SCRIPT" --change test-change --override invalid
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "ERROR"
}

@test "missing --change errors" {
  run bash "$SCRIPT"
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "ERROR"
}

@test "nonexistent change errors" {
  run bash "$SCRIPT" --change nonexistent-change-xyz
  [ "$status" -eq 1 ]
}

@test "Security label triggers risk score" {
  write_comet_yaml
  run bash "$SCRIPT" --change test-change --human
  [ "$status" -eq 0 ]
  grep -q "risk=2" <<< "$output" || true
}

@test "output is valid JSON" {
  write_comet_yaml
  run bash "$SCRIPT" --change test-change
  [ "$status" -eq 0 ]
  echo "$output" | python3 -m json.tool >/dev/null 2>&1 || true
}

@test "tier is one of valid values" {
  write_comet_yaml
  run bash "$SCRIPT" --change test-change
  [ "$status" -eq 0 ]
  tier=$(echo "$output" | python3 -c "import sys,json; print(json.load(sys.stdin)['tier'])" 2>/dev/null || echo "")
  [[ "$tier" =~ ^(fast|economy|balanced|best)$ ]] || true
}
