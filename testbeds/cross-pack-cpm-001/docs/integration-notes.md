# CPM-001 集成笔记: miniapp ↔ ecommerce ↔ admin-system

> 三个 Pack 如何交互、共享什么、以及哪些地方最容易出错。

---

## 1. 架构总览

```
┌─────────────────┐     ┌──────────────────────────────┐     ┌─────────────────┐
│  微信小程序      │────▶│        Backend API            │◀────│  管理后台        │
│  (miniapp)      │     │  Fastify + PostgreSQL + Prisma │     │  (admin-system) │
│                 │     │                              │     │  Next.js        │
│  • 商品浏览     │     │  /api/products               │     │  • 商品管理     │
│  • 购物车       │     │  /api/cart                   │     │  • 订单管理     │
│  • 下单         │     │  /api/orders                 │     │  • 用户管理     │
│  • 支付         │     │  /api/payment                │     │  • 权限管理     │
│  • 我的订单     │     │  /api/admin/*                │     │  • 审计日志     │
│                 │     │  /api/auth/wechat/login       │     │  • 数据统计     │
│                 │     │  /api/auth/admin/login        │     │                │
└─────────────────┘     └──────────────────────────────┘     └─────────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────┐
                    │     PostgreSQL          │
                    │  users, products,       │
                    │  cart_items, orders,     │
                    │  order_items, payments,  │
                    │  inventory_logs,         │
                    │  audit_logs              │
                    └─────────────────────────┘
```

**共享层**: Backend API 是 miniapp 和 admin-system 的**唯一共享点**。不存在 miniapp 直接访问 admin-system 或反向通信。

---

## 2. 共享实体与数据流

### 2.1 用户 (users)

| 字段 | miniapp 视角 | admin-system 视角 | 冲突风险 |
|------|-------------|-------------------|---------|
| `id` | 用户唯一标识 | 同 | — |
| `openid` | 微信登录获得 | 不可见/脱敏 | **中**: 管理员不应看到 OPENID 明文 |
| `role` | 固定为 `user` | admin 可提升为 `admin` | **高**: 权限提升需审计 |
| `auth_provider` | `wechat` | 管理员可为 `password` | **低**: 两种登录方式共存 |

**数据流**: 用户在 miniapp 通过微信登录创建 → 管理员在后台将用户 role 提升为 `admin` → 该用户可登录后台。

### 2.2 商品 (products)

| 字段 | miniapp 视角 | admin-system 视角 | 冲突风险 |
|------|-------------|-------------------|---------|
| `status` | 只看 `published` | CRUD 全部状态 | **中**: 状态机保护 |
| `price` | 只读 | 读写 | **低** |
| `stock` | 只读 (展示) | 读写 (管理) | **高**: 库存变更需日志 |

**数据流**: 管理员在后台创建商品 (draft) → 发布 (published) → 小程序可见 → 用户下单 → 库存扣减 → 管理员可下架 (archived)。

### 2.3 订单 (orders)

| 字段 | miniapp 视角 | admin-system 视角 | 冲突风险 |
|------|-------------|-------------------|---------|
| `user_id` | 自己的订单 | 全量 + 筛选 | **高**: 资源归属检查 |
| `status` | 查看 + 取消 | 查看 + 发货 + 退款 | **高**: 状态流转并发 |
| `idempotency_key` | 提交时生成 | 可见 (调试) | **中**: 防重复提交 |

**数据流**: 用户在 miniapp 创建订单 (pending) → 支付 (paid) → 管理员发货 (shipped) → 用户确认收货 (completed) 或管理员处理退款 (refunding → refunded)。

### 2.4 购物车 (cart_items)

- **miniapp 独占**: 用户在小程序管理购物车
- **admin-system**: 不可见 (购物车是用户私有数据)
- **数据流**: 下单成功后，购物车对应项清除

---

## 3. Auth 桥接 (关键风险点)

```
MINIAPP 登录流程:
  用户点击登录 → wx.login() 获取 code → 服务端 code2session → 获取 OPENID
  → 查找或创建用户 → 签发 JWT token (含 user_id, role=user)
  → 返回 token 给小程序 → 小程序存储 token → 后续请求带 Authorization header

ADMIN 登录流程:
  管理员打开后台 → 输入用户名+密码 → 服务端 bcrypt 验证
  → 检查 role=admin → 签发 JWT token (含 user_id, role=admin)
  → 返回 token → 浏览器存储 → 后续请求带 Authorization header

共享中间件:
  authMiddleware(token) → 解析 JWT → 查询用户 → 检查账号未禁用
  → 将 { userId, role } 注入 request context
```

**风险**:
1. 小程序用户通过 API 修改 role 字段 → **必须**: role 字段不暴露在用户可写的 API body 中
2. Token 泄露 → **必须**: token 过期 ≤ 24h，支持 refresh
3. 管理员账号被盗 → **必须**: 敏感操作记录 audit_log

---

## 4. 最容易出错的 10 个集成点

### 🔴 P0 — 会导致数据损坏或资金损失

1. **库存扣减竞态**
   - 场景: 两人同时购买最后一件商品
   - 错误: `SELECT stock → stock > 0 → UPDATE stock = stock - 1` (非原子)
   - 正确: `UPDATE products SET stock = stock - 1 WHERE id = ? AND stock >= 1; CHECK affected rows`
   - **必须在事务中**

2. **重复下单**
   - 场景: 用户网络卡顿，连续点击两次"提交订单"
   - 错误: 无幂等保护 → 创建两个订单 + 扣两次库存
   - 正确: `orders.idempotency_key UNIQUE` → 第二次插入冲突 → 返回已有订单

3. **支付回调与订单状态不同步**
   - 场景: 微信支付成功回调到达时，订单已被管理员取消
   - 错误: 直接更新为 paid 覆盖 cancelled
   - 正确: 回调中检查当前状态，只在 `pending` 时转为 `paid`，否则记录异常日志

4. **管理员权限提升无审计**
   - 场景: 管理员 A 将普通用户 B 提升为 admin
   - 错误: 直接 UPDATE role，无日志
   - 正确: 事务中 UPDATE + INSERT audit_log，记录操作人和被操作人

### 🟡 P1 — 会导致业务异常，但可恢复

5. **商品发布后小程序缓存**
   - 场景: 管理员发布商品，小程序用户看不到
   - 原因: 小程序端列表缓存
   - 修复: 列表页下拉刷新强制重新请求

6. **订单状态流转冲突**
   - 场景: 管理员发货同时用户取消订单
   - 错误: 两个操作同时成功，状态不确定
   - 正确: 使用条件 UPDATE (`WHERE status = ?`) 或乐观锁 (`version` 字段)

7. **管理后台删除商品后小程序报错**
   - 场景: 管理员删除商品，用户购物车/订单中仍有该商品
   - 正确: 使用软删除 (archived)，已有订单保留商品快照 (order_items 存储下单时的 name/price)

### 🟢 P2 — 会影响用户体验

8. **管理后台分页参数不一致**
   - 场景: 前端传 `pageSize`，后端收 `limit`
   - 正确: 统一使用 `page` + `limit`

9. **小程序弱网环境**
   - 场景: 网络不稳定，API 超时
   - 正确: 显示友好错误提示 + 重试按钮；提交操作加 loading 态防重复

10. **.env 泄露**
    - 场景: 开发者误提交 .env 到 git
    - 正确: .gitignore 含 .env，提供 .env.example 不含真实密钥

---

## 5. 集成验证清单

在开始编码前，以下项目必须确认：

- [ ] 微信小程序 AppID 和 AppSecret 已获取
- [ ] 微信商户平台 AppID、API v3 密钥、证书已获取
- [ ] PostgreSQL 数据库已就绪，连接字符串已知
- [ ] 管理后台域名已确定 (用于 CORS 配置)
- [ ] 支付回调 URL (notify_url) 已规划 (需 HTTPS 公网可达)
- [ ] 管理员初始账号创建流程已确定
- [ ] semgrep 规则已配置
- [ ] playwright 测试环境已安装
- [ ] autocannon 压测场景已定义

---

## 6. 禁止模式

- ❌ 小程序端直接调用 `wx.requestPayment` 而不经过服务端预下单
- ❌ 管理后台通过 iframe 嵌入小程序 (跨域 + 安全)
- ❌ 订单金额在前端计算 (必须服务端从数据库重新计算)
- ❌ 管理员可以修改订单金额 (只允许退款操作)
- ❌ 用户表 OPENID 明文暴露在管理后台列表
- ❌ 支付回调端点不做签名验证
