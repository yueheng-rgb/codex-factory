# FACTORY-PROJECT-ISOLATION-0 — A: Scope Lock Report

> Phase: FACTORY-PROJECT-ISOLATION-0
> Section: A — Isolation Scope Lock
> Date: 2026-06-29
> Status: ACTIVE

---

## 1. Inherited Baseline

- **USER-HANDOFF-0**: PASS, v0.5 delivered
- **FACTORY-DEFAULT-WORKFLOW-0**: PASS, 60/60 verifier checks
- v0.5 artifact: `outputs/codex-factory-core-v0.5.0.zip`
- SHA256: `9FD3A5F979FE1FDEA712F69CAC300E2F49F4E84705A0448D98186CA950AC16CB`

## 2. What This Phase IS

Define and solidify **cross-project isolation** for Codex Factory. Establish protocols, schemas, and boundaries so that one project's External Conversation Space, Snapshot, Attach Packet, phase ledger, risk, blocker, cleanup state, agent ledger, working copy, and outputs cannot be erroneously mounted, inherited, or cleaned up in another project.

### In Scope

| Item | Description |
|------|-------------|
| Project Identity Model | Schema for unique project identification |
| Project Registry | Known-project list with lifecycle states |
| Mount Isolation Rules | What can/cannot mount across projects |
| Cross-Project Memory Boundary | Context/memory isolation rules |
| Output/Governance Isolation | Phase reports, verifier outputs isolation |
| Cleanup Isolation | Safe cleanup scoped to project identity |
| Agent Ledger Isolation | Agent outputs scoped to projectId |
| Working Copy Isolation | Parallel working copies per project |
| Lifecycle Interaction | Status transitions and cross-project effects |
| Simulation (10 scenarios) | Walk-through of isolation behaviors |
| Default Workflow Integration Points | Required updates to DEFAULT-WORKFLOW-0 |
| Strategy Decision | Answers to key strategy questions |
| Negative Controls (31) | Preventing cross-contamination regressions |
| Verifier Script | Automated verification |

## 3. What This Phase IS NOT

| Excluded | Reason |
|----------|--------|
| Creating a new release | Not a release phase |
| Modifying v0.5 zip | v0.5 is frozen |
| Creating v0.6 | Premature |
| Real project validation | Theory phase — validation deferred |
| Going to cloud | Cloud is deferred |
| Production deployment | Not applicable |
| Starting Native Build Pro | Not a build phase |
| Deleting real projects | Safety boundary |
| Destructive cleanup execution | Cleanup is PLAN-only |

## 4. Goal

Prevent project context/memory/output/cleanup/agent-ledger cross-contamination so that Factory can safely manage multiple projects without leaking state between them.

## 5. Success Criteria

- [ ] Project Identity Model with schema defined
- [ ] Project Registry with lifecycle states defined
- [ ] Mount isolation rules defined
- [ ] Cross-project memory boundary defined
- [ ] Output/governance isolation defined
- [ ] Cleanup isolation defined
- [ ] Agent ledger isolation defined
- [ ] Working copy isolation defined
- [ ] Lifecycle interaction matrix defined
- [ ] 10 simulation scenarios completed
- [ ] Default workflow integration points identified
- [ ] Strategy decision answered
- [ ] 31 negative controls defined and passed
- [ ] Verifier script passes all checks
