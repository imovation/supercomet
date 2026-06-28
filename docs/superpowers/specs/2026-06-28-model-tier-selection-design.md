---
comet_change: model-tier-selection
role: technical-design
canonical_spec: openspec
archived-with: 2026-06-28-model-tier-selection
status: final
---

# model-tier-selection — Technical Design

## Architecture

```
.comet.yaml (task metadata)
  │
  ▼
comet-model-tier.sh
  ├─ Score: file_count + risk_label + plan_detail
  ├─ Map: 0-1→fast, 2-3→economy, 4-5→balanced, 6+→best
  ├─ Output: JSON | human-readable
  └─ Override: --override <tier>
```

## Interface

```bash
comet-model-tier.sh --task-id 1.1 --change <change-name> [--human] [--override <tier>]
```

## Decisions

- Scores from .comet.yaml task fields: files count, risk label presence (Security/Core/Critical), plan code detail
- Output formats: default JSON, --human for readable
- Degradation: no model_tier field → output default tier with INFO
- Override: --override bypasses scoring
