# FACTORY-BUILD-0 / G: Mode Boundary Clarification Report

> **Phase**: FACTORY-BUILD-0
> **Date**: 2026-06-27

---

## The Four Modes of Codex Factory

Codex Factory has 4 modes. Only ONE is the mainline. The other 3 support it.

### BUILD MODE — The Mainline 🏗️

| Aspect | Definition |
|--------|------------|
| **What** | The primary production mode. Accepts requirements → produces working code. |
| **Role** | MAINLINE. Everything else supports Build. |
| **Output** | Working codebase with verified quality gate |
| **Trigger** | User wants to create or extend a project |

### DIAGNOSTIC MODE — The Gate 🛡️

| Aspect | Definition |
|--------|------------|
| **What** | Readonly safety gate. Detects gaps. Does NOT fill them. Does NOT build. |
| **Role** | GATE inside Build pipeline. Gates BUILD → DELIVER. |
| **Output** | Gap report with verifier results |
| **Never** | Replace Build. Auto-repair. Claim product quality. |

### BENCHMARK MODE — The Measurement 📊

| Aspect | Definition |
|--------|------------|
| **What** | Compares outcomes. Measures Build effectiveness. Does NOT produce projects. |
| **Role** | METHOD of verifying Factory. Not a Factory goal. |
| **Output** | Comparative metrics |
| **Never** | Replace real project production. Be treated as build mechanism. |

### RELEASE MODE — The Package 📦

| Aspect | Definition |
|--------|------------|
| **What** | Wraps proven capabilities into distributable form. |
| **Role** | OUTPUT of proven Build operation. Follows capability. |
| **Output** | Versioned distribution package |
| **Never** | Precede proven build capability. Become the goal. |

---

## Boundary Hierarchy

`
BUILD (mainline)
├── DIAGNOSTIC (gate inside Build)
├── BENCHMARK (measures Build effectiveness)
└── RELEASE (packages proven Build)
`

## Six Boundary Rules

| # | Rule |
|---|------|
| 1 | BUILD > DIAGNOSTIC: Diagnostic is a gate inside Build, not above it |
| 2 | BUILD > BENCHMARK: Benchmark measures Build, Build does not serve Benchmark |
| 3 | BUILD > RELEASE: Release packages Build, Build does not exist for Release |
| 4 | DIAGNOSTIC ≠ PRODUCT: Diagnostic Pack is a tool, not the Factory product |
| 5 | BENCHMARK ≠ PRODUCTION: Running benchmarks does not produce projects |
| 6 | RELEASE ≠ CAPABILITY: Creating ZIPs does not create build capability |

## Anti-Patterns (Forbidden)

- Diagnostic Pack as Factory final form
- Benchmark-first development
- Release-driven development
- SkillMarket as ongoing main project
- Small repair phases consuming mainline
