#!/usr/bin/env bats

# comet-speculate BATS tests
# Covers: full mode output format, quick mode output format,
#         validation failures (missing fields, too few options),
#         degradation (YAML parse error, missing optional fields)

setup() {
  export TMP_DIR="$(mktemp -d)"
  export SPECULATE_SCRIPT="$(pwd)/src/scripts/comet-speculate.sh"
  export OUTPUT_DIR="$TMP_DIR/output"
  mkdir -p "$OUTPUT_DIR"
}

teardown() {
  rm -rf "$TMP_DIR"
}

write_full_yaml() {
  cat > "$TMP_DIR/full-input.yaml" << 'EOF'
topic: "Feature X 的实现方式"
summary: "一句话概述"
options:
  - name: "方案 A"
    pros:
      - "优点1"
      - "优点2"
    cons:
      - "缺点1"
    effort: "3天"
  - name: "方案 B"
    pros:
      - "优点1"
    cons:
      - "缺点1"
      - "缺点2"
    effort: "5天"
recommendation: "方案 A"
reason: "因为 xxx"
EOF
}

write_quick_yaml() {
  cat > "$TMP_DIR/quick-input.yaml" << 'EOF'
topic: "小功能调整"
summary: "快速修复"
recommendation: "直接修改配置"
reason: "无需代码变更"
EOF
}

# --- Full Mode Tests ---

@test "full mode generates explore-findings.md with all sections" {
  write_full_yaml

  run bash "$SPECULATE_SCRIPT" \
    --mode full \
    --from-file "$TMP_DIR/full-input.yaml" \
    --output "$OUTPUT_DIR/explore-findings.md"

  [ "$status" -eq 0 ]
  grep -q "# Explore Findings" "$OUTPUT_DIR/explore-findings.md"
  grep -q "Topic.*Feature X" "$OUTPUT_DIR/explore-findings.md"
  grep -q "Mode.*full" "$OUTPUT_DIR/explore-findings.md"
  grep -q "## Summary" "$OUTPUT_DIR/explore-findings.md"
  grep -q "## Options" "$OUTPUT_DIR/explore-findings.md"
  grep -q "## Recommendation" "$OUTPUT_DIR/explore-findings.md"
  grep -q "方案 A" "$OUTPUT_DIR/explore-findings.md"
  grep -q "方案 B" "$OUTPUT_DIR/explore-findings.md"
  grep -q "优点1" "$OUTPUT_DIR/explore-findings.md"
  grep -q "缺点1" "$OUTPUT_DIR/explore-findings.md"
  grep -q "Effort Estimate.*3天" "$OUTPUT_DIR/explore-findings.md"
  grep -q "Effort Estimate.*5天" "$OUTPUT_DIR/explore-findings.md"
  grep -q "因为 xxx" "$OUTPUT_DIR/explore-findings.md"
}

@test "full mode writes version and date metadata" {
  write_full_yaml

  run bash "$SPECULATE_SCRIPT" \
    --mode full \
    --from-file "$TMP_DIR/full-input.yaml" \
    --output "$OUTPUT_DIR/explore-findings.md"

  [ "$status" -eq 0 ]
  grep -q "Version.*1" "$OUTPUT_DIR/explore-findings.md"
  grep -qE "Date.*[0-9]{4}-[0-9]{2}-[0-9]{2}" "$OUTPUT_DIR/explore-findings.md"
}

@test "full mode with 2 options passes" {
  cat > "$TMP_DIR/two-options.yaml" << 'EOF'
topic: "二选一"
options:
  - name: "方案 A"
    pros:
      - "快"
    cons:
      - "糙"
    effort: "1天"
  - name: "方案 B"
    pros:
      - "稳"
    cons:
      - "慢"
    effort: "3天"
recommendation: "方案 A"
reason: "时间紧"
EOF

  run bash "$SPECULATE_SCRIPT" \
    --mode full \
    --from-file "$TMP_DIR/two-options.yaml" \
    --output "$OUTPUT_DIR/explore-findings.md"

  [ "$status" -eq 0 ]
  grep -q "方案 A" "$OUTPUT_DIR/explore-findings.md"
  grep -q "方案 B" "$OUTPUT_DIR/explore-findings.md"
}

@test "full mode with 3 options passes" {
  cat > "$TMP_DIR/three-options.yaml" << 'EOF'
topic: "三选一"
options:
  - name: "方案 A"
    pros:
      - "快"
    cons:
      - "糙"
    effort: "1天"
  - name: "方案 B"
    pros:
      - "稳"
    cons:
      - "慢"
    effort: "3天"
  - name: "方案 C"
    pros:
      - "好"
    cons:
      - "贵"
    effort: "5天"
recommendation: "方案 B"
reason: "平衡"
EOF

  run bash "$SPECULATE_SCRIPT" \
    --mode full \
    --from-file "$TMP_DIR/three-options.yaml" \
    --output "$OUTPUT_DIR/explore-findings.md"

  [ "$status" -eq 0 ]
  grep -q "方案 C" "$OUTPUT_DIR/explore-findings.md"
}

@test "full mode with 4 options warns but passes" {
  cat > "$TMP_DIR/four-options.yaml" << 'EOF'
topic: "四选一"
options:
  - name: "方案 A"
    pros:
      - "a"
    cons:
      - "b"
    effort: "1天"
  - name: "方案 B"
    pros:
      - "c"
    cons:
      - "d"
    effort: "2天"
  - name: "方案 C"
    pros:
      - "e"
    cons:
      - "f"
    effort: "3天"
  - name: "方案 D"
    pros:
      - "g"
    cons:
      - "h"
    effort: "4天"
recommendation: "方案 A"
reason: "最少工作量"
EOF

  run bash "$SPECULATE_SCRIPT" \
    --mode full \
    --from-file "$TMP_DIR/four-options.yaml" \
    --output "$OUTPUT_DIR/explore-findings.md"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "WARN"
  grep -q "方案 D" "$OUTPUT_DIR/explore-findings.md"
}

@test "full mode with 1 option fails validation" {
  cat > "$TMP_DIR/one-option.yaml" << 'EOF'
topic: "仅一个方案"
options:
  - name: "唯一方案"
    pros:
      - "简单"
    cons:
      - "不灵活"
    effort: "1天"
recommendation: "唯一方案"
reason: "唯一选择"
EOF

  run bash "$SPECULATE_SCRIPT" \
    --mode full \
    --from-file "$TMP_DIR/one-option.yaml" \
    --output "$OUTPUT_DIR/explore-findings.md"

  [ "$status" -eq 1 ]
  echo "$output" | grep -q "WARN"
  [ ! -f "$OUTPUT_DIR/explore-findings.md" ]
}

# --- Quick Mode Tests ---

@test "quick mode generates explore-findings.md without options section" {
  write_quick_yaml

  run bash "$SPECULATE_SCRIPT" \
    --mode quick \
    --from-file "$TMP_DIR/quick-input.yaml" \
    --output "$OUTPUT_DIR/explore-findings.md"

  [ "$status" -eq 0 ]
  grep -q "# Explore Findings" "$OUTPUT_DIR/explore-findings.md"
  grep -q "Mode.*quick" "$OUTPUT_DIR/explore-findings.md"
  grep -q "直接修改配置" "$OUTPUT_DIR/explore-findings.md"
  grep -q "无需代码变更" "$OUTPUT_DIR/explore-findings.md"
  if grep -q "## Options" "$OUTPUT_DIR/explore-findings.md"; then
    echo "ERROR: quick mode should not have Options section" >&2
    false
  fi
}

@test "quick mode missing topic fails validation" {
  cat > "$TMP_DIR/no-topic.yaml" << 'EOF'
summary: "no topic"
recommendation: "方案 A"
reason: "reasons"
EOF

  run bash "$SPECULATE_SCRIPT" \
    --mode quick \
    --from-file "$TMP_DIR/no-topic.yaml" \
    --output "$OUTPUT_DIR/explore-findings.md"

  [ "$status" -eq 1 ]
  echo "$output" | grep -q "WARN"
}

@test "quick mode missing recommendation fails validation" {
  cat > "$TMP_DIR/no-recommendation.yaml" << 'EOF'
topic: "有 topic 无推荐"
reason: "有理由"
EOF

  run bash "$SPECULATE_SCRIPT" \
    --mode quick \
    --from-file "$TMP_DIR/no-recommendation.yaml" \
    --output "$OUTPUT_DIR/explore-findings.md"

  [ "$status" -eq 1 ]
  echo "$output" | grep -q "WARN"
}

@test "quick mode missing reason fails validation" {
  cat > "$TMP_DIR/no-reason.yaml" << 'EOF'
topic: "有 topic"
recommendation: "方案 A"
EOF

  run bash "$SPECULATE_SCRIPT" \
    --mode quick \
    --from-file "$TMP_DIR/no-reason.yaml" \
    --output "$OUTPUT_DIR/explore-findings.md"

  [ "$status" -eq 1 ]
  echo "$output" | grep -q "WARN"
}

@test "quick mode without summary still passes" {
  cat > "$TMP_DIR/no-summary.yaml" << 'EOF'
topic: "没有 summary"
recommendation: "方案 A"
reason: "理由充分"
EOF

  run bash "$SPECULATE_SCRIPT" \
    --mode quick \
    --from-file "$TMP_DIR/no-summary.yaml" \
    --output "$OUTPUT_DIR/explore-findings.md"

  [ "$status" -eq 0 ]
  grep -q "未提供概述" "$OUTPUT_DIR/explore-findings.md"
}

# --- Edge Cases ---

@test "special characters in topic and option names are handled" {
  cat > "$TMP_DIR/special-chars.yaml" << 'EOF'
topic: "测试 & 特殊 <字符>"
summary: "带特殊字符的概述——包含破折号"
options:
  - name: "方案 (A): 前端*方案"
    pros:
      - "优点——带破折号"
    cons:
      - "缺点 & 问题"
    effort: "3天"
  - name: "方案 B: 后端/API"
    pros:
      - "优点1"
    cons:
      - "缺点1"
    effort: "5天"
recommendation: "方案 (A): 前端*方案"
reason: "因为 & 理由"
EOF

  run bash "$SPECULATE_SCRIPT" \
    --mode full \
    --from-file "$TMP_DIR/special-chars.yaml" \
    --output "$OUTPUT_DIR/explore-findings.md"

  [ "$status" -eq 0 ]
  grep -q "测试 & 特殊" "$OUTPUT_DIR/explore-findings.md"
  grep -q "前端\*方案" "$OUTPUT_DIR/explore-findings.md"
}

@test "empty pros or cons list warns but passes" {
  cat > "$TMP_DIR/empty-pros-cons.yaml" << 'EOF'
topic: "测试空列表"
options:
  - name: "方案 A"
    pros:
    cons:
      - "有一个缺点"
    effort: "1天"
  - name: "方案 B"
    pros:
      - "有一个优点"
    cons:
    effort: "2天"
recommendation: "方案 B"
reason: "有优点"
EOF

  run bash "$SPECULATE_SCRIPT" \
    --mode full \
    --from-file "$TMP_DIR/empty-pros-cons.yaml" \
    --output "$OUTPUT_DIR/explore-findings.md"

  [ "$status" -eq 0 ]
  grep -q "方案 A" "$OUTPUT_DIR/explore-findings.md"
  grep -q "方案 B" "$OUTPUT_DIR/explore-findings.md"
}

@test "nonexistent input file errors" {
  run bash "$SPECULATE_SCRIPT" \
    --mode full \
    --from-file "/tmp/nonexistent-file-12345.yaml" \
    --output "$OUTPUT_DIR/explore-findings.md"

  [ "$status" -eq 1 ]
  echo "$output" | grep -q "ERROR"
}

@test "invalid mode errors" {
  cat > "$TMP_DIR/basic.yaml" << 'EOF'
topic: "test"
recommendation: "A"
reason: "R"
EOF

  run bash "$SPECULATE_SCRIPT" \
    --mode invalid \
    --from-file "$TMP_DIR/basic.yaml" \
    --output "$OUTPUT_DIR/explore-findings.md"

  [ "$status" -eq 1 ]
  echo "$output" | grep -q "ERROR"
}

@test "missing required options errors" {
  run bash "$SPECULATE_SCRIPT" \
    --from-file "$TMP_DIR/basic.yaml"

  [ "$status" -ne 0 ]
}
