# FACTORY R2.3-D Next Phase Recommendation

## Current State (End of R2.3-D)

- **Capability Registry Runtime:** Fully operational — 91 candidates, 14-check gate, 6-bucket plan generator
- **PENDING_HUMAN path:** Closed — CAP-SKILL-099 exercises the full approval flow
- **PENDING_SANDBOX path:** Closed — high-risk MCPs trigger sandbox requirement
- **Monitor-only policy:** Formalized — global visibility, zero invocation
- **Registry diff:** Operational — snapshot + 10-change-type detection
- **Bootstrap integration:** Plan generator produces per-phase capability governance
- **Integration simulation:** 9/9 scenarios passed
- **Verification:** 25/27 checks passed

## Recommended Next: R2.3-E Capability Import Pipeline

### Priority 1: Skill Import Pipeline MVP

Convert a capability from "pending_human / AVAILABLE" → "verified / VERIFIED" through the full import pipeline:

1. **Librarian Agent** picks CAP-SKILL-099 (or another candidate)
2. **Source Validation** — verify source, license, supply chain risk
3. **Security Agent** audits for forbidden actions, secret exposure, network access
4. **Architect Agent** evaluates engineering applicability
5. **Human Approval** gate (already implemented in PENDING_HUMAN path)
6. **Verifier Agent** creates testable verification rules
7. **Integrator Agent** promotes to VERIFIED + writes to typed registry
8. **Full audit trail** in capability-decision-index.jsonl

### Priority 2: Phase-Aware Filtering v2

Replace heuristic phase matching with explicit `applicablePhases` field:
```json
"applicablePhases": ["planning", "design", "implementation", "verification"]
```

### Priority 3: Real Project Trial

Run a complete Factory Bootstrap + Capability Plan cycle on a non-simulation project:
- Pick a `fullstack-admin` or `saas-tool` project
- Generate capability plan for each phase
- Track which capabilities are actually used vs planned
- Measure gate accuracy

### Priority 4: Auto-Snapshot on Registry Change

Make `Save-RegistrySnapshot` automatic when any registry file is modified — prevent silent registry drift.

### Priority 5: Remote Manifest Sync (Local-First)

Design a hash-based manifest exchange format:
- Only manifest hashes and version indices leave local
- No code, no secrets, no project data
- Pull from trusted sources, verify SHA256
- Push only public capability manifests (opt-in)

### Deferred to Later

- Real MCP server integration (Stitch, Figma, Playwright, etc.)
- GLM / external search API connection
- Cloud runner setup
- Hardware purchase decisions
- Real external skill import from marketplace

## Phase Dependencies

```
R2.3-C (Runtime) ──┐
                   ├── R2.3-D (Governance) ──► R2.3-E (Import Pipeline)
R2.3-A (Schemas) ──┘                              │
                                                   ├── R2.3-F (Real Project Trial)
                                                   ├── R2.3-G (Phase Filtering v2)
                                                   └── R2.3-H (Remote Manifest Sync)
```
