# FACTORY-BUILD-REALWORLD-2-P1-G: Local Django Baseline Report

**Generated:** 2026-06-28T10:19:11+08:00 | **Verdict:** BASELINE_PASS_WITH_TEST_FAILURES

| Check | Result |
|---|---|
| manage.py check | PASS — 0 issues |
| makemigrations --dry-run | PASS — No changes detected |
| Migrations pending | 20+ (expected — fresh DB) |
| Test discovery | 23 tests found |
| Tests passed | 13/23 |
| Tests failed | 8 |
| Test errors | 2 |

## Test Failures

8 FAIL + 2 ERROR in CorrectionTests, VerificationTests, PatientManagementTests. Likely causes:
1. Django 6.0.6 vs original 5.x API incompatibilities
2. Missing seed data (seed_data management command not run)
3. Test setup assumptions about pre-existing records

These are documented for REALWORLD-2-P2 targeted repair — NOT fixed in this phase.
