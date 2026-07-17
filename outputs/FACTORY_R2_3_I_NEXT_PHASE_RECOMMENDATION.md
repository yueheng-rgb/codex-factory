# R2.3-I Next Phase Recommendation

## Current State

R2.3-I is complete:
- 4 skills in registry (1 factoryRuntimeVerified, 3 auditPassed)
- Real Agent Bridge operational (ARP/SCP/VCP packet generator)
- 3 benchmark projects (Next.js, CLI, Fastify API)
- Promotion policy formalized

## Recommendation: R2.3-J — MCP/Tool Sandbox Phase

### Rationale

The skill ecosystem now has:
- A working trust ladder (candidate → factoryRuntimeVerified)
- A bridge to real agents
- Multi-project benchmarks
- Audit pipeline for static security

The next logical step is to extend the audit/verification capability to cover MCP servers and tool-level sandboxing, as skill capabilities may include MCP servers, CLI tools, and external integrations.

### R2.3-J Should Include

1. **MCP Server Audit** — Extend audit pipeline to MCP server manifests
2. **Tool Sandbox** — Basic sandbox for testing skill tool usage without risk
3. **CAP-SKILL-013/014/015 Runtime Trial** — Promote auditPassed skills to factoryRuntimeVerified
4. **Real Agent Bridge Integration** — Test ARP consumption by actual Codex session
5. **External Skill Import** — Import 1-2 verified external skills through full pipeline

### What R2.3-J Should NOT Do

- Do NOT connect to external MCP servers
- Do NOT execute untrusted tools without sandbox
- Do NOT import unverified external skills
- Do NOT skip audit for any capability
- Do NOT claim full MCP ecosystem without sandbox verification

### Pre-conditions Met
- [x] Audit pipeline works on skills
- [x] Trust ladder defined
- [x] Bridge generates consumable packets
- [x] Multi-project benchmarks exist
- [ ] MCP schema understood (to be done in R2.3-J)
- [ ] Sandbox mechanism designed (to be done in R2.3-J)
