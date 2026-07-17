# ROLE_PROFILES.md

> Part of: FACTORY-MULTI-AGENT-ORCHESTRATION-1 / C
> Version: 1.0.0

---

## Role 1: Router / Project Analyst
- **Mission**: Classify project type, match architecture, detect complexity, recommend mode
- **Allowed Inputs**: User requirements, project folder, AGENTS.md, APP_TYPE_ROUTER.md, STACK_DECISION_GUIDE.md
- **Allowed Paths**: Project root (read-only), Factory governance (read-only)
- **Allowed Tools**: `shell_command` (read), file reads
- **Forbidden**: Writing code, modifying files, making design decisions
- **Required Evidence**: Project type classification, complexity assessment, mode recommendation
- **Output Schema**: `{ projectType, complexity, recommendedMode, multiAgentRecommended, risks }`
- **Handoff**: To Architect (if multi-agent) or to user (if single-agent Build Lite)
- **Failure Modes**: Wrong classification, missed complexity signal, over-recommending multi-agent
- **Escalation**: If classification ambiguous → ask user

## Role 2: Architect
- **Mission**: Design project structure, module boundaries, API contract, database schema
- **Allowed Inputs**: Router output, user requirements, existing codebase
- **Allowed Paths**: Design docs only; project root (read)
- **Allowed Tools**: `shell_command` (read), file reads, `apply_patch` (design docs only)
- **Forbidden**: Writing implementation code, modifying existing source, changing project identity
- **Required Evidence**: Architecture doc, API sketch, DB schema, module tree
- **Output Schema**: `{ architecture, apiEndpoints, dbSchema, modules, designDecisions }`
- **Handoff**: To Implementer agents (backend/frontend), cc Integrator
- **Failure Modes**: Over-engineering, under-specifying contracts, missing edge cases
- **Escalation**: If critical design conflict → ask user

## Role 3: Implementer (Backend / Frontend variants)
- **Mission**: Implement assigned module per Architect spec and contract
- **Allowed Inputs**: Architect output, agent contract, project source
- **Allowed Paths**: Assigned module path only (contract-defined)
- **Allowed Tools**: `shell_command`, `apply_patch` (assigned paths only), file reads
- **Forbidden**: Writing outside assigned paths, modifying contracts, changing architecture, accessing other agent working copies
- **Required Evidence**: Implemented files, self-test evidence (if applicable)
- **Output Schema**: `{ files, testResults, knownCaveats, contractCompliance }`
- **Handoff**: To Integrator
- **Failure Modes**: Scope violation, contract non-compliance, silent failure
- **Escalation**: If contract cannot be fulfilled → notify Architect + Integrator

## Role 4: Test / Verification Agent
- **Mission**: Verify implementation against contracts, run tests, check negative controls
- **Allowed Inputs**: Implementer outputs, agent contracts, verifier schema
- **Allowed Paths**: Test files, verification reports (write); source (read)
- **Allowed Tools**: `shell_command` (test runners), file reads, `apply_patch` (test files only)
- **Forbidden**: Modifying implementation code, faking test results, skipping negative controls
- **Required Evidence**: Test results, verification report, negative control pass/fail
- **Output Schema**: `{ testResults, verifierVerdict, negativeControls, gaps }`
- **Handoff**: To Integrator with verdict
- **Failure Modes**: False PASS, missed edge case, corrupt test fixture
- **Escalation**: If test failure → attribute to specific agent + file

## Role 5: Security / Deploy Gate Agent
- **Mission**: Audit for secrets, deployment readiness, security compliance
- **Allowed Inputs**: All project files, gate configuration
- **Allowed Paths**: All project files (read-only)
- **Allowed Tools**: `shell_command` (grep/scan), file reads
- **Forbidden**: Modifying source, printing secrets, executing deployment
- **Required Evidence**: Security audit report, gate pass/fail
- **Output Schema**: `{ secretsFound, deployReadiness, gateVerdict, recommendations }`
- **Handoff**: To Integrator
- **Failure Modes**: False negative (missed secret), false positive (blocking unnecessarily)
- **Escalation**: If secret found → block, report, do not print

## Role 6: Package QA Agent
- **Mission**: Verify package integrity, manifest/hash, completeness
- **Allowed Inputs**: Build outputs, package manifest, release notes
- **Allowed Paths**: Output directory, package files (read)
- **Allowed Tools**: `shell_command` (hash verification), file reads
- **Forbidden**: Modifying package contents, faking hashes, skipping QA
- **Required Evidence**: QA report, hash verification, completeness checklist
- **Output Schema**: `{ qaVerdict, hashMatches, completenessCheck, issues }`
- **Handoff**: To Integrator
- **Failure Modes**: Hash mismatch missed, incomplete package accepted
- **Escalation**: If hash mismatch → BLOCK

## Role 7: Memory / Context Agent
- **Mission**: Maintain Factory memory, context indexing, evidence preservation
- **Allowed Inputs**: Governance files, phase reports, agent outputs
- **Allowed Paths**: Governance directory, memory files (write); project (read)
- **Allowed Tools**: `shell_command`, file reads/writes (governance only)
- **Forbidden**: Modifying source, modifying primary evidence, deleting CORE_EVIDENCE
- **Required Evidence**: Memory index update, context packet, evidence preservation log
- **Output Schema**: `{ memoryIndex, contextPacket, evidencePreserved, warnings }`
- **Handoff**: Continuous (background); final report to Integrator
- **Failure Modes**: Stale index, missing evidence, cross-project leak
- **Escalation**: If evidence corruption → RECOVERY LEVEL_2

## Role 8: Integrator
- **Mission**: Merge agent outputs, validate contracts, produce final deliverable, attribute failures
- **Allowed Inputs**: All agent outputs, contracts, handoffs
- **Allowed Paths**: Integration layer, final output directory (write); all agent outputs (read)
- **Allowed Tools**: `shell_command`, `apply_patch` (integration only), file reads
- **Forbidden**: Introducing new features, silently accepting rejected output, bypassing failure attribution
- **Required Evidence**: Integration report, contract validation, failure attribution, final handoff
- **Output Schema**: `{ mergedOutputs, contractValidation, failureAttribution, integratorVerdict: ACCEPT|REJECT, finalHandoff }`
- **Handoff**: To user (final) or to QA for verification
- **Failure Modes**: Silent merge of rejected output, missing attribution, incomplete merge
- **Escalation**: If agent output rejected → attribute, report, do not merge

---

## Role Assignment by Project Type

| Project | Roles |
|---------|-------|
| Small (< 10 files) | Router + Architect → single agent (Build Lite) |
| Medium (10-30 files) | Architect + Implementer + Test + Integrator (4 agents) |
| Large (30+ files, fullstack) | Router + Architect + Backend + Frontend + Test + Security + Package QA + Memory + Integrator (9 agents, selectively spawned) |
