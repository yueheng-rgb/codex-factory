# FACTORY-BUILD-0 / C: Target Product Definition Report

> **Phase**: FACTORY-BUILD-0
> **Date**: 2026-06-27

---

## Product Identity

**Codex Factory Build Harness** — A Complex Project Production Harness for Codex.

It is NOT an audit tool. It is NOT a diagnostic pack. It is a **build engine** that helps Codex construct complex full-stack projects from requirements to delivery.

## Who Uses It

| Role | Need |
|------|------|
| Developer using Codex | Build complex full-stack projects with Codex as primary builder |
| Team lead / Architect | Orchestrate multi-agent builds with clear state and handoff |
| Student / Learner | Get projects from idea to working code with diagnostic safety net |

## Core Function (One Sentence)

Accept project requirements → classify complexity → select build mode → generate blueprint → produce task graph → execute build → run diagnostic gate → deliver.

## 10 Concrete User-Facing Functions

| ID | Function | Description |
|----|----------|-------------|
| F01 | **Project Intake** | Provide project path/description; harness reads and classifies |
| F02 | **Complexity Classifier** | Auto-detect file count, framework, auth, DB, risk → SIMPLE/MODERATE/COMPLEX |
| F03 | **Mode Selector** | Route to Vanilla/Build Lite/Build Pro based on complexity + user goal |
| F04 | **Blueprint Generator** | Architecture blueprint: pages, APIs, DB schema, permissions |
| F05 | **Task Graph Generator** | Dependency-ordered task graph with file ownership |
| F06 | **Build Execution Engine** | Single-agent or multi-agent execution with state management |
| F07 | **Diagnostic Gate** | Post-build readonly safety check (Quick/Student/Full) |
| F08 | **Targeted Repair** | User-approved fixes for diagnostic findings |
| F09 | **State File Management** | Persist project state across sessions |
| F10 | **Handoff Packet** | Portable state for continuation in new Codex window |

## What It Is NOT

- NOT a replacement for Vanilla Codex
- NOT an automatic repair tool
- NOT a product quality guarantee
- NOT a CI/CD pipeline
- NOT a deployment tool

## Success Criteria

| Milestone | Criterion |
|-----------|-----------|
| **MVP** | One real complex project built end-to-end with Build Harness, passing Diagnostic Gate |
| **v1** | 3+ real projects of different types built successfully |
| **v2** | Multi-agent build outperforms Vanilla on complex projects |
