---
comet_change: revert-restore
role: technical-design
canonical_spec: openspec
---

# revert-restore — Technical Design

## Flow

```
git revert <commit> → run tests → MUST FAIL → git revert HEAD (restore) → run tests → MUST PASS
```

Hard Gate: if tests PASS after revert, tests are invalid — BLOCKED.

## Interface

```bash
comet-revert-restore.sh --commit <hash> [--test-cmd "command"] [--task-label Security|Core|Critical]
```

Skips non-critical tasks (exit 0, "SKIP: not critical").

## Safety

- Requires clean worktree OR uses git worktree for isolation
- Revert conflicts → manual resolution hint, exit 0 with WARN
