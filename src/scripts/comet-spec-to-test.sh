#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: comet-spec-to-test.sh <spec-file> [options]

Options:
  --framework FRAMEWORK  Target framework: jest, vitest, pytest, go-test
  --output PATH          Write output to file (default: stdout)
  --help                 Show this help

USAGE
  exit 0
}

SPEC_FILE=""
FRAMEWORK=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --framework) FRAMEWORK="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    --help) usage ;;
    -*)
      echo "ERROR: Unknown option: $1" >&2
      usage
      ;;
    *)
      SPEC_FILE="$1"
      shift
      ;;
  esac
done

if [ -z "$SPEC_FILE" ]; then
  echo "ERROR: spec file path is required" >&2
  usage
fi

if [ ! -f "$SPEC_FILE" ]; then
  echo "ERROR: Spec file not found: $SPEC_FILE" >&2
  exit 1
fi

VALID_FRAMEWORKS="jest vitest pytest go-test"
if [ -n "$FRAMEWORK" ]; then
  VALID=0
  for fw in $VALID_FRAMEWORKS; do
    [ "$FRAMEWORK" = "$fw" ] && VALID=1
  done
  if [ "$VALID" -eq 0 ]; then
    echo "WARN: Unknown framework '$FRAMEWORK', using generic format. Valid: $VALID_FRAMEWORKS" >&2
    FRAMEWORK="generic"
  fi
else
  FRAMEWORK="generic"
fi

sanitize_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//'
}

SCENARIO_COUNT=0
IN_SCENARIO=0
SCENARIO_NAME=""
STEPS=()

GEN_OUTPUT=""

while IFS= read -r line; do
  if echo "$line" | grep -qE '^#### Scenario:'; then
    IN_SCENARIO=1
    SCENARIO_NAME=$(echo "$line" | sed 's/^#### Scenario: *//')
    SCENARIO_COUNT=$((SCENARIO_COUNT + 1))
    STEPS=()
    continue
  fi

  if [ "$IN_SCENARIO" -eq 1 ]; then
    if echo "$line" | grep -qE '^#### '; then
      IN_SCENARIO=0
      continue
    fi

    step=$(echo "$line" | sed -n 's/^.*\*\*\(WHEN\|THEN\|GIVEN\|AND\)\*\* *\(.*\)/\1 \2/p')
    if [ -n "$step" ]; then
      STEPS+=("$step")
      continue
    fi
  fi
done < "$SPEC_FILE"

if [ "$SCENARIO_COUNT" -eq 0 ]; then
  echo "WARN: No Scenario blocks found in $SPEC_FILE" >&2
  case "$FRAMEWORK" in
    jest|vitest)
      GEN_OUTPUT="// [MANUAL] No scenarios found — test skeleton cannot be generated"
      ;;
    pytest)
      GEN_OUTPUT="# [MANUAL] No scenarios found — test skeleton cannot be generated"
      ;;
    go-test)
      GEN_OUTPUT="// [MANUAL] No scenarios found — test skeleton cannot be generated"
      ;;
    *)
      GEN_OUTPUT="[MANUAL] No scenarios found — test skeleton cannot be generated"
      ;;
  esac
else
  IN_SCENARIO=0
  SCENARIO_NAME=""
  STEPS=()

  while IFS= read -r line; do
    if echo "$line" | grep -qE '^#### Scenario:'; then
      if [ "$IN_SCENARIO" -eq 1 ] && [ -n "$SCENARIO_NAME" ]; then
        SANITIZED=$(sanitize_name "$SCENARIO_NAME")

        case "$FRAMEWORK" in
          jest|vitest)
            GEN_OUTPUT+="// Scenario: $SCENARIO_NAME"$'\n'
            GEN_OUTPUT+="it('scenario: $SANITIZED', () => {"$'\n'
            for s in "${STEPS[@]}"; do
              GEN_OUTPUT+="  // $s"$'\n'
            done
            GEN_OUTPUT+="  // TODO: implement test logic"$'\n'
            GEN_OUTPUT+="});"$'\n'
            GEN_OUTPUT+=""$'\n'
            ;;
          pytest)
            PYNAME=$(echo "$SANITIZED" | tr '-' '_')
            GEN_OUTPUT+="# Scenario: $SCENARIO_NAME"$'\n'
            GEN_OUTPUT+="def test_${PYNAME}():"$'\n'
            for s in "${STEPS[@]}"; do
              GEN_OUTPUT+="    # $s"$'\n'
            done
            GEN_OUTPUT+="    # TODO: implement test logic"$'\n'
            GEN_OUTPUT+="    pass"$'\n'
            GEN_OUTPUT+=""$'\n'
            ;;
          go-test)
            GONAME=$(echo "$SANITIZED" | sed 's/-\([a-z]\)/\U\1/g' | sed 's/^./\U&/')
            GEN_OUTPUT+="// Scenario: $SCENARIO_NAME"$'\n'
            GEN_OUTPUT+="func Test${GONAME}(t *testing.T) {"$'\n'
            for s in "${STEPS[@]}"; do
              GEN_OUTPUT+="  // $s"$'\n'
            done
            GEN_OUTPUT+="  // TODO: implement test logic"$'\n'
            GEN_OUTPUT+="}"$'\n'
            GEN_OUTPUT+=""$'\n'
            ;;
          generic)
            GEN_OUTPUT+="- Scenario: $SCENARIO_NAME"$'\n'
            for s in "${STEPS[@]}"; do
              GEN_OUTPUT+="  - $s"$'\n'
            done
            GEN_OUTPUT+="  - TODO: implement test logic"$'\n'
            GEN_OUTPUT+=""$'\n'
            ;;
        esac
      fi

      IN_SCENARIO=1
      SCENARIO_NAME=$(echo "$line" | sed 's/^#### Scenario: *//')
      STEPS=()
      continue
    fi

    if [ "$IN_SCENARIO" -eq 1 ]; then
      if echo "$line" | grep -qE '^#### '; then
        IN_SCENARIO=0
        continue
      fi

      step=$(echo "$line" | sed -n 's/^.*\*\*\(WHEN\|THEN\|GIVEN\|AND\)\*\* *\(.*\)/\1 \2/p')
      if [ -n "$step" ]; then
        STEPS+=("$step")
      fi
    fi
  done < "$SPEC_FILE"

  if [ "$IN_SCENARIO" -eq 1 ] && [ -n "$SCENARIO_NAME" ]; then
    SANITIZED=$(sanitize_name "$SCENARIO_NAME")

    case "$FRAMEWORK" in
      jest|vitest)
        GEN_OUTPUT+="// Scenario: $SCENARIO_NAME"$'\n'
        GEN_OUTPUT+="it('scenario: $SANITIZED', () => {"$'\n'
        for s in "${STEPS[@]}"; do
          GEN_OUTPUT+="  // $s"$'\n'
        done
        GEN_OUTPUT+="  // TODO: implement test logic"$'\n'
        GEN_OUTPUT+="});"$'\n'
        GEN_OUTPUT+=""$'\n'
        ;;
      pytest)
        PYNAME=$(echo "$SANITIZED" | tr '-' '_')
        GEN_OUTPUT+="# Scenario: $SCENARIO_NAME"$'\n'
        GEN_OUTPUT+="def test_${PYNAME}():"$'\n'
        for s in "${STEPS[@]}"; do
          GEN_OUTPUT+="    # $s"$'\n'
        done
        GEN_OUTPUT+="    # TODO: implement test logic"$'\n'
        GEN_OUTPUT+="    pass"$'\n'
        GEN_OUTPUT+=""$'\n'
        ;;
      go-test)
        GONAME=$(echo "$SANITIZED" | sed 's/-\([a-z]\)/\U\1/g' | sed 's/^./\U&/')
        GEN_OUTPUT+="// Scenario: $SCENARIO_NAME"$'\n'
        GEN_OUTPUT+="func Test${GONAME}(t *testing.T) {"$'\n'
        for s in "${STEPS[@]}"; do
          GEN_OUTPUT+="  // $s"$'\n'
        done
        GEN_OUTPUT+="  // TODO: implement test logic"$'\n'
        GEN_OUTPUT+="}"$'\n'
        GEN_OUTPUT+=""$'\n'
        ;;
      generic)
        GEN_OUTPUT+="- Scenario: $SCENARIO_NAME"$'\n'
        for s in "${STEPS[@]}"; do
          GEN_OUTPUT+="  - $s"$'\n'
        done
        GEN_OUTPUT+="  - TODO: implement test logic"$'\n'
        GEN_OUTPUT+=""$'\n'
        ;;
    esac
  fi
fi

if [ -n "$OUTPUT" ]; then
  OUTPUT_DIR=$(dirname "$OUTPUT")
  mkdir -p "$OUTPUT_DIR" 2>/dev/null || true
  echo "$GEN_OUTPUT" > "$OUTPUT"
else
  echo "$GEN_OUTPUT"
fi

exit 0
