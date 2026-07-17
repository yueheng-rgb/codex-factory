# FACTORY_BUILD_REALWORLD_1_C_BASELINE_VERIFICATION_REPORT

> Phase: REALWORLD-1 / C — Baseline Verification
> Timestamp: 2026-06-27
> Working Copy: `harness\realworld\online-bookstore-36\working-copy\OnlineBookstore_Experiment5\`

## 1. mvnw clean test

| Metric | Value |
|--------|-------|
| Command | `mvnw.cmd clean test` |
| Exit Code | 0 (BUILD SUCCESS) |
| Tests Run | **30** |
| Failures | 0 |
| Errors | 0 |
| Skipped | 0 |
| Duration | 19.4s |

## 2. JaCoCo Coverage

| Metric | Baseline (working copy) | REPORT.md Claim | README Claim | 提交说明 Claim |
|--------|------------------------|-----------------|--------------|----------------|
| Instruction | **65.9%** | 66.0% | 66.0% | 65.85% |
| Branch | **46.7%** | 46.6% | 46.6% | — |
| Line | **63.4%** | 63.5% | 63.5% | 63.39% |
| Complexity | **57.4%** | 57.5% | — | — |
| Method | **60.0%** | 60.1% | — | — |
| Classes | **30** | — | — | — |

**Conclusion**: Coverage values consistent within rounding tolerance (±0.1%).

## 3. H2 Startup Smoke

| Metric | Value |
|--------|-------|
| Profile | h2 |
| Port | 8080 |
| Startup Duration | 3.2s |
| Tomcat Started | YES |
| H2 Console Available | YES (jdbc:h2:mem:online_bookstore) |
| HikariPool | Started successfully |
| Result | **PASS** |

## 4. Docker Profile Issue (R1)

| Check | Result |
|-------|--------|
| docker-compose.yml references `docker` profile | YES (L15: `SPRING_PROFILES_ACTIVE: docker`) |
| application-docker.yml exists | **NO** |
| Available profiles | h2, mysql, redis, nocache |
| Risk | **CONFIRMED CRITICAL** — docker-compose up will fail |

## 5. OpenAPI vs Controller Coverage (R2)

| Source | Endpoints |
|--------|-----------|
| OpenAPI yaml paths | 10 (7 unique paths, some multi-method) |
| BookController | 7 |
| CartController | 5 |
| OrderController | 6 |
| UserController | 6 |
| **Total in source** | **24** |
| Coverage | **10/24 (41.7%)** |
| **Missing endpoints** | 14 (category search, book search, PUT/DELETE book, cart update/remove/clear, user orders list, all orders list, order status update, user CRUD beyond register/login) |
| **Risk** | **CONFIRMED HIGH** — API documentation significantly incomplete |

## 6. Endpoint Count Cross-Reference (R3)

| Source | Claimed | Actual | Delta |
|--------|---------|--------|-------|
| Controller source | — | **24** | — |
| README.md | 9 | 24 | -15 |
| openapi.yaml | 10 | 24 | -14 |
| 提交说明.txt | 28 | 24 | **+4 (overcount)** |
| Risk | **CONFIRMED MEDIUM** | | |

## 7. Error Code Coverage (R5)

| Source | Count | Codes |
|--------|-------|-------|
| EXPERIMENT_FINAL_REPORT.md | **7** | BOOK_NOT_FOUND, ORDER_NOT_FOUND, INSUFFICIENT_STOCK, VALIDATION_FAILED, USER_NOT_FOUND, CART_NOT_FOUND, INTERNAL_SERVER_ERROR |
| Source (service + exception) | **11** | Above 7 + DUPLICATE_ISBN, ORDER_TERMINAL, ORDER_ALREADY_CANCELLED, ORDER_COMPLETED, USER_ALREADY_EXISTS, AUTH_FAILED |
| Risk | **CONFIRMED MEDIUM** — 4 error codes undocumented | | |

## 8. Evidence Directory Status (R6)

| Directory | Status |
|-----------|--------|
| evidence/screenshots/ | **EMPTY** |
| evidence/video/ | **EMPTY** |
| evidence/signatures/ | **EMPTY** |
| evidence/runtime/api-validation/ | 17 JSON files present |
| evidence/jmeter/ | Structure present |
| evidence/git/ | Structure present |
| evidence/performance/ | Directory exists |

## 9. External Service Dependencies (R7)

| Service | Required By | Available? |
|---------|-------------|------------|
| MySQL 8.0 | application-mysql.yml | ❌ |
| Redis 7.0 | application-redis.yml | ❌ |
| JMeter 5.6+ | jmeter/*.jmx | ❌ |
| Git | Git evidence, push | ❌ |
| Jenkins | Jenkinsfile | ❌ |
| Docker | docker-compose.yml | ❌ |

## Baseline Verdict

| Check | Result |
|-------|--------|
| Compilation | PASS |
| Tests (30) | PASS (0 failures) |
| JaCoCo Coverage | PASS (matches report) |
| H2 Startup | PASS |
| Docker Profile | **FAIL** (application-docker.yml missing) |
| OpenAPI Coverage | **FAIL** (10/24 endpoints) |
| Endpoint Count Consistency | **FAIL** (3 docs disagree) |
| Error Code Coverage | **FAIL** (7 vs 11) |
