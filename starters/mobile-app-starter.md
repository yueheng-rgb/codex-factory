# Mobile App Starter (Expo / React Native)

## 适合项目
- Expo / React Native 移动应用
- 跨平台 iOS + Android App
- 需要原生能力（相机、推送、定位）的应用

## 不适合项目
- 微信小程序
- 纯 Web 响应式网站
- 后端 API 服务

## 推荐技术栈
- **框架：** Expo (React Native)
- **语言：** TypeScript
- **导航：** expo-router
- **API：** axios 或 fetch + interceptor
- **Auth：** expo-secure-store 存 token
- **UI：** NativeWind 或 自定义组件
- **状态：** React Context 或 Zustand

## 推荐目录结构
```
app/
├── (auth)/               # 登录/注册
│   ├── login.tsx
│   └── register.tsx
├── (tabs)/               # 底部 Tab 导航
│   ├── index.tsx         # 首页
│   ├── discover.tsx      # 发现
│   └── profile.tsx       # 我的
├── detail/
│   └── [id].tsx          # 详情页
├── _layout.tsx           # 根布局
└── +not-found.tsx        # 404 页
src/
├── components/           # 通用组件
├── services/
│   └── api.ts            # API 封装
├── hooks/                # 自定义 Hooks
├── stores/               # 状态管理
└── types/                # 类型定义
```

## 核心页面/模块
1. **登录页**（手机号/邮箱 + 验证码/密码）
2. **首页**（内容/功能入口）
3. **详情页**（内容详情）
4. **用户中心**（个人信息、设置、退出）
5. **Tab 导航**（首页 + 分类/发现 + 我的）

## 登录态管理
- Token 存在 SecureStore（安全存储）
- API 拦截器自动附加 token
- 401 时自动跳转登录页
- Token 刷新机制

## 四态要求
- **loading**：骨架屏或 spinner
- **empty**：空状态插图 + 引导文案
- **error**：错误提示 + 重试按钮
- **success**：正常展示内容

## 最小闭环
- 登录页
- 首页（列表/内容）
- 详情页
- 用户中心
- loading/error/empty 四态

## 常见坑
- ❌ 只在 iOS 测试，Android 跑不通
- ❌ 没做 SafeArea 适配（刘海屏）
- ❌ 列表不优化（长列表卡顿）
- ❌ 键盘弹出遮挡输入框
- ❌ Token 存在 AsyncStorage（不安全）

## 第一阶段实现清单
1. [ ] Expo 项目脚手架
2. [ ] 导航配置（tabs + stack）
3. [ ] 登录页 + token 管理
4. [ ] 首页列表 + 四态
5. [ ] 详情页 + 四态
6. [ ] 用户中心
7. [ ] API 封装 + 拦截器
