# Smoke Checklist — node-api-postgres

> 手动验收清单。运行 `npm run dev` 后逐项检查。
> 以后安装 Playwright 后可升级为自动测试。

## 基础检查

- [ ] `npm run dev` 正常启动，http://localhost:3000
- [ ] `npm run typecheck` 无错误
- [ ] `npm run build` 无错误

## API — 公开端点

### GET /health
- [ ] `GET /health` → `{ "ok": true, "data": { "status": "ok" } }`

### POST /auth/login
- [ ] 正确凭证 `{ "username": "admin", "password": "admin123" }` → 返回 token 和 user
- [ ] 正确凭证 `{ "username": "user", "password": "user123" }` → 返回 token（role: user）
- [ ] 空 username → `{ ok: false, error: { code: "VALIDATION_ERROR" } }`
- [ ] 空 password → `{ ok: false, error: { code: "VALIDATION_ERROR" } }`
- [ ] 错误密码 → `{ ok: false, error: { code: "UNAUTHORIZED" } }`，HTTP 401
- [ ] 不存在的用户 → `{ ok: false, error: { code: "UNAUTHORIZED" } }`

## API — 需认证端点

### GET /records（列表 + 分页 + 搜索 + 筛选）
- [ ] 无 token → 返回 `UNAUTHORIZED` 401
- [ ] 有 token，默认分页 → `{ ok: true, data: { items, page, limit, total, totalPages } }`
- [ ] `?page=2&limit=1` → 分页正确
- [ ] `?search=示例` → 搜索过滤
- [ ] `?status=pending` → 状态筛选
- [ ] 搜索结果为空 → items 为空数组，total=0

### GET /records/:id（详情）
- [ ] `GET /records/rec-001` → 返回记录详情
- [ ] `GET /records/nonexistent` → `NOT_FOUND` 404

### POST /records（创建）
- [ ] 正确数据 `{ "title": "新记录", "description": "描述内容" }` → 201，返回新记录
- [ ] 空 title → `VALIDATION_ERROR` 400
- [ ] 空 description → `VALIDATION_ERROR` 400
- [ ] title 过短（1 个字符）→ `VALIDATION_ERROR` 400

### PATCH /records/:id（更新）
- [ ] `{ "status": "active" }` → 状态更新成功
- [ ] `{ "remark": "备注内容" }` → 备注更新成功
- [ ] `{ "status": "invalid_status" }` → `VALIDATION_ERROR` 400
- [ ] 不存在的 id → `NOT_FOUND` 404

### POST /records/:id/action（业务动作）
- [ ] `{ "action": "approve" }` on pending record → 状态变为 active
- [ ] `{ "action": "cancel" }` on active record → 状态变为 cancelled
- [ ] 非法状态转换（如 approve on completed）→ `VALIDATION_ERROR` 400
- [ ] 传入 idempotencyKey → 正常返回（幂等占位不报错）

## API — Admin 端点

### GET /admin/audit-logs
- [ ] 无 token → `UNAUTHORIZED` 401
- [ ] user token（role: user）→ `FORBIDDEN` 403
- [ ] admin token → 返回分页审计日志列表
- [ ] `?action=CREATE` → 按 action 筛选

## 错误格式统一
- [ ] 所有错误响应格式：`{ ok: false, error: { code, message } }`
- [ ] HTTP 状态码与 error code 对应：400/401/403/404/409/500

## 控制台
- [ ] `npm run dev` 控制台无未捕获异常
- [ ] 错误请求不在控制台抛出 500 崩溃
