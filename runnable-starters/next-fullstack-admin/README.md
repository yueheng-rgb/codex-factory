# Next.js Fullstack Admin — Runnable Starter

> 一个可直接复制使用的 Next.js 全栈管理后台骨架。
> 适合管理后台、报名系统、记录系统、审核系统、统计后台。

## 适合项目

- 企业内部管理系统
- 会员管理系统
- 报名/申请管理系统
- 业务记录管理系统
- 审核/审批后台
- 统计/数据看板
- 配置管理后台

## 不适合项目

- 官网/纯展示页/落地页（请使用 `vite-react-content-site` starter）
- 微信小程序（请使用 miniapp 相关 starter）
- 纯后端 API 服务（请使用 `node-api-postgres` starter）
- 复杂实时协作系统
- 电商系统

## 目录说明

```
next-fullstack-admin/
├── README.md                 # 本文件
├── AGENTS.md                 # Codex 使用说明
├── PROJECT_BRIEF.md          # 项目需求模板
├── package.json / tsconfig.json / next.config.js
├── .env.example
├── prisma/
│   └── schema.prisma.example # 数据库模型示例
├── app/
│   ├── layout.tsx / globals.css
│   ├── page.tsx              # 根路由 → dashboard
│   ├── login/page.tsx        # 登录页
│   ├── dashboard/page.tsx    # 仪表盘
│   ├── records/page.tsx      # 记录列表
│   ├── records/[id]/page.tsx # 记录详情
│   ├── settings/users/page.tsx # 用户管理占位
│   └── api/                  # API route handlers
│       ├── health/route.ts
│       ├── auth/login/route.ts
│       └── records/
│           ├── route.ts           # GET 列表 / POST 新建
│           └── [id]/route.ts      # GET 详情 / PATCH 更新
├── components/               # 10 个共享组件
├── lib/                      # 工具库（api-response, auth-placeholder, mock-db 等）
└── tests/
    └── smoke-checklist.md
```

## 如何复制使用

```bash
cp -r C:/Codex_App_Factory/runnable-starters/next-fullstack-admin ./my-admin
cd my-admin
```

## 如何安装与运行

```bash
npm install
npm run dev          # http://localhost:3000
npm run typecheck
npm run build
```

## API 设计说明

所有 API 使用统一响应格式 `{ ok: true, data: ... }` 或 `{ ok: false, error: { code, message } }`。

| 端点 | 说明 |
|------|------|
| `GET /api/health` | 健康检查 |
| `POST /api/auth/login` | Mock 登录（admin/admin123 或 user/user123） |
| `GET /api/records?page=1&limit=20&search=xx&status=active` | 记录列表（分页+搜索+筛选） |
| `POST /api/records` | 新建记录 |
| `GET /api/records/:id` | 记录详情 |
| `PATCH /api/records/:id` | 修改记录状态/备注 |

## mock-db 说明

当前使用**内存 mock 数据库**（`lib/mock-db.ts`），数据只在进程运行期间存在，重启后重置。

## 如何替换为真实数据库

1. 安装 Prisma：`npm install prisma @prisma/client`
2. 重命名 `prisma/schema.prisma.example` → `prisma/schema.prisma`
3. 在 `.env` 中配置 `DATABASE_URL`
4. 运行 `npx prisma migrate dev`
5. 替换 `lib/mock-db.ts` 为 Prisma Client 调用
6. 替换 `lib/records.ts` 中的查询逻辑

## 如何接真实认证

1. 安装认证库（如 NextAuth.js 或 better-auth）
2. 替换 `lib/auth-placeholder.ts` 为真实 JWT/Cookie 管理
3. 在 API handler 中添加认证中间件
4. 密码使用 bcrypt 哈希存储
5. 配置 token 过期与刷新

## 如何扩展业务模块

1. 在 `prisma/schema.prisma.example` 中添加新模型
2. 在 `app/api/` 下新建 API routes
3. 在 `app/` 下新建页面目录
4. 复用 `lib/api-response.ts` 的统一响应格式
5. 复用 `components/` 中的共享组件

## 如何避免过度设计

- ❌ 不要加支付
- ❌ 不要加分账
- ❌ 不要加多租户
- ❌ 不要加消息队列
- ❌ 不要加复杂 AI
- ✅ 第一版只做 1 个核心资源的 CRUD
- ✅ 权限只做 admin/user 两种角色
- ✅ 所有 API 使用统一格式
- ✅ 所有权限在服务端校验

## 第一阶段验收标准

- [ ] `npm run dev` 正常启动
- [ ] `/login` 可登录（admin/admin123）
- [ ] `/dashboard` 显示统计卡片
- [ ] `/records` 显示记录列表
- [ ] 搜索和状态筛选可用
- [ ] `/records/:id` 可查看详情
- [ ] 修改状态功能正常
- [ ] 直接访问 `/records/nonexistent` 显示错误
- [ ] `npm run typecheck` 通过
- [ ] `npm run build` 通过
