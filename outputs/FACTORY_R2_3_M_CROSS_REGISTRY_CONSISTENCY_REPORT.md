# R2.3-M Cross-Registry Consistency Report

## Findings: 13 WARN, 0 BLOCKERS

### Warnings

- CAP-SKILL-001~012: In capability-candidate-registry but have no skill packages. These are pre-R2.3 external candidates that were surveyed but never imported. Not a blocker — they are deferred candidates.
- CAP-SKILL-099: Ghost entry in registry (no corresponding skill).

### Healthy Registries

| Registry/Ledger | Status |
|------|:---:|
| capability-candidate-registry.jsonl | ✅ 97 entries |
| tool-candidate-registry.jsonl | ✅ 11 entries |
| skill-usage-index.jsonl | ✅ Active |
| tool-invocation-index.jsonl | ✅ Active |
| sandbox-session-index.jsonl | ✅ Active |

### Promotion Consistency

All 4 active skills have matching status between skill.json and capability registry.
