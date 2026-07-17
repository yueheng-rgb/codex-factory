# FACTORY-DEFAULT-WORKFLOW-0 — B: Default Startup Protocol Report

> Phase: FACTORY-DEFAULT-WORKFLOW-0
> Section: B — Default Startup Protocol
> Date: 2026-06-28

## Deliverables

| File | Path |
|------|------|
| Protocol Definition | `factory-workflow/DEFAULT_FACTORY_STARTUP_PROTOCOL.md` |
| Governance JSON | `governance/factory-workflow/factory-default-workflow-0-default-startup-protocol.json` |

## Protocol Summary

The Default Startup Protocol defines a 10-step sequence:

1. **Factory Presence Detection** — check for `.codex-factory/`
2. **Installation Recommendation** — offer v0.5 install if missing
3. **Read AGENTS.md** — apply project-level instructions
4. **Factory Bootstrap** — Router + Stack Decision
5. **Router / Project Type Detection** — classify simple vs complex
6. **Preflight** — workspace state, blockers
7. **Code Gate** — do NOT write code yet
8. **Text Discussion** — project type, complexity, risks, mode, multi-agent
9. **Multi-Agent Decision Gate** — mandatory question for large projects
10. **Proceed After Mode Decision** — only after confirmation

## Key Design Decisions

- **Build Lite is default** — Native Build Pro is conditional, never default
- **Multi-agent requires explicit confirmation** — cannot start silently
- **Bootstrap is mandatory** — only explicit user override can skip
- **Discussion precedes code** — always

## Verification

- [x] Protocol file created
- [x] All 10 steps defined
- [x] Anti-bypass rules documented
- [x] Default mode priority table defined
- [x] Governance JSON created
