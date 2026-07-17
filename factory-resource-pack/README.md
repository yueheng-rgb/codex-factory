# Codex Factory Resource Pack — v0.1

Foundation resource pack for the Codex App Factory governance system.

## Quick Start
1. Copy actory-resource-pack/ to your project root.
2. Run ootstrap/validate-resource-pack.ps1 to verify integrity.
3. Use core/factoryctl/factoryctl.ps1 status to check Factory state.
4. Follow ootstrap/session-rotation-startup-checklist.md for new sessions.

## Structure
- core/ — Operational entrypoints (factoryctl, agent tracking, handoff)
- ole-model/ — Agent organization role definitions
- protocols/ — Operating protocols (scheduling, reporting, evidence, claims)
- policies/ — Machine-readable decision policies
- schemas/ — Contract, evidence, and progress schemas
- erifier-modules/ — Reusable verifier check implementations
- 
egative-fixtures/ — Negative control scenario templates
- phase-templates/ — Phase specification templates
- ootstrap/ — New project onboarding and validation
- eference-archive/ — Historical reference material (not operational)
- deprecated/ — Deprecated modules with replacement paths

## Boundaries
See BOUNDARY.md for full boundary rules.
See SCORING_SYSTEM_GATE.md for the scoring system prohibition.