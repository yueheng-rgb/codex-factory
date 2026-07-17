# Vite React Content Site — Runnable Starter

> 一个可直接复制使用的 Vite + React + TypeScript 单页内容站骨架。
> 适合官网、宣传页、落地页、招聘页、活动页、服务介绍页。

## 适合项目

- 企业官网
- 产品/服务介绍页
- 活动/营销落地页
- 个人作品集
- 招聘页
- 服务介绍页
- 报名/咨询页（需自行扩展联系表单）

## 不适合项目

- 需要数据库的管理后台（请使用 `next-fullstack-admin` starter）
- 需要用户系统的 SaaS 工具（请使用 `next-saas-ai-tool` starter）
- 纯后端 API 服务（请使用 `node-api-postgres` starter）
- 微信小程序（请使用 miniapp 相关 starter）
- Three.js 3D 交互原型（请使用 `vite-threejs-interactive` starter）

## 目录说明

```
vite-react-content-site/
├── README.md                 # 本文件
├── AGENTS.md                 # Codex 使用说明
├── PROJECT_BRIEF.md          # 项目需求填写模板
├── package.json              # 依赖和脚本
├── tsconfig.json             # TypeScript 配置
├── vite.config.ts            # Vite 配置
├── index.html                # HTML 入口
├── .env.example              # 环境变量模板
├── src/
│   ├── main.tsx              # React 入口
│   ├── App.tsx               # 根组件（组装所有 section）
│   ├── styles.css            # 全局样式
│   ├── data/
│   │   └── siteContent.ts    # 站点内容配置（修改此文件替换内容）
│   ├── components/
│   │   ├── Header.tsx        # 顶部导航
│   │   ├── Hero.tsx          # 首屏区
│   │   ├── Features.tsx      # 核心功能
│   │   ├── HowItWorks.tsx    # 使用流程
│   │   ├── UseCases.tsx      # 适用场景
│   │   ├── CTA.tsx           # 行动号召
│   │   ├── Footer.tsx        # 页脚
│   │   ├── EmptyState.tsx    # 空状态示例组件
│   │   └── ErrorState.tsx    # 错误状态示例组件
│   └── utils/
│       └── contentGuards.ts  # 内容守卫工具
└── tests/
    └── smoke-checklist.md    # 手动 smoke 测试清单
```

## 如何复制使用

```bash
# 复制整个目录到新项目
cp -r C:/Codex_App_Factory/runnable-starters/vite-react-content-site ./my-website
cd my-website
```

## 如何安装依赖

```bash
npm install
```

## 如何运行

```bash
npm run dev
```

浏览器打开 `http://localhost:5173`

## 如何 build

```bash
npm run build
```

产物在 `dist/` 目录。

## 如何 preview

```bash
npm run preview
```

在本地预览生产构建产物。

## 如何 typecheck

```bash
npm run typecheck
```

## 如何替换内容

1. 编辑 `src/data/siteContent.ts`
2. 修改 `PROJECT_NAME` 占位符为你的项目名
3. 替换 Hero 区标题和描述
4. 添加你的核心功能列表
5. 修改使用步骤
6. 修改适用场景
7. 替换联系方式的邮箱
8. 所有文本集中在一个文件，组件只负责渲染

## 如何扩展联系表单

1. 创建一个 `ContactForm.tsx` 组件
2. 在 CTA 区嵌入或替换现有按钮
3. 如果只需要收集信息，可以用简单的 form + mailto 或接入后端 API
4. 如果需要数据库存储，考虑切换到 `next-fullstack-admin` starter

## 如何避免过度设计

- ❌ 不要加数据库
- ❌ 不要加用户登录/注册
- ❌ 不要加支付
- ❌ 不要加复杂路由（本 starter 是单页，用锚点导航）
- ❌ 不要加 Tailwind 或其他 UI 库（已有纯 CSS）
- ✅ 如果需要后台管理，切换到 `next-fullstack-admin` starter
- ✅ 如果需要更多页面，使用 react-router 或切换到 Next.js

## 第一阶段验收标准

- [ ] `npm run dev` 能正常启动
- [ ] `npm run build` 无错误
- [ ] `npm run typecheck` 无错误
- [ ] 所有页面板块可见
- [ ] Header 导航锚点可点击
- [ ] CTA 按钮可点击
- [ ] 375px 宽下无横向溢出
- [ ] 控制台无报错
