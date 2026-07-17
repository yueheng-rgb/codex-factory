# Context Packet Simulation

## Simulated Scenario: BUILD-8 to PRO-2 Handoff

### Step 1: Ingest BUILD-8 memory
- Read .codex-factory/ files from BUILD-8 RUN-PRO
- Filter: keep L3+ (verifier JSON, decision log, task graph, agent registry)
- Discard: L0-L1 (conversation, self-reports)

### Step 2: Generate context packet for PRO-2 Orchestrator
```json
{
  "packetId": "atlasops-pro2-orchestrator-20260627",
  "criticalState": {
    "projectPhase": "PRE-PRO-2",
    "currentStatus": "BUILD-8 complete, PRO-P1 hardened",
    "activeBlockers": ["PRO-2 not yet started"]
  },
  "decisions": [
    {"id":"D01","decision":"Build Lite = practical default","evidencePath":"factory-build-8-result.json"},
    {"id":"D02","decision":"Native Build Pro = conditional","evidencePath":"factory-build-pro-p1-result.json"}
  ],
  "risks": [
    {"id":"R01","risk":"Long-horizon native agent lifecycle untested","severity":"medium"}
  ],
  "rejectedClaims": [
    {"claim":"v0.5 release ready","reason":"Insufficient evidence","evidencePath":"factory-build-8-p1-strategy-freeze.json"},
    {"claim":"multi-agent default","reason":"Rejected under current evidence"}
  ],
  "evidenceReferences": [
    {"type":"verifier","path":"verifier-factory-build-8-result.json","hash":"(computed)"},
    {"type":"hash","path":"BUILD-8 product server.js","hash":"(computed)"}
  ],
  "forbiddenActions": [
    "Do not create v0.5 package",
    "Do not claim multi-agent default",
    "Do not modify BUILD-8 products"
  ],
  "nextSteps": ["Start PRO-2 when user approves"]
}
```

### Step 3: Validate packet
- Size check: ~200 words → PASS
- Evidence paths: 4 L4+ references → PASS
- Risks: all active → PASS
- No L0-L1 content → PASS
- Packet VALID

### Step 4: Role-filtered packets
- Orchestrator: full packet
- worker-backend: critical state + decisions + next steps + forbidden actions
- worker-verify: evidence section + risks + rejected claims
