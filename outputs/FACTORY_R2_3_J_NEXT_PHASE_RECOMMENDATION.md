# R2.3-J Next Phase Recommendation

## Current State

R2.3-J complete:
- Tool/MCP registry with 10 entries
- 11-check permission gate operational
- 8 negative controls blocked correctly
- 15/16 simulation PASS
- 18/18 verification PASS
- TPP bridge operational
- Sandbox policy formalized

## Recommendation: R2.3-K — Frontend Tool Trial + Search Provider Adapter

### Rationale

The tool sandbox foundation is in place. The next step is to trial the lowest-risk tools from the registry in a controlled environment. Start with frontend verification tools (Playwright in sandbox) and a search provider adapter (read-only, no API keys).

### R2.3-K Should Include

1. **Playwright Sandbox Trial** — Run Playwright verifier in disposable workspace on a localhost project
2. **Search Provider Adapter** — Create a read-only search intake adapter (no API keys, uses pre-fetched/manual results)
3. **Tool-to-Skill Bridge** — Convert verified tools into importable skill packages
4. **CAP-SKILL-013/014 Runtime Trial** — Promote auditPassed skills to factoryRuntimeVerified

### What R2.3-K Should NOT Do
- Do NOT connect to real Stitch MCP
- Do NOT use real API keys
- Do NOT write to real project files from tools
- Do NOT skip sandbox for file-write tools
- Do NOT skip human approval for high-risk tools

### Pre-conditions Met
- [x] Tool registry operational
- [x] Permission gate blocks high-risk tools
- [x] Sandbox policy defined
- [x] Invocation ledger recording
- [x] Negative controls verified

### Pre-conditions Not Met
- [ ] Playwright installed in disposable workspace
- [ ] Search intake format defined for tool context
- [ ] Tool-to-skill conversion pipeline
