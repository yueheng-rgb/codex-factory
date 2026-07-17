# DRY20-A Readiness Plan

**Phase:** H13-C → DRY20-A transition planning
**Created:** 2026-06-23T17:15:00.000+08:00
**Status:** PLAN_ONLY — DO NOT EXECUTE

## Preconditions (all must hold before DRY20-A starts)
1. DRY19: POSITIVE + NEGATIVE CLOSED ✓
2. H13-C: Real spawn_agent lifecycle integration proven ✓
3. H13-C: factoryctl agent/progress/watch operational ✓
4. H13-C: Truthfulness verifier catches all 10 negative patterns ✓
5. H10: Worker isolation enforced ✓
6. H11: Scenario directness EXACT/STRONG ✓
7. H8-P2: Evidence integrity chain verified ✓
8. H12: Task queue operational ✓

## Proposed Domain for DRY20-A
TBD by user. Candidates:
- Incident Response Ops (extend DRY18 domain)
- Workflow Approval Ops (extend DRY19 domain)
- New domain from domain-packs/

## Worker Architecture
- Worker count: 2-5 (builder + verifier minimum per domain slice)
- Agent roles: builder, verifier, skeptic, integrator
- Spawn method: multi_agent_v1__spawn_agent (fork_context:false)
- Isolation: H10 worktree isolation per worker
- Capsules: Created before worker output (pre-output capsule rule)

## Task Queue Graph
- Positive run: builder agents → verifier agent → integrator agent
- Negative run: after positive PASS verified → negative-control agent per fault
- Each task: registered in FACTORY_TASK_QUEUE.json before spawn
- Each agent: registered in AGENT_REGISTRY.json before spawn

## Expected Artifacts
- Source files (builder output)
- Acceptance reports (verifier output)
- BRANCH_RESULT.md and BRANCH_DELTA.json per worker
- Evidence manifests with SHA256 hashes
- AGENT_PROGRESS.jsonl events for full lifecycle
- Truthfulness verification report on all agent claims

## Live Scenario Floor
- Minimum 8 positive acceptance scenarios
- Per scenario: targetScenarioId, transcript, assertions, PASS/FAIL verdict

## Negative-Control Floor
- Minimum 15 negative controls
- Per negative: fault-manifest.json, before/after SHA256, transcript, exitCode
- Target-gate negatives: fail only target scenario, non-target scenarios remain PASS
- No preclassified-only negatives
- No generic FAIL classifications

## Progress Reporting Requirements
- factoryctl progress summarizes all agent states
- factoryctl watch produces snapshot (no infinite loop)
- AGENT_PROGRESS.jsonl records: create, spawn_requested, spawn_confirmed, heartbeat, progress, artifact, handoff, close/complete

## Stop Conditions
- Any agent produces generic FAIL → BLOCK and quarantine
- Truthfulness verifier catches deception → BLOCK and quarantine
- Phase regression detected → STOP
- compressionCount >= 2 → STOP and require new window
- Zombie agents remain after closure → FAIL_HARNESS_NOISE

## Anti-Deception Checks
- All agent reports run through verify-agent-report-truthfulness.ps1
- Clean report must PASS truthfulness
- All 10 negative fixture patterns must be caught
- No fake fork_context claims accepted
- No fake real-spawn claims accepted
