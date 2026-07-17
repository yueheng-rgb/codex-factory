# FACTORY-MEMORY-QUALITY-P2 — A: Evidence Intake & Scope Lock

**Timestamp:** 2026-06-28T17:50:00+08:00

---

## Inherited

| Source | Key Finding |
|--------|-------------|
| Context Space P0-P7 | Mainline compression solved; not lossless backup |
| Memory Quality P0/P1 | Context Packet / schema / generator / validator |
| P4/P4-R1 | Compression coverage needs verifier |
| P5/P6/P7 | Snapshot / Attach / fresh-window validated |
| REALWORLD-2 | Multi-phase supported by external space |
| AB-0/AB-0-R1 | Design ≠ execution — memory must not confuse |

---

## Current Problem

Information entering memory pool still needs stronger filtering, format constraints, caveat requirements, and a Socratic clarifying gate.

## P2 Purpose

**Primary:** Optimize memory ingestion quality — control what enters and how.

**Is:** Minimal ingestion policy, schema + templates, caveat enforcement, Socratic gate (high-risk only), validator.

**Is NOT:** v0.5 release, RC, cloud, cleanup/deletion, Native Build Pro.

---

**Scope:** FROZEN — memory ingestion quality only
**Status:** EVIDENCE_INTAKE_AND_SCOPE_LOCKED
