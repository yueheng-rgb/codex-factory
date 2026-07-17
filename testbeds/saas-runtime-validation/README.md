# SaaS Runtime Validation Testbed
# Codex Factory R5.4 — SaaS Tool Pack Runtime Validation

## Purpose
Validates the R5.3 SaaS Tool Expert Pack at runtime.
Proves all 14 invariants, 10 risk rules, test categories, engine plan,
and audit gates work in real code.

**NOT a production SaaS platform.** This is a validation testbed.

## Activated Pack
- Pack: `saas-tool` v1.0.0
- Source: `governance/expert-packs/saas-tool/saas-tool-pack.json`

## Invariants Validated (14/14)
tenant_data_isolation, user_cannot_access_other_tenant_data, subscription_status_controls_access, expired_subscription_cannot_generate, usage_quota_non_negative, quota_decrement_must_be_atomic, generation_cost_must_be_recorded, generation_history_belongs_to_tenant, api_key_never_exposed_to_client, provider_key_server_side_only, billing_webhook_idempotency_required, rate_limit_enforced_per_user_or_tenant, admin_required_for_plan_change, deleted_workspace_cannot_generate

## Stack
Fastify + TypeScript + Vitest + in-memory store

## Quick Start
```bash
npm install
npm test
npx tsx src/server.ts   # Port 3300
```
