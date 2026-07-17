# FACTORY-CONTEXT-SPACE-MOUNT-TRIAL-R1 — Attach Packet Freshness Validation Policy Report

**Date**: 2026-06-28
**Sub-step**: D — Freshness Validation Policy

---

## Problem

The original Mount Protocol has no freshness check. It trusts `conversation-space.json.mainline.current_phase` implicitly. When that field is stale, the entire Attach Packet carries stale state.

## Policy Defined

6 freshness validation rules:
- FRESH-001: current_phase == lastCompletedPhase → STALE
- FRESH-002: Verifier PASS → cannot show as pending
- FRESH-003: next_actions from direction-guard, not stale current_phase
- FRESH-004: Legacy risks >2 phases old → archive
- FRESH-005: generated_at + mount_count mandatory
- FRESH-006: sourceOfTruthPaths <3 → UNKNOWN

## Required Fields Added

freshnessStatus, freshnessCheckedAt, freshnessCheckMethod, sourceOfTruthPaths, currentActivePhase, lastCompletedPhase, nextRecommendedPhase, archivedLegacyWarnings, activeBlockers

## Verdict

**Policy defined. Attach Packet must self-describe freshness. Stale packets cannot direct work.**
