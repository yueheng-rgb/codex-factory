# Stack Decision Guide — 技术栈决策指南

> 给 Codex 固定技术栈选择规则。**不要每次新项目重新发明技术栈。**

---

## 默认选型规则

### 1. fullstack-admin

| 层面 | 默认选择 | 备选 |
|------|---------|------|
| 框架 | Next.js (App Router) | — |
| 语言 | TypeScript | — |
| 数据库 | PostgreSQL | MySQL |
| ORM | Prisma 或 Drizzle | — |
| UI 库 | shadcn/ui 或 Ant Design | MUI |
| 样式 | Tailwind CSS | CSS Modules |
| 测试 | Playwright (smoke test) | — |
| 表单 | react-hook-form + zod | — |
| 表格 | TanStack Table | — |

**选型理由：**
- Next.js：前后端一体，减少项目拆分
- PostgreSQL：数据类型丰富，适合业务系统
- Prisma/Drizzle：类型安全，迁移方便
- shadcn/ui：组件可定制，不像 Ant Design 那么重
- Ant Design：如果用户偏好开箱即用的完整组件库

---

### 2. content-site

| 层面 | 默认选择 | 备选 |
|------|---------|------|
| 构建工具 | Vite 或 Next.js | — |
| 语言 | React + TypeScript | — |
| 样式 | Tailwind CSS | — |
| 布局 | 响应式（mobile-first） | — |
| 内容 | Markdown 或 CMS | — |
| SEO | react-helmet-async 或 Next.js Metadata | — |

**选型理由：**
- Vite：构建快，适合纯前端内容站
- Next.js：如果需要 SSR/SEO
- Tailwind：快速出效果，响应式方便

---

### 3. saas-tool

| 层面 | 默认选择 | 备选 |
|------|---------|------|
| 框架 | Next.js | — |
| 语言 | TypeScript | — |
| 数据库 | PostgreSQL | — |
| ORM | Prisma 或 Drizzle | — |
| Auth | NextAuth.js 或 better-auth | — |
| UI 库 | shadcn/ui | — |
| 样式 | Tailwind CSS | — |
| 必建表 | users, generation_history, user_quota, api_logs | — |

**选型理由：**
- Next.js：全栈能力，API Routes 方便
- Auth：需要健全的用户系统
- 必建表：SaaS 核心数据追踪

---

### 4. api-service

| 层面 | 默认选择 | 备选 |
|------|---------|------|
| 运行时 | Node.js | — |
| 框架 | Fastify 或 Express | Hono |
| 语言 | TypeScript | — |
| 数据库 | PostgreSQL | — |
| ORM | Prisma 或 Drizzle | — |
| 文档 | OpenAPI (Swagger) | — |
| 测试 | Vitest + supertest | — |

**选型理由：**
- Fastify：性能好，Schema 验证内置
- Express：生态最大，团队熟悉度高
- OpenAPI：标准接口文档

---

### 5. miniapp

| 层面 | 默认选择 | 备选 |
|------|---------|------|
| 前端 | 原生微信小程序 或 uni-app | Taro |
| 后端 | Node.js + Fastify/Express | — |
| 数据库 | PostgreSQL | — |
| Auth | 微信登录 (OPENID 服务端处理) | — |
| 密钥 | 全部放服务端 | — |

**选型理由：**
- 原生小程序：体积小，微信兼容最好
- uni-app：如果需要跨端（H5 + 小程序）
- 密钥安全：小程序前端不可信

---

### 6. mobile-app

| 层面 | 默认选择 | 备选 |
|------|---------|------|
| 框架 | Expo (React Native) | — |
| 语言 | TypeScript | — |
| 导航 | expo-router | React Navigation |
| API | axios 或 fetch + interceptor | — |
| Auth | SecureStore 存 token | — |
| UI | NativeWind 或自定义组件 | — |

**选型理由：**
- Expo：开发生态完善，构建方便
- expo-router：文件系统路由，接近 Next.js 体验

---

### 7. threejs-interactive

| 层面 | 默认选择 | 备选 |
|------|---------|------|
| 构建 | Vite | — |
| 语言 | TypeScript | — |
| 3D 引擎 | Three.js | — |
| UI 层 | HTML/CSS 或 React | — |
| 测试 | Playwright (截图/按钮) | — |

**选型理由：**
- Vite：模块热更新快，3D 开发体验好
- Three.js：生态最成熟

---

## 通用规则

### 禁止使用的技术（除非明确要求）
- GraphQL（默认走 REST）
- tRPC（过度抽象，新项目不推荐）
- NoSQL（默认用关系型数据库）
- 微服务架构（小项目不要）
- Kubernetes/Docker Compose（本地开发不需要）

### 所有项目的通用依赖
- TypeScript（类型安全）
- ESLint + Prettier（代码规范）
- .env.example（环境变量模板，不提交真实密钥）
- .gitignore（标准 Node.js 项目忽略）
- README.md（说明如何启动）

---

## Architecture Scaling Rules（Phase 3B-4.5）

### 默认原则

1. **默认选择简单可运行架构** — starter 是安全起点
2. **用体量和风险决定是否升级** — S/M/L/XL + 风险等级
3. **高级架构必须由需求触发** — 不由 Codex 主观炫技触发
4. **第一阶段不做微服务** — 除非用户明确要求且项目必须
5. **第一阶段不做支付/多租户/消息队列** — 除非用户明确要求且项目目标依赖它
6. **L/XL 项目先设计扩展点** — 但第一阶段仍保持最小闭环
7. **内部业务系统涉及次数/余额/核销/审批/提成/库存** — 必须考虑审计和事务

### 升级决策树

```
需求中有支付/订单/订阅？
  → YES: 至少 L 级，需要事务+审计+幂等

需求中有次数/余额/库存/额度？
  → YES: 至少 L 级，需要条件 UPDATE + 事务 + 审计日志

需求中有多角色+敏感数据？
  → YES: 至少 M 级，需要服务端 RBAC + 审计

需求中有实时协作/多人编辑/聊天？
  → YES: XL 级，需要 WebSocket/实时同步

需求只是展示信息/无登录/无数据库？
  → S 级就够了，不要升级

需求只是简单 CRUD + 1-2 个管理员？
  → M 级就够了，不要上微服务/队列
```

### 禁止模式

- ❌ S 级项目用 Next.js + PostgreSQL（过度设计）
- ❌ M 级 CRUD 拆微服务
- ❌ 展示网站加 Redis 缓存
- ❌ 小程序前端直接调 OpenAI API（密钥暴露）
- ❌ mock-db 当正式数据库用（L 级以上必须换真实 DB）