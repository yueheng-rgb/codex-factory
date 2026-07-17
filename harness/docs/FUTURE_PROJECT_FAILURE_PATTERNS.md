**Future Project Failure Patterns — Phase 6C-T0-R1**

This document catalogs failure patterns observed across Phase 6C (A through S2) that future real projects should expect and guard against.

---

## Pattern 1: PASS Report, PARTIAL Bundle

**Example**: Phase 6C-S2, Phase 6C-T0 initial

**Symptom**: Final report says PASS, but audit ZIP lacks key evidence.
**Root cause**: Report written before evidence collection complete. Agent assumes engineering success = audit success.
**Detection**: `validate-audit-bundle-schema.ps1`, `validate-final-zip-self-consistency.ps1`
**Prevention**: Run schema validator against staging before ZIP creation. Only write PASS after all machine validators pass.

---

## Pattern 2: Missing Command stderr

**Example**: Phase 6C-D (multiple phases)

**Symptom**: stdout and exitCode present, but no stderr file.
**Root cause**: Agent doesn`t capture stderr separately. When stderr empty, no file created.
**Detection**: Schema validator checks for `*-stderr.log`.
**Prevention**: Always create stderr file even if empty. Document `stderrBytes: 0`.

---

## Pattern 3: SHA256SUMS Record Drift

**Example**: Phase 6C-T0 initial

**Symptom**: SHA256SUMS.txt has N entries, but SHA report says checkedEntries = N-2.
**Root cause**: SHA256SUMS regenerated after report created, or files added/removed after SHA generation.
**Detection**: `validate-final-zip-self-consistency.ps1` checks record count consistency.
**Prevention**: SHA256SUMS must be the LAST file generated before ZIP creation. Never modify ZIP after SHA generation.

---

## Pattern 4: Schema Validator Reports Its Own Failure

**Example**: Phase 6C-T0 initial

**Symptom**: `audit-bundle-schema-validation-report.json` inside ZIP says FAIL, but ZIP contains all required files.
**Root cause**: Schema validator run against incomplete staging directory, report saved, then ZIP created with complete files but stale FAIL report.
**Detection**: `validate-final-zip-self-consistency.ps1` reads schema report and verifies verdict.
**Prevention**: Schema validator must be run against final staging (all files present) OR final ZIP. Never bake pre-validated FAIL reports.

---

## Pattern 5: Missing Mailbox Evidence

**Example**: Phase 6C-S2

**Symptom**: Phase claims multi-agent handoff via resume_agent, but ZIP lacks mailbox messages and manifest.
**Root cause**: Mailbox is advisory (not hard gate). Agents use spawn_agent/resume_agent but don`t persist artifacts.
**Detection**: Schema validator checks mailbox evidence if phase declares runtimeMailbox.
**Prevention**: If phase claims multi-agent handoff, require mailbox evidence. If not claiming, state clearly.

---

## Pattern 6: Report Claims Untested Capability

**Example**: Multiple phases

**Symptom**: Report says "X capacity proven" but no evidence of X in ZIP.
**Root cause**: Agent extrapolates from similar but different test. Overconfidence in claims.
**Detection**: CFP-001 (report/evidence contradiction).
**Prevention**: Every capability claim must be backed by machine-readable evidence in ZIP. Limit claims to what was actually tested.

---

## Pattern 7: Stale baseCanonicalHash

**Example**: Phase 6C-A2 FR5

**Symptom**: Patch fails integration because canonical changed after Builder finished.
**Root cause**: Multiple Builders, no coordination on canonical version.
**Detection**: `validate-state.ps1` checks baseCanonicalHash binding.
**Prevention**: Freeze canonical before Builder start (control-plane freeze). Serialize integration of verified patches.

---

## Pattern 8: Approval Stall

**Example**: Any phase with external commands

**Symptom**: Agent waits indefinitely for user approval on escalated command.
**Root cause**: New commands (npm install, etc.) require user approval.
**Detection**: Timeout sweep detects stale in_progress tasks.
**Prevention**: Pre-approve command prefixes. Use `--yes` or equivalent where safe.

---

## Pattern 9: Context Loss

**Example**: Long-running phases

**Symptom**: Agent loses track of task requirements, repeats work, or produces inconsistent output.
**Root cause**: Codex context compression or truncation over long conversations.
**Detection**: Hash chain breaks, event sequence gaps.
**Prevention**: Contract-first planning (read SPEC.md once, write PLAN.md). Handoff files. Limit phase scope.

---

## Pattern 10: Self-Referencing SHA256

**Example**: Phase 6C-A1, early phases

**Symptom**: Final report claims ZIP SHA256 is X, but ZIP can`t contain its own hash.
**Root cause**: Report writer computes ZIP SHA256 before final ZIP exists, or writes it into a file that goes inside ZIP.
**Detection**: `validate-final-zip-self-consistency.ps1`.
**Prevention**: ZIP digest ALWAYS in external sidecar meta. Internal reports only reference "external sidecar metadata".

---

## Summary

All 10 patterns are now machine-checkable through:
- `validate-audit-bundle-schema.ps1`
- `validate-final-zip-self-consistency.ps1`
- `validate-evidence-gates.ps1` (CFP-001 through CFP-012)
- `validate-sha256sums.ps1`
- `validate-bundle-layout.ps1`
- `assess-future-project-risk.ps1`

Future projects will still encounter problems, but they will fail noisily and explicitly rather than silently claiming PASS with missing evidence.
