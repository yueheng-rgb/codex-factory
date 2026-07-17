# Task Decomposition Engine

## Overview

The Task Decomposition Engine analyzes a project requirement and automatically produces:
- Task graph with dependencies
- Multi-agent worker plan
- Validation plan per task
- Risk classification
- Evidence requirements
- Agent execution plan

## Usage

```powershell
pwsh -File runtime/task-decomposition-engine.ps1 -Requirement ./my-requirement.md -OutputDir ./output

# Or pass requirement text directly
pwsh -File runtime/task-decomposition-engine.ps1 -Requirement "Build an admin dashboard with JWT auth and PostgreSQL"
```

## Inputs

| Input | Required | Description |
|---|---|---|
| `-Requirement` | Yes | Path to requirement .md file or raw text |
| `-OutputDir` | No | Output directory for generated plans |
| `-Json` | No | Output JSON to stdout |

The engine also reads:
- `factory.config.json` — for provider config
- `packs/enabled-packs.json` — for skill pack matching
- `knowledge/evidence/evidence-pack.json` — for knowledge referencing

## Outputs

| File | Description |
|---|---|
| `task_graph.json` | Nodes (tasks) + edges (dependencies) |
| `worker_plan.json` | Main agent + integrator + worker assignments |
| `validation_plan.json` | Per-task validation methods + global gates |
| `risk_classification.json` | P0-P3 risk levels with required gates |
| `agent_execution_plan.json` | Phase order + agent assignments + acceptance criteria |
| `engine-full-output.json` | All results combined |

## Project Type Detection

The engine detects project type from requirement keywords:
- `admin-system` — admin, dashboard, CRUD, role-based
- `ecommerce` — cart, order, payment, product catalog
- `miniapp` — wechat, mini program, wxml
- `saas` — multi-tenant, subscription, billing
- `backend-api` — REST API, GraphQL, microservice
- `game-threejs` — game, three.js, webgl
- `cpp-tool` — C++, native, cmake

If confidence is low, the engine outputs `NEED_USER_CLARIFICATION` instead of guessing.

## Risk Classification

| Level | Criteria | Required Gates |
|---|---|---|
| P0 | Auth, payment, permissions, production deploy | snapshot-verify + secret-scan + review-gate + artifact-gate |
| P1 | Database schema, API contracts, file uploads | snapshot-verify + secret-scan + review-gate |
| P2 | Business logic, CRUD, workflows | snapshot-verify + secret-scan |
| P3 | Documentation, styles, non-critical | snapshot-verify |
