# FACTORY-BUILD-PRO-2-P1 — Section F: Pack Architecture Draft

**Phase**: FACTORY-BUILD-PRO-2-P1 | **Date**: 2026-06-27 | **Status**: DRAFT

## Proposed Pack Layout: `codex-factory-core` v0.9.0-pre

| Directory | Contents | Required For |
|-----------|----------|-------------|
| `core/` | Build mode, task graph, verifier, memory | ALL |
| `memory-quality/` | Quality hierarchy, ingestion, filtering, verification | Build Pro |
| `context-packets/` | Schema, generator, validator, role profiles | Build Pro |
| `agent-lifecycle/` | Registry, handoff, close receipt, write scope | Build Pro |
| `quality-gates/` | Diagnostic gate, recovery drill, negative controls | Build Pro |
| `optional/` | Reviewer-Verifier Diagnostic Pack, Vanilla tools | NONE |

**No release ZIP created.** Actual pack assembly deferred to `FACTORY-BUILD-PACK-ARCHITECTURE-P1`.
