# Content Site Starter

## 适合项目
- 企业官网
- 产品/服务介绍页
- 活动/营销落地页
- 个人作品集/博客
- 报名/表单收集页

## 不适合项目
- 需要复杂用户系统的 SaaS
- 后台管理系统
- 需要数据库的 CRUD 系统

## 推荐技术栈
- **构建：** Vite 或 Next.js
- **语言：** React + TypeScript
- **样式：** Tailwind CSS
- **布局：** 响应式（mobile-first）
- **动画：** Framer Motion（可选）
- **SEO：** react-helmet-async 或 Next.js Metadata

## 推荐目录结构
```
src/
├── components/
│   ├── layout/           # Header, Footer, Layout
│   ├── sections/         # Hero, Features, CTA 等页面区块
│   └── ui/               # Button, Card 等基础组件
├── pages/                # 路由页面（或 app/ 目录）
│   ├── index.tsx         # 首页
│   ├── about.tsx         # 关于页
│   └── contact.tsx       # 联系页
├── assets/               # 图片、字体
├── styles/               # 全局样式
└── utils/                # 工具函数
```

## 核心页面/模块
1. **首页**（Hero + 核心卖点 + CTA）
2. **列表/展示页**（产品或内容的列表）
3. **详情页**（单个产品/内容的详情）
4. **联系/表单页**（可选）
5. **Header + Footer**（全局导航）

## 数据结构建议
- 如果是纯静态站：数据写 JSON/Markdown
- 如果需要简单 CMS：可以用 Markdown 文件 + frontmatter
- 如果有报名表单：后端用简单的 API 存数据

## 最小闭环
- 首页 + 列表页 + 详情页（共计 3-5 个页面）
- 响应式布局（375px-1440px）
- 基本 SEO meta 标签
- 页面间导航 + Header/Footer

## 常见坑
- ❌ 忽略移动端适配
- ❌ 图片不压缩、不懒加载
- ❌ 没做 SEO meta 标签
- ❌ 动画性能差（移动端卡顿）
- ❌ 表单无提交状态/防重复提交

## 第一阶段实现清单
1. [ ] 项目脚手架
2. [ ] Header + Footer 组件
3. [ ] 首页（Hero + 卖点区域）
4. [ ] 列表页
5. [ ] 详情页
6. [ ] 响应式布局验证（375px / 768px / 1440px）
7. [ ] 基本 SEO（title, description, og:image）
