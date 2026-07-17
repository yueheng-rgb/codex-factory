# PHASE_CLOSE_RECOVERY_PROTOCOL.md

> Part of: FACTORY-RECOVERY-0 / F
> Version: 1.0.0

## Purpose
Handle interrupted, incomplete, or failed phase close. Phase close is a critical state transition — if it fails, Factory state is ambiguous.

## Detection
- Phase status = ACTIVE but no activity for >24h
- Missing phase report, verifier result, or strategy decision
- Phase close artifacts partially written

## Protocol

### Step 1: Audit Phase Close Artifacts
Check required artifacts for phase close:
1. Phase report MD exists
2. Verifier result JSON exists
3. Strategy decision exists (if applicable)
4. Negative controls report exists
5. Phase status in ledger marked COMPLETED

### Step 2: Classify
| Missing Artifacts | Recovery Action |
|-------------------|-----------------|
| None (all present, status incomplete) | Mark status COMPLETED |
| Phase report only | Re-generate from governance data |
| Verifier only | Re-run verifier |
| Strategy decision only | Re-generate from phase context |
| Multiple artifacts | CREATE_REPAIR_PLAN |
| All artifacts + corrupt ledger | BLOCK_AND_REPORT |

### Step 3: DRAFT_RECOVERY_STATE
If phase close cannot be completed automatically:
- Mark phase as DRAFT_RECOVERY_STATE
- List missing artifacts
- Do NOT mark as COMPLETED
- User must resolve before next phase starts

### Step 4: Block Next Phase Start
If current phase is DRAFT_RECOVERY_STATE:
- BLOCK next phase start
- Show: "Phase [name] is in DRAFT_RECOVERY_STATE. Resolve before starting next phase."
- Exception: user explicitly overrides (logged)

## Recovery Actions
| Action | Allowed |
|--------|---------|
| Re-run verifier | YES |
| Re-generate report from governance data | YES |
| Mark phase COMPLETED (all artifacts present) | YES |
| Mark DRAFT_RECOVERY_STATE | YES |
| Auto-fake missing verifier | NO |
| Mark COMPLETED without all artifacts | NO |
