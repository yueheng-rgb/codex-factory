# Session Rotation Protocol

> **Category**: session-rotation | **Stability**: stable
>
> Defines when and how to rotate sessions in a Codex Factory project.
> Session rotation ensures clean state handoff between work periods.

---

## When to Rotate

Rotate sessions when ANY of the following triggers fire:

### Mandatory Rotation Triggers

| Trigger | Threshold | Action |
|---------|-----------|--------|
| **Phase Boundary** | Current phase marked `closed` | Rotate before starting next phase |
| **Context Pressure** | Compression level reaches `critical` per `compression-policy.md` | Rotate immediately |
| **Stale Agent Detected** | Agent in `in_progress` > session staleness threshold | Rotate after resolving stale agent |
| **Hardware/Environment Change** | New machine, new shell, new Codex instance | Rotate on new environment |
| **Explicit User Request** | User asks for new session | Rotate per user request |
| **Time Threshold** | Session duration > 8 hours of active work | Rotate at next natural break |

### Recommended Rotation Triggers

| Trigger | Threshold | Action |
|---------|-----------|--------|
| **Agent Count Threshold** | > 20 agents in current session | Consider rotation at phase boundary |
| **Transcript Size** | Agent transcript exceeds practical limits | Consider rotation |
| **Cognitive Load** | Main Agent notes context fragmentation | Consider rotation |

---

## Pre-Rotation Requirements

Before rotating, the current session MUST:

### 1. Run `factoryctl verify` (Preflight)

```powershell
.\factory-resource-pack\core\factoryctl\factoryctl.ps1 verify
```

**Required**: Exit code must be 0. If verification fails, the rotation is blocked until issues are resolved.

Blocking failures:
- Unmet P0 complexity floors
- P0 verifier gaps not addressed
- Stale agents in non-terminal state
- Corrupted registry files

### 2. Complete Current Phase or Mark Pause Point

- If phase is complete: generate `CLOSURE.json`
- If phase is in progress: record pause point with current state snapshot
- Document all in-progress work and next steps

### 3. Generate Session Rotation Handoff

```powershell
.\factory-resource-pack\core\handoff\generate-handoff.ps1 `
    -OutputPath "session-rotation-handoff.json" `
    -CurrentPhase "<phase-id>" `
    -SessionId "<session-id>"
```

### 4. Verify Handoff Integrity

```powershell
.\factory-resource-pack\core\handoff\handoff-verify.ps1 `
    -HandoffPath "session-rotation-handoff.json"
```

### 5. Mark All Agents Terminal

- All agents MUST be in one of: `completed`, `failed`, `closed`
- No agent may remain `in_progress` across rotation
- Mark `stale` agents appropriately before rotation

### 6. Record Rotation Event

```powershell
.\factory-resource-pack\core\agent-tracking\record-progress.ps1 `
    -Event "Session rotation: $(Get-Date -Format o)" `
    -NextSessionId "<next-session-id>"
```

---

## Handoff Contents

The `session-rotation-handoff.json` MUST contain:

```json
{
  "handoffVersion": "1.0",
  "previousSessionId": "string",
  "nextSessionId": "string",
  "rotationTimestamp": "ISO8601",
  "handoffIsCurrent": true,
  "previousSessionClosed": true,
  "currentPhase": {
    "phaseId": "string",
    "phaseStatus": "closed|in_progress|paused",
    "closureRef": "string (path to CLOSURE.json if closed)"
  },
  "agentState": {
    "totalAgents": "number",
    "completedAgents": "number",
    "failedAgents": "number",
    "closedAgents": "number",
    "staleAgents": "number"
  },
  "verifierState": {
    "lastVerifierRun": "ISO8601",
    "lastVerifierVerdict": "PASS|FAIL",
    "lastVerifierRef": "string"
  },
  "allowedNextPhase": ["list of valid next phase IDs"],
  "unresolvedItems": [
    {
      "id": "string",
      "priority": "P1|P2",
      "description": "string",
      "deferredToPhase": "string"
    }
  ],
  "pausePoint": {
    "description": "string (if phase is paused)",
    "resumeInstructions": "string"
  },
  "nativeGenerated": true,
  "generatedBy": "string (agent role)"
}
```

---

## Post-Rotation Validation

After starting the new session, the new Main Agent MUST:

### 1. Run `factoryctl verify`

```powershell
.\factory-resource-pack\core\factoryctl\factoryctl.ps1 verify
```

### 2. Verify Handoff

```powershell
.\factory-resource-pack\core\handoff\handoff-verify.ps1 -HandoffPath "session-rotation-handoff.json"
```

### 3. Confirm No Stale Agents

- New session must start with zero `in_progress` agents
- All agents from previous session must be terminal

### 4. Confirm Allowed Next Phase

- Current phase must be in `allowedNextPhase` from handoff
- If not, escalate: phase progression anomaly

### 5. Run Session Startup Checklist

Follow `bootstrap/session-rotation-startup-checklist.md` in full.

---

## Rotation Blockers

The following conditions BLOCK session rotation:

| Blocker | Resolution |
|---------|------------|
| `factoryctl verify` fails | Fix verification failures first |
| Agent in `in_progress` | Mark terminal or resolve |
| Handoff generation fails | Debug handoff script, regenerate |
| Handoff verification fails | Debug handoff integrity issue |
| Corrupted registry files | Repair registry, re-verify |
| Unresolved P0 gaps | Escalate to Main Agent |

---

## Emergency Rotation

If a session must be rotated urgently (crash, force-close, environment loss):

1. Attempt emergency handoff generation with whatever state is available
2. Mark emergency rotation in handoff: `"emergencyRotation": true`
3. New session MUST run full verification before any work
4. New session MUST audit state integrity before continuing
5. Emergency rotations are recorded as P1 incident

---

## SCORING_SYSTEM_GATE

Per `SCORING_SYSTEM_GATE.md`: Session rotation handoff must use verifier-based gating. No scoring system may determine whether rotation is allowed.
