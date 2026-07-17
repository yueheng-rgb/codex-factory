# External Skills Research / 现成 Skill 调研清单

> 调研可安装的现成 Codex skills，评估其用途、适用场景和风险。

---

## 调研原则
- 优先官方团队、知名团队、活跃仓库
- 不安装描述夸张的"全能大师"类 skill
- 不运行未知脚本
- 安装前先理解 skill 做什么

---

## 1. fullstack-dev

- **用途：** 全栈开发辅助
- **适用项目：** fullstack-admin、saas-tool
- **是否建议安装：** 🌕 待确认
- **风险：** 可能覆盖本地的 Codex_App_Factory 规则
- **建议：** 安装前先看 SKILL.md 是否与本地规则冲突

## 2. webapp-testing

- **用途：** Web 应用测试（Playwright）
- **适用项目：** 所有 Web 项目
- **是否建议安装：** 🌕 待确认
- **风险：** 低（测试技能通常不冲突）
- **建议：** 如果能增强 Playwright smoke test 能力，推荐安装

## 3. frontend-design

- **用途：** 前端 UI 设计
- **适用项目：** 所有有前端的项目
- **是否建议安装：** ⚠️ 谨慎
- **风险：** 可能与本地 frontend-ui-system skill 冲突，可能引入 AI 味设计
- **建议：** 先看 SKILL.md 的设计风格倾向，如果偏向"AI 味"则不装

## 4. next-best-practices

- **用途：** Next.js 最佳实践
- **适用项目：** 所有 Next.js 项目
- **是否建议安装：** 🌕 待确认
- **风险：** 低
- **建议：** 如果是 Vercel 官方或知名团队出品，推荐安装

## 5. postgres-best-practices / supabase-postgres-best-practices

- **用途：** PostgreSQL 最佳实践
- **适用项目：** 所有使用 PostgreSQL 的项目
- **是否建议安装：** 🌕 待确认
- **风险：** 低
- **建议：** 数据库最佳实践通常有益，推荐安装

## 6. better-auth-best-practices

- **用途：** better-auth 认证库最佳实践
- **适用项目：** 使用 better-auth 的项目
- **是否建议安装：** 🌕 待确认
- **风险：** 低
- **建议：** 如果项目使用 better-auth 则推荐

## 7. web-quality-audit

- **用途：** Web 质量审计
- **适用项目：** 所有 Web 项目
- **是否建议安装：** 🌕 待确认
- **风险：** 可能检查标准与本地规则不一致
- **建议：** 先看检查项是否与本地规则互补

## 8. react-native-best-practices

- **用途：** React Native 最佳实践
- **适用项目：** mobile-app 类型
- **是否建议安装：** 🌕 待确认
- **风险：** 低
- **建议：** 如果做 Expo/RN 项目则推荐

## 9. Trail of Bits security skills

- **insecure-defaults** — 不安全默认值检测
- **static-analysis** — 静态分析
- **sharp-edges** — 尖锐边缘（安全边界）
- **适用项目：** 所有涉及安全的项目
- **是否建议安装：** ✅ 推荐
- **风险：** 低
- **建议：** Trail of Bits 是知名安全团队，这些 skill 能增强安全检测能力

---

## 安装计划

### 当前状态
由于不能联网查询来源，先创建此调研清单。待有网络后：

1. 用 `skill-installer` 查询每个 skill 的详细信息
2. 确认来源可信后，逐个安装
3. 安装后检查是否与本地规则冲突

### 优先安装顺序
1. Trail of Bits 安全 skills（安全性优先）
2. postgres-best-practices（数据库质量）
3. webapp-testing（测试能力）
4. 其他按项目需要安装
