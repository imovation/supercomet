---
comet_change: comet-speculate
role: technical-design
canonical_spec: openspec
---

# comet-speculate — Technical Design

## Architecture

```
Agent (reasoning)
  │
  ├── writes YAML input ──→ /tmp/explore-input.yaml
  │                                │
  │                   comet-speculate.sh
  │                     ┌──────────────┐
  │                     │ validate     │
  │                     │ transform    │
  │                     │ write        │
  │                     └──────┬───────┘
  │                            │
  └── detects & reads ←── openspec/explore-findings.md
                              (in /comet-open)
```

## Components

### 1. comet-speculate.sh

**Location**: `src/scripts/comet-speculate.sh`

**Interface**:
```bash
# Full mode (2-3 options comparison)
comet-speculate.sh --mode full --from-file <yaml-path>
comet-speculate.sh --mode full --from-file <yaml-path> --output <path>

# Quick mode (recommendation only)
comet-speculate.sh --mode quick --from-file <yaml-path>
```

**YAML Input Format (full mode)**:
```yaml
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
```

**YAML Input Format (quick mode)**:
```yaml
topic: "Feature X 的实现方式"
summary: "一句话概述"
recommendation: "方案 A"
reason: "因为 xxx"
```

**Markdown Output** (`openspec/explore-findings.md`):
```markdown
# Explore Findings

- **Topic**: Feature X 的实现方式
- **Mode**: full
- **Date**: 2026-06-28
- **Version**: 1

## Summary

一句话概述

## Options

### Option 1: 方案 A

- **Pros**: 优点1, 优点2
- **Cons**: 缺点1
- **Effort Estimate**: 3天

### Option 2: 方案 B

- **Pros**: 优点1
- **Cons**: 缺点1, 缺点2
- **Effort Estimate**: 5天

## Recommendation

**推荐方案 A** — 因为 xxx
```

**Validation rules**:
- Topic must be non-empty string
- Full mode: 2-3 options, each with non-empty name, pros, cons, effort
- Quick mode: recommendation and reason must be non-empty
- Validation failure → WARN to stderr, exit code 1

**Degradation**:
- YAML parse error → WARN "[MANUAL] YAML parse failed", exit 0
- Missing optional fields (effort for quick mode) → INFO, skip field
- Missing required fields → WARN, exit 1 but no block on workflow

### 2. SKILL.md Files

**comet-speculate/SKILL.md** (`src/skills/comet-speculate/SKILL.md`):
- Defines when agent should invoke full exploration mode
- Guides agent through: clarifying topic → proposing 2-3 approaches → comparing trade-offs → writing YAML → calling comet-speculate.sh
- Documents YAML schema

**comet-quick-speculate/SKILL.md** (`src/skills/comet-quick-speculate/SKILL.md`):
- Defines when agent should invoke quick exploration mode
- Guides agent through: clarifying topic → proposing single recommendation → calling comet-speculate.sh --mode quick

### 3. /comet-open Integration

Modify `/comet-open` SKILL.md step 0:
- Before proposal creation, check existence of `openspec/explore-findings.md`
- If found, read and inject Summary + Recommendation as context for proposal drafting
- Include attribution: "基于 explore-findings.md 探索结果"
- Version detection: if version > 1, degrade gracefully

## Data Flow

```
1. User triggers /comet-speculate
2. Agent follows SKILL.md: asks clarifying questions
3. Agent synthesizes YAML input
4. Agent calls: comet-speculate.sh --mode full --from-file /tmp/explore.yaml
5. Script validates YAML, generates openspec/explore-findings.md
6. User calls /comet-open
7. /comet-open detects explore-findings.md, injects context
8. Proposal is drafted with exploration insights
```

## Error Handling

| Scenario | Behavior |
|----------|----------|
| YAML parse error | WARN stderr, exit 0, no file written |
| Missing required field | WARN stderr, exit 1, partial file written |
| Too few options (full mode) | WARN stderr, exit 1 |
| Too many options (>3 in full mode) | WARN stderr but continue, exit 0 |
| Output directory not writable | ERROR stderr, exit 1 |
| YAML tool not available | Degrade to basic grep-based parsing |

## Testing

### Unit Tests (BATS)

- `test_lib_yaml.sh`: YAML validation functions
  - Valid full-mode YAML → pass
  - Valid quick-mode YAML → pass
  - Missing topic → fail
  - Full mode with 1 option → fail (requires 2-3)
  - Full mode with 4 options → warn but pass
  - Empty pros/cons list → warn but pass
  - Special characters in text → handled correctly

### Integration Test

- Write explore-findings.md via script
- Verify /comet-open detection logic
- Verify correct markdown output format
