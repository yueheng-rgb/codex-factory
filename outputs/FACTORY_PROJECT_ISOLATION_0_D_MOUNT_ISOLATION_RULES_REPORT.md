# FACTORY-PROJECT-ISOLATION-0 — D: Mount Isolation Rules Report

> Phase: FACTORY-PROJECT-ISOLATION-0
> Section: D — Mount Isolation Rules
> Date: 2026-06-29

## Deliverables

| File | Path |
|------|------|
| Rules Doc | `factory-isolation/MOUNT_ISOLATION_RULES.md` |
| Governance JSON | `governance/factory-isolation/factory-project-isolation-0-mount-isolation-rules.json` |

## Summary

Defines 5 mount validation rules:
1. Attach Packet must match projectId + pathFingerprint
2. Snapshot must match projectId
3. Phase ledger must match projectId
4. Foreign risk/blocker → FOREIGN_PROJECT_CONTEXT (view only)
5. Foreign context never mounted as current state

Also defines the 8-step Mount Gate Sequence and cross-project (global) artifact rules.
