# RECOVERY_FAILURE_MODE_CATALOG.md

> Part of: FACTORY-RECOVERY-0 / B
> Version: 1.0.0

## FM-01: Missing Project Registry
- **Severity**: CRITICAL
- **Detection**: `%USERPROFILE%\.codex-factory\project-registry.json` not found
- **Safe Action**: CREATE_REPAIR_PLAN — generate skeleton registry, populate from discovered `.codex-factory/` dirs
- **User Confirmation**: YES — must confirm each discovered project
- **Auto-Repair**: NO — requires user confirmation per project
- **Forbidden**: Auto-creating active projects without user confirmation

## FM-02: Corrupt Project Registry
- **Severity**: CRITICAL
- **Detection**: JSON parse failure on registry file
- **Safe Action**: BLOCK_AND_REPORT — show corruption location, offer restore from backup or rebuild
- **User Confirmation**: YES
- **Auto-Repair**: NO
- **Forbidden**: Silently using partial/corrupt registry

## FM-03: projectId Mismatch
- **Severity**: CRITICAL
- **Detection**: Mounted projectId != expected projectId from registry
- **Safe Action**: USER_CONFIRM_IDENTITY — show both identities, ask user to confirm correct one
- **User Confirmation**: YES (mandatory)
- **Auto-Repair**: NO
- **Forbidden**: Auto-confirming identity, silently switching project context

## FM-04: pathFingerprint Mismatch
- **Severity**: WARNING
- **Detection**: Computed pathFingerprint != stored pathFingerprint
- **Safe Action**: USER_CONFIRM_IDENTITY — "Project path changed. Same project moved?" 
- **User Confirmation**: YES
- **Auto-Repair**: NO — user confirms, then fingerprint updates
- **Forbidden**: Auto-accepting changed path as same project

## FM-05: contentFingerprint Mismatch
- **Severity**: WARNING
- **Detection**: Computed contentFingerprint != stored
- **Safe Action**: Show warning, allow user to continue or investigate
- **User Confirmation**: Optional (warning only)
- **Auto-Repair**: Update fingerprint after user confirms
- **Forbidden**: Blocking project on content change alone

## FM-06: Stale Snapshot
- **Severity**: WARNING
- **Detection**: Snapshot older than 7 days
- **Safe Action**: AUTO_REGENERATE_SNAPSHOT — regenerate from current state
- **User Confirmation**: NO (derived artifact, safe to regenerate)
- **Auto-Repair**: YES
- **Forbidden**: Treating stale snapshot as current evidence

## FM-07: Stale Attach Packet
- **Severity**: WARNING
- **Detection**: Attach packet older than 7 days
- **Safe Action**: AUTO_REGENERATE_ATTACH_PACKET
- **User Confirmation**: NO (derived)
- **Auto-Repair**: YES
- **Forbidden**: Mounting stale packet as current context

## FM-08: Missing Phase Ledger
- **Severity**: CRITICAL
- **Detection**: Phase ledger file not found
- **Safe Action**: CREATE_REPAIR_PLAN — reconstruct from phase reports and verifier results
- **User Confirmation**: YES
- **Auto-Repair**: NO — must confirm reconstructed state
- **Forbidden**: Auto-creating fake phase history

## FM-09: Corrupt Phase Ledger
- **Severity**: CRITICAL
- **Detection**: JSON parse failure
- **Safe Action**: BLOCK_AND_REPORT — show corruption, offer restore from backup
- **User Confirmation**: YES
- **Auto-Repair**: NO
- **Forbidden**: Silently dropping corrupt entries

## FM-10: Missing Verifier Result
- **Severity**: WARNING
- **Detection**: Current phase has no verifier result
- **Safe Action**: BLOCK_AND_REPORT — cannot auto-fake; suggest re-running verifier
- **User Confirmation**: N/A (block only)
- **Auto-Repair**: NO — verifier must be re-run
- **Forbidden**: Auto-faking verifier PASS, treating UI summary as verifier result

## FM-11: Missing Phase Report
- **Severity**: WARNING
- **Detection**: Phase has verifier but no report MD
- **Safe Action**: Show UNKNOWN_WITH_REASON in dashboard; suggest re-generation
- **User Confirmation**: Optional
- **Auto-Repair**: NO — report must be regenerated from phase data
- **Forbidden**: Auto-faking report content

## FM-12: Phase Close Interrupted
- **Severity**: WARNING
- **Detection**: Phase status = ACTIVE but no activity for >24h, or incomplete close artifacts
- **Safe Action**: CREATE_REPAIR_PLAN — mark as DRAFT_RECOVERY_STATE, list missing close artifacts
- **User Confirmation**: YES
- **Auto-Repair**: NO
- **Forbidden**: Marking interrupted close as full PASS

## FM-13: Governance JSON Malformed
- **Severity**: CRITICAL
- **Detection**: JSON parse failure on any governance file
- **Safe Action**: BLOCK_AND_REPORT — identify file, line, error; offer restore
- **User Confirmation**: YES
- **Auto-Repair**: NO
- **Forbidden**: Using partially parsed JSON

## FM-14: Manifest/Hash Mismatch
- **Severity**: CRITICAL
- **Detection**: File hash != manifest hash
- **Safe Action**: BLOCK_AND_REPORT — block release/package trust
- **User Confirmation**: YES
- **Auto-Repair**: NO — must investigate tampering
- **Forbidden**: Ignoring hash mismatch for releases

## FM-15: Agent Ledger Missing Entry
- **Severity**: WARNING
- **Detection**: Agent output file exists but no corresponding ledger entry
- **Safe Action**: Show in dashboard; mark as ORPHAN_OUTPUT
- **User Confirmation**: Optional
- **Auto-Repair**: NO — cannot retroactively create ledger entry
- **Forbidden**: Auto-creating fake ledger entries

## FM-16: Agent Output with Wrong projectId
- **Severity**: WARNING
- **Detection**: Agent output projectId != current projectId
- **Safe Action**: Mark FOREIGN_CONTEXT in dashboard; DO NOT accept
- **User Confirmation**: N/A (block only)
- **Auto-Repair**: NO
- **Forbidden**: Accepting foreign agent output as current

## FM-17: Cleanup State Ambiguous
- **Severity**: WARNING
- **Detection**: Pending cleanup plan exists but project identity unconfirmed
- **Safe Action**: PLAN only; require identity confirmation before execution
- **User Confirmation**: YES
- **Auto-Repair**: NO
- **Forbidden**: Executing cleanup without confirmed project identity

## FM-18: Archived/Frozen/Deleted Mounted Incorrectly
- **Severity**: CRITICAL
- **Detection**: Project status != ACTIVE/PAUSED but mounted as writable
- **Safe Action**: BLOCK_AND_REPORT — force status to correct mount permissions
- **User Confirmation**: YES
- **Auto-Repair**: NO
- **Forbidden**: Allowing writes to archived/frozen/deleted projects

## FM-19: Foreign Context Mounted as Current
- **Severity**: CRITICAL
- **Detection**: FOREIGN_PROJECT_CONTEXT marker found in active context
- **Safe Action**: BLOCK_AND_REPORT — demote to reference-only, warn user
- **User Confirmation**: YES
- **Auto-Repair**: NO — user must explicitly approve promoting foreign context
- **Forbidden**: Silently promoting foreign context to current

## FM-20: Dashboard Reports CORRUPT_OR_INCONSISTENT
- **Severity**: CRITICAL
- **Detection**: Dashboard health indicators show CRITICAL
- **Safe Action**: Run full recovery assessment, generate recovery plan
- **User Confirmation**: YES
- **Auto-Repair**: NO — only after recovery plan approved
- **Forbidden**: Ignoring dashboard CRITICAL and continuing
