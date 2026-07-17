# FACTORY-BUILD-PACK-STAGING-P7 — B: Clean Trial Environment Design

**Timestamp:** 2026-06-28T17:20:00+08:00
**Section:** B — Clean Trial Environment Design

---

## Environment

| Property | Value |
|----------|-------|
| Type | FRESH_EXTRACTION |
| Source | `codex-factory-core-v0.9.0-pre-P6-R1-STAGING.zip` |
| Target | `harness/build-mode/pack-staging-p7-clean-user-trial/extracted/` |
| Pre-existing Factory | No |
| Deploy traces | No |
| Real projects | No |

---

## Three Clean Fixtures

| ID | Name | Deploy Traces | Expected Security Gate | Expected Context Space |
|----|------|---------------|----------------------|----------------------|
| FIXTURE-1 | fresh-simple-project | No | NOT_TRIGGERED | NOT_REQUIRED |
| FIXTURE-2 | fresh-deployed-trace-project | Yes | TRIGGERED_BLOCKING | NOT_REQUIRED |
| FIXTURE-3 | fresh-long-horizon-project | No | NOT_TRIGGERED | REQUIRED |

All fixtures are synthetic — no real projects, no `.env`, no secrets, no deployment.

---

## Expected Behavior Matrix

| Fixture | Build Lite | Security Gate | Package QA | Context Space |
|---------|-----------|---------------|------------|---------------|
| Simple | Default (auto) | Not triggered | On handoff | Not required |
| Deployed Trace | Default (auto) | **BLOCKED** (6 checks) | On handoff | Not required |
| Long-horizon | Default (auto) | Not triggered | On handoff | Required |

---

**Status:** ENVIRONMENT_DESIGNED
**Verdict:** 3 clean fixtures ready for trial
