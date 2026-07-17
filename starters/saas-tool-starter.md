# SaaS / AI Tool Starter

## 适合项目
- AI 生成工具（文案、图片、代码等）
- 模板/素材库
- 按次数/额度计费的在线工具
- 会员订阅制 SaaS

## 不适合项目
- 纯内容展示网站
- 简单的无用户系统工具
- 不需要计费的内部工具

## 推荐技术栈
- **框架：** Next.js + TypeScript
- **数据库：** PostgreSQL
- **ORM：** Prisma 或 Drizzle
- **Auth：** NextAuth.js 或 better-auth
- **UI：** shadcn/ui + Tailwind CSS
- **必建表：** users, generation_history, user_quota, api_logs

## 推荐目录结构
```
src/
├── app/
│   ├── (auth)/           # 登录/注册
│   ├── (dashboard)/      # 用户控制台
│   │   ├── generate/     # 生成页（核心）
│   │   ├── history/      # 生成历史
│   │   └── settings/     # 账号设置
│   └── api/              # API Routes
├── components/
├── lib/
│   ├── db.ts
│   ├── auth.ts
│   └── quota.ts          # 额度管理
└── server/
    └── actions/
```

## 核心页面/模块
1. **登录/注册页**
2. **生成工具页**（核心交互：输入 → 生成 → 展示结果）
3. **生成历史列表**（分页查看历史记录）
4. **用户额度页**（剩余次数/额度显示）
5. **会员/定价页**（可选，第一版可不做）

## 数据结构建议
- `users`：id, email, password_hash, role, quota_total, quota_used, created_at, updated_at
- `generation_history`：id, user_id, input, output, type, created_at
- `user_quota_logs`：id, user_id, change_amount, reason, created_at（审计用）
- `api_logs`：id, user_id, endpoint, method, status, duration_ms, created_at

## 最小闭环
- 登录（不开放注册，管理员手动加账号 或 开放注册）
- 一次完整生成流程（输入 → 处理 → 输出）
- 生成历史列表
- 额度查询 + 扣除

## 常见坑
- ❌ 额度扣除和生成不是原子操作（可能出现扣了额度但没生成）
- ❌ 历史列表没分页
- ❌ 不知道用量还剩多少
- ❌ 没有日志追踪（排查问题困难）

## 第一阶段实现清单
1. [ ] 项目脚手架 + 数据库连接
2. [ ] 用户认证（登录/注册）
3. [ ] 生成工具页面 + API
4. [ ] 额度表 + 扣除逻辑（事务保护）
5. [ ] 生成历史列表（分页）
6. [ ] 额度查询显示
7. [ ] API 调用日志
