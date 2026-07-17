# FACTORY R2.3-D Monitor-Only Visibility Policy

## Policy Statement

Capabilities with `recommendedAction` = "monitor" are **globally visible as reference material** to all agents, but **cannot be invoked** by any agent. They appear in `monitorOnlyCapabilities` (never in `allowedCapabilities`), and any invocation attempt returns `MONITOR_ONLY`.

## Rationale

This is a conscious design tradeoff from R2.3-C:

- **Visibility ≠ Permission:** Knowledge of a capability's existence is not permission to use it
- **Cross-role awareness:** All agents benefit from knowing what capabilities exist, even if they can't use them
- **Security through gate, not obscurity:** Hiding capability existence from agents doesn't improve security; the gate is the enforcement point

## Gate Behavior

The monitor check (CHECK 4) runs BEFORE:
- Agent eligibility (CHECK 5)
- Project type applicability (CHECK 6)
- Secrets check (CHECK 7)
- File write check (CHECK 8)
- Network restrictions (CHECK 9)
- Cloud restrictions (CHECK 10)
- Human confirmation (CHECK 11)
- Sandbox check (CHECK 12)

This means monitor-only capabilities short-circuit ALL later checks. They are visible to unregistered agents, wrong project types, and agents without auth — but only as reference.

## What "Monitor-Only" Means

| Allowed | Forbidden |
|---------|-----------|
| ✅ Read capability metadata (name, type, description) | ❌ Import the capability into project |
| ✅ Include in capability plan as reference | ❌ Execute the capability |
| ✅ Cross-reference in research | ❌ Configure the capability |
| ✅ Use as knowledge for architecture decisions | ❌ Invoke MCP server |
| ✅ Track in registry diff | ❌ Appear in allowedCapabilities bucket |
| | ❌ Bypass gate via "monitor but invoke" |

## Capabilities Currently Marked Monitor-Only

39 of 91 capabilities have `recommendedAction=monitor`, including:
- MCP servers awaiting integration (Stitch, Figma, Brave Search, Context7, Memory, Security Scanner, Package Manager)
- Cloud services (Supabase, Vercel, Object Storage, Queue, Secrets Manager, Observability)
- Community search providers (Zhihu/Juejin/CSDN)
- Generators and templates not yet validated
- External knowledge sources not yet reviewed

## Transition Path (Monitor → Import)

1. Capability is `monitor` → visible to all as reference
2. Librarian agent reviews + Security agent audits → recommendation to upgrade
3. Architect agent approves engineering applicability
4. `recommendedAction` changed to `import` or `adapt`
5. Next Bootstrap cycle picks up the change

## Verified (R2.3-D Simulation)

- Scenario G: IMPL-FE-001 tries to execute CAP-MCP-001 (Stitch, monitor) → MONITOR_ONLY ✓
- Scenario D: Research agent + search providers → monitor_only bucket populated ✓
- Scenario C: Network-restricted MCPs still visible as monitor_only ✓
