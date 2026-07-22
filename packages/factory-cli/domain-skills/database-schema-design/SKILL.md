---
name: database-schema-design
description: Design or review relational schemas, constraints, indexes, audit fields, and transactional updates. Use for tables, migrations, balances, quotas, inventory, or other concurrent state.
---

<!-- >>> CODEX_APP_FACTORY:SKILL >>> -->
# Database schema design

- Model current state separately from append-only events, adjustments, and audit logs.
- Add primary keys, audit timestamps, required foreign keys, unique constraints, and query-driven indexes.
- Use integer minor units or decimal types for money; never floating point.
- Protect quota, balance, and inventory updates with conditional atomic updates or transactions and row locks.
- Specify transaction boundaries, delete behavior, pagination indexes, and migration rollback/forward safety.
<!-- <<< CODEX_APP_FACTORY:SKILL <<< -->
