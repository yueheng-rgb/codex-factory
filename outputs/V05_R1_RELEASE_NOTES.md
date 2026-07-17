# Codex Factory v0.5.1-r1 — Release Notes

> **Type:** LOCAL_TOOLING_PATCH_RELEASE
> **Base:** v0.5.0
> **Date:** 2026-06-29

---

## What Changed from v0.5

v0.5 delivered the core local tooling system: Build Lite, Native Build Pro, Context Packet, External Conversation Space, Phase Close, Package QA Gate, Security/Deploy Gate, factory CLI.

v0.5.1-r1 integrates 7 theory phases (263 verifier checks) completed after v0.5:

1. **Default Workflow** — "Select folder + state requirement" auto-enters Factory flow. Cleanup defaults to PLAN. Full paths in every handoff.
2. **Project Isolation** — Each project gets a projectId, pathFingerprint, contentFingerprint. Cross-project context contamination prevented.
3. **State Dashboard** — CLI dashboard (`factory state`) shows project identity, paths, phase, agent ledger, health warnings.
4. **Recovery** — Startup recovery scan detects missing/stale/corrupt/foreign state. Recovery prompts included.
5. **Multi-Agent Orchestration** — Role profiles (Planner, Builder, Skeptic, Verifier, Integrator). Contracts, handoffs, failure attribution. Multi-agent requires user confirmation.
6. **Evidence Taxonomy** — E0-E8 evidence levels. Prevents overclaim. Dashboard/snapshot/attach are NOT primary evidence.
7. **Project Lifecycle** — 9 states (NEW -> ACTIVE -> PAUSED/FROZEN/ARCHIVED/DELETED/MIGRATED/UNKNOWN/CORRUPT). Transition matrix with permission enforcement.

## What R1 Does NOT Do
- Not v0.6
- Not cloud service
- Not deployment tool
- Not production-hardened
- Multi-agent does NOT auto-start
- Build Lite NOT removed
- No real project validation included

## New CLI Commands
- `factory state` — Dashboard
- `factory state --json` / `--agents` / `--brief`
- `factory recover --dry-run` — Recovery scan
- `factory evidence check` — Evidence validator
- `factory cleanup plan` — Cleanup planning
- `factory lifecycle` — Lifecycle state

## Limitations
- Dashboard/recovery/evidence scripts are fixture-level prototypes; not production-hardened
- Multi-agent orchestration is policy + schemas; runtime integration depends on Codex platform capabilities
- CLI canonical name (`factory.ps1`) is a target; current entry is `factoryctl.ps1`

## Package Info
- **File:** codex-factory-core-v0.5.1-r1.zip
- **Size:** ~866 KB
- **SHA256:** D563C5E462314E9EEC858E3E0E9D4E2B4131B0546B3FA289B4BD8EB1BE5E6A6B
