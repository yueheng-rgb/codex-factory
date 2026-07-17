# Context Packet Model

## Definition
A context packet is a filtered, minimal, high-quality document generated from external memory for a specific phase, agent role, or reader. It is what Codex should read before acting in a new session or phase.

## Structure
```json
{
  "packetId": "project-phase-role-timestamp",
  "generatedAt": "ISO-8601",
  "targetAudience": "orchestrator|worker-backend|worker-frontend|worker-verify|reviewer|user",
  "evidenceLevel": "L4",
  "sections": {
    "criticalState": {
      "projectPhase": "string",
      "currentStatus": "string",
      "activeBlockers": ["string"]
    },
    "decisions": [
      {"id": "string", "decision": "string", "rationale": "string", "evidencePath": "string"}
    ],
    "risks": [
      {"id": "string", "risk": "string", "severity": "string", "status": "string"}
    ],
    "rejectedClaims": [
      {"claim": "string", "reason": "string", "evidencePath": "string"}
    ],
    "evidenceReferences": [
      {"type": "verifier|hash|handoff|close-receipt", "path": "string", "hash": "string"}
    ],
    "forbiddenActions": ["string"],
    "nextSteps": ["string"]
  },
  "excludedFromPacket": {
    "rawConversation": true,
    "unverifiedClaims": true,
    "redundantState": true
  }
}
```

## Size Budget
- Critical state: max 500 words
- Decisions: max 10 most recent relevant
- Risks: all active
- Total packet: max 2000 words (fits in ~3000 tokens)
