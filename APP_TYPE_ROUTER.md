# App Type Router — 应用类型路由

> 根据用户需求关键词，自动判断项目应该走哪种类型。

---

## 分类规则

### ① fullstack-admin（管理后台/前后端系统）

**触发关键词：** 后台、管理、统计、账号、表格、记录、权限、审核、审批、配置、列表、CRUD、报表、仪表盘

**适合场景：**
- 企业内部管理系统
- 数据管理后台
- 审批/审核系统
- 报表/统计看板
- 权限管理系统

**不适合场景：**
- 面向 C 端消费者的展示网站
- 纯 API 服务
- 微信小程序前端

**推荐 starter：** `starters/fullstack-admin-starter.md`
**推荐 blueprint：** `blueprints/fullstack-admin-blueprint.md`
**推荐技术栈：** Next.js + TypeScript + PostgreSQL + Prisma/Drizzle + shadcn/ui 或 Ant Design

**第一版最小闭环：**
- 登录 + 一个核心资源的完整 CRUD（列表+新增+编辑+删除+搜索+分页）
- 权限校验（至少区分管理员和普通用户）

---

### ② content-site（内容展示网站/营销页）

**触发关键词：** 官网、宣传、展示、介绍、落地页、活动页、报名页、博客、作品集、公司主页

**适合场景：**
- 企业官网
- 产品落地页
- 活动报名页
- 个人作品集
- 博客/内容站

**不适合场景：**
- 需要复杂用户系统的 SaaS 产品
- 后台管理系统
- 移动 App

**推荐 starter：** `starters/content-site-starter.md`
**推荐 blueprint：** `blueprints/content-site-blueprint.md`
**推荐技术栈：** Vite 或 Next.js + React + TypeScript + Tailwind CSS

**第一版最小闭环：**
- 3-5 个核心页面（首页+列表页+详情页+关于页）
- 响应式布局
- 基本 SEO meta 标签

---

### ③ saas-tool（SaaS / AI 工具）

**触发关键词：** AI生成、模板、生成历史、额度、次数、会员、订阅、积分、使用量、API Key

**适合场景：**
- AI 生成工具（文案、图片、代码 等）
- 模板库/素材库
- 按次数/额度计费的在线工具
- 会员订阅制产品

**不适合场景：**
- 纯内容展示网站
- 没有用户系统的简单工具
- 不需要计费/计次的内部工具

**推荐 starter：** `starters/saas-tool-starter.md`
**推荐 blueprint：** `blueprints/saas-tool-blueprint.md`
**推荐技术栈：** Next.js + Auth + PostgreSQL + 生成历史表 + 用户额度表 + API 调用日志

**第一版最小闭环：**
- 登录 + 一次完整的生成流程 + 生成历史列表
- 额度扣除与查询

---

### ④ api-service（后端 API 服务）

**触发关键词：** 接口、后端、API、数据库服务、给前端调用、RESTful、数据接口、微服务接口

**适合场景：**
- 纯后端 API 服务
- 为前端/移动端提供数据接口
- 数据库 CRUD 服务层

**不适合场景：**
- 需要前端页面的完整项目
- 内容展示网站

**推荐 starter：** `starters/api-service-starter.md`
**推荐 blueprint：** `blueprints/api-service-blueprint.md`
**推荐技术栈：** Node.js + Fastify/Express + PostgreSQL + Prisma/Drizzle + OpenAPI 文档

**第一版最小闭环：**
- 1-2 个核心资源的 CRUD API
- 统一错误格式
- 鉴权中间件
- OpenAPI 文档

---

### ⑤ miniapp（微信小程序 / H5）

**触发关键词：** 小程序、微信、OPENID、扫码、公众号、微信登录、uni-app

**适合场景：**
- 微信小程序
- uni-app 跨端项目
- 微信公众号 H5 页面
- 需要微信生态的项目

**不适合场景：**
- PC 端后台管理系统
- React Native / Expo App
- 不涉及微信的纯 Web 项目

**推荐 starter：** `starters/miniapp-starter.md`
**推荐 blueprint：** `blueprints/miniapp-blueprint.md`
**推荐技术栈：** 原生微信小程序或 uni-app + 后端 API（Node.js）

**第一版最小闭环：**
- 微信登录
- 1-2 个核心页面
- 服务端处理 OPENID 和密钥
- 前端只做展示和 API 调用

---

### ⑥ mobile-app（Expo / React Native App）

**触发关键词：** App、安卓、iOS、React Native、Expo、Flutter、移动应用、上架

**适合场景：**
- Expo / React Native 移动应用
- 需要原生能力（相机、推送、定位）的 App
- 跨平台移动应用

**不适合场景：**
- 微信小程序（走 miniapp）
- 纯 Web 网站
- 后端 API 服务

**推荐 starter：** `starters/mobile-app-starter.md`
**推荐 blueprint：** `blueprints/mobile-app-blueprint.md`
**推荐技术栈：** Expo / React Native + API Client + 登录态 + 页面导航

**第一版最小闭环：**
- 登录页 + 首页 + 1个核心功能的完整流程
- loading/error/empty 状态

---

### ⑦ threejs-interactive（Three.js 交互式 Web 原型）

**触发关键词：** 3D、场景、Three.js、地图、可点击物体、虚拟空间、WebGL、3D展示、交互式3D

**适合场景：**
- 3D 产品展示
- 虚拟展厅/空间
- 交互式 3D 地图
- 3D 数据可视化

**不适合场景：**
- 需要表单/数据库的常规 Web 应用
- 微信小程序
- 纯 2D 网站

**推荐 starter：** `starters/threejs-interactive-starter.md`
**推荐 blueprint：** `blueprints/threejs-interactive-blueprint.md`
**推荐技术栈：** Vite + TypeScript + Three.js + UI 面板层 + 场景对象层 + 状态管理

**第一版最小闭环：**
- 一个可交互的 3D 场景
- 至少一个可点击/交互的物体
- 基本 UI 面板
- 能在浏览器中查看

---

## 使用方式

收到新项目需求后：
1. 扫描需求关键词
2. 匹配上述分类规则
3. 如果有多个关键词同时满足 → 选匹配数最多的类型
4. 如果仍不确定 → 列出 2-3 个候选类型，请用户确认

---

## 项目体量判断（Phase 3B-4.5）

每个项目类型判断后，还需要判断体量等级和架构是否需要升级。

### content-site

- **常见体量：** S
- **默认 starter：** `vite-react-content-site`
- **升级条件：** 需要表单提交收集数据、需要后台管理查看提交记录、需要数据库存储
- **不升级条件：** 只是展示信息、纯营销页、无用户数据
- **如果升级：** 考虑为表单接简单后端 API，或切换到 fullstack-admin

### fullstack-admin

- **常见体量：** M-L
- **默认 starter：** `next-fullstack-admin`
- **升级条件：** 多角色、审计、事务、核销、提成、报表、长期使用、高风险数据
- **不升级条件：** 简单报名/记录管理、1-2 个管理员、数据可恢复
- **如果升级：** 引入真实 PostgreSQL、Prisma/Drizzle、审计日志、事务边界

### saas-tool

- **常见体量：** M-L
- **默认 starter：** `next-saas-ai-tool`（待创建）
- **升级条件：** 真实 AI API、额度扣减、支付、订阅、生成历史、API 调用日志
- **不升级条件：** 只做 mock 演示、内部工具、无额度管理
- **如果升级：** 引入事务保护额度扣减、API 调用日志、审计

### api-service

- **常见体量：** M-L
- **默认 starter：** `node-api-postgres`（待创建）
- **升级条件：** 高并发、多服务、需要消息队列、需要缓存
- **不升级条件：** 单服务、低并发、内部 API

### miniapp

- **常见体量：** M-L
- **默认 starter：** 无 runnable starter（待创建）
- **升级条件：** 支付、核销、扫码、多角色、高并发
- **不升级条件：** 简单展示、签到、个人工具

### mobile-app

- **常见体量：** M-L
- **默认 starter：** 无 runnable starter（待创建）
- **升级条件：** 实时通信、推送、支付、离线缓存

### threejs-interactive

- **常见体量：** S-M
- **默认 starter：** `vite-threejs-interactive`（待创建）
- **升级条件：** 大型场景、多人协作、后端数据驱动
- **不升级条件：** 单人交互、展示型、无后端