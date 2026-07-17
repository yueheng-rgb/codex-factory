# Fullstack Admin Starter

## 适合项目
- 企业内部管理系统
- 数据管理后台
- 审批/审核/配置系统
- 报表/统计看板
- 权限/角色管理系统

## 不适合项目
- 面向消费者的展示网站
- 纯 API 后端服务
- 微信小程序

## 推荐技术栈
- **框架：** Next.js (App Router) + TypeScript
- **数据库：** PostgreSQL
- **ORM：** Prisma 或 Drizzle
- **UI 库：** shadcn/ui（轻量）或 Ant Design（功能全）
- **样式：** Tailwind CSS
- **表单：** react-hook-form + zod
- **表格：** TanStack Table
- **测试：** Playwright (smoke test)

## 推荐目录结构
```
src/
├── app/                    # Next.js App Router 页面
│   ├── layout.tsx          # 根布局（侧边栏+顶栏）
│   ├── page.tsx            # 首页/仪表盘
│   ├── (auth)/             # 登录/注册页（无侧边栏布局）
│   └── (dashboard)/        # 后台页面（带侧边栏布局）
│       ├── users/          # 用户管理
│       └── settings/       # 设置
├── components/             # 通用组件
│   ├── ui/                 # shadcn/ui 组件
│   ├── forms/              # 表单组件
│   └── tables/             # 表格组件
├── lib/                    # 工具函数
│   ├── db.ts               # 数据库连接
│   ├── auth.ts             # 认证逻辑
│   └── utils.ts            # 通用工具
├── server/                 # 服务端逻辑
│   ├── actions/            # Server Actions
│   └── api/                # API Routes
└── types/                  # TypeScript 类型定义
```

## 核心页面/模块
1. **登录/注册页**（如果不需要注册，只做登录）
2. **仪表盘**（概览统计）
3. **核心 CRUD 页面**（列表 + 新增 + 编辑 + 删除 + 搜索 + 分页）
4. **用户管理**（可选，第一版视需求而定）

## 数据结构建议
- 每张表必须有：`id`, `created_at`, `updated_at`
- 需要软删除：加 `deleted_at`
- 涉及操作日志：单独建 `audit_logs` 表
- 用户-角色-权限：标准 RBAC 三表

## 最小闭环
- 登录（1 个管理员账号即可，不开放注册）
- 一个核心资源的完整 CRUD（列表 + 新增 + 编辑 + 删除 + 搜索 + 分页）
- 权限校验（服务端）

## 常见坑
- ❌ 权限只在前端隐藏按钮
- ❌ 删除用 GET 请求
- ❌ 数据表缺审计字段
- ❌ 分页不做服务端分页
- ❌ 搜索不做防抖
- ❌ 表单缺校验（前端 + 后端都要）

## 第一阶段实现清单
1. [ ] 项目脚手架 + 数据库连接
2. [ ] 登录页 + 服务端认证
3. [ ] 一个核心资源的数据表 + Prisma Schema
4. [ ] 核心资源的列表页（分页 + 搜索）
5. [ ] 核心资源的新增/编辑页（表单校验）
6. [ ] 核心资源的删除功能（确认弹窗）
7. [ ] 权限校验中间件
8. [ ] 基本的 loading/error/empty 状态
