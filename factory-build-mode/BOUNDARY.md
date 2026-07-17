# Build Mode — Boundary Document

## What Build Mode IS

### 1. The Mainline
Build Mode is the primary production mode of Codex Factory. It accepts project requirements and produces working code. All other modes (Diagnostic, Benchmark, Release) support Build Mode.

### 2. A Control Plane
Build Mode provides the decision framework, templates, and state structures. It does NOT implement projects itself — Codex does. Build Mode is the harness, Codex is the builder.

### 3. A Pipeline
The build pipeline has 9 stages:
0. INTAKE — Accept project requirements
1. CLASSIFY — Determine complexity
2. ROUTE — Select execution mode
3. BLUEPRINT — Generate architecture
4. TASK_GRAPH — Decompose into tasks
5. BUILD — Execute implementation
6. DIAGNOSTIC_GATE — Quality check (readonly)
7. REPAIR — Targeted fixes (user-approved)
8. DELIVER — Handoff and state finalization

### 4. Complexity-Aware
Build Mode scales with project complexity:
- SIMPLE → VANILLA_BUILD (single Codex, default)
- MEDIUM → BUILD_LITE (single Codex + harness guidance)
- LARGE → BUILD_REVIEWER (with Reviewer-Verifier)
- LONG_HORIZON → BUILD_CONTINUATION (session handoff)
- HIGH_RISK → BUILD_PRO_4_AGENT (conditional, not automatic)

### 5. State-Persistent
All build state lives under {project}/.codex-factory/:
- state.json — Current stage and progress
- rchitecture-map.json — Design decisions
- 	ask-graph.json — Work items
- decisions.md — Decision log
- isks.json — Active risks
- handoff-packet.md — Continuation summary

## What Build Mode Is NOT

- NOT a release package
- NOT v0.5
- NOT a multi-agent default
- NOT a product quality guarantee
- NOT a replacement for Vanilla
- NOT an automatic repair tool
- NOT a deployment tool

## Boundaries

| Layer | Default | When Active |
|-------|---------|-------------|
| Vanilla Codex | Always | Product implementation |
| Build Mode | On user request | Project production pipeline |
| Diagnostic Pack | Gate in pipeline | Post-build quality check |
| 4-agent P1 | OFF | >100 files, multi-app, HIGH_RISK |
| 7-agent / 10-role | CUT | Never |
| v0.5 release | BLOCKED | Never |

## Forbidden Patterns

- Diagnostic Pack as main product
- Multi-agent as default for simple projects
- Auto-repair after diagnostic
- Release packaging before build capability proven
- Treating Build Mode MVP as a finished product
- Confusing control-plane artifacts with product code
