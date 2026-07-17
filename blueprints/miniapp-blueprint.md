# MiniApp Blueprint（微信小程序）

## 用户需求拆解

当用户说"做一个小程序"时，按以下步骤拆解：

### 最少必要问题
1. 小程序做什么？（展示 / 交易 / 工具 / 社区）
2. 需要微信登录吗？（默认需要，走 wx.login）
3. 需要支付吗？（微信支付）
4. 数据从哪来？（后端 API）
5. 用户主要是谁？（决定 UI 风格）

### 不能默认乱加的内容
- ❌ 不要把 PC 后台强行压缩成手机页面
- ❌ 不要默认加微信支付
- ❌ 不要默认加地图/定位
- ❌ 不要默认加客服消息
- ❌ 不要把 AppSecret 放前端

## 第一版页面结构

```
pages/index/index      →  首页（列表/入口）
pages/detail/detail    →  详情页
pages/user/user        →  用户中心（"我的"）
```

**不需要做的页面（第一版）：**
- 设置页
- 关于页
- 搜索页（如果在首页就能搜就不需要独立页）
- 订单页（除非有交易）

## 第一版数据结构（后端）

```
users
  id (PK)
  openid (UNIQUE)          -- 微信 OPENID
  unionid (可空)
  nickname
  avatar_url
  created_at
  updated_at
```

**注意：** 小程序端不直接操作数据库，所有数据通过后端 API 获取。

## 第一版交互流程

```
用户打开小程序
  → 静默调用 wx.login 获取 code
  → 发 code 给后端 → 后端换 openid → 返回自定义 token
  → 首页加载数据（API 带 token）
  → 点击进入详情
  → 在用户中心查看个人信息
  → token 过期 → 后端返回 401 → 前端重新走登录流程
```

## 安全规则
- AppSecret 只存后端环境变量
- wx.login 的 code 由前端获取，发给后端，后端调用 `https://api.weixin.qq.com/sns/jscode2session`
- 后端返回自定义 token，前端存本地
- 所有 API 请求必须带 token
- 敏感操作在后端记日志

## 第一版运行方式

```bash
# 后端
cd server
npm install
npm run dev

# 小程序端
用微信开发者工具打开 miniapp 目录
在开发者工具中预览
```

## 后续扩展方向
- 微信支付
- 分享功能
- 订阅消息
- 扫码功能
- 客服消息
