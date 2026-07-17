# FACTORY R2.3-B — Next Phase Plan (R2.3-C Recommendation)

> **Phase:** FACTORY-R2.3-B
> **Date:** 2026-07-09

---

## 1. R2.3-B Completion Status

| Deliverable | Status | Count |
|-------------|--------|-------|
| Capability candidate registry (master) | ✅ | 90 entries |
| MCP candidate registry | ✅ | 14 entries |
| Skill candidate registry | ✅ | 12 entries |
| Search provider registry | ✅ | 10 entries |
| Template/starter registry | ✅ | 9 entries |
| Verifier registry | ✅ | 10 entries |
| Runner registry | ✅ | 6 entries |
| Main survey report | ✅ | 1 |
| Priority matrix | ✅ | 1 |
| MCP risk notes | ✅ | 1 |
| Search provider strategy | ✅ | 1 |
| Frontend tooling survey | ✅ | 1 |
| High-scale capabilities | ✅ | 1 |
| Import/wrap policy | ✅ | 1 |
| Next phase plan (this) | ✅ | 1 |

## 2. R2.3-C Recommendation

### Primary Target: **A. Capability Registry Runtime**

**Rationale:** R2.3-B produced 90 capability entries across 7 registries. R2.3-C should make these registries machine-readable and queryable at runtime, enabling:
- Agent loader to discover available capabilities
- Permission gate to check capability access rules
- LIB-001 to query registry for skill import decisions
- RSRC-001 to query search providers for research intake

**Deliverables:**
1. untime/capability-loader.ps1 — Loads and queries registries
2. untime/capability-permission-gate.ps1 — Extends R2.2 permission gate with capability checks
3. Registry query API (filter by type, priority, agent, recommendedAction)
4. Integration test: agent spawn with capability-aware permission check

### Secondary Target: **C. Skill Import Pipeline**

**Rationale:** P0 skills (trailofbits-security, skill-creator, skill-installer) are ready for import. The import policy is defined (R2.3-B Import/Wrap Policy). R2.3-C should implement the first automated import.

**Deliverables:**
1. untime/skill-importer.ps1 — Imports external skill, runs checks
2. First import: trailofbits-security-skills (P1, low risk, no network)
3. Import pipeline test: candidate → imported → adapted → verified

### Tertiary Target: **B. MCP/Tool Permission Gate**

**Rationale:** playwright-mcp and filesystem-mcp are P0. R2.3-C should build the sandbox wrapper for at least one MCP.

**Deliverables:**
1. untime/mcp-sandbox.ps1 — Sandbox wrapper for MCP execution
2. playwright-mcp sandbox integration
3. Test: sandboxed playwright test execution

## 3. What NOT to Do in R2.3-C

| Item | Reason |
|------|--------|
| Connect real APIs (GLM, Perplexity, etc.) | Search adapter interface first, API later |
| Run Stitch MCP / Figma MCP | Needs API keys, monitor status only |
| Implement cloud services | Not needed, local-first |
| Full multi-agent auto-orchestration | R2.3-E scope |
| Business project code | Explicitly excluded |
| Hardware purchase / cloud provisioning | Not triggered |

## 4. R2.3 Sub-Phase Roadmap (Updated)

| Phase | Name | Scope |
|-------|------|-------|
| ✅ R2.3-A | Research Intake Protocol | Schemas + role design + trial |
| ✅ R2.3-B | External Capability Survey | 90 candidates + 7 registries + 8 reports |
| → R2.3-C | Capability Registry Runtime | Loader + permission gate + skill import MVP |
| R2.3-D | Ecommerce Playbook Trial | Full pipeline: intake→packet→capsule→skill |
| R2.3-E | Skill Registry Runtime Integration | Auto-load skills at agent spawn |

## 5. Immediate Actions (Post R2.3-B)

1. **Validate registries** — run JSON validation on all 7 registry files
2. **Mark P0 candidates** as eady_for_import in master registry
3. **Create import queue** for R2.3-C: trailofbits-security, skill-creator, skill-installer, shadcn-ui-blocks
4. **Draft capability-loader.ps1** specification

---

> **Recommendation:** R2.3-C should implement **Capability Registry Runtime** as primary target, **Skill Import Pipeline** as secondary, and **MCP Sandbox** as tertiary. This sequence maximizes value while minimizing risk: registry first (enables all other capability features), skill import second (immediate Factory improvement), MCP sandbox third (prepares for safe external tool integration).

