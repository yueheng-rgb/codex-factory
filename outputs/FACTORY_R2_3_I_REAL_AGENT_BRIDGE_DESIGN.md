# R2.3-I Real Agent Bridge Design

**Phase:** FACTORY-R2.3-I | **Date:** 2026-07-10

## Purpose

Bridge Factory skill packages to real Codex agent sessions via consumable context packets. The bridge does NOT assume control over Codex internals — it generates external context injection packets.

## Packet Types

| Packet | Schema | Purpose |
|--------|--------|---------|
| Agent Run Packet (ARP) | `schemas/agent-run-packet.schema.json` | Full agent session context with loaded skills |
| Skill Context Packet (SCP) | Inline in ARP schema | Single skill summary for targeted injection |
| Verification Command Packet (VCP) | Inline in ARP schema | Verification checklist for verifier agents |

## ARP Structure

```json
{
  "packetId": "ARP-{projectId}-{phaseId}-{agentId}-{timestamp}",
  "projectId": "...",
  "agentId": "...",
  "loadedSkillRefs": [
    {
      "skillId": "CAP-SKILL-004",
      "trustLevel": "VERIFIED",
      "status": "factoryRuntimeVerified",
      "summary": "<500 char instruction summary>",
      "allowedTools": ["read"],
      "forbiddenActions": ["write_project_code", ...],
      "triggerConditions": ["project has AGENTS.md", ...]
    }
  ],
  "forbiddenActions": ["<deduplicated across all skills>"],
  "handoffRequired": true,
  "trustStatusNote": "..."
}
```

## Key Design Decisions

1. **Summary, not full content** — Packets include max 500-char instruction summary to avoid context bloat
2. **Trust transparency** — Each skillRef includes trustLevel and status so agents know what they're loading
3. **Deduplicated constraints** — forbiddenActions from all skills are merged and deduplicated
4. **No MCP/API dependency** — Packets are local JSON files, no network needed

## Example Output

`examples/agent-run-packets/arp-pm-001-fullstack-admin.json` — 3-skill ARP for PM-001 on fullstack-admin project
