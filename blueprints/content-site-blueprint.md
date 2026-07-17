# Content Site Blueprint

## 用户需求拆解

当用户说"做一个 XX 网站/落地页"时，按以下步骤拆解：

### 最少必要问题
1. 网站目的是什么？（品牌展示 / 产品介绍 / 活动报名 / 内容发布）
2. 目标用户是谁？（To B / To C / 投资人）
3. 主要内容是什么？（产品 / 服务 / 文章 / 作品）
4. 需要哪些页面？（首页 + 列表 + 详情 + 关于 + 联系）
5. 内容是会变还是静态？（决定要不要 CMS）
6. 需要表单吗？（咨询表单 / 报名表单）

### 不能默认乱加的内容
- ❌ 不要默认加用户注册/登录
- ❌ 不要默认加数据库
- ❌ 不要默认加持久的 CMS 后台
- ❌ 不要默认加支付功能
- ❌ 不要默认加评论系统

## 第一版页面结构

```
/           →  首页（Hero + 核心卖点/特色 + CTA 按钮）
/products   →  产品/服务列表页
/products/1 →  产品/服务详情页
/about      →  关于页
/contact    →  联系页（含表单，可选）
```

**不需要做的页面（第一版）：**
- 搜索页
- 用户个人中心
- 后台管理
- 博客（除非明确要求）

## 第一版数据结构

如果是纯静态站：数据放 JSON 文件或 Markdown

```typescript
// products.json
[
  {
    "id": "1",
    "title": "产品名称",
    "description": "简短描述",
    "image": "/images/product1.jpg",
    "features": ["特性1", "特性2"],
    "cta_text": "了解更多",
    "cta_link": "/contact"
  }
]
```

如果有报名表单：简单后端存数据
```
submissions
  id (PK)
  name
  email
  phone
  message
  created_at
```

## 第一版交互流程

```
用户访问网站 → 看到首页 Hero → 向下滚动看卖点
  → 点击 CTA → 跳转产品/服务页
  → 浏览列表 → 点击进入详情
  → 有兴趣 → 去联系页提交表单
  → 提交成功 → 显示感谢信息
```

## 第一版运行方式

```bash
npm install
npm run dev       # Vite 开发服务器
```

## 后续扩展方向
- 多语言
- 博客/文章
- SEO 优化（sitemap, structured data）
- 数据分析（Google Analytics）
- CMS 后台
- 用户反馈收集
