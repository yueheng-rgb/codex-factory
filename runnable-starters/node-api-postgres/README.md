# node-api-postgres — Node.js API/Backend Service Starter

> 一个通用 Node.js + TypeScript + Fastify 后端 API 服务骨架。
> 用于小程序后端、App 后端、纯 API 服务、PostgreSQL 业务服务。

## 适合项目

- 小程序后端 API
- App 后端接口服务
- 纯 API 服务（给前端/移动端调用）
- PostgreSQL 业务数据库驱动的服务
- 需要统一 API 格式 + 权限占位 + 审计日志的项目

## 不适合项目

- 纯官网/展示页（切换到 `vite-react-content-site`）
- 管理后台全栈（切换到 `next-fullstack-admin`）
- SaaS/AI 工具（切换到 `next-saas-ai-tool`）
- 复杂微服务平台
- 高并发实时通信系统
- 复杂搜索引擎/大数据管道

## 目录说明

```
node-api-postgres/
├── README.md
├── AGENTS.md
├── PROJECT_BRIEF.md
├── package.json
├── tsconfig.json
├── .env.example
├── src/
│   ├── server.ts              # 启动入口
│   ├── app.ts                 # Fastify app 工厂
│   ├── routes/                # API 路由
│   │   ├── health.ts          # GET /health
│   │   ├── auth-placeholder.ts # POST /auth/login
│   │   ├── records.ts         # CRUD /records + /records/:id/action
│   │   └── admin.ts           # GET /admin/audit-logs
│   ├── services/              # 业务逻辑层
│   │   ├── record-service.ts
│   │   └── audit-service.ts
│   ├── repositories/          # 数据访问层
│   │   ├── record-repository.ts
│   │   └── user-repository.ts
│   ├── middleware/            # 中间件
│   │   ├── auth.ts            # 认证 + admin 权限占位
│   │   ├── error-handler.ts   # 全局错误处理
│   │   └── request-logger.ts  # 请求日志占位
│   ├── utils/                 # 工具模块
│   │   ├── api-response.ts    # 统一 API 响应格式
│   │   ├── validation.ts      # 服务端校验
│   │   ├── pagination.ts      # 分页解析
│   │   └── idempotency.ts     # 幂等 Key 管理
│   ├── db/                    # 数据库相关
│   │   ├── schema.prisma.example # 数据库 schema 示例
│   │   ├── mock-db.ts         # Mock 数据（内存，演示用）
│   │   └── transaction-notes.md # 事务/幂等/审计正确做法
│   └── types/
│       └── index.ts           # 共享类型定义
└── tests/
    └── smoke-checklist.md     # 手动验收清单
```

## 如何复制使用

### 方法 1：复制脚本（推荐）

```powershell
C:\Codex_App_Factory\scripts\create-project-from-starter.ps1 `
  -StarterName node-api-postgres `
  -TargetPath C:\Projects\my-api `
  -ProjectName my-api
```

### 方法 2：手动复制

1. 复制整个 `node-api-postgres` 目录到目标路径
2. 全局搜索 `PROJECT_NAME`，替换为实际项目名
3. 填写 `PROJECT_BRIEF.md`
4. 编辑 `src/db/mock-db.ts` 中的 mock 数据

## 如何运行

```bash
npm install
npm run dev         # 开发模式（tsx watch，自动重启）
npm run typecheck   # TypeScript 类型检查
npm run build       # 编译到 dist/
npm run start       # 生产启动（编译后）
```

## API 端点

| 方法 | 路径 | 认证 | 说明 |
|------|------|------|------|
| `GET` | `/health` | 否 | 健康检查 |
| `POST` | `/auth/login` | 否 | Mock 登录（username + password） |
| `GET` | `/records` | 是 | 记录列表（page/limit/search/status） |
| `GET` | `/records/:id` | 是 | 记录详情 |
| `POST` | `/records` | 是 | 创建记录 |
| `PATCH` | `/records/:id` | 是 | 更新记录 |
| `POST` | `/records/:id/action` | 是 | 业务动作（状态流转 + 幂等占位） |
| `GET` | `/admin/audit-logs` | admin | 审计日志列表 |

所有 API 使用统一格式：`{ ok: true, data }` / `{ ok: false, error: { code, message } }`

## 如何替换内容

1. **替换 mock 数据**：编辑 `src/db/mock-db.ts`
2. **修改认证逻辑**：编辑 `src/middleware/auth.ts` 和 `src/repositories/user-repository.ts`
3. **替换业务模型**：编辑 `src/types/index.ts` 和相关 route/service/repository
4. **接入真实数据库**：配置 `.env` → 替换 repositories/ 为 Prisma/Drizzle
5. **启用真实 JWT**：在 `src/middleware/auth.ts` 中替换 mock token 逻辑

## 如何避免过度设计

- 第一版只用 mock-db，不要马上接真实 PostgreSQL
- 不要默认加 Redis/队列/微服务
- 不要默认加 Swagger/OpenAPI 复杂文档
- 如果只是简单 CRUD，不要加复杂状态机
- 如果只是内部工具，不要加复杂 RBAC
- 如果项目达到 L/XL，只说明升级路径，第一阶段不堆复杂架构

## 升级路径

| 阶段 | 内容 |
|------|------|
| **第一阶段（本 starter）** | mock-db + mock auth + 8 个端点 + 统一 API 格式 |
| **升级：接真实数据库** | PostgreSQL + Prisma/Drizzle + schema.prisma |
| **升级：接真实认证** | JWT + bcrypt + refresh token |
| **升级：高风险项目** | 事务保护 + 幂等约束 + 审计日志持久化 |
| **升级：高并发** | 连接池 + 读写分离 + 缓存层 |

## 第一阶段验收标准

- `npm run dev` 能启动，监听 3000 端口
- `GET /health` 返回 `{ ok: true, data: { status: "ok" } }`
- `POST /auth/login` 正确/错误凭证均有对应响应
- `GET /records` 支持分页 + 搜索 + 筛选
- `POST /records` 服务端校验必填字段
- `PATCH /records/:id` 状态枚举校验有效
- `POST /records/:id/action` 有幂等 key 占位
- `GET /admin/audit-logs` 需要 admin 权限占位
- `npm run typecheck` 通过
- `npm run build` 通过
