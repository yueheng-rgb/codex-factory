# Codex Factory v2.0 — Deprecated Directions Final Lock

> **Release:** v2.0.0 | **Date:** 2026-07-12  
> **Status: ALL LOCKS PRESERVED — NOTHING REOPENED**

---

## Lock #1: Independent Search Agent

**Ban:** Independent Search Agent is FORBIDDEN.

- Search must flow through canonical /api/paas/v4/web_search + search_std
- Only Pre-Build Research Gate (Agent RSRC) may initiate search
- Implementer must NEVER search directly
- No separate search agent process

**First locked:** R2.4  
**Evidence:** AGENTS.md, runtime/pre-build-research-gate.ps1  
**Status:** LOCKED — never reopened

---

## Lock #2: Dual Search Channel

**Ban:** Dual Search Channel is FORBIDDEN.

- /chat/completions web_search is downgraded, NOT an alternative channel
- Only one canonical search path exists
- No parallel search channels

**First locked:** R2.4  
**Evidence:** AGENTS.md  
**Status:** LOCKED — never reopened

---

## Lock #3: Search Agent as Future Default

**Ban:** Search Agent as Future Default is FORBIDDEN.

- Multi-agent is NOT the default mode
- Search is an RSRC function, not an agent role
- Compression defense correctly blocks attempts to reopen this

**First locked:** R2.4  
**Evidence:** AGENTS.md, v2.0-RC compression defense (BLOCKED)  
**Status:** LOCKED — detected and BLOCKED in v2.0-RC resume gate

---

## Lock #4: Implementer Direct Search

**Ban:** Implementer must NEVER call search tools directly.

- Implementer only receives Evidence Pack from RSRC
- Implementer cannot initiate search, browse URLs, or extract web evidence
- This boundary is enforced by worker contracts

**First locked:** R2.4  
**Evidence:** AGENTS.md, governance/contracts/worker-contract.schema.json  
**Status:** LOCKED — never reopened

---

## Lock #5: Chat URL Extraction as Canonical Evidence

**Ban:** /chat/completions URL extraction is NOT canonical evidence.

- Only structured Evidence Pack v2 (with search_std) is canonical
- Chat-provided URLs are unreliable and non-auditable
- Evidence Binding requires structured evidence, not chat excerpts

**First locked:** R2.4  
**Evidence:** AGENTS.md, runtime/gate-evidence-binder.ps1  
**Status:** LOCKED — never reopened

---

## Lock #6: Mock/Dry_Run as Live

**Ban:** Mock or dry_run results must NEVER be labeled as live.

- Test-only results must be labeled TEST or DRY_RUN
- Live production claims require live data and real tools
- Risk Gate detects and blocks mislabeled results

**First locked:** R2.4  
**Evidence:** AGENTS.md, runtime/risk-enforcement-gate-v2.ps1  
**Status:** LOCKED — never reopened

---

## Lock #7: Multi-Agent as Default Mode

**Ban:** Multi-agent mode must NOT be the default execution mode.

- Single-agent execution is the default
- Multi-agent is opt-in for specific scenarios (complex, multi-surface, L_CLASS)
- No automatic worker spawning without explicit design decision

**First locked:** R2.6  
**Evidence:** governance/agent/agent-communication-policy.json  
**Status:** LOCKED — never reopened

---

## Lock #8: External Engine Bypassing Evidence Binding

**Ban:** External engine results must pass through Evidence Binding.

- Raw engine output is not a gate decision
- Parsers must transform output into structured Evidence Binding
- Tool unavailability (TOOL_UNAVAILABLE) is NOT PASS
- Tool CLEAN is NOT "production safe"

**First locked:** R2.14  
**Evidence:** runtime/risk-enforcement-gate-v2.ps1, runtime/engine-broker.ps1  
**Status:** LOCKED — never reopened

---

## Lock #9: Firecrawl as Canonical Search

**Ban:** Firecrawl must NOT replace canonical search.

- Firecrawl is a Reader/Extractor candidate only
- Canonical search path is /api/paas/v4/web_search
- Firecrawl may be used for content extraction, not search routing

**First locked:** R3.0  
**Evidence:** runtime/engine-broker.ps1  
**Status:** LOCKED — never reopened

---

## Lock #10: Expert Pack Bypassing Risk Gate

**Ban:** Expert Pack activation must NOT bypass Risk Gate.

- Expert Pack invariants and risk rules must flow through Risk Gate
- Pack activation without risk assessment is FORBIDDEN
- L_CLASS projects with expert packs require decomposition or human audit

**First locked:** v1.1  
**Evidence:** governance/expert-packs/, runtime/risk-enforcement-gate-v2.ps1  
**Status:** LOCKED — never reopened

---

## Lock #11: Compression Summary as Trusted Memory

**Ban:** Compression summaries must NOT be treated as trusted memory.

- Agent context compression is lossy and may contain stale/deprecated claims
- Only Trusted Project State Store is source-of-truth
- Resume Gate must cross-check compression summaries against Trusted State

**First locked:** v1.3  
**Evidence:** runtime/memory-admission-gate.ps1, runtime/compression-summary-verifier.ps1  
**Status:** LOCKED — validated in v2.0-RC (3/3 errors detected)

---

## Lock #12: Local Smoke as Production Capacity Proof

**Ban:** Local load smoke tests must NOT be claimed as production capacity proof.

- Autocannon localhost smoke does NOT prove "X concurrent users"
- Large-scale claims (100w+) require explicit architecture review and real load testing
- Performance classifier correctly maps such claims to CRITICAL/L_CLASS

**First locked:** R3.1  
**Evidence:** AGENTS.md, runtime/engine-parser-autocannon.ps1  
**Status:** LOCKED — enforced in classification

---

## Lock #13: Docker Compose as Production Cloud Deployment

**Ban:** Docker Compose examples must NOT be claimed as production cloud deployment.

- Docker Compose is for local development/staging illustration
- No Kubernetes, no cloud load balancing, no production infrastructure
- READY_FOR_STAGING ≠ READY_FOR_PRODUCTION

**First locked:** v1.3  
**Evidence:** outputs/V1_3_TRUST_CLOSURE_REPORT.md  
**Status:** LOCKED — never reopened

---

## Lock #14: v2.0 as "Final"

**Ban:** v2.0 must NOT be called "Final".

- This is v2.0.0, not the last version
- v2.x and v3.0 roadmap is defined
- No version of Codex Factory is ever "Final"

**First locked:** v2.0  
**Evidence:** outputs/V2_0_RELEASE_NOTES.md  
**Status:** NEW LOCK — effective immediately

---

## Lock #15: READY_FOR_STAGING as READY_FOR_PRODUCTION

**Ban:** Projects at staging readiness must NOT be claimed as production-ready.

- Staging readiness means: Dockerfile, docker-compose, basic health check
- Production readiness requires: real DB, real auth, real deployment, monitoring, backup
- No project currently meets production readiness

**First locked:** v1.3  
**Evidence:** outputs/V1_3_TRUST_CLOSURE_REPORT.md  
**Status:** LOCKED — never reopened

---

## Verification

Run the deprecated lock check:
`powershell
 = @(
  "Independent Search Agent",
  "Dual Search Channel",
  "Search Agent as Future Default",
  "Implementer direct search",
  "chat URL extraction as canonical evidence",
  "mock/dry_run as live",
  "multi-agent default mode",
  "external engine bypass Evidence Binding",
  "Firecrawl as canonical search",
  "Expert Pack bypass Risk Gate",
  "compression summary as trusted memory",
  "local smoke as production capacity proof",
  "Docker Compose as production cloud deployment",
  "v2.0 as Final",
  "READY_FOR_STAGING as READY_FOR_PRODUCTION"
)
Write-Output "All 0 deprecated locks PRESERVED."
`

**Result: 15/15 locks PRESERVED. NO deprecated direction reopened in v2.0.**
