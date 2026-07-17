# Codex Benchmark Suite

> 8 个专门测试 Codex 项目生成能力的 benchmark 项目。
> 目标是检验 Codex_App_Factory 是否能稳定提升 Codex，不用于真实业务。

---

## Benchmark 1: Content Site — 教育机构招生落地页

**一句话需求**:
> 帮我做一个编程培训机构的招生落地页，展示课程、师资、学员案例和报名方式。

**预期项目类型**: content-site / landing-page
**预期体量等级**: S
**预期 starter**: `vite-react-content-site`
**不应选择的 starter**: next-fullstack-admin, next-saas-ai-tool, node-api-postgres

**第一阶段最小闭环**:
- 单页落地页，包含 Hero / 课程介绍 / 师资 / 案例 / CTA
- 内容从 siteContent.ts 统一管理
- CTA 跳转到联系区域（placeholder 联系方式）
- 响应式适配

**暂不实现内容**:
- 数据库 / 登录 / 后台管理
- 在线报名表单提交
- 支付 / 课程购买
- 真实学员数据

**最容易出错的点**:
- 冲动加上登录和后台
- 把 landing page 做成 mini CMS
- 引入数据库存储"报名信息"

**通过标准**:
- 项目类型判断正确
- 选择 vite-react-content-site
- 未引入数据库/登录/后台
- install/typecheck/build/dev 全通过

**失败标准**:
- 创建了数据库表
- 加了 NextAuth
- 把报名做成了表单提交到后端

---

## Benchmark 2: Fullstack Admin — 课程报名管理系统

**一句话需求**:
> 帮我做一个课程报名管理系统，学生可以提交报名信息，管理员可以登录后台查看报名列表，搜索筛选报名记录，修改报名状态。

**预期项目类型**: fullstack-admin
**预期体量等级**: M
**预期 starter**: `next-fullstack-admin`
**不应选择的 starter**: vite-react-content-site, next-saas-ai-tool

**第一阶段最小闭环**:
- 管理员登录（mock auth）
- Dashboard 展示报名统计
- 报名记录列表页 + 搜索筛选
- 报名详情页 + 状态修改
- Mock 数据（不接真实数据库）
- 统一 API 返回格式

**暂不实现内容**:
- 真实数据库
- 真实认证
- 学生公开报名表单
- 短信/邮件通知
- Excel 导出
- 复杂审批流

**最容易出错的点**:
- 把 mock-db 当正式数据库用
- 忘记服务端校验
- 详情页依赖列表页 state 传参而非通过 id 获取
- 状态修改不做枚举校验

**通过标准**:
- 项目类型判断正确
- 选择 next-fullstack-admin
- 所有 mock 数据有明确注释
- API 统一格式 + 服务端校验
- install/typecheck/build/dev 全通过

**失败标准**:
- 直接连了 PostgreSQL
- 没有服务端校验
- 改了 starter 但没有保持 API 统一格式

---

## Benchmark 3: SaaS AI Tool — AI 文案生成网站

**一句话需求**:
> 帮我做一个 AI 文案生成网站，用户输入主题后生成一段宣传文案，系统需要记录生成历史，并显示用户剩余生成次数。

**预期项目类型**: saas-tool / ai-tool
**预期体量等级**: M-L
**预期 starter**: `next-saas-ai-tool`
**不应选择的 starter**: next-fullstack-admin, vite-react-content-site

**第一阶段最小闭环**:
- Mock AI provider (无真实 API key)
- 工具页: 输入主题 → 生成文案 → 展示结果
- 额度管理: mock 初始 20 次，成功扣 1，失败不扣
- 生成历史: 按用户隔离，支持分页
- 账户页: 显示总次数/已用/剩余

**暂不实现内容**:
- 真实 AI API
- 真实数据库
- 支付/订阅
- 多租户
- OpenAI SDK / LangChain / Anthropic SDK

**最容易出错的点**:
- 在前端代码写真实 API key
- 生成失败仍然扣减额度
- 没有幂等保护
- 历史记录没有按用户隔离

**通过标准**:
- 项目类型判断正确
- 选择 next-saas-ai-tool
- mock provider 无真实 key
- 额度扣减在服务端
- 生成失败不扣次数
- 历史按用户隔离
- 前端无 API key
- install/typecheck/build/dev 全通过

**失败标准**:
- 安装了 OpenAI SDK
- 前端代码中有 API key
- 生成失败扣了次数
- 没做额度检查

---

## Benchmark 4: API Service — 小程序签到后端 API

**一句话需求**:
> 帮我做一个小程序签到功能的后端 API，用户签到获得积分，连续签到有额外奖励，管理员可以看签到统计。

**预期项目类型**: api-service / backend-service
**预期体量等级**: M
**预期 starter**: `node-api-postgres`
**不应选择的 starter**: next-fullstack-admin, vite-react-content-site

**第一阶段最小闭环**:
- POST /api/sign-in — 签到
- GET /api/sign-in/status — 签到状态（连续天数、积分）
- GET /api/admin/sign-in/stats — 管理员统计
- Mock 数据库 + 事务注释
- 统一 API 返回格式
- 幂等 key 占位
- 连续签到逻辑

**暂不实现内容**:
- 前端页面/小程序
- 真实数据库
- 真实认证
- 积分兑换/商城
- 推送通知

**最容易出错的点**:
- 签到一天可以签多次
- 并发签到时的积分重复发放
- 管理员 API 没做权限占位
- 没有幂等 key

**通过标准**:
- 项目类型判断正确
- 选择 node-api-postgres
- 纯 API 项目，无前端页面
- 签到有防重复逻辑
- 连续签到奖励正确
- 管理员接口有权限占位
- install/typecheck/build/dev 全通过

**失败标准**:
- 创建了前端页面
- 同一天可重复签到
- 没有事务注释
- 管理员接口无权限保护

---

## Benchmark 5: Three.js Interactive — 可点击虚拟展厅

**一句话需求**:
> 帮我做一个 3D 虚拟展厅，用户可以旋转视角看展品，点击展品弹出信息框，信息框用 HTML/CSS 来做不要用 Three.js 做 UI。

**预期项目类型**: threejs-interactive / 3d-web-prototype
**预期体量等级**: M
**预期 starter**: `vite-threejs-interactive`
**不应选择的 starter**: vite-react-content-site, next-fullstack-admin

**第一阶段最小闭环**:
- Three.js 场景 + 基础灯光/相机
- 3-5 个展品对象（简单几何体）
- 点击展品 → Raycaster 检测 → 弹出 HTML 信息卡片
- 对象注册表 (object registry)
- UI 层与 Three.js 层分离
- 自适应屏幕

**暂不实现内容**:
- 复杂 3D 模型/GLTF 加载
- 物理引擎
- 多人同步
- 音视频
- 移动端手势

**最容易出错的点**:
- 用 Three.js sprite 做 UI 而不是 HTML/CSS
- 没有对象 registry，展品信息硬编码在 click handler
- 没有清理 Three.js 资源（内存泄漏）
- 相机控制太自由导致迷失

**通过标准**:
- 项目类型判断正确
- 选择 vite-threejs-interactive
- UI 与 Three.js 分离
- 有点击交互和对象注册表
- install/typecheck/build/dev 全通过

**失败标准**:
- 用 Three.js 做文字 UI
- 对象信息硬编码
- 没有 Raycaster
- 没有对象注册表

---

## Benchmark 6: L 级业务原型 — 医院理疗核销系统原型

**一句话需求**:
> 帮我做一个医院中医理疗核销系统的原型：患者来做理疗时，医师扫码/选择患者核销理疗次数；管理端知道谁的次数快用完、今日核销量、异常核销预警。

**预期项目类型**: fullstack-admin（但体量更大）
**预期体量等级**: L
**预期 starter**: `next-fullstack-admin`
**升级条件**: 达到 M 级后考虑是否升级到多模块架构

**第一阶段最小闭环**:
- 管理后台页面原型
- 患者管理（姓名、理疗项目、剩余次数）
- 核销流程（点选患者 → 确认核销 → 扣减次数）
- 核销记录列表
- 仪表盘统计（今日核销、即将耗尽列表）
- Mock 数据 + 事务注释
- 权限边界文档

**暂不实现内容**:
- 真实数据库
- 真实认证
- 扫码（硬件集成）
- 头像防代班（图像识别）
- 异常检测算法
- 支付/医保对接
- 多院区
- 消息推送

**最容易出错的点**:
- 把原型当成正式系统做
- 扣减次数没有事务保护
- 没考虑并发核销
- 忽略了审计字段
- 权限设计过于简单（医师能看所有患者）

**通过标准**:
- 判断了 L 级体量
- 明确说明第一步只做原型
- 指出防代班/审计/异常检测的风险但暂不做
- 核销有事务注释
- 有 createdAt/updatedAt 审计字段

**失败标准**:
- 直接做成正式系统
- 接真实数据库
- 忽略审计安全
- 没提到头像防代班风险

---

## Benchmark 7: Multi-surface App — 学生 + 老师 + 管理后台 + API

**一句话需求**:
> 帮我做一个学习系统：学生端可以看自己的学习计划和完成任务；老师端可以发布任务和批改；管理后台可以看所有学生和老师的统计数据；所有数据通过 API 交互。

**预期项目类型**: 多端项目（学生前端 + 老师前端 + 管理后台 + API Service）
**预期体量等级**: XL
**预期 starter**: 需要组合 — `node-api-postgres` (API) + `next-fullstack-admin` (后台) + `vite-react-content-site` (学生/老师前端)
**不应选择的**: 单一 starter

**第一阶段最小闭环**:
- API Service: 学生 CRUD、任务 CRUD、完成/批改 API
- 管理后台: 学生列表 + 任务概览统计
- 学生端: 任务列表 + 完成按钮
- 老师端: 任务发布 + 批改页面
- 所有数据通过 API 交互
- Mock 数据库 + 权限占位

**暂不实现内容**:
- 真实数据库
- 真实认证
- 实时通知
- 文件上传
- 视频/语音
- 排名/积分

**最容易出错的点**:
- 把所有功能塞进一个 next-fullstack-admin
- 学生端和老师端权限不分
- API 不做统一格式
- 没规划项目边界（API + 3 个前端 = 4 个子项目）

**通过标准**:
- 判断为 XL 多端项目
- 明确需要拆分项目边界
- 第一阶段只做其中一个子项目
- 说明了完整的项目拆分方案

**失败标准**:
- 全部塞进一个 next-fullstack-admin
- 没有分项目
- 权限混在一起

---

## Benchmark 8: Stress Test — 线上剧本杀互动世界 Web 原型

**一句话需求**:
> 帮我做一个线上剧本杀互动世界的 Web 原型：有 3D 场景可探索，有角色和线索系统，主持人可以控制游戏阶段和分发线索，玩家可以在地图上看到自己的位置和任务。

**预期项目类型**: threejs-interactive + fullstack-admin（主持人面板）
**预期体量等级**: XL
**预期 starter**: 需要组合 — `vite-threejs-interactive` (3D 场景) + `next-fullstack-admin` (主持人面板)

**第一阶段最小闭环**:
- 3D 场景: 一个房间 + 2-3 个可交互道具（点击显示线索）
- 主持人面板: 控制游戏阶段、分发线索给玩家
- 小地图: 俯视图显示玩家位置
- 任务面板: 每个玩家看到自己的任务
- 双端状态同步占位 (WebSocket/Socket.IO 注释)
- Mock 剧本数据

**暂不实现内容**:
- 真实多人在线
- WebSocket 真实连接
- 完整剧本内容
- GLTF 美术资源
- 移动端
- 音视频通话
- AI 主持人

**最容易出错的点**:
- 过度架构（微服务、消息队列、分布式状态）
- 把 3D 交互信息放在 Three.js 里面而不是 UI 层
- 主持人面板和 3D 场景共用同一个项目导致混乱
- 没有明确项目边界

**通过标准**:
- 判断为 XL 复杂度
- 明确拆分 3D 场景和主持人面板
- 说明了双端同步占位方案
- 第一阶段只做单机原型
- 指出不做微服务

**失败标准**:
- 架构过度设计
- Three.js 和业务逻辑混在一起
- 没有 UI 与 3D 分离
- 第一天就上 WebSocket 真实连接

---

## Benchmark 总览

| # | 名称 | 类型 | 体量 | Starter | 核心测试点 |
|---|---|---|---|---|---|
| 1 | 教育机构招生落地页 | content-site | S | vite-react-content-site | 不乱加后台 |
| 2 | 课程报名管理系统 | fullstack-admin | M | next-fullstack-admin | mock-auth/mock-db 边界 |
| 3 | AI 文案生成网站 | saas-tool | M-L | next-saas-ai-tool | mock AI/额度/幂等 |
| 4 | 小程序签到 API | api-service | M | node-api-postgres | 纯 API/事务/幂等 |
| 5 | 可点击虚拟展厅 | threejs | M | vite-threejs-interactive | UI 与 3D 分离 |
| 6 | 理疗核销系统原型 | fullstack-admin | L | next-fullstack-admin | 原型/审计/安全风险 |
| 7 | 多端学习系统 | multi-surface | XL | 组合 | 项目边界拆分 |
| 8 | 剧本杀互动世界 | threejs+admin | XL | 组合 | 复杂度控制/架构 |

## 跑 Benchmark 规则

1. 每次只跑 1 个 benchmark
2. 必须完整执行: Project Expertise Flow → Starter Selection → Copy → Brief → 改造 → Runtime Validation
3. 跑完后对照 CODEX_CAPABILITY_SCORECARD.md 打分
4. 发现工厂级缺陷必须回流修复
5. 每个 benchmark 输出独立评分报告