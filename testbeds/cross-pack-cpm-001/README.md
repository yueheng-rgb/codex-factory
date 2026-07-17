# CPM-001: 小程序商城 + 后台管理 · Cross-Pack Mission

> **Mission ID:** CPM-001  
> **Status:** REQUIRES_HUMAN_REVIEW  
> **Date:** 2026-07-12  
> **Workers:** Worker A (test harness), Worker B (docs/manifest/handoff), Worker C (Integrator, pending)

---

## Mission Description

构建一个完整的**微信小程序电商商城** + **PC 管理后台**系统。

用户端：微信小程序完成商品浏览、购物车、下单、支付、订单查看。  
管理端：PC Web 后台管理商品、订单、用户、权限。

---

## Packs Activated

| Pack | Type | Role |
|------|------|------|
| `miniapp` | 微信小程序 | 用户端商城前端 |
| `ecommerce` | 电商业务 | 商品/订单/购物车/支付/库存 |
| `admin-system` | 管理后台 | PC 后台 CRUD + 权限 + 审计 |

---

## Architecture Scaling Decision

- **Scale Level:** **L** (中型业务系统 / 风险敏感系统)
- **Risk Level:** **high** — 涉及支付、订单、库存、权限、审计
- **Frontend:** 原生微信小程序 (miniapp) + Next.js 管理后台 (admin-system)
- **Backend:** Node.js + Fastify + PostgreSQL + Prisma
- **Auth:** 微信登录 (OPENID) + 管理后台 JWT RBAC

---

## Invariants (28 Total)

### MINIAPP Pack (I01–I05)
| # | Invariant | Source |
|---|-----------|--------|
| I01 | 微信登录 OPENID 必须服务端处理，小程序端不接触 AppSecret | miniapp-starter |
| I02 | 小程序前端只做展示和 API 调用，不做权限判断 | miniapp-blueprint |
| I03 | Token 有过期时间 (≤ 24h)，过期自动跳转登录 | auth-permission-boundary |
| I04 | 所有 API 请求携带 token，服务端校验 | auth-permission-boundary |
| I05 | 小程序密钥 (AppSecret) 只在服务端环境变量，不入前端代码 | GLOBAL_CODEX_RULES |

### ECOMMERCE Pack (I06–I14)
| # | Invariant | Source |
|---|-----------|--------|
| I06 | 商品 CRUD 完整生命周期 (列表/详情/新建/编辑/删除) | feature-completeness |
| I07 | 订单状态机: pending→paid→shipped→completed，含退款路径 | database-consistency |
| I08 | 库存扣减使用条件 UPDATE + 事务，禁止 SELECT-then-UPDATE | database-consistency |
| I09 | 防重复提交: 订单表 idempotency_key 唯一约束 | database-consistency |
| I10 | 支付需要真实商户 AppID，不可 mock 通过 | STACK_DECISION_GUIDE |
| I11 | 金额字段使用 DECIMAL 或 INTEGER(分)，禁止 FLOAT/DOUBLE | database-consistency |
| I12 | 购物车数量变更必须原子操作 | database-consistency |
| I13 | 订单创建与库存扣减在同一事务中 | database-consistency |
| I14 | 订单状态非法流转必须报错，不可静默 | database-consistency |

### ADMIN-SYSTEM Pack (I15–I21)
| # | Invariant | Source |
|---|-----------|--------|
| I15 | RBAC 至少 admin/user 两种角色，服务端校验每个 API | auth-permission-boundary |
| I16 | API 统一响应格式: `{ success, data/error }` | backend-api-contract |
| I17 | 列表分页规范: page/limit/total/totalPages | backend-api-contract |
| I18 | 资源归属检查: 管理员只能操作本组织数据 | auth-permission-boundary |
| I19 | 管理员敏感操作记录审计日志 (操作人/时间/操作/IP) | auth-permission-boundary |
| I20 | 权限提升操作需要二次验证或更高权限 | auth-permission-boundary |
| I21 | 前端隐藏按钮 ≠ 权限控制，403 必须从服务端返回 | auth-permission-boundary |

### CROSS-CUTTING (I22–I28)
| # | Invariant | Source |
|---|-----------|--------|
| I22 | 每个数据展示区域实现四态: loading/empty/error/success | error-empty-loading-states |
| I23 | 每个表单/按钮实现四态: idle/submitting/success/failed | frontend-state-and-form-logic |
| I24 | 所有数据库表含审计字段: created_at, updated_at, (deleted_at) | GLOBAL_CODEX_RULES |
| I25 | 外键必须建索引，常用查询字段建索引 | database-consistency |
| I26 | .env.example 提供，密钥不入 git | GLOBAL_CODEX_RULES |
| I27 | 一条明确命令可运行/预览整个系统 | GLOBAL_CODEX_RULES |
| I28 | 管理后台响应式布局，小程序适配微信规范 | GLOBAL_CODEX_RULES |

---

## Start / Test Commands

### 后端 API
```bash
cd backend
npm install
cp .env.example .env  # 填写 DATABASE_URL, WECHAT_APPID, WECHAT_SECRET
npx prisma migrate dev
npm run dev            # Fastify on :3000
```

### 管理后台 (Next.js)
```bash
cd admin-frontend
npm install
cp .env.example .env   # NEXT_PUBLIC_API_URL=http://localhost:3000
npm run dev            # Next.js on :3001
```

### 微信小程序
```
使用微信开发者工具打开 miniapp/ 目录
在 project.config.json 中填写真实 AppID
```

### 验证命令
```bash
# 后端 API 健康检查
curl http://localhost:3000/api/health

# 自动化测试 (Worker A 构建)
cd testbeds/cross-pack-cpm-001/tests
npx playwright test
npx autocannon http://localhost:3000/api/products
npx semgrep --config=auto backend/
```

---

## Human Review Required

> **REVIEW_REQUIRED_NOT_RUN** — 以下项目必须在编码前由人类审核确认：

1. **支付流程** — 需要真实微信商户 AppID，不可 mock
2. **生产 AppID** — 小程序 AppID 和 AppSecret 需要从微信开放平台获取
3. **管理员权限提升** — 权限模型需人工审核，防止越权
4. **数据库 schema** — 订单/支付/库存表设计需审核
5. **外部引擎** — semgrep (安全扫描), autocannon (压力测试), playwright (E2E) 需提前配置

---

## File Map

```
testbeds/cross-pack-cpm-001/
├── README.md                  ← this file
├── worker-handoff-B.json      ← Worker B handoff record
├── mission-manifest.json      ← full mission manifest
├── docs/
│   └── integration-notes.md   ← cross-pack interaction analysis
├── src/                       ← Worker A test harness (pending)
└── tests/                     ← Worker A test suite (pending)
```
