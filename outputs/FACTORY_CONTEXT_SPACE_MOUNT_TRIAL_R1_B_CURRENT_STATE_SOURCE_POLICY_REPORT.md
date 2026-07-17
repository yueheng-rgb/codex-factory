# FACTORY-CONTEXT-SPACE-MOUNT-TRIAL-R1 — Current-State Source of Truth Policy Report

**Date**: 2026-06-28
**Phase**: FACTORY-CONTEXT-SPACE-MOUNT-TRIAL-R1
**Sub-step**: B — Current-State Source of Truth Policy

---

## 1. Problem Solved

The Mount Trial exposed that mount.ps1 reads `current_phase` directly from `conversation-space.json` without cross-referencing higher-priority sources (verifier results, phase ledger). When the master state file is stale, the Attach Packet inherits stale state.

## 2. Policy Hierarchy (Priority Descending)

| Level | Source | Trust Tier | Rule |
|-------|--------|-----------|------|
| 1 (Highest) | Verifier JSON with PASS | TIER-1 | Canonical truth; no lower source can override |
| 2 | Phase ledger latest completed entry | TIER-1 | Determines lastCompletedPhase |
| 3 | current-factory-state.json currentTrustedPhase | TIER-1 | Must be consistent with verifier |
| 4 | Active thread currentPhase | TIER-2 | What is currently being worked on |
| 5 | Direction guard nextRecommendedPhase | TIER-2 | Recommends but does not override verifier |
| 6 | Attach Packet (derived) | TIER-3 | DERIVED, not source of truth |
| 7 (Lowest) | Compressed summaries, legacy rotation | TIER-4 | Archived warnings only |

## 3. Override Rules

- **OVERRIDE-001**: PASS by verifier → cannot show as pending
- **OVERRIDE-002**: Legacy risks → archived unless active blocker confirmed
- **OVERRIDE-003**: Attach Packet must carry freshnessStatus + sourceOfTruthPaths
- **OVERRIDE-004**: current_phase == lastCompletedPhase → STALE flag

## 4. State Field Mapping

| Field | Source |
|-------|--------|
| lastCompletedPhase | phase-ledger.json latest completed entry |
| currentActivePhase | active-thread.json or direction-guard activeValidationPhase |
| nextRecommendedPhase | direction-guard.json nextRecommendedPhase |
| archivedLegacyWarnings | legacy risks where status != ACTIVE_BLOCKER |
| activeBlockers | risk-ledger.jsonl activeRisk=true AND blocker=true |

## 5. Verdict

**Policy defined. Priority hierarchy established. Mount Protocol must be updated to respect this hierarchy.**
