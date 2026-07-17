# SaaS Tool Expert Pack v1.0.0
# Codex Factory R5.3

## Status: ACTIVE

The SaaS Tool Expert Pack is the second domain-specific capability pack for Codex Factory.
It provides surface templates, risk rules, business invariants, test patterns, engine
recommendations, and benchmark cases for SaaS / AI tool projects.

## Domain Scope

### Covered Modules
- User account / auth
- Tenant / workspace isolation
- Subscription / plan management
- Usage quota tracking
- AI generation request/response
- Generation history
- API key / provider key management
- Billing webhook handling
- Admin console
- Rate limiting

### NOT Covered (Non-Claims)
- SOC2/ISO27001 compliance certification
- GDPR/data-privacy compliance implementation
- Real AI model provider integration code
- Production-scale multi-region deployment
- SSO/SAML/OIDC enterprise auth
- Actual payment gateway integration code

## Surface Templates

| Template | Surfaces | Risk | Typical Use Case |
|----------|----------|------|------------------|
| saas-lite | frontend-web, api-service, database | MEDIUM | Single-tenant AI tool, no billing |
| saas-standard | frontend-web, api-service, database, background-worker, docs-release | HIGH | Multi-tenant with subscriptions and quotas |
| saas-enterprise | frontend-web, api-service, database, background-worker, admin-web, docs-release | CRITICAL | Full SaaS with admin, webhooks, rate limiting |
| saas-platform | frontend-web, api-service, database, background-worker, admin-web, docs-release | L_CLASS | AI SaaS with multiple providers, usage tracking |

## Risk Rules (10 domain-specific rules)

| Rule | Trigger | Level |
|------|---------|-------|
| SAAS-R001 | tenant/workspace isolation | CRITICAL |
| SAAS-R002 | subscription/plan access | CRITICAL |
| SAAS-R003 | quota/credit decrement | CRITICAL |
| SAAS-R004 | API key exposure | CRITICAL |
| SAAS-R005 | provider key server-side | CRITICAL |
| SAAS-R006 | billing webhook idempotency | CRITICAL |
| SAAS-R007 | generation cost tracking | HIGH |
| SAAS-R008 | rate limit enforcement | HIGH |
| SAAS-R009 | admin escalation | CRITICAL |
| SAAS-R010 | content ownership/privacy | HIGH |

## Business Invariants (14)

| # | Invariant | Severity |
|---|-----------|----------|
| 1 | tenant_data_isolation | CRITICAL |
| 2 | user_cannot_access_other_tenant_data | CRITICAL |
| 3 | subscription_status_controls_access | CRITICAL |
| 4 | expired_subscription_cannot_generate | CRITICAL |
| 5 | usage_quota_non_negative | CRITICAL |
| 6 | quota_decrement_must_be_atomic | CRITICAL |
| 7 | generation_cost_must_be_recorded | HIGH |
| 8 | generation_history_belongs_to_tenant | HIGH |
| 9 | api_key_never_exposed_to_client | CRITICAL |
| 10 | provider_key_server_side_only | CRITICAL |
| 11 | billing_webhook_idempotency_required | CRITICAL |
| 12 | rate_limit_enforced_per_user_or_tenant | HIGH |
| 13 | admin_required_for_plan_change | CRITICAL |
| 14 | deleted_workspace_cannot_generate | HIGH |

## Activation Keywords

Chinese: SaaS, 多租户, tenant, workspace, 工作区, 订阅, subscription, 套餐, plan, 用量, 额度, quota, AI生成, AI工具, AI platform, API key, apikey, provider key, 密钥, webhook, rate limit, 限流, 计费, billing, 生成历史, 租户隔离, 配额, credit, 用量追踪, 工作空间

English: saas, tenant, workspace, subscription, plan, quota, AI generation, api key, billing, rate limit, multi-tenant
