# AGENTS.md — next-fullstack-admin Starter

> 本文件告诉 Codex 如何使用和维护此 starter。

## 这是什么

`next-fullstack-admin` 是一个 Next.js 全栈管理后台骨架。
用于管理后台、会员系统、报名系统、记录系统、审核系统、统计后台等 **fullstack-admin** 项目。

## 适合什么项目

- 企业内部管理系统
- 报名/申请管理系统
- 业务记录管理 + 状态流转
- 审核/审批后台
- 统计/数据看板

## 不适合什么项目

- ❌ 官网/纯展示页/落地页（切换到 `vite-react-content-site` starter）
- ❌ 微信小程序（切换到 `miniapp` 相关 starter）
- ❌ 纯后端 API（切换到 `node-api-postgres` starter）
- ❌ 复杂实时协作
- ❌ 复杂电商

## 使用前必须遵守的规则

### 1. 先读取 Codex_App_Factory
修改此 starter 之前，必须先读取 `C:\Codex_App_Factory` 中的核心规则。

### 2. 先走 Project Expertise Flow
必须先确认用户需求**真的适合** fullstack-admin 类型。

### 3. 第一版只做最小闭环
- 1 个核心资源的完整 CRUD（列表 + 搜索 + 筛选 + 新增 + 编辑 + 删除）
- 登录（1 个管理员账号，不开放注册）
- 权限校验（服务端）

### 4. 禁止强行添加
- ❌ 不要添加支付、分账
- ❌ 不要添加多租户
- ❌ 不要添加消息队列
- ❌ 不要添加复杂 AI
- ❌ 不要加不需要的角色和权限

### 5. 强制规则
- 所有权限必须服务端校验（前端隐藏按钮 ≠ 权限）
- 所有 API 必须使用统一返回格式 `{ ok, data/error }`
- 所有列表必须考虑分页、搜索、筛选、空状态
- 所有表单必须考虑 submitting、防重复提交、成功/失败反馈
- 详情页必须能直接访问（不依赖列表页 state）
- 数据库项目必须考虑审计字段（createdAt / updatedAt）

### 6. mock-db 不是正式数据库
当前使用内存 mock 数据。真实项目必须替换为 PostgreSQL + Prisma/Drizzle。

### 7. 完成后
- 运行 `npm run typecheck`
- 运行 `npm run build`
- 输出简短里程碑报告
