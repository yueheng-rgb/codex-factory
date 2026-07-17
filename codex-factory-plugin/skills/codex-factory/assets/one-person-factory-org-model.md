# One-Person Factory Organizational Model

> Phase: H18 · Category: role-model · Stability: stable

## Abstract

The One-Person Factory is an organizational model where a single human founder
operates a full software production capability through a structured ensemble of
Codex agents. Each agent role maps to a traditional company function, allowing
one person to wield the output bandwidth of a small team while maintaining sole
ownership of product vision, budget, and risk acceptance.

## Core Premise

The founder is the sole human. Every other role is instantiated as a Codex agent
or agent ensemble governed by factory protocols. No agent role carries independent
authority to ship, spend, or accept risk without founder or protocol gate.

## Role → Company Function Mapping

| Agent Role | Company Analogy | Scope Boundary |
|---|---|---|
| **User/Founder** | CEO / Product Owner | Vision, budget, risk acceptance, ship authority |
| **Main Agent / Orchestrator** | CTO / Engineering Director | Task graph, assignment, scheduling, closure decisions |
| **Architect** | Principal Architect | System design, tech choices, dependency modeling |
| **Planner / PM** | Product Manager / Scrum Master | Scope decomposition, milestone planning, dependency ordering |
| **Builder** | Senior Engineer | Implementation within scoped contract |
| **Integrator** | Release Manager | Sole merge owner, dependency graph management |
| **Verifier** | QA Director / Auditor | Readonly verification, gate enforcement, JSON verdicts |
| **Auditor** | Compliance Officer | Process audit, protocol adherence, drift detection |
| **Platform / factoryctl** | DevOps / Platform Engineering | Agent registry, progress ledger, handoff state, tooling |
| **Memory / Handoff / Progress Ledger** | Institutional Knowledge DB | Session continuity, handoff artifacts, progress events |
| **Contract / Governance Layer** | Legal / Governance | Contract definitions, authority boundaries, rule enforcement |

## Distribution Principle

Role distribution is not about simulating a company org chart. It is about:

1. **Separation of concerns** — No agent both writes and verifies its own work.
2. **Checks and balances** — Builder, Integrator, Verifier, and Auditor are independent.
3. **Evidence chain** — Every completion claim must be independently verifiable.
4. **Sole ownership** — The founder is the only entity that can accept risk, ship, or override gates.

## Authority Model

- **Founder authority**: Absolute. May override any gate with explicit acknowledgment.
- **Protocol authority**: Encoded in governance layer. Applies to all agents including Main Agent.
- **Agent authority**: Scoped strictly to defined role outputs. No agent may self-expand scope.
- **Verifier authority**: Veto on PASS/FAIL. Readonly. Cannot modify implementation.
- **Integrator authority**: Sole merge owner. May request repairs but cannot modify worker scope.

## Information Asymmetry Controls

The model explicitly prevents information asymmetry problems:

- Verifier is readonly and cannot be the same agent as Builder or Integrator.
- Integrator cannot self-verify merges.
- Main Agent cannot write worker implementation scope undeclared.
- Progress events must precede completion claims; stale progress invalidates claims.
- Summary is not evidence unless corroborated by verifier result.

## Failure Isolation

Each role has defined failure modes (see `agent-role-matrix.json`). When a role fails:

1. The failure is classified (P0/P1/P2) per `p0-p1-p2-decision-protocol.md`.
2. P0 failures block closure unconditionally.
3. P1 failures block next-phase advancement until repaired.
4. P2 failures are recorded as non-blocking caveats.

## Relationship to Factory Protocols

This organizational model is operationalized by the protocols in `factory-resource-pack/protocols/`:

- `main-agent-scheduling-protocol.md` — How Orchestrator schedules work
- `worker-reporting-protocol.md` — How workers report completion
- `integrator-verifier-boundary.md` — Integrator/Verifier separation
- `p0-p1-p2-decision-protocol.md` — Failure classification
- `evidence-hierarchy.md` — What counts as evidence
- `claim-classification.md` — How claims are classified
- `scoring-system-policy.md` — Why scores are prohibited for gating

## Anti-Patterns

- Main Agent writing implementation code inside a worker''s scope
- Integrator self-verifying merges
- Builder marking own work as PASS
- Treating compressed summaries as evidence
- Allowing score-based gating instead of binary verifier checks
- Collapsing Architect and Builder into one agent for the same module

## Version

| Field | Value |
|---|---|
| Phase | H18 |
| Category | role-model |
| Stability | stable |
| Depends on | BOUNDARY.md, SCORING_SYSTEM_GATE.md |
| Referenced by | agent-role-matrix.json, all protocols/ |
