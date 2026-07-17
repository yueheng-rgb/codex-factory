# App Type Classifier

## 用途
根据用户需求自动判断应用类型，防止 Codex 把简单需求做成最复杂的系统。

## 使用场景
- 每次接到新项目需求时
- 用户需求描述模糊需要归类时

## 判断规则

### 触发关键词 → 类型映射

| 关键词 | 类型 | 默认策略 |
|--------|------|---------|
| 后台、管理、统计、账号、表格、记录、权限、审核 | fullstack-admin | 需要登录 + 数据库 + CRUD |
| 官网、宣传、展示、介绍、落地页、活动页、报名页 | content-site | 纯前端为主，可能有简单表单 |
| AI生成、模板、生成历史、额度、次数、会员、订阅 | saas-tool | 需要登录 + 额度 + 生成历史 |
| 接口、后端、API、数据库服务、给前端调用 | api-service | 纯后端，无前端页面 |
| 小程序、微信、OPENID、扫码、公众号 | miniapp | 小程序前端 + 后端 API |
| App、安卓、iOS、React Native、Expo、Flutter | mobile-app | Expo/RN 前端 + 后端 API |
| 3D、场景、Three.js、地图、可点击物体、虚拟空间 | threejs-interactive | Vite + Three.js 纯前端 |

### 多关键词匹配
如果需求同时满足多个类型的关键词：
1. 统计每个类型的匹配关键词数
2. 选匹配数最多的类型
3. 如果并列，优先选更简单的类型

### 不要默认做成最复杂系统
- 用户说"做一个页面" → content-site，不是 fullstack-admin
- 用户说"做一个工具" → 先判断是不是 saas-tool
- 用户说"管理XX数据" → fullstack-admin，但只做最小 CRUD

## 输出格式
```
## 应用类型判断
- **类型：** [类型名称]
- **匹配关键词：** [命中的关键词列表]
- **推荐 starter：** [starter 文件名]
- **推荐 blueprint：** [blueprint 文件名]
- **推荐 skills：** [相关 skills 列表]
- **理由：** [为什么选这个类型]
```
