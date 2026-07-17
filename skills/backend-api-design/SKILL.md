# Backend API Design

## 用途
设计专业的后端 API：分层、错误格式、鉴权、中间件、分页、筛选。
**不要把业务规则只放前端。** 服务端必须是数据的最终权威。

## 使用场景
- 设计 API 结构时
- 需要决定路由、中间件、错误处理方案时

## API 分层架构

```
Route 层    →  路由定义，参数提取
Controller 层 →  请求/响应处理，调用 Service
Service 层  →  业务逻辑（核心）
Repository 层 →  数据访问（如果使用 ORM 可合并到 Service）
Middleware 层 →  横切关注点（auth, validation, error, rate-limit, log）
```

## 统一响应格式

```typescript
// 成功 - 单个/操作
{
  "success": true,
  "data": { ... }
}

// 成功 - 列表
{
  "success": true,
  "data": [ ... ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}

// 失败
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",   // 机器可读
    "message": "名称不能为空",      // 人类可读
    "details": [                   // 可选，详细错误
      { "field": "name", "message": "必填" }
    ]
  }
}
```

## HTTP 状态码规则

| 状态码 | code | 场景 |
|--------|------|------|
| 200 | SUCCESS | 正常响应 |
| 201 | CREATED | 创建成功 |
| 400 | VALIDATION_ERROR | 请求参数错误 |
| 401 | UNAUTHORIZED | 未登录 |
| 403 | FORBIDDEN | 无权限 |
| 404 | NOT_FOUND | 资源不存在 |
| 409 | CONFLICT | 冲突（如重复创建） |
| 429 | RATE_LIMITED | 请求过多 |
| 500 | INTERNAL_ERROR | 服务器内部错误 |

## 中间件栈（按顺序）

```
1. Logger          →  记录请求信息
2. Rate Limiter    →  限流（可选，第一版可不做）
3. Auth            →  校验 token，注入 user 信息
4. Validate        →  校验 request body/query/params
5. Controller      →  业务处理
6. Error Handler   →  统一错误处理（最后的 catch-all）
```

## 分页规范

```
GET /api/resource?page=1&limit=20
GET /api/resource?page=1&limit=20&search=关键字
GET /api/resource?page=1&limit=20&status=active&sort=created_at&order=desc
```

## 服务端校验（不在前端做的）
- ❌ 只在前端做必填校验
- ❌ 只在前端做格式校验
- ❌ 信任前端传来的 user_id/role
- ✅ 所有输入都在服务端校验
- ✅ 权限从 token 中解析，不信任请求参数
- ✅ 敏感操作检查资源归属

## 不要做的事
- ❌ 把业务规则只写在前端
- ❌ 错误信息暴露数据库结构
- ❌ 在 URL 中传敏感数据
- ❌ GET 请求做修改操作
- ❌ 无分页的列表接口
- ❌ 错误码混乱不一致

## 输出格式
```
## API 设计

### 端点列表
POST   /api/auth/login
GET    /api/resource?page=&limit=&search=
GET    /api/resource/:id
POST   /api/resource
PUT    /api/resource/:id
DELETE /api/resource/:id

### 鉴权方案
- 方式：JWT / Session
- 过期时间：...
- 刷新策略：...

### 中间件
- [ ] Auth
- [ ] Validate
- [ ] Error Handler
```
