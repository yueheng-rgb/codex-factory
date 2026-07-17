# PROJECT_BRIEF — API/Backend Service 项目需求模板

> 使用本 starter 前，先填写此模板明确项目范围。

## 基本信息

- **项目名称：** [填写]
- **项目类型：** api-service / backend-service / miniapp-backend / app-backend
- **目标调用方：** [填写：小程序？App？Web 前端？第三方？]
- **目标用户：** [填写：谁通过调用方使用这个 API？]

## 核心业务资源

[填写：这个 API 管理什么数据？如：报名记录、订单、设备数据、用户信息等]

## 核心业务流程

1. [步骤 1]
2. [步骤 2]
3. [步骤 3]

## 用户角色

- **管理员（admin）：** [权限说明]
- **普通用户（user）：** [权限说明]

## 权限边界

- admin 可以：[列出]
- user 可以：[列出]
- user 不可以：[列出]
- 权限校验位置：服务端中间件

## API 范围（第一版）

- [ ] `GET /health`
- [ ] `POST /auth/login`
- [ ] `GET /records` — 分页 + 搜索 + 筛选
- [ ] `GET /records/:id`
- [ ] `POST /records` — 创建
- [ ] `PATCH /records/:id` — 更新
- [ ] `POST /records/:id/action` — 业务动作
- [ ] `GET /admin/audit-logs` — admin 审计日志
- [ ] 其他：[填写]

## 数据模型（第一版）

- [ ] 核心业务表：[名称] — 关键字段：[列出]
- [ ] 用户表：username, password_hash, role, is_active
- [ ] 审计日志表：user_id, action, target_type, target_id, detail

## 第一阶段最小闭环

调用方能完成：[描述一个真实任务]

涉及 API：[1-3 个]

涉及数据：[1-2 张表]

## 暂不实现内容

- [ ] 真实数据库连接（先用 mock-db）
- [ ] 真实 JWT 认证（先用 mock token）
- [ ] Redis / 缓存层
- [ ] 消息队列
- [ ] 微服务拆分
- [ ] Swagger / OpenAPI 文档
- [ ] 支付 / 订阅
- [ ] 文件上传
- [ ] WebSocket 实时通知
- [ ] 多租户隔离
- [ ] 其他：[填写]

## 升级条件

当以下任意条件满足时，从 mock-db 升级为真实数据库：
- [ ] 需要数据持久化（重启不丢失）
- [ ] 需要并发写入
- [ ] 需要事务一致性
- [ ] 需要数据完整性和唯一约束
- [ ] 外部集成或正式上线

## 第一阶段验收路径

1. `GET /health` → 返回 `{ ok: true }`
2. `POST /auth/login` → 正确凭证返回 token，错误凭证返回 401
3. 使用 token 调用 `GET /records` → 返回分页列表
4. 使用 token 调用 `POST /records` → 创建记录，返回 201
5. 使用 token 调用 `PATCH /records/:id` → 修改状态
6. 使用 admin token 调用 `GET /admin/audit-logs` → 返回审计列表
