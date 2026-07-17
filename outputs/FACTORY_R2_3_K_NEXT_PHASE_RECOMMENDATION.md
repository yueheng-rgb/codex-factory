# R2.3-K Next Phase Recommendation

## Current State

R2.3-K complete:
- Playwright sandbox trial: 6/6 PASS (real execution)
- Read-only search adapter operational
- Search quality gate formalized
- Simulation 10/10 PASS
- Verification 21/21 PASS

## Recommendation: R2.3-L — Capability Ecosystem Audit + Network Boundary Refinement

### Rationale

Two gaps emerged from R2.3-J/K:
1. **Network boundary granularity**: Playwright's networkAccess=true flagged REJECT even for localhost-only use. Need to distinguish localhost/loopback from external network.
2. **Tool sandbox hardening**: With Playwright proven in sandbox, time to formalize sandbox lifecycle (create → execute → verify → cleanup → ledger)

### R2.3-L Should Include

1. **Network Boundary Refinement** — Add `networkScope` to tool capability schema (none/localhost/allowlisted/external)
2. **Sandbox Lifecycle Manager** — Create a sandbox lifecycle manager for disposable workspaces
3. **Tool-to-Skill Bridge MVP** — Convert Playwright verifier trial results into a formal skill package
4. **CAP-SKILL-013/015 Runtime Trial** — Promote auditPassed skills

### What R2.3-L Should NOT Do
- Do NOT connect Stitch MCP
- Do NOT use real API keys
- Do NOT skip sandbox for file-write tools
- Do NOT grant network access without scope definition
