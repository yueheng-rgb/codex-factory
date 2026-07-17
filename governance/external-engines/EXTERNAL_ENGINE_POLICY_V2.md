# External Engine Policy v2

**Version:** 2.0.0
**Applies to:** Codex Factory v1.x
**Last updated:** 2026-07-11

---

## Engine Categories

| Category | Engines | Purpose |
|----------|---------|---------|
| **security** | semgrep, codeql | Static analysis, vulnerability detection |
| **performance** | autocannon, k6 | Load testing, API smoke, throughput measurement |
| **ui-e2e** | playwright | Browser automation, UI smoke, E2E validation |
| **reader** | firecrawl-reader | Web page content extraction (NOT search) |

---

## Evidence Binding Policy

Every engine result MUST enter Evidence Binding with:

1. `engine_id` — which engine ran
2. `engine_version` — exact version
3. `run_status` — RUN / TOOL_UNAVAILABLE / TOOL_FAILED / SKIPPED / PROJECT_START_FAILED
4. `target_project` — which project was tested
5. `command_redacted` — command WITHOUT secrets
6. `result_summary` — human-readable summary
7. `findings` — structured findings if any
8. `parser_status` — parser result
9. `non_claims` — what this result does NOT prove
10. `skip_reason` — if skipped, why
11. `failure_classification` — if failed, what category

---

## Firecrawl Boundary (CRITICAL)

Firecrawl is a **reader/extractor only**. It MUST NOT:

- Replace canonical search (`/api/paas/v4/web_search`)
- Generate canonical Evidence Packs
- Be marked as `source_origin=canonical_search`
- Be used for P0_MUST_SEARCH gates

Firecrawl evidence MUST be marked `source_origin=firecrawl_reader`.

---

## Non-Claims per Engine

### autocannon / k6
- Local smoke only — NOT production capacity proof
- Dev-machine measurements — NOT reproducible benchmarks
- Does NOT prove million-concurrency capability

### semgrep / codeql
- CLEAN != bug-free or secure
- False negatives exist
- Not a replacement for manual security review

### playwright
- UI smoke != comprehensive E2E
- Does NOT cover all browser/device combinations

### firecrawl-reader
- NOT canonical search
- Content quality depends on target page structure

---

## Unavailable Engine Handling

| Engine | Reason | How to Activate |
|--------|--------|-----------------|
| codeql | CLI not installed | Download from github.com/github/codeql-cli-binaries |
| k6 | CLI not installed | `choco install k6` (Windows) or download from grafana.com |
| firecrawl-reader | No API key | Set `FIRECRAWL_API_KEY`, install `@mendable/firecrawl-js` |

All unavailable engines MUST be reported as `TOOL_UNAVAILABLE` with `INSTALL_REQUIRED`.
NEVER fake PASS for unavailable tools.
