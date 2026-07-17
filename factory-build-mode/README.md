# Codex Factory - Build Mode MVP

> **Version**: 0.1.0-mvp | **Status**: MVP Control Plane
> **Type**: Build Harness control-plane artifacts (NOT a release package)

---

## What This Is

The Build Mode MVP is the first concrete implementation of the Codex Factory Build Harness. It provides prompt templates, policies, state structures, and scripts that guide Codex through the build pipeline:

INTAKE -> CLASSIFY -> ROUTE -> BLUEPRINT -> TASK_GRAPH -> BUILD -> DIAGNOSTIC_GATE -> DELIVER

## What This Is NOT

- NOT a release ZIP for Codex Factory
- NOT v0.5 (v0.5 remains BLOCKED)
- NOT a product quality guarantee
- NOT a multi-agent implementation (multi-agent is CONDITIONAL)
- NOT a replacement for Vanilla Codex (Vanilla remains product leader)

## Directory Structure

| Directory | Contents |
|-----------|----------|
|  + "	emplates/" + @" | JSON templates for intake, classification, blueprint, task graph, memory |
|  + "examples/" + @" | Filled-in example templates |
|  + "policies/" + @" | Machine-readable policy files for classifier, mode selector, agent allocation |
|  + "prompts/" + @" | Ready-to-copy Codex prompts for common user commands |
|  + "memory-templates/" + @" | .codex-factory/ state file templates |
|  + "scripts/" + @" | Helper scripts for state management |

## Strategy Boundary

| Decision | Status |
|----------|--------|
| Multi-agent | CONDITIONAL, not default |
| 7-agent mode | CUT as default |
| 10-role model | CUT |
| 4-agent P1 | KEEP CONDITIONALLY |
| v0.5 release | BLOCKED |
| Vanilla product leader | PRESERVED |
| Diagnostic Pack | Gate only, not product |

## Quick Start

1. Read BUILD_MODE_MVP.md for the full workflow description
2. Copy a template from templates/ for your project type
3. Use prompts from prompts/ in a new Codex window
4. State files go under {project}/.codex-factory/
