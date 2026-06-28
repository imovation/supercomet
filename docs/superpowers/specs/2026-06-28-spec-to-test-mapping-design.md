---
comet_change: spec-to-test-mapping
role: technical-design
canonical_spec: openspec
---

# spec-to-test-mapping — Technical Design

## Architecture

```
spec.md (#### Scenario blocks)
  │
  ▼
comet-spec-to-test.sh
  ├─ Parse: extract GIVEN/WHEN/THEN steps
  ├─ Detect: framework (Jest/Vitest/Pytest/Go-test/generic)
  ├─ Generate: test skeleton function
  └─ Output: stdout (pipe to file)
```

## Components

### comet-spec-to-test.sh

**Interface**:
```bash
comet-spec-to-test.sh <spec-file> [--framework jest|vitest|pytest|go-test] [--output <file>]
```

**Framework detection precedence**:
1. `--framework` explicit flag
2. `package.json` → jest/vitest dependency
3. File extension in test/ dir → `.py` (pytest), `_test.go` (go-test)
4. Default: generic comment block format

**Skeleton formats**:

Jest/Vitest:
```javascript
// Scenario: <name>
it('scenario: <kebab-name>', () => {
  // GIVEN <step>
  // WHEN <step>
  // THEN <step>
  // TODO: implement test logic
});
```

Pytest:
```python
# Scenario: <name>
def test_<snake_name>():
    # GIVEN <step>
    # WHEN <step>
    # THEN <step>
    # TODO: implement test logic
    pass
```

**Degradation**:
- No Scenario blocks found → exit 0, "INFO: no scenarios found"
- Unparseable Scenario → output [MANUAL] comment, WARN stderr, continue
- Unknown framework → use generic format

## Testing

- BATS: valid spec input → correct skeleton format per framework
- BATS: empty spec → graceful exit
- BATS: malformed spec → [MANUAL] degradation
