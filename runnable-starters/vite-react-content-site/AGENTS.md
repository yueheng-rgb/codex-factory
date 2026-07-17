# AGENTS.md — vite-react-content-site Starter

> 本文件告诉 Codex 如何使用和维护此 starter。

## 这是什么

`vite-react-content-site` 是一个 Vite + React + TypeScript 单页内容站骨架。
用于官网、宣传页、落地页、招聘页、活动页、服务介绍页等 **content-site / landing-page** 项目。

## 适合什么项目

- 企业官网
- 产品/服务介绍页
- 营销落地页
- 活动报名展示页
- 招聘/团队介绍页

## 不适合什么项目

- ❌ 管理后台 / 数据库系统（请切换到 `fullstack-admin` starter）
- ❌ SaaS / AI 工具（请切换到 `saas-tool` starter）
- ❌ 微信小程序（请切换到 `miniapp` starter）
- ❌ 复杂 Web App（请切换到 `mobile-app` 或全栈 starter）

## 使用前必须遵守的规则

### 1. 先读取 Codex_App_Factory
修改此 starter 之前，必须先读取 `C:\Codex_App_Factory` 中的核心规则：
- `GLOBAL_CODEX_RULES.md`
- `APP_TYPE_ROUTER.md`
- `STACK_DECISION_GUIDE.md`

### 2. 先走 Project Expertise Flow
必须先确认用户需求**真的适合** content-site 类型，而不是强行把一个 SaaS 需求塞进单页网站。

### 3. 不要强行加东西
- ❌ 不要给内容站加数据库
- ❌ 不要给内容站加用户登录/注册
- ❌ 不要给内容站加管理后台
- ❌ 不要给内容站加支付
- ❌ 不要给内容站加复杂 AI
- ✅ 第一版只做：内容结构、响应式、CTA、联系方式

### 4. 扩展原则
- 如果用户需要表单收集 → 添加 ContactForm 组件 + 简单后端 API（或第三方表单服务）
- 如果用户需要后台管理 → **切换到** `next-fullstack-admin` starter，不要在这个 starter 里硬塞
- 如果用户需要更多页面 → 添加 react-router 或切换到 Next.js

### 5. 修改时必须保留
- 移动端响应式适配
- 锚点导航（Header → section）
- 内容与渲染分离（siteContent.ts 驱动组件）
- 无横向溢出

### 6. 完成后
- 运行 `npm run typecheck` 确认无类型错误
- 运行 `npm run build` 确认能成功构建
- 输出简短里程碑报告
