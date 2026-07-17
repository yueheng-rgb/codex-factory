# FACTORY R2.3-C Capability Runtime — Gap Notes

**Phase:** FACTORY-R2.3-C-CAPABILITY-REGISTRY-RUNTIME
**Date:** 2026-07-09

---

## Gap 1: PENDING_HUMAN path unreachable with current registry data

**Severity:** Low
**Status:** Documented, no runtime bug

**Description:** The permission gate has a trustLevel → PENDING_HUMAN check (Lines: CHECK 11: AVAILABLE/CAUTION trust requires human confirmation). However, all 90 registry entries with trustLevel="AVAILABLE" also have recommendedAction="monitor". The monitor check (CHECK 4) short-circuits before the human confirmation check.

**Impact:** The PENDING_HUMAN decision type is implemented but cannot be triggered by any existing registry entry.

**Fix:** Add at least one capability with trustLevel="AVAILABLE" AND recommendedAction="import" or "adapt". This will allow the PENDING_HUMAN gate to be exercised.

**Example fix entry:**
```json
{
  "capabilityId": "CAP-SKILL-013",
  "name": "community-skill-template",
  "type": "skill",
  "trustLevel": "AVAILABLE",
  "recommendedAction": "import",
  "securityRisk": "medium",
  ...
}
```

---

## Gap 2: No "reject" or "deprecated" capabilities in registry

**Severity:** Low
**Status:** Documented

**Description:** The gate checks for recommendedAction="reject" and "deprecated" (CHECK 3), but the registry contains 0 entries with these actions. Tests F and G use quarantine as a proxy.

**Impact:** The reject/deprecated code paths exist but are untested with real registry data.

**Fix:** When a capability is rejected or deprecated during the review process, change its recommendedAction accordingly. The gate will automatically enforce.

---

## Gap 3: PENDING_SANDBOX path gated by secrets check

**Severity:** Low
**Status:** Documented

**Description:** Capabilities with securityRisk="high" or "critical" trigger PENDING_SANDBOX (CHECK 12). However, in current registry, all high-risk capabilities that are agent-eligible also have requiredSecrets, causing the secrets check (CHECK 9) to produce REJECT before the sandbox check.

**Impact:** The PENDING_SANDBOX decision is unreachable through current registry data.

**Fix:** Add a capability with securityRisk="high", requiredSecrets=[], and applicableAgents matching a test agent.

---

## Gap 4: Monitor short-circuit masks trust-level and human-confirmation checks

**Severity:** Low (design tradeoff)
**Status:** Accepted

**Description:** When recommendedAction="monitor", the gate returns MONITOR_ONLY before evaluating trustLevel, human confirmation, or sandbox requirements.

**Rationale:** Monitor-only capabilities are reference/observation only. They should be visible to all agents as knowledge resources, not invocation tools. Trust-level grading of monitor-only content is deferred to the Librarian agent's curation process.

---

## Gap 5: Phase-aware filtering is name-based

**Severity:** Medium
**Status:** Known limitation

**Description:** Get-CapabilitiesByPhase uses wildcard matching on PhaseId strings (DESIGN→templates, IMPL→SDKs). No `applicablePhases` field exists in the registry schema.

**Impact:** Phase filtering is heuristic, not contract-based. Future projects with non-standard phase naming may get incorrect capability subsets.

**Fix (R2.3-D):** Add `applicablePhases` array field to capability schema, or add a phase-type classification to the capability loader.

---

## Gap 6: No "applicablePhases" field in registry schema

**Severity:** Low
**Status:** Schema gap

**Description:** The capability schema has applicableProjectTypes and applicableAgents but no applicablePhases. This limits precise phase-gating of capabilities.

**Fix (R2.3-D):** Add `applicablePhases` (array of phase-type strings: "planning", "design", "implementation", "verification", "audit", "research") to capability schema.

---

## Gap 7: No capability-to-capability dependency tracking

**Severity:** Medium
**Status:** Not implemented

**Description:** Some capabilities depend on others (e.g., a template may require a specific SDK). The current gate checks capabilities in isolation.

**Fix (future):** Add `dependsOn` field (array of capabilityIds) to capability schema. Gate should check that all dependencies are also allowed before granting.

---

## Gap 8: Variable name collision between agent-loader and registry-integrity-check

**Severity:** High (fixed)
**Status:** RESOLVED

**Description:** Both scripts used `$script:RequiredFields` causing agent-loader to validate agent definitions against capability field names after both were dot-sourced.

**Fix:** Renamed to `$script:RegistryRequiredFields` in registry-integrity-check.ps1.

---

## Summary

| Gap | Severity | Status |
|-----|----------|--------|
| PENDING_HUMAN unreachable | Low | Documented |
| No reject/deprecated caps | Low | Documented |
| PENDING_SANDBOX unreachable | Low | Documented |
| Monitor short-circuit | Low | Accepted (design) |
| Phase filter name-based | Medium | Known limitation |
| No applicablePhases field | Low | Schema gap |
| No capability dependencies | Medium | Not implemented |
| Variable collision | High | RESOLVED |

**None of these gaps block R2.3-C delivery.** They are documented for R2.3-D and future improvements.
