# FACTORY-DEFAULT-WORKFLOW-0 — M: Strategy Decision Report

> Phase: FACTORY-DEFAULT-WORKFLOW-0
> Section: M — Strategy Decision
> Date: 2026-06-28

---

## Q1: Does this phase define the default Factory usage path?

**YES.** FACTORY-DEFAULT-WORKFLOW-0 defines the complete "select folder + state requirement" path: Bootstrap → Router → Preflight → Discussion → Complexity → Multi-Agent Decision → Implementation → Handoff → Cleanup. This is the canonical default usage protocol for all future Factory sessions.

## Q2: Is multi-agent decision now mandatory for large projects?

**YES, as a question.** For projects meeting 3+ of the 5 criteria (server+client, database, 3+ modules, auth, >5 files), Factory MUST ask the multi-agent question. Multi-agent execution still requires explicit user confirmation — it is not auto-enabled.

## Q3: Is natural-language cleanup defined?

**YES.** The Natural Language Cleanup Contract (Section G) defines a 4-step protocol: Interpret → PLAN → Confirm → Execute. Cleanup NEVER deletes source code or CORE_EVIDENCE. "删除该项目缓存" always produces a PLAN first.

## Q4: Is full path handoff defined?

**YES.** The Project Path Handoff Contract (Section F) defines 7 mandatory path categories, absolute path requirements, UNKNOWN_WITH_REASON handling, and a structured handoff template.

## Q5: Is cloud deferred?

**YES.** The Cloud Deferral Record (Section K) formally records that cloud infrastructure is deferred to post-v1.0. No servers, domains, or deployment pipelines in v0.x.

## Q6: What should next be?

Based on findings from this phase, the recommended next phases are:

| Priority | Phase | Rationale |
|----------|-------|-----------|
| 1 | **FACTORY-PROJECT-ISOLATION-0** | Ensure Factory works correctly when mounted on a real project without leaking state |
| 2 | **FACTORY-MULTI-AGENT-ORCHESTRATION-1** | Refine role profiles with real project validation |
| 3 | **FACTORY-STATE-DASHBOARD-0** | Implement CLI `factory state` based on requirements from Section I |
| 4 | **FACTORY-RECOVERY-0** | Startup recovery from corrupted state |
| 5 | **FACTORY-V05-R1** | Only if CLI name mismatch needs repair |

## Q7: What should NOT be done now?

| Do NOT Do | Reason |
|-----------|--------|
| Create v0.6 | Default workflow must be validated first |
| Go to cloud | Cloud is deferred |
| Buy servers/domains | Not in scope |
| Start real project validation | Wait until after this phase closes |
| Build state dashboard web UI | Requirements only in this phase |
| Enable multi-agent by default | Always requires user confirmation |
