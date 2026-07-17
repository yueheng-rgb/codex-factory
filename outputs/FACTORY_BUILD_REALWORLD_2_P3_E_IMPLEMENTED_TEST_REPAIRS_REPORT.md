# FACTORY-BUILD-REALWORLD-2-P3-E: Implemented Test Repairs

**Generated:** 2026-06-28T10:35:52+08:00 | **File changed:** core/tests.py | **App code changed:** 0

| FIX | Test | Change |
|---|---|---|
| FIX-001 | test_admin_can_add_sessions | "project" → "projects": [...] |
| FIX-002 | test_transaction_log_generated_on_add | Cascades from FIX-001 |
| FIX-003 | test_doctor_can_verify_with_balance | "project"+"sessions_count" → "verify_project" list + "verify_count_{id}" |
| FIX-004 | test_doctor_cannot_delete_verification_record | Same as FIX-003 |
| FIX-005 | test_verification_creates_record_and_transaction | Same as FIX-003 |
| FIX-006 | test_doctor_can_submit_correction | "corrected_count" → "correction_count" + added "correction_type" |
| FIX-007 | test_admin_can_approve_correction | Cascades from FIX-006 |
| FIX-008 | test_correction_creates_reverse_transaction | Cascades from FIX-006 |
| FIX-009 | test_duplicate_verification_detected | Same as FIX-003 (applied twice) |
| (bonus) | test_doctor_cannot_verify_insufficient_balance | Same fix — currently passes with wrong fields by coincidence |

All changes: test-only field name updates. Zero application code modified.
