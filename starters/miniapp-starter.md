# MiniApp Starter（微信小程序）

## 适合项目
- 微信小程序
- uni-app 跨端项目
- 微信公众号 H5 页面
- 需要微信生态（登录、支付、扫码）的项目

## 不适合项目
- PC Web 管理后台
- React Native / Expo 原生 App
- 不涉及微信的纯 Web 项目

## 推荐技术栈
- **前端：** 原生微信小程序 或 uni-app
- **后端：** Node.js + Fastify/Express + TypeScript
- **数据库：** PostgreSQL
- **Auth：** 微信登录（wx.login + 服务端 code2session）
- **密钥：** 全部放服务端，前端不可见

## 推荐目录结构（小程序端）
```
miniapp/
├── pages/
│   ├── index/           # 首页
│   ├── detail/          # 详情页
│   └── user/            # 用户中心
├── components/          # 公共组件
├── utils/
│   ├── api.js           # API 请求封装
│   ├── auth.js          # 登录态管理
│   └── storage.js       # 本地存储
├── app.js               # 入口
├── app.json             # 全局配置
└── app.wxss             # 全局样式
```

## 核心页面/模块
1. **首页**（展示/列表）
2. **详情页**（查看详情）
3. **用户中心**（个人信息、设置）
4. **微信登录流程**（静默登录 + 授权）

## 安全规则
- ❌ **绝不**把 AppSecret 放前端代码
- ❌ **绝不**在前端直接调用 code2session
- ✅ 前端 `wx.login` → 获取 code → 发给后端 → 后端调用 code2session → 返回自定义 token
- ✅ 所有 API 调用在后端校验登录态
- ✅ 敏感操作记日志

## 最小闭环
- 微信静默登录
- 首页（列表）
- 详情页
- 1 个核心功能的完整流程

## 常见坑
- ❌ AppSecret 暴露在前端
- ❌ 没处理弱网/断网状态
- ❌ 登录态过期不刷新
- ❌ 图片不压缩（小程序包大小限制）
- ❌ 没做 rpx 适配

## 第一阶段实现清单
1. [ ] 小程序项目脚手架
2. [ ] 后端 API 项目
3. [ ] 微信登录（服务端处理）
4. [ ] 首页列表
5. [ ] 详情页
6. [ ] API 请求封装（含 token 管理）
7. [ ] 弱网/loading/empty/error 状态
