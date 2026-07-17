# Native Build Pro User Commands

## Activation
```
User: "Use Native Build Pro for [project-name]"
Codex: Checks readiness gate → if READY, proceeds; if BLOCKED, reports why and offers Build Lite.
```

## Spawn Command Templates
```
Orchestrator to worker-backend:
  spawn_agent agent_type=worker fork_context=false
  message="You are worker-backend. SCOPE: [files]. TASK: [description]. RULES: [rules]."

Orchestrator to worker-frontend:
  spawn_agent agent_type=worker fork_context=false
  message="You are worker-frontend. SCOPE: [files]. TASK: [description]. RULES: [rules]."

Orchestrator to worker-verify:
  spawn_agent agent_type=worker fork_context=false
  message="You are worker-verify. SCOPE: [files]. READONLY for product code. TASK: [description]."
```

## Monitor Commands
```
Orchestrator: wait_agent targets=[agent-ids] timeout_ms=300000
Orchestrator: close_agent target=agent-id  (after verifying output)
```

## Audit Commands
```
Verifier: Check agent registry → all completed, 0 stale/orphan
Verifier: Check write-scope map → 0 violations
Verifier: Check close receipts → all present
Verifier: Run diagnostic gate → PASS
```

## Post-Run Commands
```
User: "Freeze Build Pro run [phase-id]"
Codex: Runs lifecycle audit → if clean, freezes evidence.
```
