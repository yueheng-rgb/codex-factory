# FACTORY-CONTEXT-SPACE-P3 — Snapshot Pack Concept and Boundary

**Date**: 2026-06-28
**Sub-step**: B

---

## 1. Definition

A **Snapshot Pack** is a pre-generated, curated JSON bundle extracted from the P2 SQLite local index. It captures the working context needed for a specific scenario — reducing the need for ad-hoc query assembly.

## 2. Snapshot Types (8)

| Snapshot ID | Name | Scenario | Content Focus |
|-------------|------|----------|--------------|
| SNAP-FW | Fresh Window | New Codex window opens for Factory work | Current goal, strategy, frozen conclusions, active risks, next recommended phase |
| SNAP-CD | Current Direction | Quick check: where are we? | Current phase, last completed, strategy, direction guard summary |
| SNAP-PS | Phase Start | Starting a new phase | Phase ledger, relevant frozen conclusions, relevant risks, strategy |
| SNAP-US | User Summary | User asks: what happened? | Timeline of completed phases, key decisions, active risks, next options |
| SNAP-RSK | Risk Snapshot | Risk audit | All active risks with severity, mitigation, discovery phase, active blocker status |
| SNAP-RD | Release Decision | Should we release? | All frozen conclusions about release, strategy flags, blocked phases, evidence |
| SNAP-NBP | Native Build Pro | Preparing NBP orchestration | Context Packet required status, agent lifecycle policy, relevant risks |
| SNAP-QA | Package QA | Pre-delivery QA check | Package QA gate status, staging bundle status, release blocked status, evidence |

## 3. Boundary — IN SCOPE

- Generate snapshots from P2 SQLite index
- Validate each snapshot against freshness and integrity rules
- Refresh snapshots when underlying data changes
- Expose snapshots to Attach Packet v3 as fallback context
- Lifecycle management: create, validate, refresh, expire, retire

## 4. Boundary — OUT OF SCOPE

- Cloud sync of snapshots
- Network-based snapshot sharing
- Real-time streaming updates
- Snapshot diff/comparison engine
- Replacing P2 query (snapshots supplement, not replace)
- Modifying real projects or old packages
- Native Build Pro execution
- REALWORLD-2-P1 execution

## 5. Key Principle

**Snapshots are high-quality context packs, not evidence. They always point back to the P2 index and verifier JSON for verification.**
