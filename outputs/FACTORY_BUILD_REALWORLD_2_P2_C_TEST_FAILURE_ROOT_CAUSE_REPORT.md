# FACTORY-BUILD-REALWORLD-2-P2-C: Test Failure Root-Cause Report

**Generated:** 2026-06-28T10:27:05+08:00 | **Verdict:** ROOT_CAUSE_IDENTIFIED

## Summary

23 tests: 13 passed, 8 failed, 2 errors.

## Primary Cause: Django Version Mismatch

Installed Django: **6.0.6** | Project target: **5.x**
5 failures classified as version/dependency mismatch.
4 as real code bug or missing seed data. 2 as config issues.

## Classification

| Type | Count |
|---|---|
| Django version/dependency mismatch | 5 |
| Real code bug or missing seed data | 4 |
| Config issue (timezone) | 2 |

## Recommendation

Pin Django to 5.x via equirements.txt or adapt code to Django 6.x API. Run seed_data management command before tests.
