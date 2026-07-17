# EVIDENCE_LEVEL_MODEL.md

> Part of: FACTORY-EVIDENCE-TAXONOMY-0 / B
> Version: 1.0.0

---

## Primary Evidence Levels

### E0 — UNSUPPORTED
- **Definition**: Model guess, hallucination, no file/report/verifier backing
- **Can Support**: Nothing — blocked for all claims
- **Example**: Agent says "project is complete" with no artifacts
- **Promotion**: Cannot be promoted — needs E4+ execution

### E1 — DESIGN_ANALYSIS
- **Definition**: Planned architecture, design-only score, no raw execution
- **Can Support**: Design completeness, architectural reasoning
- **Cannot Support**: Execution correctness, product existence, performance
- **Example**: AB-0 design analysis, architecture proposal
- **Promotion**: Must be followed by E4+ execution to support execution claims

### E2 — POLICY_REVIEW
- **Definition**: Policy/spec/document reviewed, no command execution
- **Can Support**: Policy compliance, spec correctness
- **Cannot Support**: Runtime behavior, build success, test results
- **Example**: RC-USER-ACCEPTANCE-0 policy review
- **Promotion**: Must be followed by E4+ execution

### E3 — LIVE_INSPECTED
- **Definition**: Actual file/script/policy inspected, limited command or content verification, not full behavior execution
- **Can Support**: File existence, content correctness (static)
- **Cannot Support**: Full end-to-end behavior
- **Example**: RC-SMOKE-1 partial live inspection
- **Caveat Required**: "Live-inspected, not full E2E executed"

### E4 — LIVE_EXECUTED_FIXTURE
- **Definition**: Command executed on safe fixture, exit code/log captured, not real project
- **Can Support**: Tool behavior, script correctness on fixtures
- **Cannot Support**: Real project correctness
- **Example**: Verifier smoke on test fixtures
- **Caveat Required**: "Fixture execution — not real project validation"

### E5 — RAW_OUTPUT_EXECUTION
- **Definition**: Actual generated code/files/output exist, inventory/hash/log present, scoring based on raw output
- **Can Support**: Product existence, file inventory, hash integrity
- **Cannot Support**: Production readiness, real-world correctness (alone)
- **Example**: AB-1 raw code output with independent scoring
- **Key**: Has file inventory + hash — verifiable artifacts

### E6 — REALWORLD_LOCAL
- **Definition**: Real project working copy, local validation/smoke/test, no production deployment
- **Can Support**: Local workflow correctness, build/run on developer machine
- **Cannot Support**: Production readiness, cloud deployment, multi-user
- **Example**: Real project built and run locally with Factory
- **Caveat Required**: "Local readiness — not production readiness"

### E7 — PRODUCTION_VALIDATED
- **Definition**: Production-like or production deployment validated, explicit user approval, no secrets exposed
- **Can Support**: Production readiness claim (scoped)
- **Cannot Support**: Universal proof (needs E8)
- **Out of v0.5 default scope**
- **Requires**: Explicit user approval, security audit, deploy gate pass

### E8 — REPLICATED_EVIDENCE
- **Definition**: Multiple project types / repeated trials, stronger generality
- **Can Support**: Generalization claims (still scoped to tested types)
- **Cannot Support**: Universal proof (no evidence can)
- **Requires**: Multiple E6/E7 trials across different project types

---

## Special Non-Primary Evidence Types

### SNAPSHOT_WORKING_CONTEXT
- Working context snapshot — not primary evidence
- Can support: context recovery, state reproduction
- Cannot support: correctness, completeness, production readiness

### ATTACH_PACKET_WORKING_CONTEXT
- Working context attachment — not primary evidence
- Same restrictions as SNAPSHOT

### DASHBOARD_DIAGNOSTIC_VIEW
- Diagnostic view derived from other evidence — not primary
- Can support: health assessment, warning detection
- Cannot support: claims about project correctness (must reference primary evidence)

### USER_CHAT_SUMMARY
- Conversation summary — not structured evidence
- Cannot support: any formal claim
- Informational only

### FOREIGN_CONTEXT
- Evidence from wrong projectId — cannot support current project claims
- Marked as FOREIGN_CONTEXT per PROJECT-ISOLATION-0

### CORRUPT_OR_UNTRUSTED
- Corrupt, unverifiable, or tampered evidence — blocked
- Triggers RECOVERY LEVEL_2 or LEVEL_3
