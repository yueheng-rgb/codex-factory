# FACTORY-BUILD-REALWORLD-2-P2-D: Dependency Compatibility Plan

**Generated:** 2026-06-28T10:27:49+08:00 | **Verdict:** COMPATIBILITY_PLAN_READY

## Current State
- Python 3.13.13, Django 6.0.6 installed, no requirements.txt
- Project targets Django 5.x → version mismatch confirmed

## Options

| Option | Action | Network? | Status |
|---|---|---|---|
| A: Pin Django 5.x | pip install django==5.x | YES | REQUIRES_APPROVAL |
| B: Adapt to Django 6.x | Update deprecated APIs | NO | CODEX_CAN_DO |
| C: Accept baseline | Document 13/23 as known gap | NO | CODEX_CAN_DO |

**Recommendation: B** — adapt working copy code to Django 6.x. No network needed. Minimal code changes.
