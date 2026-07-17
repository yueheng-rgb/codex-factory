# FACTORY-BUILD-0 / Mainline Reset Report

> **Phase**: FACTORY-BUILD-0 / Complex Project Production Harness Mainline Reset
> **Date**: 2026-06-27
> **Verdict**: PASS — 29/29 verifier checks, 30/30 negative controls

---

## Executive Summary

Codex Factory has been reset to its core mission: enabling Codex to build truly complex projects. Diagnostic Pack v1.1.0 is repositioned as a safety gate. SkillMarket is closed as evidence. The Build Harness is now the mainline.

## Phase Results

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| A | Mainline Correction Record (7 corrections) | PASS |
| B | Build Capability Inventory (31 items classified) | PASS |
| C | Target Product Definition (10 functions) | PASS |
| D | Build Harness Workflow (9 stages) | PASS |
| E | Build Agent Model (3 tiers) | PASS |
| F | External Memory Roadmap (3 phases) | PASS |
| G | Mode Boundary Clarification (4 modes) | PASS |
| H | Next 3 Major Phases Plan | PASS |
| I | Next Phase Instruction Draft (BUILD-1) | PASS |
| J | Negative Controls (30/30) | PASS |
| K | Verifier (29/29) | PASS |

## Key Design Decisions

1. Build Harness is the mainline — 9-stage pipeline from intake to delivery
2. Diagnostic Pack is a gate at Stage 6 — readonly, no auto-repair
3. Agent model scales with complexity: Vanilla (default) -> Build Lite -> Build Pro (4-agent)
4. External memory is file-based under .codex-factory/ — 8 state files
5. Release packaging follows proven build capability — not before
6. Multi-agent remains conditional, not default — 4-agent P1 preserved for complex projects

## Deliverables Created

| Type | Count | Location |
|------|-------|----------|
| Governance JSONs | 11 | governance/factory-build/ |
| Reports (MD) | 10 | outputs/ |
| Verifier Script | 1 | scripts/ |

## Recommended Next Phase

**FACTORY-BUILD-1 / Build Mode MVP**

Build the 10-component Build Harness MVP. Complete instruction draft in: outputs/FACTORY_BUILD_0_I_NEXT_PHASE_INSTRUCTION_DRAFT.md
