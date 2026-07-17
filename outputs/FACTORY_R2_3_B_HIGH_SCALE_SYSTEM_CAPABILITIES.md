# FACTORY R2.3-B — High-Scale System Capabilities

> **Phase:** FACTORY-R2.3-B
> **Date:** 2026-07-09

---

## 1. Scope

Capabilities needed for large-scale projects: ecommerce, distributed systems, high-concurrency, data-intensive applications.

## 2. Capability Inventory

### Database Layer

| Capability | Status | Notes |
|-----------|--------|-------|
| PostgreSQL (default) | P0 import | Already in STACK_DECISION_GUIDE |
| Prisma ORM | P0 import | Type-safe, migration, studio |
| PostgreSQL read replicas | P2 monitor | Only for L/XL with explicit need |
| Connection pooling (PgBouncer) | P2 monitor | High-concurrency optimization |
| Redis caching | P2 import | Cache-Aside for product details |
| Elasticsearch/OpenSearch | P3 monitor | Full-text search for products/orders |

### Application Layer

| Capability | Status | Notes |
|-----------|--------|-------|
| Inventory deduction (conditional UPDATE) | P1 import | Knowledge capsule CAP-ecommerce-inventory-deduction |
| Order state machine | P1 import | Knowledge capsule planned |
| Payment idempotency | P1 import | Stripe idempotency key pattern |
| Rate limiting | P2 monitor | express-rate-limit / fastify-rate-limit |
| Circuit breaker | P2 monitor | opossum / fastify-circuit-breaker |
| Graceful degradation | P3 monitor | Fallback strategies |

### Messaging & Events

| Capability | Status | Notes |
|-----------|--------|-------|
| Kafka | P2 monitor | Event-driven order processing |
| RocketMQ | P2 monitor | Alibaba ecosystem alternative |
| Redis pub/sub | P2 monitor | Lightweight event bus |
| In-process event emitter | P1 import | For S/M projects (no external MQ) |

### Observability

| Capability | Status | Notes |
|-----------|--------|-------|
| Structured logging (pino/winston) | P1 import | JSON log format |
| Error tracking (Sentry) | P3 monitor | Production only |
| Metrics (Prometheus) | P3 monitor | Production only |
| Tracing (OpenTelemetry) | P3 monitor | Production only |

### Testing at Scale

| Capability | Status | Notes |
|-----------|--------|-------|
| Load testing (k6/artillery) | P2 monitor | API stress testing |
| Chaos testing | P3 quarantine | Over-engineering for Factory scope |
| Data generation (faker.js) | P2 import | Test data generation |

## 3. Knowledge Reserve Status

From R2.3-A trial example, one knowledge capsule exists:
- **CAP-ecommerce-inventory-deduction** (draft): Conditional UPDATE pattern, anti-patterns, Redis decision rules

Planned capsules (R2.3-D):
- CAP-ecommerce-order-state-machine
- CAP-ecommerce-payment-idempotency
- CAP-database-readwrite-splitting

## 4. Key Judgments

### When does a project need these capabilities?

| Trigger | Minimum Complexity | Recommended Capabilities |
|---------|-------------------|-------------------------|
| "电商/订单/库存" | L | Inventory deduction, order state machine, payment idempotency |
| "高并发" | L | Connection pooling, Redis caching, rate limiting |
| "实时/WebSocket" | L | WebSocket (Socket.io/WS), event-driven |
| "大数据/搜索" | XL | Elasticsearch, read replicas |
| "微服务" | XL | Kafka/RocketMQ, circuit breaker |

### Anti-overengineering rules (reaffirmed)

- S/M projects: No Redis, no MQ, no read replicas
- First version: No payment, no multi-tenant, no complex MQ
- "高并发" in requirements → Verify actual QPS need before scaling

