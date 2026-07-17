# FACTORY-BUILD-0 / I: Next Phase Instruction Draft

> **Target Phase**: FACTORY-BUILD-1 / Build Mode MVP
> **Generated**: 2026-06-27
> **For**: A new Codex window to execute as one large phase

---

## Instruction for FACTORY-BUILD-1 / Build Mode MVP

> Copy the following into a new Codex window to begin.

---

Phase: FACTORY-BUILD-1 / Build Mode MVP

You are building the Codex Factory Build Harness MVP — a complex project production harness that helps Codex build real projects from requirements to delivery.

## Context

FACTORY-BUILD-0 has completed the mainline reset. Codex Factory's core goal is to help Codex achieve its ceiling on complex projects. Diagnostic Pack v1.1.0 is a safety gate, not the product. SkillMarket is closed as evidence.

The Build Harness MVP must be a functional pipeline: intake → classify → route → blueprint → task graph → build → diagnostic gate → deliver.

## What to Build (10 Components)

### 1. Project Intake
Create starters/build-harness/intake.md — a prompt template that:
- Accepts project path or requirements description
- Reads existing codebase or starts greenfield
- Produces a project manifest: type, tech stack, scope, existing assets
- Gate: Proof-of-Read confirmation

### 2. Complexity Classifier
Create starters/build-harness/classifier.md — a decision guide that:
- Counts files, detects auth/DB/API presence
- Classifies as SIMPLE (<10 files, no auth), MODERATE (10-100, auth/DB), COMPLEX (>100, multi-app, auth, DB)
- Assesses risk: auth, financial, compliance
- Output: classification + risk level

### 3. Mode Selector
Create starters/build-harness/mode-selector.md — routes based on classification:
- SIMPLE → Vanilla Mode (single agent, standard Codex)
- MODERATE → Build Lite (single agent + harness guidance)
- COMPLEX → Build Pro (4-agent P1, conditional)
- Diagnosis-only goal → Diagnostic Gate only, skip build

### 4. Blueprint Generator
Create starters/build-harness/blueprint-generator.md — generates:
- Page tree with first-version scope
- API endpoint outline
- DB schema sketch (entities + relationships)
- Permission boundaries (roles + access)
- Tech stack confirmation

### 5. Task Graph Generator
Create starters/build-harness/task-graph-generator.md — produces:
- Task nodes decomposed from blueprint
- Dependency ordering
- File ownership per node
- Effort estimate per node

### 6. Build Execution Engine
Create starters/build-harness/build-execution.md — defines:
- Single-agent execution flow (default)
- State management during build
- Stage-gate enforcement between blueprint→task-graph→build→diagnostic
- Error handling and retry logic

### 7. Diagnostic Gate Integration
Create starters/build-harness/diagnostic-gate.md — integrates Diagnostic Pack:
- Select diagnostic mode based on complexity
- Run readonly checklist after build
- Flag gaps without auto-fix
- Gate: 0 critical → proceed. Critical → repair decision.

### 8. State File Management
Create starters/build-harness/state-file-schema.json — defines:
- state.json schema with stage tracking
- Update rules: when and what to write

### 9. One-Command Template
Create starters/build-harness/BUILD_HARNESS_STARTUP.md — a single prompt that:
- A new Codex window can read to start the Build Harness
- Includes all routing logic
- References all component files
- Contains the complete instruction set

### 10. Verifier + Negative Controls
Create scripts/factory-build-1-verify.ps1 — verifies:
- All 9 components exist
- Classifier produces correct output for sample projects
- Mode selector routes correctly
- Blueprint completeness
- Task graph coverage
- Diagnostic gate wired
- State file schema valid
- At least 15 negative controls

## Constraints

- Do NOT create ZIP
- Do NOT start benchmark
- Do NOT declare multi-agent default
- Do NOT claim product quality superiority
- Do NOT modify existing product code outside build-harness/
- Diagnostic Pack is a GATE, not the product
- Multi-agent is CONDITIONAL, not default
- Build Pro (4-agent) is for COMPLEX projects only

## Deliverables

- starters/build-harness/ — all 9 component files
- scripts/factory-build-1-verify.ps1 — verifier
- outputs/FACTORY_BUILD_1_BUILD_MODE_MVP_REPORT.md — summary
- governance/factory-build/factory-build-1-result.json — machine result
- governance/factory-build/verifier-factory-build-1-result.json — verifier JSON

## Success Criteria

A new Codex window, given a project path, can:
1. Read BUILD_HARNESS_STARTUP.md
2. Run intake → classify → route → blueprint → task graph
3. Execute build (single-agent default)
4. Run diagnostic gate
5. Report results with state file updated
