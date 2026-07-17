# RECOVERY_DECISION_MATRIX.md

> Part of: FACTORY-RECOVERY-0 / C
> Version: 1.0.0

## Actions

| Action | Meaning | Auto-Allowed |
|--------|---------|-------------|
| AUTO_REBUILD_DERIVED_CACHE | Rebuild computed cache from primary sources | YES |
| AUTO_REGENERATE_SNAPSHOT | Regenerate snapshot from current state | YES |
| AUTO_REGENERATE_ATTACH_PACKET | Regenerate attach packet from current context | YES |
| AUTO_REINDEX | Rebuild index files from source data | YES |
| USER_CONFIRM_IDENTITY | Ask user to confirm project identity | NO |
| USER_CONFIRM_MIGRATION | Ask user to confirm migration path | NO |
| BLOCK_AND_REPORT | Stop and report issue to user | NO |
| RESTORE_FROM_ARCHIVE | Restore file from backup/archive | NO |
| CREATE_REPAIR_PLAN | Generate non-destructive repair plan | NO |
| MANUAL_REVIEW_REQUIRED | Escalate — cannot auto-decide | NO |
| DO_NOT_REPAIR | Explicitly refuse repair | NO |

## Matrix

| FM | Action | Rationale |
|----|--------|-----------|
| FM-01 Missing Registry | CREATE_REPAIR_PLAN | Cannot auto-create; user must confirm each project |
| FM-02 Corrupt Registry | BLOCK_AND_REPORT + RESTORE_FROM_ARCHIVE | Corruption must be investigated |
| FM-03 projectId Mismatch | USER_CONFIRM_IDENTITY | Identity is user's decision |
| FM-04 pathFingerprint Mismatch | USER_CONFIRM_IDENTITY | Path change may be legitimate or error |
| FM-05 contentFingerprint Mismatch | Warning only (no block) | Content changes are normal |
| FM-06 Stale Snapshot | AUTO_REGENERATE_SNAPSHOT | Derived artifact, safe |
| FM-07 Stale Attach Packet | AUTO_REGENERATE_ATTACH_PACKET | Derived artifact, safe |
| FM-08 Missing Phase Ledger | CREATE_REPAIR_PLAN | Reconstruct from phase reports |
| FM-09 Corrupt Phase Ledger | BLOCK_AND_REPORT | Cannot use corrupt ledger |
| FM-10 Missing Verifier | BLOCK_AND_REPORT (DO_NOT_REPAIR) | Verifier must be re-run |
| FM-11 Missing Phase Report | Show UNKNOWN_WITH_REASON | Cannot auto-fake content |
| FM-12 Phase Close Interrupted | CREATE_REPAIR_PLAN → DRAFT_RECOVERY_STATE | List missing artifacts |
| FM-13 Malformed Governance JSON | BLOCK_AND_REPORT | Parsing failure is critical |
| FM-14 Manifest/Hash Mismatch | BLOCK_AND_REPORT | Tampering must be investigated |
| FM-15 Agent Ledger Missing Entry | Warning (ORPHAN_OUTPUT) | Cannot retroactively create |
| FM-16 Wrong projectId Agent Output | BLOCK (FOREIGN_CONTEXT) | Never accept foreign |
| FM-17 Cleanup Ambiguous | PLAN only + identity confirm | Never execute without identity |
| FM-18 Wrong Mount Status | BLOCK_AND_REPORT | Force correct permissions |
| FM-19 Foreign Context as Current | BLOCK_AND_REPORT | Demote to reference |
| FM-20 Dashboard CRITICAL | CREATE_REPAIR_PLAN | Full recovery assessment |

## Rules
- Derived cache/snapshot/attach/index → safe to auto-regenerate
- Identity/fingerprint → user must confirm
- Missing verifier → cannot auto-fake; must re-run
- Corrupt evidence → cannot silently repair
- Cross-project conflict → must block, never auto-resolve
- Cleanup → destructive repair forbidden by default
