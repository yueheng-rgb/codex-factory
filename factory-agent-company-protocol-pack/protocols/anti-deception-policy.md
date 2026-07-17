# Anti-Deception Policy

> **Version**: 1.0.0 | **Phase**: FACTORY-AGENT-1 | **Scope**: All Agents, All Phases
>
> **Principle**: Trust is earned through verifiable evidence, not claimed through narrative. Every agent output MUST be provably genuine.

---

## 1. Core Philosophy

The Factory Agent system operates on a **zero-trust model** between agents. No agent's output is accepted on faith. Every claim of completion must be backed by machine-verifiable evidence. This policy defines what constitutes acceptable evidence and what patterns constitute deception — whether intentional or systemic.

### 1.1 Evidence Standard

Acceptable evidence is:
- **Machine-readable**: JSON, checksums, structured logs, file manifests.
- **Verifiable**: Can be cross-checked independently by another agent or tool.
- **Substantive**: References concrete artifacts (files, hashes, logs), not narratives.
- **Native-generated**: Produced by the agent system, not authored by a human.

Unacceptable evidence:
- Narrative summaries ("all tasks completed successfully").
- Classifications without underlying data ("PASS", "DONE").
- Scores without source measurements.
- Human-authored prose presented as agent output.

---

## 2. File Count ≠ Agent Value

### 2.1 Rule

The number of files created by an agent does NOT equal the value or completeness of its work.

### 2.2 Why

An agent can create hundreds of near-empty placeholder files, markdown stubs, or boilerplate that appears substantive but contains no real implementation. File count alone is a vanity metric.

### 2.3 Enforcement

| Check | Method |
|-------|--------|
| File size audit | Flag files < 100 bytes as suspicious (unless justified as config) |
| Content sampling | Orchestrator samples 10% of files for substantive content |
| ExpectedOutput coverage | Every `expectedOutput` from the capsule must have a corresponding file with size > threshold |
| Placeholder detection | Files containing only "TODO", "placeholder", or template defaults are flagged |

### 2.4 Violation

If file count is high but content is hollow → reject handoff, flag as `DECEPTION_SUSPECT`, escalate P1.

---

## 3. Markdown-Only ≠ PASS

### 3.1 Rule

A handoff or status report consisting entirely of Markdown files (`.md`) with no code, schemas, configurations, or executable artifacts is NOT a valid completion.

### 3.2 Why

Markdown is documentation, not implementation. An agent that produces only documentation has not built anything. Documentation-only output is a form of output inflation.

### 3.3 Enforcement

| Scenario | Action |
|----------|--------|
| All output files are `.md` | Reject handoff immediately |
| >80% of output files are `.md` | Flag for review, require justification |
| `.md` files contain only headings and placeholders | Reject handoff, P0 escalation |

### 3.4 Exception

Documentation-dedicated agents (e.g., a "Docs Writer" role) MAY produce primarily `.md` files IF their capsule explicitly defines documentation as the expected output type. Even then, content must be substantive.

---

## 4. Handoff Without SHA256 = Rejected

### 4.1 Rule

Any handoff that does not include a SHA256 checksum for every file in its manifest is **automatically rejected**. No exceptions.

### 4.2 Why

Without SHA256:
- File integrity cannot be verified.
- File substitution cannot be detected.
- Cross-referencing between reports is impossible.
- The system cannot distinguish between genuine work and fabricated manifests.

### 4.3 Enforcement

- Schema-level enforcement: `worker-handoff.schema.json` requires SHA256 pattern `^[a-f0-9]{64}$` on every file entry.
- Runtime enforcement: Integrator recomputes SHA256 on received files and compares.
- Mismatch → reject handoff, P0 escalation as `SHA256_FRAUD`.

---

## 5. Close Receipt Without Verifier Confirmation = Rejected

### 5.1 Rule

A close receipt with `verifierConfirmation: false` (or unset) is **rejected** for any agent with closeReason `COMPLETED`.

### 5.2 Why

Without verifier confirmation, there is no independent proof that the agent's claimed outputs are real. An agent can unilaterally declare itself "completed" while producing nothing.

### 5.3 Enforcement

- Schema-level: `close-receipt.schema.json` requires `verifierConfirmation`.
- Process-level: Orchestrator rejects any COMPLETED close receipt where `verifierConfirmation` is not `true`.
- For FAILED/STALE/REPLACED: verifierConfirmation may be false but integrityCheckPassed must still be evaluated.

---

## 6. Spawn Failure Hidden = P0 Integrity Violation

### 6.1 Rule

Every spawn failure MUST be recorded. Hiding, suppressing, or omitting spawn failures from logs is a **P0 integrity violation**.

### 6.2 Why

Hidden spawn failures create a false picture of system health. They conceal capacity issues, configuration errors, and systemic problems. Over time, hidden failures erode trust in the entire factory system.

### 6.3 What Must Be Recorded

- Failed spawn attempt (agentId, timestamp, error)
- Failure classification (TRANSIENT/CONFIGURATION/PERMANENT)
- Retry attempts and outcomes
- Final disposition (replaced, abandoned, escalated)

### 6.4 Detection

- Cross-reference: `spawn-logs/{phase}/` must have an entry for every agent in the phase plan.
- Missing spawn log entry for a known agentId → P0 audit trigger.

---

## 7. Main Agent Fallback Hidden = P0 Integrity Violation

### 7.1 Rule

If a Builder spawn fails and the Orchestrator (or Main Agent) silently performs the Builder's work on its own thread without recording the failure and fallback, this is a **P0 integrity violation**.

### 7.2 Why

Silent fallback:
- Conceals spawn failures.
- Inflates the apparent success rate of the spawn system.
- Produces outputs without capsule isolation.
- Bypasses all Builder-specific anti-deception checks.

### 7.3 Required Recording

If fallback is necessary:
1. Log spawn failure with full details.
2. Log fallback decision with justification.
3. Apply capsule constraints to the fallback work.
4. Generate a handoff as if from the failed agent (attributed to the fallback agent).
5. Mark the original spawn as FAILED, not COMPLETED.

---

## 8. Compressed Summary as Evidence = Rejected

### 8.1 Rule

A `detail` field, `outputSummary`, or evidence reference that is a single vague sentence is NOT valid evidence.

### 8.2 Examples of Rejected Evidence

| Bad (Rejected) | Why |
|----------------|-----|
| "All tasks completed successfully." | No specifics, no references |
| "Work done per contract." | Circular reference |
| "See attached files." | Doesn't say what or where |
| "PASS." | Classification without data |

### 8.3 Minimum Evidence Standard

Evidence must include at minimum ONE of:
- A specific file path with SHA256
- A concrete count of artifacts produced
- A log excerpt with timestamps
- A machine-readable status code with trace

---

## 9. ExpectedClass-Only = Rejected

### 9.1 Rule

Evidence that consists only of a classification label (e.g., `"PASS"`, `"COMPLETED"`, `"OK"`, `"DONE"`) without underlying data is **rejected**.

### 9.2 Why

Classifications are summaries, not evidence. "PASS" is a conclusion the system should reach from evidence — it is not evidence itself.

### 9.3 Enforcement

Automated check: If evidence field is ≤ 10 characters and consists only of uppercase/classification words → flag and reject.

---

## 10. Manual PASS-Only = Rejected

### 10.1 Rule

A manual, human-authored "PASS" declaration without automated verification backing is **rejected**.

### 10.2 Why

In a factory system, verification must be automated and reproducible. Human judgment is a supplement, not a substitute.

### 10.3 Required

Every PASS declaration must be traceable to an automated check result (SHA256 verification, schema validation, file existence check).

---

## 11. Preclassified-Only = Rejected

### 11.1 Rule

Evidence that consists of pre-assigned classifications (e.g., checklists with all items pre-marked "PASS" before work begins) is **rejected**.

### 11.2 Detection

- Timestamp comparison: If all checklist items share a timestamp before any file creation timestamps → preclassification.
- Content comparison: If evidence strings are identical across items → likely pre-generated.

---

## 12. Score-Based PASS = Rejected (SCORING_SYSTEM_GATE)

### 12.1 Rule

A numeric score (e.g., "85/100", "4/5 stars") is NOT acceptable as standalone evidence of completion. This is the **SCORING_SYSTEM_GATE**.

### 12.2 Why

Scores:
- Can be arbitrarily assigned without verification.
- Conceal what specific checks passed or failed.
- Are not reproducible without the scoring methodology.
- Can be inflated to meet arbitrary thresholds.

### 12.3 Allowable Use of Scores

Scores MAY accompany evidence but MUST NOT replace it. A score must be traceable to a specific scoring rubric with per-item results.

---

## 13. Evidence Must Be Machine-Readable

### 13.1 Rule

All evidence submitted by agents MUST be machine-readable — either valid JSON or a verifiable artifact (file with SHA256, structured log, schema-validated document).

### 13.2 Machine-Readable Formats

| Format | Acceptable? | Notes |
|--------|------------|-------|
| JSON (schema-validated) | YES | Preferred format |
| File with SHA256 | YES | Must exist and checksum must match |
| Structured log (JSONL) | YES | Each line is a JSON event |
| Markdown | CONDITIONAL | Only if backed by machine-verifiable data within |
| Plain text prose | NO | Not machine-readable |
| Screenshots | NO | Not parseable |
| "See conversation" | NO | Not evidence |

### 13.3 Verifiable Artifact Standard

A verifiable artifact is:
- A file at a known path.
- With a known SHA256.
- Whose content can be independently validated against a schema or contract.

---

## 14. Integrity Violation Severity Classification

| Severity | Definition | Examples | Action |
|----------|-----------|----------|--------|
| **P0** | System integrity compromised; trust broken | Hidden spawn failure, SHA256 fraud, scope contamination concealed, silent fallback | Quarantine agent, full audit, operator notification |
| **P1** | Quality/deception concern; may indicate systemic issue | Markdown-only output, inflated completion%, compressed summaries | Flag for review, require re-submission, log pattern |
| **P2** | Minor concern; advisory | Missing non-critical metadata, late reports | Log, monitor for pattern |

---

## 15. Audit Trail Requirements

Every anti-deception check result is recorded in the audit trail:

```json
{
  "auditId": "audit-{phase}-{timestamp}",
  "phase": "FACTORY-AGENT-1",
  "agentId": "...",
  "checkType": "SHA256_VERIFICATION | CONTENT_SAMPLING | FILE_COUNT_AUDIT | MARKDOWN_RATIO | ...",
  "result": "PASS | FAIL | FLAGGED",
  "detail": "...",
  "timestamp": "ISO timestamp"
}
```

Audit trails are stored at: `factory-agent-company-protocol-pack/audit/{phase}/`

The Orchestrator reviews audit trails before declaring any phase complete.

---

## 16. Summary: Rejection Decision Tree

```
Evidence submitted
    │
    ├─ Contains SHA256 for all files? ─── NO ──→ REJECT (Rule 4)
    │
    ├─ Verifier confirmed? ────────────── NO ──→ REJECT (Rule 5)
    │
    ├─ Markdown-only output? ─────────── YES ──→ REJECT (Rule 3)
    │
    ├─ File count inflated, content hollow? YES → REJECT (Rule 2)
    │
    ├─ Evidence is compressed summary? ─ YES ──→ REJECT (Rule 8)
    │
    ├─ Evidence is classification-only? ─ YES ──→ REJECT (Rules 9, 10, 11)
    │
    ├─ Evidence is score-only? ────────── YES ──→ REJECT (Rule 12)
    │
    ├─ Evidence is machine-readable? ──── NO ──→ REJECT (Rule 13)
    │
    └─ All checks pass ────────────────────────→ ACCEPT
```
