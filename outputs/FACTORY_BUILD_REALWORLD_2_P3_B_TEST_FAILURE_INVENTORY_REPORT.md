# FACTORY-BUILD-REALWORLD-2-P3-B: Test Failure Inventory
**Generated:** 2026-06-28T10:35:09+08:00 | **Verdict:** INVENTORY_COMPLETE

## Root Cause: Form Field Name Mismatches (NOT Django version)

All 10 failures (7 root + 3 cascading) caused by tests using outdated field names that don't match current view/form API. Views were refactored (multi-project support, form restructuring) but tests were not updated.

## Classification
- TEST_EXPECTATION_FIX: 7
- CASCADES: 3
- Django version mismatch: 0
- Real application bug: 0
