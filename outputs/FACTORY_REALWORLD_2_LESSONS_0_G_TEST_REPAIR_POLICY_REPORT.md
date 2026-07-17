# FACTORY-REALWORLD-2-LESSONS-0 Section G: Test Repair Policy

**Timestamp**: 2026-06-28T10:58:00+08:00
**Status**: POLICY_FORMALIZED

---

## TEST_REPAIR_POLICY_v1

### Three Principles

1. **CLASSIFICATION_FIRST** — Classify each failure before attempting repair
2. **HONEST_SKIP_ALLOWED** — Skip environment mismatches with documented reason
3. **NO_FAKE_PASS** — Never modify assertions to force-pass; never hide skips

### Classification Categories

| Category | Action | REALWORLD-2 Example |
|----------|--------|---------------------|
| ENVIRONMENT_MISMATCH | SKIP + document | Django 6.x removed features (2 tests) |
| CODE_BUG | FIX code or REPORT | View returns wrong status |
| DATA_ISSUE | FIX test data | Missing fixtures |
| CONFIG_ISSUE | FIX config | Missing INSTALLED_APPS |
| TEST_BUG | FIX test | Form field name mismatch (most fixes) |

### Reporting

Always: `X pass / Y skip / Z fail` — never collapse skips into pass.

### REALWORLD-2 Evidence

- Initial: 13/0/10 → After P3: 20/0/3 → Final: 21/2/0
- Skip reason: Django 6.x ENVIRONMENT_MISMATCH
- App code changes: 0
- Test changes: 1 file, field name alignment only
