# Deprecated Modules

> **Category**: deprecated | **Stability**: DEPRECATED — DO NOT USE
>
> This directory lists modules that have been deprecated.
> Each entry includes the replacement path and deprecation reason.
> Do NOT use deprecated modules in new work.

---

## ⚠️ Critical Warning

**All modules listed here are DEPRECATED.** Using them will produce:

- Missing functionality (modules may have been removed or replaced)
- Incompatible outputs (schemas and contracts have changed)
- Violations of current governance rules (e.g., scoring-based gates)
- Audit failures (deprecated modules are not part of the active resource pack)

**Always use the replacement module instead.**

---

## Deprecated Module Index

| Deprecated Module | Replacement | Deprecation Reason |
|------------------|-------------|-------------------|
| `drift-severity-scoring` | `architecture-drift-detector` (in verifier-modules/) | Scoring-based severity assessment replaced by binary drift detection. Scoring approach violated SCORING_SYSTEM_GATE.md. |
| `evidence-classification` | `nativeGenerated` boolean flag | Classification system assigning trust scores to evidence replaced by simple boolean: evidence either is nativeGenerated or it isn't. Scoring trust levels proved unreliable. |
| `agent-lifecycle` (old) | `agent-reliability-runtime` | Original lifecycle tracker used scoring to assess agent "health." Replaced by binary state machine in `agent-lifecycle-protocol.md` and registry-based tracking. |
| `contract-engine` | `worker-contract-engine` | Original contract engine had hardcoded schema assumptions. Replaced by configurable contract engine with schema-driven validation. |
| `dry23-integration-hub` | `dry24-integration-hub` | DRY23-era integration patterns incompatible with DRY24+ governance requirements. API contracts changed, handoff format changed. |
| `integration-hub-old` | `dry24-integration-hub` | Pre-DRY24 integration hub with deprecated routing logic. Superseded by the DRY24-compliant hub. |
| *(future additions)* | *(replacement path)* | *(reason for deprecation)* |

---

## Deprecation Policy

### When to Deprecate

A module is deprecated when:
1. Its functionality has been superseded by a newer module
2. Its approach is incompatible with current governance rules
3. Its outputs cannot be validated by current verifiers
4. It uses prohibited patterns (scoring, summary-as-evidence, etc.)

### Deprecation Process

1. Identify the replacement module that provides equivalent or better functionality
2. Document the deprecation reason (what changed and why)
3. Add entry to this README
4. Add entry to `deprecated-module-index.json`
5. Move or copy the deprecated module to `deprecated/` directory (if it existed as a file)
6. Update MANIFEST.json to mark the module as `deprecated`
7. Notify active phases that may reference the module

### After Deprecation

- Deprecated modules remain in `deprecated/` for historical reference
- Active code MUST NOT import or reference deprecated modules
- New phases MUST NOT use deprecated modules
- Existing phases using deprecated modules SHOULD migrate to replacements
- Verifiers check for deprecated module usage in active phases

---

## Migration Guidance

### drift-severity-scoring → architecture-drift-detector
- Remove all score-based severity calculations
- Replace with binary drift detection (drift detected: yes/no)
- Use `architecture-drift-detector` verifier for all drift assessment

### evidence-classification → nativeGenerated
- Remove all evidence trust scores
- Replace with `nativeGenerated: true/false` boolean
- Evidence is either machine-generated (trusted) or not (requires corroboration)

### agent-lifecycle (old) → agent-reliability-runtime
- Remove agent health scores
- Use binary state machine defined in `agent-lifecycle-protocol.md`
- Track agent state through `AGENT_REGISTRY.json` and `AGENT_PROGRESS.jsonl`

### contract-engine → worker-contract-engine
- Migrate contract definitions to new schema format
- Update contract references in phase specifications
- Re-validate all existing contracts against new engine

### dry23-integration-hub → dry24-integration-hub
- Update integration configurations to DRY24 API contracts
- Regenerate integration handoff artifacts
- Re-validate all integration points

### integration-hub-old → dry24-integration-hub
- Remove all old routing configurations
- Replace with DRY24-compliant routing
- Re-run integration verifiers

---

## SCORING_SYSTEM_GATE

Several deprecated modules (drift-severity-scoring, evidence-classification, agent-lifecycle old)
were deprecated specifically because they used scoring as gates, violating `SCORING_SYSTEM_GATE.md`.
Their replacements use binary verifier-based checks.

---

## See Also

- `deprecated/deprecated-module-index.json` — machine-readable index
- `MANIFEST.json` — current module disposition (check `deprecated` category)
- `SCORING_SYSTEM_GATE.md` — the prohibition that drove several deprecations
- `BOUNDARY.md` — rules governing module packaging
