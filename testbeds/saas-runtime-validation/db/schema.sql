-- Codex Factory R6.0 — SaaS Runtime Validation Postgres Schema
-- Generated: 2026-07-11
-- Usage: psql -U postgres -d saas_validation -f db/schema.sql
-- Test mode: in-memory (default). Set DATABASE_URL to use Postgres.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Tenants / Workspaces
CREATE TABLE IF NOT EXISTS tenants (
    id          TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    status      TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','DELETED')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Users
CREATE TABLE IF NOT EXISTS users (
    id          TEXT PRIMARY KEY,
    email       TEXT NOT NULL,
    role        TEXT NOT NULL DEFAULT 'MEMBER' CHECK (role IN ('ADMIN','MEMBER')),
    tenant_id   TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_users_tenant ON users(tenant_id);

-- Subscriptions
CREATE TABLE IF NOT EXISTS subscriptions (
    id              TEXT PRIMARY KEY,
    tenant_id       TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    plan            TEXT NOT NULL DEFAULT 'free',
    status          TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','EXPIRED','CANCELLED')),
    quota_total     INTEGER NOT NULL DEFAULT 1000,
    quota_remaining INTEGER NOT NULL DEFAULT 1000 CHECK (quota_remaining >= 0),
    expires_at      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_subscriptions_tenant ON subscriptions(tenant_id);

-- Generation History
CREATE TABLE IF NOT EXISTS generations (
    id          TEXT PRIMARY KEY,
    tenant_id   TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    model       TEXT NOT NULL,
    prompt      TEXT NOT NULL,
    output      TEXT NOT NULL,
    token_count INTEGER NOT NULL DEFAULT 0,
    cost        NUMERIC(10,6) NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_generations_tenant ON generations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_generations_created ON generations(created_at DESC);

-- API Keys (encrypted at rest — raw key NEVER in queryable column)
CREATE TABLE IF NOT EXISTS api_keys (
    id          TEXT PRIMARY KEY,
    tenant_id   TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    key_hash    TEXT NOT NULL,
    masked_key  TEXT NOT NULL,
    provider    TEXT NOT NULL DEFAULT 'openai',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_api_keys_tenant ON api_keys(tenant_id);

-- Billing Events (idempotency via unique event_id)
CREATE TABLE IF NOT EXISTS billing_events (
    event_id    TEXT PRIMARY KEY,
    tenant_id   TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    event_type  TEXT NOT NULL,
    amount      NUMERIC(10,2) NOT NULL DEFAULT 0,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Provider Keys (server-side only, NEVER queried by API)
CREATE TABLE IF NOT EXISTS provider_keys (
    provider    TEXT PRIMARY KEY,
    encrypted_key TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Migration tracking
CREATE TABLE IF NOT EXISTS _migrations (
    id          SERIAL PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE,
    applied_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
INSERT INTO _migrations (name) VALUES ('001_initial_schema') ON CONFLICT DO NOTHING;
