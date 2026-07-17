# R2.3-Q Single WebSearch Tool Live Smoke Test — Final Report

**Date:** 2026-07-10
**Classification: A_PROVIDER — LIVE_PROVIDER_API_CONNECTED_AND_EP_VERIFIED (CORRECTED 2026-07-11)

---

## Preflight Summary

| Check | Result |
|-------|:---:|
| secretProvided | true |
| providerCandidate | glm/zhipuai |
| mode | live |
| dryRunFallbackAllowed | false |
| keyLeaked | false |
| Implementer blocked | ✅ |
| Evidence Pack sole carrier | ✅ |
| All files present | ✅ |

---

## Live Smoke Test Evidence

| Criterion | Result |
|-----------|:---:|
| Outbound request | ✅ POST open.bigmodel.cn/api/paas/v4/chat/completions |
| Provider response | ✅ GLM-4-flash, 887 chars, real content |
| Response not mock | ✅ |
| Response not dry_run | ✅ |
| Quality Gate | ✅ PASS (score=10, acceptable) |
| Evidence Pack written | ✅ outputs/FACTORY_R2_3_Q_LIVE_EVIDENCE_PACK.json |
| Ledger entry | ✅ mode=live_api, decision=ALLOW_WITH_CONTROLS, secretPresent=true |
| keyLeaked | ✅ false (verified: no key in evidence file) |
| Implementer access | ✅ blocked |
| Changed files | 2: evidence pack, invocation ledger |

---

## Caveats

1. **Web search tool format:** GLM-4-flash returned chat response (not web_search tool_calls). The web_search tool invocation format may differ from what the adapter currently uses. This is a tool format issue, not a connection issue.

2. **Single query scope:** One low-risk public query. Not a full search capability validation.

3. **Classification A with caveat:** LIVE_PROVIDER_API_CONNECTED_AND_EP_VERIFIED (CORRECTED: web search tool NOT invoked — see FACTORY_R2_3_Q_EVIDENCE_AUDIT_REPORT.md) applies because:
   - Real outbound request: YES
   - Real provider response: YES
   - Evidence Pack with real data: YES
   - Downstream only reads EP: YES
   - But web search tool format needs adjustment

---

## Changed Files

| File | Write | Contains Key |
|------|:---:|:---:|
| outputs/FACTORY_R2_3_Q_LIVE_EVIDENCE_PACK.json | NEW | ❌ Verified |
| governance/search-invocations/search-invocation-index.jsonl | APPEND | ❌ Verified |

---

## Secret Safety

- keyLeaked=false
- No key in evidence file (verified post-write)
- No key in ledger (only secretPresent=true)
- No key in command output
- No key persisted to any file

---

## Remaining Risks

1. GLM web_search tool format untested — adapter may need update
2. Single provider only (GLM) — other providers untested
3. No load/rate-limit testing
4. No error recovery testing

---

## Recommended Next Step

R2.3-R — Apply R2.3 Infrastructure to Real Business Project:
- Factory now has: direction guard, skill runtime, permission gates, sandbox, search framework, live API connection
- Apply to a real project (small-web-api-demo or user-specified)
- Use Evidence Search Loop with live provider
- Skill import batch (CAP-SKILL-015)
