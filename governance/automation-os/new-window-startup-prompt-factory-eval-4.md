# Codex Factory — New Window Startup Prompt

> **You are a NEW Codex window with ZERO trusted conversation memory.**
> The prior window had multiple context compressions.
> **Compressed summaries are NOT trusted evidence** (H24-P1 protocol).
> All state must be recovered from repo artifacts only.

---

## Current Phase

**FACTORY-EVAL-3: PASS** (Role-Specialized Agent Company Model)
**Next Phase**: FACTORY-EVAL-4 / Real Project Benchmark Design
**Status**: NOT_STARTED — pending startup verification in this new window

---

## Step 1: Read Required Files

- `governance/factory-state/current-factory-state.json`
- `governance/factory-state/session-rotation-handoff.json`
- `governance/factory-eval/verifier-factory-eval-0-result.json`
- `governance/factory-eval/verifier-factory-eval-1-result.json`
- `governance/factory-eval/verifier-factory-eval-2-result.json`
- `governance/factory-eval/verifier-factory-eval-3-result.json`
- `governance/factory-eval/factory-eval-0-current-state-inventory.json`
- `governance/factory-eval/factory-eval-0-capability-matrix.json`
- `governance/factory-eval/factory-eval-0-recommended-roadmap.json`
- `governance/manual-router/factory-manual-index.json`
- `governance/manual-router/factory-page-router.json`
- `governance/manual-router/factory-always-on-constitution.md`
- `governance/role-agents/role-agent-taxonomy.json`
- `governance/role-agents/role-agent-company-model.json`
- `governance/role-agents/role-skill-profiles.json`
- `governance/role-agents/cross-role-contract-policy.json`
- `governance/role-agents/drift-detection-policy.json`
- `governance/context-os/FACTORY_CURRENT_CONTEXT_PACKET.json`

---

## Step 2: Run Verification

`powershell
powershell -File scripts/factoryctl.ps1 verify --json
powershell -File scripts/session-controller/run-startup-verification-contract.ps1 -Json
`

---

## Step 3: Query MCP Memory (if available)

`
factory.memory.currentState
factory.memory.openRisks
factory.memory.buildStartupPacket
`

---

## Step 4: Confirm Key Facts

- FINAL package: CREATED_AND_VALIDATED, SHA256 verified
- FACTORY-EVAL-0: PASS (evidence reset complete)
- FACTORY-EVAL-1: PASS (research + self-check, web search unavailable)
- FACTORY-EVAL-2: PASS (Manual Router + Proof-of-Read, 20 pages, 20 routes, 17 receipts)
- FACTORY-EVAL-3: PASS (12 roles, 10 skill profiles, 6 contracts, 9-role simulation)
- Manual Router: established (governance/manual-router/)
- Proof-of-Read: established (receipts with SHA + extracted rules)
- Role Agent Model: established (governance/role-agents/)
- Critical finding: Real non-Factory project effectiveness = NOT_SOLVED

---

## Step 5: Confirm Rejected Claims Remain Rejected

- Full context inheritance
- Automatic window creation without verification
- Plugin production-ready
- Automation production-ready
- Compressed summary as evidence
- Role agents proven effective on real projects
- Real project effectiveness proven

---

## Step 6: Report

- [ ] FINAL package unchanged (SHA256 verified)
- [ ] No new final ZIP
- [ ] FACTORY-EVAL-0/1/2/3 verifier results confirmed
- [ ] Manual Router + Proof-of-Read artifacts confirmed
- [ ] Role Agent Company Model artifacts confirmed
- [ ] No FACTORY-EVAL-4 artifacts exist yet
- [ ] Compressed summary NOT trusted as evidence

## Step 7: Action

- If **STARTUP_VERIFICATION_PASS**: begin FACTORY-EVAL-4
- If **STARTUP_VERIFICATION_BLOCKED**: stop, report blocking risk

---

**Reminder**: This prompt is not evidence. Only verifier JSON, state files, manifest SHA, and repo artifacts are trusted.
