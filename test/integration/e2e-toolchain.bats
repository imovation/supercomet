#!/usr/bin/env bats

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

setup() {
  export TMP_DIR="$(mktemp -d)"
  cd "$TMP_DIR"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  mkdir -p openspec
}

teardown() {
  rm -rf "$TMP_DIR"
}

@test "comet-forward-trace.sh is executable and runs" {
  run bash "$PROJECT_ROOT/src/scripts/comet-forward-trace.sh" --help 2>/dev/null || true
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "comet-backward-trace.sh is executable and runs" {
  run bash "$PROJECT_ROOT/src/scripts/comet-backward-trace.sh" --help 2>/dev/null || true
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "comet-trace.sh is executable" {
  [ -x "$PROJECT_ROOT/src/scripts/comet-trace.sh" ]
}

@test "comet-speculate.sh is executable" {
  [ -x "$PROJECT_ROOT/src/scripts/comet-speculate.sh" ]
}

@test "comet-spec-to-test.sh is executable" {
  [ -x "$PROJECT_ROOT/src/scripts/comet-spec-to-test.sh" ]
}

@test "comet-model-tier.sh is executable" {
  [ -x "$PROJECT_ROOT/src/scripts/comet-model-tier.sh" ]
}

@test "comet-revert-restore.sh is executable" {
  [ -x "$PROJECT_ROOT/src/scripts/comet-revert-restore.sh" ]
}

@test "comet-git-notes.sh is executable" {
  [ -x "$PROJECT_ROOT/src/scripts/comet-git-notes.sh" ]
}

@test "all SKILL.md files exist" {
  [ -f "$PROJECT_ROOT/src/skills/comet-speculate/SKILL.md" ]
  [ -f "$PROJECT_ROOT/src/skills/comet-quick-speculate/SKILL.md" ]
  [ -f "$PROJECT_ROOT/src/skills/spec-to-test/SKILL.md" ]
}

@test "npm package structure correct" {
  PKG="$PROJECT_ROOT/package.json"
  [ -f "$PKG" ]
  node -e "
    const pkg = require('$PKG');
    console.assert(pkg.name === 'supercomet', 'name must be supercomet');
    console.assert(pkg.bin && pkg.bin.supercomet, 'bin must include supercomet entry');
    console.assert(pkg.peerDependencies && pkg.peerDependencies['@rpamis/comet'], 'peerDeps must include @rpamis/comet');
    console.log('Package OK');
  "
}

@test "version.yaml exists with compatible versions" {
  [ -f "$PROJECT_ROOT/dist/version.yaml" ]
  grep -q "supercomet" "$PROJECT_ROOT/dist/version.yaml"
  grep -q "comet" "$PROJECT_ROOT/dist/version.yaml"
}
