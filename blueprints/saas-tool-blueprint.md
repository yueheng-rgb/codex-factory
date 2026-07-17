# SaaS / AI Tool Blueprint

## 用户需求拆解

当用户说"做一个 XX 生成工具/SaaS"时，按以下步骤拆解：

### 最少必要问题
1. 用户输入什么？（文字/图片/文件）
2. 系统生成什么？（输出什么）
3. 怎么计费？（按次数 / 按月 / 免费试用）
4. 有没有免费额度？（默认给多少）
5. 需要会员等级吗？（默认只做一种额度）
6. 用户怎么注册？（开放注册 / 邀请制）

### 不能默认乱加的内容
- ❌ 不要默认做多级会员
- ❌ 不要默认做支付集成
- ❌ 不要默认做团队/多租户
- ❌ 不要默认做复杂 AI Pipeline
- ❌ 不要默认做消息通知

## 第一版页面结构

```
/                →  落地页（介绍工具 + CTA）
/login           →  登录页
/register        →  注册页
/dashboard       →  用户控制台（额度显示 + 快捷入口）
/generate        →  生成工具页（核心：输入 → 生成 → 结果展示）
/history         →  生成历史列表
/settings        →  账号设置（可选，第一版可不做）
```

**不需要做的页面（第一版）：**
- 会员/定价页
- 支付页
- 团队管理
- 数据分析仪表盘

## 第一版数据结构

```
users
  id (PK)
  email (UNIQUE)
  password_hash
  quota_total     -- 总配额
  quota_used      -- 已使用配额（默认0）
  is_active
  created_at
  updated_at

generation_history
  id (PK)
  user_id (FK)
  input           -- 用户输入（JSON或text）
  output          -- 生成结果（JSON或text）
  type            -- 生成类型
  status          -- pending/processing/completed/failed
  created_at

user_quota_logs   -- 配额变动日志（审计用）
  id (PK)
  user_id (FK)
  change_amount   -- 变动量（正=增加，负=扣除）
  reason
  created_at

api_logs          -- API 调用日志
  id (PK)
  user_id (FK)
  endpoint
  method
  status_code
  duration_ms
  created_at
```

## 第一版交互流程

```
用户访问落地页 → 了解工具 → 注册/登录
  → 进入控制台 → 看到剩余额度
  → 进入生成页 → 输入内容 → 点击生成
  → 系统检查额度（事务：扣额度 + 生成在一个事务中）
  → 生成中（显示 loading）
  → 成功 → 展示结果 + 扣减额度
  → 失败 → 不扣额度 + 显示错误 + 可重试
  → 可在历史页查看所有生成记录
```

## 第一版运行方式

```bash
npm install
cp .env.example .env
npx prisma migrate dev
npm run dev
```

## 后续扩展方向
- 支付集成
- 会员等级
- 配额套餐
- 批量生成
- 结果分享
- 模板市场
