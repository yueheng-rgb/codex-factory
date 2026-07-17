# FACTORY-BUILD-0 / H: Next 3 Major Phases Plan

> **Phase**: FACTORY-BUILD-0
> **Date**: 2026-06-27

---

## Phase Design Principle

Each phase is ONE large-block objective with a concrete, verifiable deliverable. No micro-phases. No splitting into sub-phases.

---

## Phase 1: FACTORY-BUILD-1 — Build Mode MVP 🏗️

**Goal**: Produce a Build Harness MVP that accepts project requirements, auto-selects mode, generates blueprint + task graph, executes build, and passes Diagnostic Gate.

**Must Include** (10 items):
1. Project intake → manifest
2. Complexity classifier (SIMPLE/MODERATE/COMPLEX)
3. Mode selector (Vanilla/Build Lite/Build Pro)
4. Blueprint generator (pages, APIs, DB, permissions)
5. Task graph generator (dependency-ordered, file ownership)
6. Build execution engine (single-agent default)
7. Diagnostic gate integration (Quick Mode)
8. State file update
9. One-command instruction template
10. Verifier + negative controls

**Deliverable**: A documented, runnable Build Harness. Depends on BUILD-0.

---

## Phase 2: FACTORY-BUILD-2 — External Memory MVP 💾

**Goal**: Implement file-based external memory so complex projects survive session boundaries.

**Must Include** (10 items):
1. state.json schema + reader/writer
2. rchitecture-map.json persistence
3. equirement-map.json traceability
4. decisions.md decision log
5. 	ask-graph.json persist + resume
6. isks.json active risk register
7. handoff-packet.md generator
8. actory-state-retrieve.ps1 retrieval script
9. Startup consistency check
10. Verifier + negative controls

**Deliverable**: File-based memory system. Depends on BUILD-1.

---

## Phase 3: FACTORY-BUILD-3 — Real Complex Project Build Trial 🎯

**Goal**: Use full Build Harness + External Memory to build a real complex project, comparing Vanilla vs Build Mode.

**Must Include** (7 items):
1. Select real complex project
2. Baseline Vanilla build
3. Build Mode run (full pipeline)
4. Diagnostic gate results
5. Targeted repair cycle
6. Continuation/handoff test
7. Outcome comparison

**Deliverable**: Evidence Build Harness completes real projects. Depends on BUILD-2.

---

## Phase Dependency Chain

`
BUILD-0 (this phase — mainline reset)
  └── BUILD-1 (Build Harness MVP)
        └── BUILD-2 (External Memory)
              └── BUILD-3 (Real Trial)
`

## What Comes After

- BUILD-4: Multi-Agent Build Pro Trial (4-agent on complex project)
- BUILD-5: Cloud Knowledge Integration
- BUILD-6: Release v1.0 (only after proven capability)
