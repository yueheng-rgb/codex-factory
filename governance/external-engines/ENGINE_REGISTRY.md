# External Engine Registry v1.0.0
# Part of: FACTORY-R3.0

## Overview

The External Engine Registry defines external tools that can be plugged into
Codex Factory as optional verifiers. Engines are only triggered when their
risk level, project type, and surface constraints match the current task.

## Architecture Principle

- **Default**: R2.14 lightweight gate detection (fast path)
- **External engines**: Optional plug-in verifiers, triggered only when matched
- **Read-only**: External tools never modify project files directly
- **Evidence-only**: Results are bound as evidence, not as gate truth

## Registered Engines

| Engine ID | Category | Risk Levels | Default | Fail Policy |
|-----------|----------|-------------|---------|-------------|
| semgrep | security_static_analysis | HIGH, CRITICAL, L_CLASS | Yes | BLOCK_IF_CRITICAL_FINDINGS |
| codeql | deep_static_analysis | CRITICAL, L_CLASS | No | BLOCK_IF_CRITICAL_FINDINGS |
| k6 | performance_load_testing | HIGH, CRITICAL, L_CLASS | No | WARN_ONLY |
| autocannon | performance_load_testing | HIGH, CRITICAL | No | WARN_ONLY |
| playwright | e2e_browser_testing | MEDIUM, HIGH, CRITICAL, L_CLASS | No | WARN_ONLY |
| firecrawl_reader | reader_extractor | (manual only) | No | EVIDENCE_ONLY |

## Trigger Rules

### By Risk Level

- **LOW**: No external engines triggered
- **MEDIUM**: playwright (UI surfaces only)
- **HIGH**: semgrep + playwright/k6 (surface-dependent)
- **CRITICAL**: semgrep/codeql + k6/autocannon + playwright (surface-dependent)
- **L_CLASS**: Engine plan generated; RUN/SKIP per availability; missing key engines + no human audit = BLOCKED

### By Project Type

| Engine | fullstack-admin | backend-api | CLI-tool | frontend-app | threejs-interactive |
|--------|:---:|:---:|:---:|:---:|:---:|
| semgrep | ✓ | ✓ | ✓ | ✓ | — |
| codeql | ✓ | ✓ | ✓ | — | — |
| k6 | ✓ | ✓ | — | — | — |
| autocannon | — | ✓ | — | — | — |
| playwright | ✓ | — | — | ✓ | ✓ |
| firecrawl_reader | ✓ | ✓ | — | ✓ | — |

## Firecrawl Constraints

- Firecrawl is ONLY a Reader/Extractor candidate
- It MUST NOT replace canonical search (`/api/paas/v4/web_search`)
- It MUST NOT become a Search Agent
- Its output goes to `extracted_content` evidence, not search evidence

## Files

- `schemas/external-engine.schema.json` — Engine definition schema
- `governance/external-engines/engine-registry.json` — Registry data
- `runtime/external-engine-registry.ps1` — Registry query module
