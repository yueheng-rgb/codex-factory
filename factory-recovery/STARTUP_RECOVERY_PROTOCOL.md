# STARTUP_RECOVERY_PROTOCOL.md

> Part of: FACTORY-RECOVERY-0 / E
> Version: 1.0.0

## Purpose
Define what happens when Factory starts and detects unhealthy state. Runs after DEFAULT_FACTORY_STARTUP_PROTOCOL Step 4 (Bootstrap).

## Protocol Steps

### Step 1: Health Scan
Run dashboard health assessment (all 7 categories from STATE-DASHBOARD-0).

### Step 2: Classify Findings
Categorize each finding against Failure Mode Catalog (FM-01 through FM-20).

### Step 3: Determine Recovery Level
| Dashboard Health | Recovery Level |
|-----------------|----------------|
| 🟢 HEALTHY | RECOVERY_LEVEL_0 — none needed |
| 🟡 WARNING (1-2) | RECOVERY_LEVEL_1 — auto-fix derived only |
| 🟡 WARNING (3+) | RECOVERY_LEVEL_2 — generate repair plan |
| 🔴 CRITICAL (any) | RECOVERY_LEVEL_3 — block + repair plan |

### Step 4: Execute Per-Level

#### RECOVERY_LEVEL_0
- No action. Proceed normally.

#### RECOVERY_LEVEL_1
- AUTO_REBUILD_DERIVED_CACHE
- AUTO_REGENERATE_SNAPSHOT (if stale)
- AUTO_REGENERATE_ATTACH_PACKET (if stale)
- AUTO_REINDEX
- Report: "Auto-repaired {N} derived artifacts."

#### RECOVERY_LEVEL_2
- CREATE_REPAIR_PLAN
- Show plan to user
- Do NOT auto-execute
- User confirms → execute plan items
- User declines → continue with warnings

#### RECOVERY_LEVEL_3
- BLOCK_AND_REPORT
- CREATE_REPAIR_PLAN (mandatory)
- Block further Factory operations until:
  - User confirms identity (if FM-03/04)
  - Corrupt files restored (if FM-02/09/13)
  - Foreign context demoted (if FM-19)
  - Critical resolution confirmed

### Step 5: Recovery Report
Output recovery summary:
```
## Recovery Summary
- **Level:** RECOVERY_LEVEL_{N}
- **Findings:** {count}
- **Auto-Repaired:** {count} derived artifacts
- **Requires Confirmation:** {count} items
- **Blocked:** {isBlocked}
- **Plan:** {planPath or "N/A"}
```

## Anti-Patterns
- ❌ Skipping health scan on startup
- ❌ Auto-executing RECOVERY_LEVEL_3
- ❌ Auto-faking missing verifier
- ❌ Silently promoting foreign context
- ❌ Continuing with CRITICAL dashboard health
