# API Service Blueprint

## 用户需求拆解

当用户说"做一个 XX API 服务/接口"时，按以下步骤拆解：

### 最少必要问题
1. 提供什么数据/服务？（核心资源是什么）
2. 谁调用？（前端 / 移动端 / 第三方 / 内部系统）
3. 怎么鉴权？（API Key / JWT Token / OAuth）
4. 数据量大吗？（决定分页策略、索引）
5. 需要写操作吗？（还是只读查询）
6. 需要哪些端点？（CRUD 全部 or 只有 R）

### 不能默认乱加的内容
- ❌ 不要默认做 GraphQL
- ❌ 不要默认做 WebSocket/实时推送
- ❌ 不要默认做微服务拆分
- ❌ 不要默认做复杂的 Rate Limiting（除非需要）
- ❌ 不要默认做 API 版本管理（v1/v2）

## 第一版 API 结构

```
POST   /api/auth/login          →  登录，返回 token
POST   /api/auth/refresh        →  刷新 token

GET    /api/[resource]          →  列表（?page=1&limit=20&search=xxx&status=active）
GET    /api/[resource]/:id      →  详情
POST   /api/[resource]          →  新建
PUT    /api/[resource]/:id      →  更新
DELETE /api/[resource]/:id      →  删除

GET    /api/docs                →  OpenAPI 文档
GET    /api/health              →  健康检查
```

## 第一版数据结构（统一响应）

```typescript
// 成功 - 列表
{
  "success": true,
  "data": [...],
  "meta": { "page": 1, "limit": 20, "total": 100, "totalPages": 5 }
}

// 成功 - 单个
{
  "success": true,
  "data": { "id": 1, "name": "..." }
}

// 失败
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Name is required",
    "details": [{ "field": "name", "message": "Required" }]
  }
}
```

## 第一版数据结构（数据库）

```
核心资源表
  id (PK, UUID 或自增)
  ...业务字段
  created_at
  updated_at
  deleted_at (软删除)

users（如果有用户系统）
  id (PK)
  username / email
  password_hash
  role
  is_active
  created_at
  updated_at
```

## 第一版交互流程

```
客户端请求 API
  → 鉴权中间件校验 token（登录接口除外）
  → 参数校验中间件校验 request body/query
  → Controller 处理请求
  → Service 层执行业务逻辑
  → 数据库操作
  → 返回统一格式响应
  → 错误 → 统一错误处理中间件返回错误格式
```

## 第一版运行方式

```bash
npm install
cp .env.example .env
npx prisma migrate dev
npm run dev        # 启动 API 服务
```

访问 `http://localhost:3000/api/docs` 查看 API 文档。

## 后续扩展方向
- API 版本管理
- Rate Limiting
- 更细粒度的权限控制
- Webhook
- 批量操作端点
- 数据导出端点
