# H18 Core Resource Pack

Operational entrypoints for the Codex Factory governance system.

## factoryctl/
- actoryctl.ps1 — Control plane: status, agents, progress, watch
- REPO-LOCAL: invoke as .\factory-resource-pack\core\factoryctl\factoryctl.ps1 status
- NOT on system PATH by default

## agent-tracking/
- egister-agent.ps1 — Register spawned agents in AGENT_REGISTRY.json
- ecord-progress.ps1 — Record progress events in AGENT_PROGRESS.jsonl
- ppend-factory-event.ps1 — Append generic factory events

## handoff/
- generate-handoff.ps1 — Generate session rotation handoff JSON
- handoff-verify.ps1 — Verify handoff SHA256 integrity

## Usage
1. Copy actory-resource-pack/ to your Factory project root.
2. Run ./bootstrap/validate-resource-pack.ps1 to verify integrity.
3. Integrate into your phase workflow.