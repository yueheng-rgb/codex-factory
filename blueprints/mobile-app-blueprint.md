# Mobile App Blueprint (Expo / React Native)

## 用户需求拆解

当用户说"做一个 App"时，按以下步骤拆解：

### 最少必要问题
1. App 做什么？（核心功能）
2. 需要登录吗？（手机号 / 邮箱 / 第三方）
3. 数据从哪来？（后端 API）
4. 需要哪些原生能力？（相机/推送/定位/存储）
5. 只做 iOS 还是双端？

### 不能默认乱加的内容
- ❌ 不要默认加推送通知
- ❌ 不要默认加相机/相册
- ❌ 不要默认加地图
- ❌ 不要默认加社交分享
- ❌ 不要默认加复杂动画

## 第一版页面结构

```
(auth)/login          →  登录页
(tabs)/               →  Tab 导航布局
  index               →  首页（内容/功能入口）
  discover            →  发现（可选）
  profile             →  用户中心
detail/[id]           →  详情页
```

**不需要做的页面（第一版）：**
- 设置页（复杂设置）
- 搜索页（如果首页能搜）
- 编辑资料页（除非必须）
- 通知页

## 第一版数据结构（后端 API）

```
users
  id (PK)
  phone / email
  password_hash 或 验证码登录
  nickname
  avatar_url
  created_at
  updated_at
```

## 第一版交互流程

```
用户打开 App
  → 检查 token
  → 无 token → 跳转登录页
  → 有 token → 进入 Tab 首页
  → 浏览首页列表 → 点击进入详情
  → 详情页 → 返回
  → 用户中心 → 查看信息 → 退出登录
  → token 过期 → 401 拦截 → 跳转登录
```

## 四态设计（每个数据页面都必须有）
- **loading**：Skeleton / ActivityIndicator
- **empty**：空状态插图 + "暂无内容" + 引导按钮
- **error**：错误提示 + "重试"按钮
- **success**：正常展示内容

## 第一版运行方式

```bash
npm install
npx expo start
# 扫码在手机上预览（Expo Go）
```

## 后续扩展方向
- 推送通知
- 相机/扫码
- 地图功能
- 离线缓存
- 深色模式
- 国际化
