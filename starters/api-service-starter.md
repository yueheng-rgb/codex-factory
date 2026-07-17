# API Service Starter

## 适合项目
- 纯后端 API 服务
- 为前端/移动端提供数据接口
- RESTful API 服务层
- 微服务中的单个服务

## 不适合项目
- 需要前端页面的完整项目
- 微信小程序（后端部分可用）
- 纯静态网站

## 推荐技术栈
- **运行时：** Node.js
- **框架：** Fastify 或 Express
- **语言：** TypeScript
- **数据库：** PostgreSQL
- **ORM：** Prisma 或 Drizzle
- **文档：** OpenAPI (Swagger)
- **测试：** Vitest + supertest

## 推荐目录结构
```
src/
├── routes/              # 路由定义
│   ├── index.ts
│   └── users.ts
├── controllers/         # 请求处理
├── services/            # 业务逻辑
├── middleware/           # 中间件
│   ├── auth.ts          # 鉴权
│   ├── error.ts         # 错误处理
│   └── validate.ts      # 请求校验
├── models/              # 数据模型（如果用 Prisma 则不需要）
├── schemas/             # 请求/响应 Schema (zod 或 JSON Schema)
├── db/
│   └── schema.prisma    # Prisma Schema
├── types/               # TypeScript 类型
├── utils/               # 工具函数
├── app.ts               # 应用入口
└── config.ts            # 配置
```

## 核心模块
1. **路由层**：定义所有 API 端点
2. **控制器层**：处理请求/响应
3. **服务层**：业务逻辑
4. **中间件层**：auth / error / validate / rate-limit
5. **数据层**：数据库操作

## 数据结构：统一响应格式
```typescript
// 成功
{ "success": true, "data": {...}, "meta": { "page": 1, "total": 100 } }

// 失败
{ "success": false, "error": { "code": "VALIDATION_ERROR", "message": "..." } }
```

## 统一错误格式
- `400` — VALIDATION_ERROR
- `401` — UNAUTHORIZED
- `403` — FORBIDDEN
- `404` — NOT_FOUND
- `409` — CONFLICT
- `429` — RATE_LIMITED
- `500` — INTERNAL_ERROR

## 最小闭环
- 1-2 个核心资源的 CRUD API
- 统一错误格式
- 鉴权中间件
- 请求参数校验
- 分页（列表接口）
- 筛选（列表接口）
- OpenAPI 文档（`/docs` 端点）

## 常见坑
- ❌ 没有统一错误格式
- ❌ 没有请求校验
- ❌ 鉴权只在部分接口做
- ❌ 列表接口没分页
- ❌ 敏感信息泄漏在错误消息中

## 第一阶段实现清单
1. [ ] 项目脚手架 + TypeScript 配置
2. [ ] 数据库连接 + Migration
3. [ ] 统一错误处理中间件
4. [ ] 鉴权中间件
5. [ ] 请求校验中间件
6. [ ] 1 个资源的 CRUD API（含分页+筛选）
7. [ ] OpenAPI 文档
8. [ ] 基本测试用例
