# FACTORY-REAL-VALIDATION-READINESS-0 — Candidate Project Selection Criteria

**Date**: 2026-06-29
**Phase**: FACTORY-REAL-VALIDATION-READINESS-0
**Sub-step**: B

---

## 1. Purpose

Define what makes a project suitable for the first R1 real project trial — real but low-risk, local only, no production interaction.

## 2. Inclusion Criteria

A candidate project MUST satisfy ALL of the following:

| # | Criterion | Rationale |
|---|-----------|-----------|
| IN-01 | Real project with actual utility | Synthetic projects don't trigger real Factory paths |
| IN-02 | Local-only workspace | No remote servers, no CI/CD, no cloud dependency |
| IN-03 | No production secrets | No SSH keys, API tokens, DB passwords, SMTP creds in code |
| IN-04 | Can create a working copy | Original must remain untouched; working copy is disposable |
| IN-05 | Multiple files/modules (≥5 files) | Enough complexity to trigger Factory router/classifier |
| IN-06 | Contains docs OR tests | Evidence of project maturity; useful for validation |
| IN-07 | Clear project ownership | User owns or has explicit permission to use |
| IN-08 | Runnable locally | Can verify: one command starts/checks the project |
| IN-09 | Non-destructive operations safe | No risk of data loss if cleanup PLAN is followed |
| IN-10 | User explicitly approves | No auto-selection; user must consent |

## 3. Exclusion Criteria (Hard Reject)

A candidate project is REJECTED if ANY of the following apply:

| # | Criterion | Consequence if violated |
|---|-----------|------------------------|
| EX-01 | Production-only project | Risk of disruption |
| EX-02 | Contains unrotated real secrets | RISK-CS-002 pattern; security violation |
| EX-03 | Requires deployment to validate | Outside R1 scope |
| EX-04 | Unclear ownership | Legal/compliance risk |
| EX-05 | Destructive actions required | Risk of data loss |
| EX-06 | TCM project | RISK-CS-002 active blocker; blocked until user rotates keys |
| EX-07 | External API dependencies that require real keys | Can't validate locally |
| EX-08 | Requires database with production data | Production data risk |

## 4. Recommended Project Types

Strongly preferred for first trial:

- CLI tool / script collection (e.g., a personal dotfiles manager, batch processor)
- Static site / documentation project (no backend, no secrets)
- Homework/assignment project (academic, self-contained)
- Local utility library (pure code, no external deps with secrets)
- Markdown/wiki project (content-heavy, low risk)

Acceptable with caution:

- Web app with local dev server (must have `.env.example`, no real `.env`)
- Django/Flask/Express project (must be runnable without production config)
- Package/library with tests (must not require publish credentials)

## 5. Rejected for First Trial

- TCM project (RISK-CS-002)
- Any project with `SECRET_KEY`, `DB_PASSWORD`, `SMTP_PASSWORD` in tracked files
- Any project requiring Docker with production images
- Any project requiring cloud credentials even for dev

## 6. Selection Process

1. User nominates a candidate project
2. Run exclusion checklist (EX-01 through EX-08)
3. Run inclusion checklist (IN-01 through IN-10)
4. If all pass → candidate accepted
5. If any EX fails → hard reject; user must nominate another
6. If any IN fails → warn; user may proceed with caution or nominate another
7. Record selection decision in `governance/factory-validation/first-trial-project-selection.json`
