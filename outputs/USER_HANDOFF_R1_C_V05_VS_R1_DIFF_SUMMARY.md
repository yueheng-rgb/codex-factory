# USER-HANDOFF-R1 — C: v0.5 vs v0.5-R1 Difference Summary

## v0.5.0 (Stable)
Core local tooling: Build Lite, Native Build Pro, Context Packet, External Conversation Space, Snapshot/Attach, Phase Close, Package QA Gate, Security/Deploy Gate, factory CLI, 7 starters, 7 blueprints, 9 skills, codex-factory-plugin.

## v0.5.1-r1 (This Handoff)
v0.5 plus 7 theory phase integrations (82 additional files):

| # | Feature | What It Does |
|---|---------|-------------|
| 1 | **Default Workflow** | "Select folder + state requirement" auto-enters Factory flow. Cleanup = PLAN first. Handoff = full paths. |
| 2 | **Project Isolation** | projectId, pathFingerprint, contentFingerprint per project. Cross-project contamination blocked. |
| 3 | **State Dashboard** | `factory state` shows project identity, paths, agent ledger, health warnings. |
| 4 | **Recovery** | `factory recover --dry-run` detects stale/corrupt/missing/foreign state. |
| 5 | **Multi-Agent Orchestration** | Role profiles + contracts + handoffs + integrator. Requires user confirmation. Never auto-starts. |
| 6 | **Evidence Taxonomy** | E0-E8 levels. Prevents overclaim. Dashboard/snapshot/attach NOT primary evidence. |
| 7 | **Project Lifecycle** | 9 states. Transition matrix. Permission enforcement. Destructive ops require confirmation. |

## What R1 Does NOT Add
- Cloud service
- Production deployment
- Real project validation
- v0.6 features
- Automatic multi-agent start
- Native Build Pro as default
