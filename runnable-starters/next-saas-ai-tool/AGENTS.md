# AGENTS.md — next-saas-ai-tool Starter

## 这是什么

`next-saas-ai-tool` 是 Next.js SaaS / AI 工具骨架。用于 AI 文案生成、模板工具、文本处理工具等 saas-tool 项目。

## 适合/不适合

✅ 适合：AI 文案工具、模板生成、文本处理、用户额度、生成历史、简单账户中心
❌ 不适合：官网展示、CRUD 后台、小程序、支付/订阅平台（需升级架构）

## 使用前规则

1. 先读取 `C:\Codex_App_Factory`
2. 先走 Project Expertise Flow + architecture-scaling-ladder 判体量
3. 第一版只做：登录 + 工具页 + 历史 + 额度
4. 不要默认加支付/订阅/多租户/复杂 AI Pipeline
5. API Key 只放后端 `.env`，不进前端代码
6. 额度扣减用事务保护（条件 UPDATE，不是先查再改）
7. 生成失败必须回退额度
8. 重复提交用幂等 Key 保护
9. mock AI 只是 placeholder，真实项目必须替换
10. mock-db 不是正式数据库，重启后数据丢失